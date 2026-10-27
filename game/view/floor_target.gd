## A floor target (ADR-010): a glowing ring and disc on their side that
## pulses gently, and flares when you land a ball in it. Display only.
class_name FloorTarget
extends Node3D

const COLOR := Color(1.0, 0.82, 0.15)

var _ring: MeshInstance3D
var _disc: MeshInstance3D
var _flash := 0.0
var _t := 0.0


func _ready() -> void:
	var r := Drill.TARGET_RADIUS / float(K.M)
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r - 0.05
	tm.outer_radius = r
	_ring.mesh = tm
	_ring.scale = Vector3(1, 0.15, 1)
	_ring.material_override = _glow(COLOR, 1.0)
	add_child(_ring)
	_disc = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r - 0.05
	cm.bottom_radius = r - 0.05
	cm.height = 0.002
	_disc.mesh = cm
	_disc.material_override = _glow(COLOR, 0.22)
	add_child(_disc)


static func _glow(c: Color, alpha: float) -> StandardMaterial3D:
	var m := World.material(Color(c, alpha))
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func show_from(sim: Sim, delta: float) -> void:
	var d := sim.drill
	_t += delta
	_flash = maxf(_flash - delta * 2.0, 0.0)
	var at := World.m(d.target_x, 0, d.target_z) + Vector3(0, 0.025, 0)
	position = position.lerp(at, clampf(delta * 8.0, 0.0, 1.0)) if _flash > 0.0 else at
	var pulse := 1.0 + 0.04 * sin(_t * 4.0) + 0.6 * _flash
	scale = Vector3(pulse, 1, pulse)
	(_disc.material_override as StandardMaterial3D).albedo_color.a = 0.22 + 0.6 * _flash


func flare() -> void:
	_flash = 1.0
