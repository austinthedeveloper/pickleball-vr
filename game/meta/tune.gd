## Developer tuning (ADR-020): the numbers worth trying in the headset, each
## a `static var` in the sim. The TUNING pages (debug builds) step them, and
## a change applies at once (a board or a feed already under way at the
## next restart). Overrides are saved to user://tuning.cfg with where each
## lives in the source; `game/tools/tune.sh pull` fetches the file and
## `tune.sh sync` writes the values in as the new defaults.
##
## Never in tests or release builds: the sim's defaults are the source's.
class_name Tune
extends RefCounted

static var path := "user://tuning.cfg"   ## tests point it elsewhere
const GROUPS := ["TARGETS", "KITCHEN", "DINKS", "HANDS", "RESETS", "VOLLEYS", "ATTACK", "PADDLE"]
const LEVELS := ["EASY", "MEDIUM", "HARD"]
## Units: how a raw value reads.
const M := "m"                       ## um, as metres
const CM := "cm"                     ## um, as centimetres
const MPS := "m/s"                   ## um per tick, as m/s
const PCT := "%"
const SEC := "s"                     ## ticks, as seconds
const RAW := ""

## Every tunable: id, group, label, script, name, index (-1 a scalar),
## unit, step, min, max (raw units).
const ALL := [
	["spot_easy", "TARGETS", "SPOT EASY", "res://sim/drill.gd", "SPOT_RADIUS", 0, M, 50000, 300000, 2000000],
	["spot_medium", "TARGETS", "SPOT MEDIUM", "res://sim/drill.gd", "SPOT_RADIUS", 1, M, 50000, 300000, 2000000],
	["spot_hard", "TARGETS", "SPOT HARD", "res://sim/drill.gd", "SPOT_RADIUS", 2, M, 50000, 300000, 2000000],
	["target", "TARGETS", "FLOOR TARGET", "res://sim/drill.gd", "TARGET_RADIUS", -1, M, 50000, 300000, 2000000],
	["inner", "TARGETS", "INNER RING", "res://sim/drill.gd", "RING_EDGES", 1, PCT, 2, 20, 95],
	["bull", "TARGETS", "BULLSEYE", "res://sim/drill.gd", "RING_EDGES", 2, PCT, 2, 5, 90],
	["lean", "KITCHEN", "LEAN ALLOWED", "res://sim/drill.gd", "KITCHEN_LEAN", -1, CM, 50000, 0, 1000000],
	["dink_past", "KITCHEN", "DINK ZONE PAST LINE", "res://sim/drill.gd", "DINK_PAST", -1, CM, 50000, 0, 2000000],
	["dink_easy", "DINKS", "PACE EASY", "res://sim/drill.gd", "PARTNER_PACE", 0, MPS, 1000, 15000, 80000],
	["dink_medium", "DINKS", "PACE MEDIUM", "res://sim/drill.gd", "PARTNER_PACE", 1, MPS, 1000, 15000, 80000],
	["dink_hard", "DINKS", "PACE HARD", "res://sim/drill.gd", "PARTNER_PACE", 2, MPS, 1000, 15000, 80000],
	["hold", "DINKS", "LEAD-IN HOLD", "res://sim/drill.gd", "HOLD_TICKS", -1, SEC, 6, 0, 240],
	["move", "DINKS", "PARTNER SPEED", "res://sim/drill.gd", "PARTNER_SPEED", -1, MPS, 2000, 10000, 80000],
	["hands_feed", "HANDS", "FEED PACE", "res://sim/drill.gd", "HANDS_FEED", -1, MPS, 2000, 20000, 120000],
	["hands_easy", "HANDS", "PACE EASY", "res://sim/drill.gd", "HANDS_PACE", 0, MPS, 2000, 30000, 180000],
	["hands_medium", "HANDS", "PACE MEDIUM", "res://sim/drill.gd", "HANDS_PACE", 1, MPS, 2000, 30000, 180000],
	["hands_hard", "HANDS", "PACE HARD", "res://sim/drill.gd", "HANDS_PACE", 2, MPS, 2000, 30000, 180000],
	["reset_easy", "RESETS", "PACE EASY", "res://sim/drill.gd", "RESET_PACE", 0, MPS, 2000, 30000, 180000],
	["reset_medium", "RESETS", "PACE MEDIUM", "res://sim/drill.gd", "RESET_PACE", 1, MPS, 2000, 30000, 180000],
	["reset_hard", "RESETS", "PACE HARD", "res://sim/drill.gd", "RESET_PACE", 2, MPS, 2000, 30000, 180000],
	["popup_easy", "RESETS", "POP-UP LINE EASY", "res://sim/drill.gd", "POPUP_OVER", 0, CM, 50000, 100000, 1500000],
	["popup_medium", "RESETS", "POP-UP LINE MEDIUM", "res://sim/drill.gd", "POPUP_OVER", 1, CM, 50000, 100000, 1500000],
	["popup_hard", "RESETS", "POP-UP LINE HARD", "res://sim/drill.gd", "POPUP_OVER", 2, CM, 50000, 100000, 1500000],
	["float_easy", "VOLLEYS", "PACE EASY", "res://sim/drill.gd", "FLOAT_PACE", 0, MPS, 1000, 15000, 90000],
	["float_medium", "VOLLEYS", "PACE MEDIUM", "res://sim/drill.gd", "FLOAT_PACE", 1, MPS, 1000, 15000, 90000],
	["float_hard", "VOLLEYS", "PACE HARD", "res://sim/drill.gd", "FLOAT_PACE", 2, MPS, 1000, 15000, 90000],
	["high", "ATTACK", "HIGH BALLS", "res://sim/drill.gd", "ATTACK_HIGH_PCT", -1, PCT, 5, 0, 100],
	["block", "PADDLE", "BLOCK KEEPS PACE", "res://sim/k.gd", "BLOCK_E_256", -1, PCT, 3, 0, 256],
]

