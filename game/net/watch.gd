## COACH VIEW (ADR-028): a coach's game watches a player's drill by
## running it too. The player's headset (WatchFeed) sends the whole state
## once ("W": the config, Sim.save_state, a line about what's on), then
## each tick's input and commands in batches ("T", BATCH ticks, about 15 a
## second: the relay allows 200 messages a second a connection). The
## coach's game (Watch) builds the same Sim and steps it on those inputs,
## a little behind, so what it draws is the player's drill exactly, from
## any angle. A hash every HASH_EVERY ticks checks it; one that differs
## (a TUNING change mid-drill, say) asks for the state again.
##
## Pure: no Nodes, no clock. The Coach node carries the messages.
class_name Watch
extends RefCounted

const BATCH := 8
const HASH_EVERY := 120
const LEAD := 24                 ## ticks kept in hand before stepping (200 ms)
const CATCH_UP := 72             ## past this many in hand, step two a tick

var sim: Sim                     ## the player's drill, as replayed; null till a "W"
var info := {}                   ## {version, lobby, online, player}
var need_state := false          ## out of step: ask for the state again
var resyncs := 0
var _queue: Array = []           ## [PackedInt32Array input or empty, commands] per tick
var _next := 0                   ## the tick the next queued input steps
var _hashes := {}                ## tick -> the player's hash after it
var _playing := false            ## the lead has filled once


## A message from the player's headset.
func on_message(m: Array) -> void:
	match m[0]:
		"W":
			info = m[3]
			if bool(info.get("online", false)):
				sim = null                   # a match with a friend: not watchable (yet)
				return
			var cfg := config_load(m[1])
			sim = Sim.new(cfg)
			sim.load_state(m[2])
			sim.drain_events()
			_queue = []
			_hashes = {}
			_next = sim.tick
			_playing = false
			need_state = false
		"T":
			if sim == null:
				return
			var first := int(m[1])
			if first != _next:
				need_state = true            # a gap: start again from the state
				return
			var cmds: Dictionary = m[3]
			var inputs: Array = m[2]
			for i in inputs.size():
				_queue.append([inputs[i], cmds.get(i, [])])
			_next += inputs.size()
			for h in m[4]:
				_hashes[int(h[0])] = int(h[1])


## Ticks received and not yet stepped.
func buffered() -> int:
	return _queue.size()


## How many ticks to step this sim tick: none till LEAD is in hand, two
## when far behind, else one (none when the queue's empty).
func due() -> int:
	if sim == null or _queue.is_empty():
		_playing = _playing and not _queue.is_empty()
		return 0
	if not _playing:
		if _queue.size() < LEAD:
			return 0
		_playing = true
	return 2 if _queue.size() > CATCH_UP else 1


## Steps the replay one tick: [the human inputs by slot, the commands],
## or null with nothing in hand. Checks the player's hash after it.
func step() -> Variant:
	if sim == null or _queue.is_empty():
		return null
	var e: Array = _queue.pop_front()
	var human: Array = [null, null, null, null]
	var p: PackedInt32Array = e[0]
	if not p.is_empty():
		human[0] = SimTypes.HumanInput.from_array(Array(p))
	sim.step(human, e[1])
	if _hashes.has(sim.tick):
		if _hashes[sim.tick] != sim.state_hash():
			need_state = true
			resyncs += 1
		_hashes.erase(sim.tick)
	return [human, e[1]]


## A MatchConfig whole, the CPUs' styles and a drill's settings with it
## (OnlineSession's config_to_dict keeps only its plain values).
static func config_save(cfg: SimTypes.MatchConfig) -> Dictionary:
	var d := {}
	for p in cfg.get_property_list():
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var v = cfg.get(p["name"])
			if v is int or v is bool or v is String:
				d[p["name"]] = v
	d["style"] = _style(cfg.style)
	d["styles"] = cfg.styles.map(func(s): return _style(s) if s else {})
	if cfg.drill:
		d["drill"] = Sim.object_vars(cfg.drill)
	return d


static func config_load(d: Dictionary) -> SimTypes.MatchConfig:
	var cfg := SimTypes.MatchConfig.new()
	for k in d:
		if k in ["style", "styles", "drill"]:
			continue
		cfg.set(k, d[k])
	cfg.style = SimTypes.CpuStyle.from_dict(d.get("style", {}))
	cfg.styles = (d.get("styles", []) as Array).map(func(s: Dictionary): return SimTypes.CpuStyle.from_dict(s) if not s.is_empty() else null)
	if d.has("drill"):
		cfg.drill = Drill.new()
		Sim.set_object_vars(cfg.drill, d["drill"])
	return cfg


static func _style(s: SimTypes.CpuStyle) -> Dictionary:
	var d := {}
	for k in ["speed", "reaction", "error", "net_rush", "dink", "lob", "drive_pace", "serve_pace", "aim", "miss"]:
		d[k] = s.get(k)
	return d


## The player's side: the state when a drill starts or a coach joins, and
## each tick's input and commands, batched.
class Feed:
	extends RefCounted
	var _inputs: Array = []
	var _cmds := {}
	var _hashes: Array = []
	var _first := 0

	## "W": everything a watcher needs to run `sim` from here.
	func start(sim: Sim, info: Dictionary) -> Array:
		_inputs = []
		_cmds = {}
		_hashes = []
		_first = sim.tick
		if bool(info.get("online", false)):
			return ["W", {}, [], info]
		return ["W", Watch.config_save(sim.config), sim.save_state(), info]

	## One tick the player's sim stepped (MatchView.tap's): the tick it
	## reached, slot 0's input ([] for none), the commands, and the hash
	## when the tick is a HASH_EVERY.
	func add(e: Array) -> void:
		var cmds: Array = e[2]
		if not cmds.is_empty():
			_cmds[_inputs.size()] = cmds.duplicate(true)
		var input: Array = e[1]
		_inputs.append(PackedInt32Array(input))
		if int(e[0]) % Watch.HASH_EVERY == 0:
			_hashes.append([int(e[0]), int(e[3])])

	## A "T" when BATCH ticks are in (or any, with `all`), else [].
	func take(all := false) -> Array:
		if _inputs.size() < Watch.BATCH and not (all and not _inputs.is_empty()):
			return []
		var m := ["T", _first, _inputs, _cmds, _hashes]
		_first += _inputs.size()
		_inputs = []
		_cmds = {}
		_hashes = []
		return m
