## Rollback over the deterministic sim (ADR-027, after the port kit's
## ADR-103): each side steps at once on a guess of the other's input, and
## steps again from the last confirmed tick when the guess changed
## something both share.
##
## Two sims. `truth` steps exactly once per tick whose inputs both sides
## know: it's hashed for the desync check and never wrong. `pred` is drawn
## and heard: it runs ahead to the present on guesses, and when a guess
## was wrong it's reset to `truth` (Sim.load_state) and the guessed ticks
## run again.
##
## Unlike the port, a guess is never exactly right: hands move every tick.
## So a guess is wrong only when it changed what both share (the ball, the
## rules, the count: Sim.snapshot without the other's pose), checked tick
## by tick as `truth` catches up. A friend's swing that missed the ball
## changes nothing; one that hit it is a correction.
##
## Your own input isn't delayed (`delay` 0): your paddle in the sim is
## where your hand is. The other's is guessed by carrying their head,
## paddle and hand on at the speed of their last two ticks (for up to
## GUESS_TICKS), with their paddle's face held and never a toss.
##
## Time sync: each input message carries the sender's present tick and how
## far ahead it thinks it is. Every SYNC_EVERY ticks, a side 2 or more
## ahead of the other holds a tick, so one side doesn't do all the
## rolling back.
##
## Pure: no Nodes, no clock. The session feeds it messages and calls
## tick() once a sim tick; what to send and play comes back.
class_name Rollback
extends RefCounted

const DELAY := 0
const WINDOW := 36               ## ticks predicted past the confirmed, at most (300 ms)
const GUESS_TICKS := 8           ## a guess carries the other's motion on this far
const HASH_EVERY := 240
const SYNC_EVERY := 120

var local_slot := 0
var remote_slot := 2
var delay := DELAY
var window := WINDOW
var truth: Sim                   ## steps on confirmed inputs only
var pred: Sim                    ## the present, on guesses where needed
var confirmed := 0               ## the next tick `truth` steps
var predicted := 0               ## the next tick `pred` steps
var desync := -1                 ## the tick whose hashes differed, or -1
var corrections := 0             ## times `pred` was reset to `truth` (a wrong guess)
var stalls := 0                  ## ticks the window was full (waiting for the other side)
var holds := 0                   ## ticks held for time sync
var checked := 0                 ## hashes compared with the other side's
var _local := {}                 ## tick -> PackedInt32Array (HumanInput.to_array)
var _remote := {}
var _local_cmds := {}            ## tick -> commands, when any
var _remote_cmds := {}
var _shared := {}                ## tick -> pred's shared state's hash after stepping it
var _guessed := {}               ## ticks `pred` stepped on a guess
var _last := PackedInt32Array()  ## the latest remote input known, and the one before
var _before := PackedInt32Array()
var _last_tick := -1
var _remote_tick := 0            ## the other side's present, as last heard
var _remote_adv := 0             ## how far ahead it thought it was
var _hold := 0
var _last_sync := -1
var _hashes := {}                ## tick -> [mine, theirs]


## Builds both sims for `cfg`, from the same state.
func _init(cfg: SimTypes.MatchConfig, local := 0, remote := 2, ticks := DELAY,
		win := WINDOW) -> void:
	local_slot = local
	remote_slot = remote
	delay = ticks
	window = win
	truth = Sim.new(cfg)
	pred = Sim.new(cfg)
	pred.load_state(truth.save_state())
	var none := pack(SimTypes.HumanInput.new())
	for t in delay:
		_local[t] = none
		_remote[t] = none


static func pack(h: SimTypes.HumanInput) -> PackedInt32Array:
	return PackedInt32Array(h.to_array())


static func unpack(p: PackedInt32Array) -> SimTypes.HumanInput:
	return SimTypes.HumanInput.from_array(Array(p))


func on_message(m: Array) -> void:
	match m[0]:
		"I":
			var t := int(m[1])
			_remote[t] = m[2] as PackedInt32Array
			if not (m[3] as Array).is_empty():
				_remote_cmds[t] = m[3]
			if t > _last_tick:
				_before = _last if t == _last_tick + 1 else PackedInt32Array()
				_last_tick = t
				_last = m[2]
			_remote_tick = maxi(_remote_tick, int(m[4]))
			_remote_adv = int(m[5])
		"H":
			_hash(int(m[1]), 1, int(m[2]))


