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
const PROFILE_ANGLES := [-30, -25, -20, -15, -10, -5, 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60,
	65, 70, 75, 80, 85, 90]
const PROFILE_TWISTS := [-45, -40, -35, -30, -25, -20, -15, -10, -5, 0, 5, 10, 15, 20, 25, 30, 35, 40, 45]
const PROFILE_REACHES := [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40]   ## cm

## Tests point this at their own file (the runner does), never the player's.
static var default_path := "user://settings.cfg"

var path := default_path
var doubles := false
var opponent := 0
var difficulty := 1
var assist := 2                      ## index into ASSISTS
var points := 0                      ## index into POINTS
var win_by_2 := false
var left_handed := false
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
const PARTNER_DRILLS := ["DINKS", "HANDS", "RESETS"]
var partner_drill := 0               ## DRILL: DINKS, HANDS (ADR-014) or RESETS (ADR-016)
var partner_hands: bool:
	get: return partner_drill == 1
	set(v): partner_drill = 1 if v else 0
var partner_best := 0


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
	paddle_angle = c.get_value("player", "paddle_angle", paddle_angle)
	paddle_profile = c.get_value("paddle", "profile", paddle_profile)
	var saved: Array = c.get_value("paddle", "profiles", [])
	for i in mini(saved.size(), profiles.size()):
		var d: Dictionary = new_profile()
		d.merge(saved[i], true)
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
	c.set_value("partner", "targets", partner_targets)
	c.set_value("partner", "best", partner_best)
	c.set_value("partner", "cross", partner_cross)
	c.set_value("partner", "spread", partner_spread)
	c.set_value("partner", "drill", partner_drill)
	c.save(path)


func tilt() -> float:
	return float(ANGLES[clampi(paddle_angle, 0, ANGLES.size() - 1)])


static func new_profile() -> Dictionary:
	return {"angle": 15, "twist": 0, "reach": 0}


## The profile in use, or null for DEFAULT.
func profile() -> Variant:
	if paddle_profile <= 0 or paddle_profile > profiles.size():
		return null
	return profiles[paddle_profile - 1]


## The paddle in the hand: [angle, twist] in degrees and reach in metres.
func paddle_pose() -> Array[float]:
	var p: Variant = profile()
	if p == null:
		return [tilt(), 0.0, 0.0]
	return [float(p["angle"]), float(p["twist"]), float(p["reach"]) / 100.0]


func match_config() -> SimTypes.MatchConfig:
	var cfg := SimTypes.MatchConfig.new()
	cfg.doubles = doubles
	cfg.difficulty = difficulty
	cfg.assist = ASSISTS[clampi(assist, 0, 3)]
	cfg.points_to_win = POINTS[clampi(points, 0, 3)]
	cfg.win_by_2 = win_by_2
	cfg.seed = int(Time.get_unix_time_from_system()) & 0x7fffffff
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
	d.hands = partner_hands
	d.resets = partner_drill == 2
	if partner_hands:
		d.zone = Drill.ZONE_ANY          # a volley that lands anywhere in counts too
		d.targets = false                # no placing: volleys, not dinks
	d.spot_z = Drill.RESET_SPOT_Z if d.resets else K.KITCHEN_DEPTH + 300000
	if partner_cross:
		d.spot_x = K.COURT_HALF_WIDTH / 2      # your right court, the partner diagonal
	cfg.drill = d
	return cfg


func lesson_config(i: int) -> SimTypes.MatchConfig:
	var cfg := match_config()
	cfg.drill = Lessons.drill(i)
	return cfg
