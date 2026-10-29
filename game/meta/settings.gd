## MATCH SETUP and the options, saved (user://settings.cfg). Screens read
## and change these; nothing else keeps settings (the port kit's rule).
class_name Settings
extends RefCounted

const VERSION := 1
const POINTS := [5, 7, 11, 15]
const ASSISTS := [K.ASSIST_OFF, K.ASSIST_LOW, K.ASSIST_MID, K.ASSIST_FULL]
const ANGLES := [0, 15, 30, 45]
## Paddle profiles (ADR-015), for paddle accessories that hold the
## controller at another angle or further from the face. DEFAULT is the
## PADDLE ANGLE above; the others override angle, twist and reach.
const PROFILE_NAMES := ["DEFAULT", "PROFILE 1", "PROFILE 2", "PROFILE 3"]
## Degrees in 5s: ANGLE tips the face back (-90..90), TURN swings it left
## or right (-90..90), TWIST rolls it about the handle (a full turn): any
## way an accessory holds the controller.
static var PROFILE_ANGLES := range(-90, 95, 5)
static var PROFILE_TURNS := range(-90, 95, 5)
static var PROFILE_TWISTS := range(-180, 185, 5)
## REACH slides the paddle along its handle, cm in 1s: out past the
## controller, or (negative) back toward your hand, for an accessory that
## holds the controller up its handle, 15-20 cm above the hand.
static var PROFILE_REACHES := range(-30, 21)

## Tests point this at their own file (the runner does), never the player's.
static var default_path := "user://settings.cfg"
## Tests pin the seed (the runner does): a match's is the clock's otherwise,
## and a test that passes on one second and fails on the next is no test.
static var seed_override := -1
## Developer tools (the TUNING pages, ADR-020): debug builds, not tests.
static var dev := OS.is_debug_build()


static func dev_tools() -> bool:
	return dev

var path := default_path
var doubles := false
var opponent := 0
var difficulty := 1
var assist := 2                      ## index into ASSISTS
var points := 0                      ## index into POINTS
var win_by_2 := false
var left_handed := false
var coach := false                   ## ADR-023: COACH MODE, the companion page served
var passthrough := false             ## ADR-021: the court in your room (headset)
var paddle_angle := 1                ## index into ANGLES
var paddle_profile := 0              ## index into PROFILE_NAMES
## The three custom profiles: {angle, twist, reach} in degrees and cm.
var profiles: Array = [new_profile(), new_profile(), new_profile()]
var venue := 0                       ## 0 is HOME (the team's); then Venues.NAMES
## BALL MACHINE (ADR-007)
var machine_shot := Drill.SHOT_DRIVE
var machine_target := Drill.TARGET_AT_YOU
var machine_rate := 1
var machine_speed := 1
var machine_at := Drill.AT_AUTO
var machine_zone := Drill.ZONE_ANY
var machine_best := 0
var lessons_done: Array = []         ## lesson ids
var machine_targets := false
## DINK PARTNER (ADR-010)
var partner_level := 1
var partner_targets := true
var partner_cross := false
var partner_spread := 1
const PARTNER_DRILLS := Drill.KIND_NAMES
var partner_drill := 0               ## DRILL: a Drill.KIND_* (ADR-014, 016, 017)
var partner_lane := Drill.LANE_ALTERNATE   ## LINE AND CROSS: LANE
var partner_hands: bool:
	get: return partner_drill == 1
	set(v): partner_drill = 1 if v else 0
var partner_best := 0
## Timed runs (ADR-022): MODE, an index into Drill.TIMES (0 free play).
var partner_time := 0
var machine_time := 0
## Every timed run kept, per player (C-18): player -> run name
## (Settings.run_name) -> [[score, date, good, best streak], ...], oldest
## first, the last RUNS_KEPT. `records` is the current player's.
var player := "PLAYER 1"
var players: Array = ["PLAYER 1"]
var records_by := {}
var records: Dictionary:
	get:
		if not records_by.has(player):
			records_by[player] = {}
		return records_by[player]
	set(v):
		records_by[player] = v
## A coach's saved workouts (C-13): [{name, steps: [{drill, level, time,
## targets}]}].
var workouts: Array = []
## The coach's ball machine (C-21), in the page's units: machine and bounce
## spots (m), speed (m/s), spin (-100 backspin .. 100 topspin, %), height
## over the net (m), seconds between balls.
var coach_machine := {"x": 0.0, "z": -7.0, "bx": 0.0, "bz": 4.0, "speed": 8.0, "spin": 0, "clear": 0.5, "every": 3.5}
const RUNS_KEPT := 100


