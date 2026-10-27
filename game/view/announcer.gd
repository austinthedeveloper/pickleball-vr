## The announcer's voice: the port kit's recorded clips (port ADR-076),
## a subset in assets/audio/announcer. It says one line at a time. A line
## of a lower priority while it's talking is dropped (stale by the time it
## could play); a higher one cuts in. `queue` lines wait their turn (the
## score after the call). Headless, nothing plays, but `said` still
## records each clip for the tests.
class_name Announcer
extends Node

const DIR := "res://assets/audio/announcer/"
const GAP := 0.06                    ## seconds between the pieces of a line

const LOW := 0
const MID := 1                       ## a call, the score
const HIGH := 2                      ## match point, a long rally
const TOP := 3                       ## the match's start and end

var families := {}                   ## "out" -> ["out_1", .. "out_4"]
var said: Array[String] = []
var silent := false
var rng := RandomNumberGenerator.new()
var _streams := {}
var _player: AudioStreamPlayer
var _pieces: Array[String] = []
var _queued: Array = []              ## [ids, priority] waiting for the voice
var _busy := 0.0
var _priority := -1
var _last := {}                      ## family -> the clip said last


func _init() -> void:
	silent = DisplayServer.get_name() == "headless"
	rng.randomize()
	var ids: Array[String] = []
	for f in ResourceLoader.list_directory(DIR):
		if f.ends_with(".wav"):
			ids.append(f.get_basename())
	var counts := {}
	for id in ids:
		counts[_stem(id)] = int(counts.get(_stem(id), 0)) + 1
	for id in ids:
		var fam: String = _stem(id) if int(counts[_stem(id)]) > 1 else id
		if not families.has(fam):
			families[fam] = []
		families[fam].append(id)
	_player = AudioStreamPlayer.new()
	_player.volume_db = 1.0
	add_child(_player)


static func _stem(id: String) -> String:
	var parts := id.split("_")
	if parts.size() > 1 and parts[-1].is_valid_int():
		parts.remove_at(parts.size() - 1)
	return "_".join(parts)


func has(family: String) -> bool:
	return families.has(family)


func busy() -> bool:
	return _busy > 0.0 or not _pieces.is_empty()


## Say `line`: families or clip ids, in order. See the class note for
## how priorities and `queue` work.
func say(line: Array, priority := MID, queue := false) -> void:
	var ids: Array[String] = []
	for f in line:
		var id := _pick(String(f))
		if id != "":
			ids.append(id)
	if ids.is_empty():
		return
	if busy():
		if queue:
			_queued.append([ids, priority])
			return
		if priority <= _priority:
			return
	_start(ids, priority)


func _pick(family: String) -> String:
	if not families.has(family):
		for f in families:                 # an exact clip ("rally_15_1": the one that says the number)
			if (families[f] as Array).has(family):
				return family
		return ""
	var options: Array = families[family]
	var id: String = options[rng.randi() % options.size()]
	if options.size() > 1 and id == _last.get(family, ""):
		id = options[(options.find(id) + 1) % options.size()]
	_last[family] = id
	return id


func _start(ids: Array[String], priority: int) -> void:
	_pieces = ids.duplicate()
	_priority = priority
	_busy = 0.0
	_next()


func _next() -> void:
	if _pieces.is_empty():
		_priority = -1
		if not _queued.is_empty():
			var q: Array = _queued.pop_front()
			_start(q[0], q[1])
		return
	var id: String = _pieces.pop_front()
	said.append(id)
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		stream = load(DIR + id + ".wav")
		_streams[id] = stream
	_busy = stream.get_length() + GAP
	if not silent:
		_player.stream = stream
		_player.play()


func _process(delta: float) -> void:
	tick(delta)


## Time passing (tests call it directly).
func tick(delta: float) -> void:
	if _busy <= 0.0:
		return
	_busy -= delta
	if _busy <= 0.0:
		_next()


## The score, the server's first: "four - two", or "three all".
static func score_line(server: int, receiver: int) -> Array:
	if server == receiver:
		return ["num_%02d_up" % mini(server, 25), "score_all"]
	return ["num_%02d_up" % mini(server, 25), "num_%02d_down" % mini(receiver, 25)]
