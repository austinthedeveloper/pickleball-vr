## Dinking online with a friend (ADR-027, after the port kit's ADR-056):
## the handshake, then rollback. The host opens a room; the guest joins it.
## Each sends HELLO (the game's version and protocol, their look); the
## versions must match. The host's START sends the match (the config and
## venue) so both build the same Sim. The host plays slot 0 (the near
## side), the guest slot 2. QUIT leaves; a lost line closes it.
##
## Each sim tick the view calls tick() with your HumanInput and draws
## `rollback.pred`. A tick's messages go out together at the next poll(),
## one frame of the line ("B"), not one per tick.
class_name OnlineSession
extends RefCounted

const PROTOCOL := 1
const IDLE := 0
const WAITING := 1               ## the host's room open, or the guest connecting
const CONNECTED := 2             ## both said HELLO
const PLAYING := 3
const CLOSED := 4

var link: NetLink
var host := false
var state := IDLE
var reason := ""                 ## why it closed, for the screen
var my_hello := {}
var peer_hello := {}             ## the other side's {version, protocol, look}
var start := {}                  ## the match, from START
var rollback: Rollback
var _pending_cmds := []          ## your commands since the last step
var _out := []                   ## messages for the next poll
var _hello_sent := false
var _waited := 0                 ## ticks in a row that couldn't step


func _init(l: NetLink = null, is_host := false) -> void:
	link = l
	host = is_host
	if link:
		state = WAITING


## {version, protocol, look} for HELLO: this game and its player.
static func hello(look := {}) -> Dictionary:
	return {"version": RelayLink.version(), "protocol": PROTOCOL, "look": look.duplicate()}


func poll() -> void:
	if link == null or state == CLOSED:
		return
	_flush()
	link.poll()
	for m in link.receive():                 # first: a QUIT may come with the close
		if m[0] == "B":
			for b in m[1]:
				_on(b)
				if state == CLOSED:
					return
		else:
			_on(m)
		if state == CLOSED:
			return
	if link.status() == NetLink.CLOSED:
		_close(link.error if link.error != "" else "CONNECTION LOST")
		return
	if link.status() == NetLink.CONNECTED and not _hello_sent and not my_hello.is_empty():
		link.send(["HELLO", my_hello])
		_hello_sent = true


func _flush() -> void:
	if _out.size() == 1:
		link.send(_out[0])
	elif _out.size() > 1:
		link.send(["B", _out])
	_out = []


func _on(m: Array) -> void:
	match m[0]:
		"HELLO":
			peer_hello = m[1]
			if int(peer_hello.get("protocol", 0)) != PROTOCOL \
					or String(peer_hello.get("version", "")) != String(my_hello.get("version", "")):
				link.send(["QUIT", "VERSION"])
				_close("VERSIONS DIFFER: %s AND %s" % [my_hello.get("version", "?"),
					peer_hello.get("version", "?")])
				return
			if state == WAITING:
				state = CONNECTED
		"START":
			start = m[1]
			_build(2, 0)
			state = PLAYING
		"QUIT":
			_close("VERSIONS DIFFER" if m.size() > 1 and m[1] == "VERSION" else "YOUR FRIEND LEFT")
		"I", "H":
			if rollback:
				rollback.on_message(m)


## The host starts the match: both build it from `info` ({cfg, venue}).
func begin(info: Dictionary) -> void:
	start = info.duplicate(true)
	link.send(["START", start])
	_build(0, 2)
	state = PLAYING


func _build(local: int, remote: int) -> void:
	rollback = Rollback.new(config_from_dict(start["cfg"]), local, remote,
		int(start.get("delay", Rollback.DELAY)))


## The slot you play: the host's near side, the guest's far side.
func slot() -> int:
	return 0 if host else 2


## One sim tick: your input goes in, with any commands since the last
## step; what it played comes out (Rollback.tick's). A desync closes it.
func tick(local: SimTypes.HumanInput) -> Dictionary:
	if rollback == null or state != PLAYING:
		return {"stepped": false, "send": [], "played": []}
	var out := rollback.tick(local, _pending_cmds)
	_out.append_array(out["send"])
	if out["stepped"]:
		_pending_cmds = []
		_waited = 0
	else:
		_waited += 1
	if rollback.desync >= 0:
		link.send(["QUIT"])
		_close("OUT OF SYNC AT TICK %d" % rollback.desync)
	return out


## Ticks in a row this side has waited for the other.
func waited() -> int:
	return _waited


## A command for the match (K.CMD_*): sent with your next input.
func command(c: Array) -> void:
	_pending_cmds.append(c)


func quit() -> void:
	if link and state != CLOSED:
		_flush()
		link.send(["QUIT"])
		link.poll()
	_close("")


func closed() -> bool:
	return state == CLOSED


func _close(why: String) -> void:
	if state == CLOSED:
		return
	state = CLOSED
	reason = why
	if link:
		link.close()


## MatchConfig to a Dictionary and back (START): its plain values. The
## CPUs' styles and a drill's settings don't travel: FRIENDLY DINK has none.
static func config_to_dict(cfg: SimTypes.MatchConfig) -> Dictionary:
	var d := {}
	for p in cfg.get_property_list():
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var v = cfg.get(p["name"])
			if v is int or v is bool or v is String:
				d[p["name"]] = v
	return d


static func config_from_dict(d: Dictionary) -> SimTypes.MatchConfig:
	var cfg := SimTypes.MatchConfig.new()
	for k in d:
		var v = d[k]
		cfg.set(k, int(v) if v is float else v)
	return cfg


## FRIENDLY DINK's config, for begin().
static func friendly_config(seed := 1994) -> SimTypes.MatchConfig:
	var cfg := SimTypes.MatchConfig.new()
	cfg.friendly = true
	cfg.humans = 2
	cfg.seed = seed
	return cfg
