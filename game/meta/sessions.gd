## Saved coaching sessions (design/COACHING.md C-10): every practice shot,
## kept on the headset, one file per session, so a coach can look back and
## see the trend. A session is a player's shots from the first one after
## the game starts (or the player changes) until it stops. The files keep
## each shot's replay too (C-17, VR-94), packed small: every other point
## of its paths (6 ticks apart), in whole centimetres.
class_name Sessions
extends RefCounted

const KEEP := 60                     ## the newest sessions kept; older files go
const SAVE_EVERY := 5                ## shots between writes (and at every run's end)
const LIVE_ONLY := ["type"]
const PACK_EVERY := 2                ## keep every 2nd path point (3 ticks apart live: 6 saved)

static var dir := "user://sessions/"  ## tests point it elsewhere
static var _count := 0

var id := ""
var player := ""
var started := ""
var shots: Array = []
var runs: Array = []                 ## timed runs: {name, score, good, best}
var _unsaved := 0


static func start(who: String) -> Sessions:
	var s := Sessions.new()
	s.player = who
	s.started = Time.get_datetime_string_from_system().replace("T", " ").left(16)
	# The time, the player and a count: two sessions in one second (a player
	# change) never share a file.
	var who_part := ""
	for ch in who:
		who_part += ch if ch.is_valid_identifier() or ch in "0123456789" else "_"
	_count += 1
	s.id = "%s-%s-%d" % [Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "-"),
		who_part, _count]
	return s


func add_shot(info: Dictionary) -> void:
	var keep := pack(info)
	for k in LIVE_ONLY:
		keep.erase(k)
	shots.append(keep)
	_unsaved += 1
	if _unsaved >= SAVE_EVERY:
		save()


func add_run(name: String, score: int, good: int, best: int) -> void:
	runs.append({"name": name, "score": score, "good": good, "best": best})
	save()


## The totals a list shows without reading every shot.
func summary() -> Dictionary:
	var good := 0
	var clear := 0.0
	var cn := 0
	var modes := {}
	for s in shots:
		if s.get("good", false):
			good += 1
		if s.has("clear"):
			clear += float(s["clear"])
			cn += 1
		var m := String(s.get("mode", "?"))
		modes[m] = int(modes.get(m, 0)) + 1
	return {"id": id, "player": player, "started": started, "shots": shots.size(), "good": good,
		"clear": snappedf(clear / cn, 0.01) if cn > 0 else -1.0, "modes": modes, "runs": runs.size()}


func save() -> void:
	if shots.is_empty() and runs.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(dir + id + ".json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"summary": summary(), "shots": shots, "runs": runs}))
	_unsaved = 0
	_prune()


static func _files() -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".json"):
			out.append(f)
	out.sort()
	return out


static func _prune() -> void:
	var files := _files()
	for i in maxi(files.size() - KEEP, 0):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + files[i]))


## Every kept session's summary, newest first; one player's only if given.
static func list(who := "") -> Array:
	var out: Array = []
	var files := _files()
	files.reverse()
	for f in files:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + f))
		if d is Dictionary and d.has("summary"):
			var s: Dictionary = d["summary"]
			if who == "" or String(s.get("player", "")) == who:
				out.append(s)
	return out


## One session in full: {summary, shots, runs}, or {} if it's gone. Its
## shots' replays come unpacked, as the live ones are.
static func read(session_id: String) -> Dictionary:
	if not session_id.is_valid_filename():
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + session_id + ".json"))
	if not d is Dictionary:
		return {}
	var shots_in: Array = d.get("shots", [])
	d["shots"] = shots_in.map(func(s: Variant) -> Variant: return unpack(s) if s is Dictionary else s)
	return d


## A shot to keep: its replay paths ([[x, y, z] m, every 3 ticks], the ball
## to you and from you) become "rp": [ticks per point, points to you, then
## x, y, z in cm, flat].
static func pack(info: Dictionary) -> Dictionary:
	var keep := info.duplicate()
	var into: Array = keep.get("in_path", [])
	var out: Array = keep.get("path", [])
	keep.erase("in_path")
	keep.erase("path")
	if out.is_empty():
		return keep
	var a := _thin(into)
	var b := _thin(out)
	var rp: Array = [3 * PACK_EVERY, a.size()]
	for p in a + b:
		for v in p:
			rp.append(roundi(float(v) * 100))
	keep["rp"] = rp
	return keep


## Every PACK_EVERY'th point, and always the last (the bounce, the hit).
static func _thin(path: Array) -> Array:
	var out: Array = []
	for i in path.size():
		if i % PACK_EVERY == 0 or i == path.size() - 1:
			out.append(path[i])
	return out


## A saved shot with its replay paths back as the live ones are, plus
## "every": ticks per point.
static func unpack(shot: Dictionary) -> Dictionary:
	if not shot.has("rp"):
		return shot
	var s := shot.duplicate()
	var rp: Array = s["rp"]
	s.erase("rp")
	var n_in := int(rp[1])
	var pts: Array = []
	for i in range(2, rp.size() - 2, 3):
		pts.append([rp[i] / 100.0, rp[i + 1] / 100.0, rp[i + 2] / 100.0])
	s["in_path"] = pts.slice(0, n_in)
	s["path"] = pts.slice(n_in)
	s["every"] = int(rp[0])
	return s
