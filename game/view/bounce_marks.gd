## Bounce marks (VR-106): each bounce leaves a pale scuff on the court that
## fades over a couple of seconds, unshaded so it reads the same by day,
## at dusk and under the lights. A ball that lands within CLOSE of a
## sideline or baseline (in or out) glows gold at its mark for a moment:
## a close call you can see. Display only: the sim's own bounce, never
## written back.
class_name BounceMarks
extends Node3D

const MARKS := 4                     ## kept at once, oldest reused
const LIFE := 2.6                    ## s a mark stays
const GLOW := 1.4                    ## s a close call glows
const CLOSE := 100000                ## um: this near a boundary line's edge is a close call
const R := 0.09                      ## m: a scuff's radius, well over a ball's (3.7 cm), so it reads from your end
const PALE := Color(0.92, 0.96, 1.0)
const GOLD := Color(1.0, 0.82, 0.22)

var _marks: Array[MeshInstance3D] = []
var _age: Array[float] = []
var _close: Array[bool] = []
var _next := 0
var close_calls := 0                 ## tests: how many glowed


## Within CLOSE of a sideline or baseline's outside edge (lines are in),
## where the ball touched the court at (x, z), um.
static func close_call(x: int, z: int) -> bool:
	var dx := absi(absi(x) - K.COURT_HALF_WIDTH)
	var dz := absi(absi(z) - K.COURT_HALF_LENGTH)
	var by_side := dx <= CLOSE and absi(z) <= K.COURT_HALF_LENGTH + CLOSE
	var by_end := dz <= CLOSE and absi(x) <= K.COURT_HALF_WIDTH + CLOSE
	return by_side or by_end


func _ready() -> void:
	for i in MARKS:
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = R
		cm.bottom_radius = R
		cm.height = 0.002
		cm.radial_segments = 16
		mi.mesh = cm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(PALE, 0.0)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_marks.append(mi)
		_age.append(LIFE)
		_close.append(false)


## A bounce at (x, z), um.
func add(x: int, z: int) -> void:
	var i := _next
	_next = (_next + 1) % MARKS
	_marks[i].position = Vector3(x / float(K.M), 0.021, z / float(K.M))
	_marks[i].visible = true
	_age[i] = 0.0
	_close[i] = close_call(x, z)
	if _close[i]:
		close_calls += 1
	_show(i)


func _process(delta: float) -> void:
	for i in MARKS:
		if not _marks[i].visible:
			continue
		_age[i] += delta
		if _age[i] >= LIFE:
			_marks[i].visible = false
			continue
		_show(i)


## A mark's look now: pale, fading; a close call gold at first, pulsing,
## a little bigger.
func _show(i: int) -> void:
	var m := _marks[i].material_override as StandardMaterial3D
	var fade := 1.0 - _age[i] / LIFE
	if _close[i] and _age[i] < GLOW:
		var pulse := 0.75 + 0.25 * cos(_age[i] * TAU * 2.0)
		m.albedo_color = Color(GOLD, 0.9 * pulse)
		_marks[i].scale = Vector3.ONE * (2.0 + 0.4 * pulse)
	else:
		m.albedo_color = Color(PALE, 0.55 * fade)
		_marks[i].scale = Vector3.ONE


func glowing() -> int:
	var n := 0
	for i in MARKS:
		if _marks[i].visible and _close[i] and _age[i] < GLOW:
			n += 1
	return n
