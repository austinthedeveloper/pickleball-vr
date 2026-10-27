## MATCH SETUP and the options, saved (user://settings.cfg). Screens read
## and change these; nothing else keeps settings (the port kit's rule).
class_name Settings
extends RefCounted

const VERSION := 1
const POINTS := [5, 7, 11, 15]
const ASSISTS := [K.ASSIST_OFF, K.ASSIST_LOW, K.ASSIST_MID, K.ASSIST_FULL]

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
	c.save(path)


func match_config() -> SimTypes.MatchConfig:
	var cfg := SimTypes.MatchConfig.new()
	cfg.doubles = doubles
	cfg.difficulty = difficulty
	cfg.assist = ASSISTS[clampi(assist, 0, 3)]
	cfg.points_to_win = POINTS[clampi(points, 0, 3)]
	cfg.win_by_2 = win_by_2
	cfg.seed = int(Time.get_unix_time_from_system()) & 0x7fffffff
	Opponents.apply(cfg, opponent)
	return cfg