func load_settings() -> void:
	var c := ConfigFile.new()
	if c.load(path) != OK:
		return
	doubles = c.get_value("match", "doubles", doubles)
	opponent = c.get_value("match", "opponent", opponent)
	difficulty = c.get_value("match", "difficulty", difficulty)
	assist = c.get_value("match", "assist", assist)
	points = c.get_value("match", "points", points)
	win_by_2 = c.get_value("match", "win_by_2", win_by_2)
	left_handed = c.get_value("player", "left_handed", left_handed)
	passthrough = c.get_value("player", "passthrough", passthrough)
	coach = c.get_value("player", "coach", coach)
	paddle_angle = c.get_value("player", "paddle_angle", paddle_angle)
	paddle_profile = c.get_value("paddle", "profile", paddle_profile)
	var saved: Array = c.get_value("paddle", "profiles", [])
	for i in mini(saved.size(), profiles.size()):
		var d: Dictionary = new_profile()
		d.merge(saved[i], true)
		d["reach"] = clampi(int(d["reach"]), PROFILE_REACHES[0], PROFILE_REACHES[-1])
		profiles[i] = d
	venue = c.get_value("match", "venue", venue)
	machine_shot = c.get_value("machine", "shot", machine_shot)
	machine_target = c.get_value("machine", "target", machine_target)
	machine_rate = c.get_value("machine", "rate", machine_rate)
	machine_speed = c.get_value("machine", "speed", machine_speed)
	machine_at = c.get_value("machine", "at", machine_at)
	machine_zone = c.get_value("machine", "zone", machine_zone)
	machine_best = c.get_value("machine", "best", machine_best)
	lessons_done = c.get_value("lessons", "done", lessons_done)
	machine_targets = c.get_value("machine", "targets", machine_targets)
	partner_level = c.get_value("partner", "level", partner_level)
	partner_targets = c.get_value("partner", "targets", partner_targets)
	partner_best = c.get_value("partner", "best", partner_best)
	partner_cross = c.get_value("partner", "cross", partner_cross)
	partner_spread = c.get_value("partner", "spread", partner_spread)
	# An older save kept HANDS as a flag.
	partner_drill = c.get_value("partner", "drill", 1 if c.get_value("partner", "hands", false) else 0)
	partner_lane = c.get_value("partner", "lane", partner_lane)
	partner_time = c.get_value("partner", "time", partner_time)
	machine_time = c.get_value("machine", "time", machine_time)
	player = c.get_value("player", "name", player)
	players = c.get_value("player", "names", players)
	records_by = c.get_value("records", "by_player", {})
	if records_by.is_empty() and c.has_section_key("records", "runs"):
		records_by[player] = c.get_value("records", "runs")   # before profiles: the first player's
	workouts = c.get_value("coach", "workouts", workouts)
	coach_machine.merge(c.get_value("coach", "machine", {}), true)


func save() -> void:
	var c := ConfigFile.new()
	c.set_value("meta", "version", VERSION)
	c.set_value("match", "doubles", doubles)
	c.set_value("match", "opponent", opponent)
	c.set_value("match", "difficulty", difficulty)
	c.set_value("match", "assist", assist)
	c.set_value("match", "points", points)
	c.set_value("match", "win_by_2", win_by_2)
	c.set_value("player", "left_handed", left_handed)
	c.set_value("player", "passthrough", passthrough)
	c.set_value("player", "coach", coach)
	c.set_value("player", "paddle_angle", paddle_angle)
	c.set_value("paddle", "profile", paddle_profile)
	c.set_value("paddle", "profiles", profiles)
	c.set_value("match", "venue", venue)
	c.set_value("machine", "shot", machine_shot)
	c.set_value("machine", "target", machine_target)
	c.set_value("machine", "rate", machine_rate)
	c.set_value("machine", "speed", machine_speed)
	c.set_value("machine", "at", machine_at)
	c.set_value("machine", "zone", machine_zone)
	c.set_value("machine", "best", machine_best)
	c.set_value("lessons", "done", lessons_done)
	c.set_value("machine", "targets", machine_targets)
	c.set_value("partner", "level", partner_level)
	c.set_value("partner", "time", partner_time)
	c.set_value("machine", "time", machine_time)
	c.set_value("player", "name", player)
	c.set_value("player", "names", players)
	c.set_value("records", "by_player", records_by)
	c.set_value("coach", "workouts", workouts)
	c.set_value("coach", "machine", coach_machine)
	c.set_value("partner", "targets", partner_targets)
	c.set_value("partner", "best", partner_best)
	c.set_value("partner", "cross", partner_cross)
	c.set_value("partner", "spread", partner_spread)
	c.set_value("partner", "drill", partner_drill)
	c.set_value("partner", "lane", partner_lane)
	c.save(path)


func tilt() -> float:
	return float(ANGLES[clampi(paddle_angle, 0, ANGLES.size() - 1)])


static func new_profile() -> Dictionary:
	return {"angle": 15, "turn": 0, "twist": 0, "reach": 0}


## The profile in use, or null for DEFAULT.
func profile() -> Variant:
	if paddle_profile <= 0 or paddle_profile > profiles.size():
		return null
	return profiles[paddle_profile - 1]