static var _defaults := {}           ## id -> the source's value, read before any override


static func entry(id: String) -> Array:
	for e in ALL:
		if e[0] == id:
			return e
	return []


static func in_group(group: String) -> Array:
	return ALL.filter(func(e: Array) -> bool: return e[1] == group)


static func _script(e: Array) -> GDScript:
	return load(e[3])


static func value(id: String) -> int:
	var e := entry(id)
	var v: Variant = _script(e).get(e[4])
	return int(v[e[5]]) if int(e[5]) >= 0 else int(v)


static func set_value(id: String, v: int) -> void:
	var e := entry(id)
	_remember(e)
	v = clampi(v, e[8], e[9])
	var s := _script(e)
	if int(e[5]) >= 0:
		var arr: Array = (s.get(e[4]) as Array).duplicate()
		arr[e[5]] = v
		s.set(e[4], arr)
	else:
		s.set(e[4], v)
	if e[4] == "DINK_PAST":
		Drill.DINK_ZONE = K.KITCHEN_DEPTH + v


static func default_of(id: String) -> int:
	_remember(entry(id))
	return _defaults[id]


static func _remember(e: Array) -> void:
	if _defaults.has(e[0]):
		return
	var v: Variant = _script(e).get(e[4])
	_defaults[e[0]] = int(v[e[5]]) if int(e[5]) >= 0 else int(v)


static func changed(id: String) -> bool:
	return value(id) != default_of(id)


## The value as it reads on the panel.
static func text(id: String, v: int) -> String:
	var e := entry(id)
	match e[6]:
		M: return "%.2f M" % (v / 1e6)
		CM: return "%d CM" % roundi(v / 1e4)
		MPS: return "%.1f M/S" % (v * K.TICK_HZ / 1e6)
		PCT: return "%d%%" % (roundi(v * 100.0 / 256.0) if e[4] == "BLOCK_E_256" else v)
		SEC: return "%.2f S" % (v / float(K.TICK_HZ))
	return str(v)


## The steps a row offers, min to max, and where `v` sits among them.
static func steps(id: String) -> Array:
	var e := entry(id)
	var out: Array[int] = []
	var v: int = e[8]
	while v <= int(e[9]):
		out.append(v)
		v += int(e[7])
	var cur := value(id)
	if not out.has(cur):
		out.append(cur)              # the source's own value, between steps
		out.sort()
	var dflt := default_of(id)
	if not out.has(dflt):
		out.append(dflt)
		out.sort()
	return out


## Puts every tunable back to the source's value.
static func reset(group := "") -> void:
	for e in ALL:
		if group == "" or e[1] == group:
			set_value(e[0], default_of(e[0]))


## Saves the overrides, with where each lives (for tune.sh sync).
static func save() -> void:
	var cf := ConfigFile.new()
	for e in ALL:
		if changed(e[0]):
			cf.set_value("tune", e[0], value(e[0]))
			cf.set_value("where", e[0], "%s:%s:%d" % [String(e[3]).trim_prefix("res://"), e[4], e[5]])
			cf.set_value("default", e[0], default_of(e[0]))
	cf.save(path)


## Applies the saved overrides (debug builds, from main).
static func load_saved() -> void:
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return
	for id in cf.get_section_keys("tune") if cf.has_section("tune") else []:
		if not entry(id).is_empty():
			set_value(id, int(cf.get_value("tune", id)))
