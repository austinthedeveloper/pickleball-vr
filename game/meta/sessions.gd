## Saved coaching sessions (design/COACHING.md C-10): every practice shot,
## kept on the headset, one file per session, so a coach can look back and
## see the trend. A session is a player's shots from the first one after
## the game starts (or the player changes) until it stops. Replay paths
## stay live only: the files keep the numbers.
class_name Sessions
extends RefCounted

const KEEP := 60                     ## the newest sessions kept; older files go
const SAVE_EVERY := 5                ## shots between writes (and at every run's end)
const LIVE_ONLY := ["path", "in_path", "type"]

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
	var keep := info.duplicate()
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


## One session in full: {summary, shots, runs}, or {} if it's gone.
static func read(session_id: String) -> Dictionary:
	if not session_id.is_valid_filename():
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + session_id + ".json"))
	return d if d is Dictionary else {}