## The paddle in the hand: [angle, twist] in degrees, reach in metres, turn
## in degrees.
func paddle_pose() -> Array[float]:
	var p: Variant = profile()
	if p == null:
		return [tilt(), 0.0, 0.0, 0.0]
	return [float(p["angle"]), float(p["twist"]), float(p["reach"]) / 100.0, float(p["turn"])]


func match_config() -> SimTypes.MatchConfig:
	var cfg := SimTypes.MatchConfig.new()
	cfg.doubles = doubles
	cfg.difficulty = difficulty
	cfg.assist = ASSISTS[clampi(assist, 0, 3)]
	cfg.points_to_win = POINTS[clampi(points, 0, 3)]
	cfg.win_by_2 = win_by_2
	cfg.seed = seed_override if seed_override >= 0 else int(Time.get_unix_time_from_system()) & 0x7fffffff
	Opponents.apply(cfg, opponent)
	cfg.venue = Venues.resolve(venue, opponent)
	return cfg


## The BALL MACHINE's drill, as set.
func machine_config() -> SimTypes.MatchConfig:
	var cfg := match_config()
	var d := Drill.new()
	d.shot = machine_shot
	d.target = machine_target
	d.rate = machine_rate
	d.speed = machine_speed
	d.machine_at = machine_at
	d.targets = machine_targets
	d.zone = machine_zone
	d.time_limit = Drill.TIMES[clampi(machine_time, 0, Drill.TIMES.size() - 1)] * K.TICK_HZ
	if d.shot == Drill.SHOT_SERVE:
		var sp := d.serve_spot()
		d.spot_x = sp[0]
		d.spot_z = sp[1]
	cfg.drill = d
	return cfg


## DINK PARTNER's rally: you at your kitchen line, no volleys from the
## kitchen, dinks counted when they land in theirs.
func partner_config() -> SimTypes.MatchConfig:
	var cfg := match_config()
	var d := Drill.new()
	d.partner = true
	d.partner_pace = partner_level
	d.targets = partner_targets
	d.zone = Drill.ZONE_KITCHEN
	d.rules = Drill.RULE_KITCHEN
	d.cross = partner_cross
	d.spread = partner_spread
	d.kind = clampi(partner_drill, 0, Drill.KIND_NAMES.size() - 1)
	d.lane = partner_lane
	d.time_limit = Drill.TIMES[clampi(partner_time, 0, Drill.TIMES.size() - 1)] * K.TICK_HZ
	if d.hands:
		d.zone = Drill.ZONE_ANY          # a volley that lands anywhere in counts too
	if d.kind != Drill.KIND_DINKS and d.kind != Drill.KIND_RESETS:
		d.targets = false                # their own spots, lanes or none
	if d.kind == Drill.KIND_VOLLEYS:
		d.rules = Drill.RULE_VOLLEY | Drill.RULE_KITCHEN
	d.spot_z = Drill.RESET_SPOT_Z if d.resets else K.KITCHEN_DEPTH + 300000
	if partner_cross or d.lanes:
		# Your right court; the partner diagonal, or (LINE AND CROSS) across,
		# so the line and the cross are each half their kitchen.
		d.spot_x = K.COURT_HALF_WIDTH / 2
	if d.lanes:
		d.cross = false
	cfg.drill = d
	return cfg


func lesson_config(i: int) -> SimTypes.MatchConfig:
	var cfg := match_config()
	cfg.drill = Lessons.drill(i)
	return cfg


# --- Records (ADR-022) ----------------------------------------------------------------

## What a timed run is kept under: the drill, its level, the time.
static func run_name(d: Drill) -> String:
	var t := Drill.TIMES.find(d.time_limit / K.TICK_HZ)
	return "%s%s %s" % [d.mode_name(), " TARGETS" if d.targets else "", Drill.TIME_NAMES[maxi(t, 0)]]


## Keeps a run; returns where it places: [rank among all (1 best), runs so far].
func add_run(name: String, score: int, good: int, best_streak: int, date: String) -> Array[int]:
	var runs: Array = records.get(name, [])
	runs.append([score, date, good, best_streak])
	if runs.size() > RUNS_KEPT:
		runs = runs.slice(runs.size() - RUNS_KEPT)
	records[name] = runs
	var rank := 1
	for r in runs:
		if int(r[0]) > score:
			rank += 1
	return [rank, runs.size()]


## A run name's best scores, highest first: [[score, date, good, best streak], ...].
func best_runs(name: String, n := 5) -> Array:
	var runs: Array = (records.get(name, []) as Array).duplicate()
	runs.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	return runs.slice(0, n)


## Its last few scores, oldest first.
func recent_scores(name: String, n := 5) -> Array[int]:
	var out: Array[int] = []
	var runs: Array = records.get(name, [])
	for r in runs.slice(maxi(runs.size() - n, 0)):
		out.append(int(r[0]))
	return out
