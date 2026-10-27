## HOW TO PLAY (ADR-007): the lessons in data/lessons.json, each a Drill.
class_name Lessons
extends RefCounted

const PATH := "res://data/lessons.json"
const RULES := {"NO_VOLLEY": Drill.RULE_NO_VOLLEY, "VOLLEY": Drill.RULE_VOLLEY,
	"KITCHEN": Drill.RULE_KITCHEN, "TOPSPIN": Drill.RULE_TOPSPIN}

static var _all: Array = []


static func all() -> Array:
	if _all.is_empty():
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_all = d["lessons"]
	return _all


static func count() -> int:
	return all().size()


static func lesson(i: int) -> Dictionary:
	return all()[clampi(i, 0, count() - 1)]


static func drill(i: int) -> Drill:
	var l := lesson(i)
	var d := Drill.new()
	d.shot = Drill.SHOT_NAMES.find(l["shot"])
	d.target = Drill.TARGET_NAMES.find(l["target"])
	d.rate = Drill.RATE_NAMES.find(l["rate"])
	d.zone = Drill.ZONE_NAMES.find(l["zone"])
	for r in l["rules"]:
		d.rules |= int(RULES[r])
	d.goal = int(l["goal"])
	if l["spot"] is String:
		var sp := d.serve_spot()
		d.spot_x = sp[0]
		d.spot_z = sp[1]
	else:
		d.spot_x = roundi(float(l["spot"][0]) * K.M)
		d.spot_z = roundi(float(l["spot"][1]) * K.M)
	return d
