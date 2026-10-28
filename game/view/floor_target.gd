## A floor target (ADR-010): a glowing ring and disc on their side that
## pulses gently, and flares when you land a ball in it. CALL THE SPOT
## (ADR-017) uses it as the spot: green, hidden until the sim lights it,
## and popping up as it does. Display only.
class_name FloorTarget
extends Node3D

const COLOR := Color(1.0, 0.82, 0.15)
const SPOT_COLOR := Color(0.25, 1.0, 0.45)

var radius := Drill.TARGET_RADIUS     ## um; set before it's added
var spot := false                    ## CALL THE SPOT: shown only while lit
var _was_lit := false
var _spot_at := Vector2.ZERO
var _ring: MeshInstance3D
var _disc: MeshInstance3D
var _flash := 0.0
var _t := 0.0


func _ready() -> void:
	var r := radius / float(K.M)
	var c := SPOT_COLOR if spot else COLOR
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r - 0.05
	tm.outer_radius = r
	_ring.mesh = tm
	_ring.scale = Vector3(1, 0.15, 1)
	_ring.material_override = _glow(c, 1.0)
	add_child(_ring)
	_disc = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r - 0.05
	cm.bottom_radius = r - 0.05
	cm.height = 0.002
	_disc.mesh = cm
	_disc.material_override = _glow(c, 0.22)
	add_child(_disc)


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
	(_disc.material_override as StandardMaterial3D).albedo_color.a = 0.22 + 0.6 * _flash


func flare() -> void:
	_flash = 1.0
