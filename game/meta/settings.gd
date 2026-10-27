## MATCH SETUP and the options, saved (user://settings.cfg). Screens read
## and change these; nothing else keeps settings (the port kit's rule).
class_name Settings
extends RefCounted

const VERSION := 1
const POINTS := [5, 7, 11, 15]
const ASSISTS := [K.ASSIST_OFF, K.ASSIST_LOW, K.ASSIST_MID, K.ASSIST_FULL]
const ANGLES := [0, 15, 30, 45]

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
	venue = c.get_value("match", "venue", venue)
	machine_shot = c.get_value("machine", "shot", machine_shot)
	machine_target = c.get_value("machine", "target", machine_target)
	machine_rate = c.get_value("machine", "rate", machine_rate)
	machine_speed = c.get_value("machine", "speed", machine_speed)
	machine_at = c.get_value("machine", "at", machine_at)
	machine_zone = c.get_value("machine", "zone", machine_zone)
	machine_best = c.get_value("machine", "best", machine_best)
	lessons_done = c.get_value("lessons", "done", lessons_done)


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
	c.set_value("match", "venue", venue)
	c.set_value("machine", "shot", machine_shot)
	c.set_value("machine", "target", machine_target)
	c.set_value("machine", "rate", machine_rate)
	c.set_value("machine", "speed", machine_speed)
	c.set_value("machine", "at", machine_at)
	c.set_value("machine", "zone", machine_zone)
	c.set_value("machine", "best", machine_best)
	c.set_value("lessons", "done", lessons_done)
	c.save(path)


func tilt() -> float:
	return float(ANGLES[clampi(paddle_angle, 0, ANGLES.size() - 1)])


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
	d.zone = machine_zone
	if d.shot == Drill.SHOT_SERVE:
		var sp := d.serve_spot()
		d.spot_x = sp[0]
		d.spot_z = sp[1]
	cfg.drill = d
	return cfg


func lesson_config(i: int) -> SimTypes.MatchConfig:
	var cfg := match_config()
	cfg.drill = Lessons.drill(i)
	return cfg