## How far ahead of the other side's present this one is, as heard.
func advantage() -> int:
	return predicted - _remote_tick


## How many ticks this side's clock leads the other's (the latency cancels).
func lead() -> int:
	return (advantage() - _remote_adv) / 2


## Ticks `pred` ran on a guess that isn't confirmed yet.
func guessing() -> int:
	return predicted - confirmed


## One sim tick: the local input and commands go in (when it steps;
## otherwise the caller keeps them for the next). Returns {stepped, send:
## [messages], played: [events from `pred`, a tick's worth each]}.
func tick(local: SimTypes.HumanInput, cmds: Array = []) -> Dictionary:
	var out := {"stepped": false, "send": [], "played": []}
	if predicted > 0 and predicted % SYNC_EVERY == 0 and predicted != _last_sync:
		_last_sync = predicted
		if lead() >= 2:
			_hold = 1
	_confirm(out)
	if _hold > 0:
		_hold -= 1
		holds += 1
		return out
	if predicted - confirmed >= window:
		stalls += 1
		return out
	var ahead := predicted + delay
	_local[ahead] = pack(local)
	if not cmds.is_empty():
		_local_cmds[ahead] = cmds.duplicate(true)
	out["send"].append(["I", ahead, _local[ahead], cmds.duplicate(true), predicted, advantage()])
	_step_pred(predicted, out)
	predicted += 1
	out["stepped"] = true
	return out


## Without stepping the present: what's confirmed now.
func catch_up() -> Dictionary:
	var out := {"stepped": false, "send": [], "played": []}
	_confirm(out)
	return out


## Steps `truth` through every tick both inputs are known for, up to the
## present `pred` has shown; resets `pred` if a guess there changed
## anything shared.
func _confirm(out: Dictionary) -> void:
	var wrong := false
	while confirmed < predicted and _local.has(confirmed) and _remote.has(confirmed):
		var t := confirmed
		truth.step(_humans(_local[t], _remote[t]), _commands(t))
		truth.drain_events()
		if not wrong and (_remote_cmds.has(t) or _shared.get(t, 0) != _shared_hash(truth)):
			wrong = true
		for d in [_local, _remote, _local_cmds, _remote_cmds, _shared, _guessed]:
			d.erase(t)
		confirmed += 1
		if t % HASH_EVERY == 0:
			var h := truth.state_hash()
			_hash(t, 0, h)
			out["send"].append(["H", t, h])
	if wrong:
		corrections += 1
		pred.load_state(truth.save_state())
		pred.drain_events()
		for t in range(confirmed, predicted):
			_step_pred(t, out)


## `pred` steps tick t: the remote input if it's here, else a guess.
func _step_pred(t: int, out: Dictionary) -> void:
	var remote: Variant = _remote.get(t)
	if remote == null:
		remote = guess(t)
		_guessed[t] = true
	pred.step(_humans(_local[t], remote), _commands(t))
	_shared[t] = _shared_hash(pred)
	out["played"].append(pred.drain_events())


## The other side's input at tick t, guessed: their last, carried on at
## its speed, the face held, no toss. null before anything is known.
func guess(t: int) -> Variant:
	if _last.is_empty():
		return null
	var g := _last.duplicate()
	g[11] = 0
	if _before.size() == _last.size():
		var k := mini(t - _last_tick, GUESS_TICKS)
		for i in [0, 1, 2, 3, 4, 8, 9, 10]:          # head, paddle, hand (not the normal)
			g[i] = _last[i] + (_last[i] - _before[i]) * k
	return g


func _shared_hash(sim: Sim) -> int:
	return hash(sim.snapshot(remote_slot))


func _humans(local: PackedInt32Array, remote: Variant) -> Array:
	var human: Array = [null, null, null, null]
	human[local_slot] = unpack(local)
	human[remote_slot] = unpack(remote) if remote != null else null
	return human


## Tick t's commands, both sides', the lower slot's first.
func _commands(t: int) -> Array:
	var mine: Array = _local_cmds.get(t, [])
	var theirs: Array = _remote_cmds.get(t, [])
	return mine + theirs if local_slot < remote_slot else theirs + mine


func _hash(t: int, who: int, h: int) -> void:
	var pair: Array = _hashes.get(t, [null, null])
	pair[who] = h
	_hashes[t] = pair
	if pair[0] != null and pair[1] != null:
		checked += 1
		if pair[0] != pair[1] and desync < 0:
			desync = t
		_hashes.erase(t)
