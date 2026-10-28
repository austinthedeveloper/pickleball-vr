## A floor target (ADR-010): a dartboard (ADR-019) glowing on their side,
## pulsing gently, flaring when you land a ball on it: an outer ring, an
## inner ring, a bright bullseye. CALL THE SPOT (ADR-017) uses it as the
## spot: green, hidden until the sim lights it, and popping up as it
## does. Display only.
class_name FloorTarget
extends Node3D

const COLOR := Color(1.0, 0.82, 0.15)
const SPOT_COLOR := Color(0.25, 1.0, 0.45)
const DISC_ALPHA := [0.14, 0.24, 0.6]   ## outer ring, inner ring, bullseye

var radius := Drill.TARGET_RADIUS     ## um; set before it's added
var spot := false                    ## CALL THE SPOT: shown only while lit
var _was_lit := false
var _spot_at := Vector2.ZERO
var _rings: Array[MeshInstance3D] = []
var _discs: Array[MeshInstance3D] = []
var _flash := 0.0
var _t := 0.0


func _ready() -> void:
	var r := radius / float(K.M)
	var c := SPOT_COLOR if spot else COLOR
	# From the outside in, each band a little brighter; the bullseye solid.
	for i in Drill.RING_EDGES.size():
		var ri: float = r * Drill.RING_EDGES[i] / 100.0
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = ri - 0.035
		tm.outer_radius = ri
		ring.mesh = tm
		ring.scale = Vector3(1, 0.15, 1)
		ring.material_override = _glow(c, 1.0)
		add_child(ring)
		_rings.append(ring)
		var disc := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = ri - 0.035
		cm.bottom_radius = ri - 0.035
		cm.height = 0.002
		disc.mesh = cm
		disc.position.y = 0.001 * i      # inner discs over outer ones
		disc.material_override = _glow(c.lightened(0.25 * i), DISC_ALPHA[i])
		add_child(disc)
		_discs.append(disc)


static func _glow(c: Color, alpha: float) -> StandardMaterial3D:
	var m := World.material(Color(c, alpha))
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func show_from(sim: Sim, delta: float) -> void:
	var d := sim.drill
	if spot:
		visible = d.spot_lit
		var moved := Vector2(d.target_x, d.target_z) != _spot_at
		if d.spot_lit and (not _was_lit or moved):
			_flash = 1.0                 # it lights, or moves: a pop to catch your eye
		_was_lit = d.spot_lit
		_spot_at = Vector2(d.target_x, d.target_z)
	_t += delta
	_flash = maxf(_flash - delta * 2.0, 0.0)
	var at := World.m(d.target_x, 0, d.target_z) + Vector3(0, 0.025, 0)
	position = position.lerp(at, clampf(delta * 8.0, 0.0, 1.0)) if _flash > 0.0 and not spot else at
	var pulse := 1.0 + 0.04 * sin(_t * 4.0) + 0.6 * _flash
	scale = Vector3(pulse, 1, pulse)
	for i in _discs.size():
		(_discs[i].material_override as StandardMaterial3D).albedo_color.a = DISC_ALPHA[i] + 0.5 * _flash


func flare() -> void:
	_flash = 1.0
