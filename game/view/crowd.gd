## The crowd: bleachers outside the fence on both sidelines, the people on
## them drawn as two MultiMeshes (bodies, heads) so the headset pays two
## draw calls a side. They sway while they watch and jump up on a point;
## how high, and for how long, follows how good the rally was.
class_name Crowd
extends Node3D

const PER_SIDE := 54
const TIERS := 3
const SHIRTS := [Color(0.85, 0.2, 0.2), Color(0.2, 0.45, 0.85), Color(0.95, 0.8, 0.2),
	Color(0.3, 0.7, 0.35), Color(0.9, 0.5, 0.15), Color(0.6, 0.3, 0.75), Color(0.92, 0.92, 0.9)]
const SKINS := [Color(0.95, 0.78, 0.62), Color(0.78, 0.56, 0.4), Color(0.55, 0.37, 0.24), Color(0.98, 0.84, 0.72)]

var bodies: MultiMeshInstance3D
var heads: MultiMeshInstance3D
var cheer := 0.0                     ## 0..1, how hard they're cheering now
var last_usec := 0                   ## this frame's cost (Perf)
var _seats: Array[Vector3] = []
var _phase: Array[float] = []
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 94                   # the same crowd every match
	var hx := K.COURT_HALF_WIDTH / float(K.M) + 3.0
	for side in [-1, 1]:
		for tier in TIERS:
			var x: float = side * (hx + 1.0 + tier * 0.8)
			var bench := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.7, 0.42 + tier * 0.4, 14.0)
			bench.mesh = bm
			bench.material_override = World.material(Color(0.55, 0.57, 0.6))
			bench.position = Vector3(x, bm.size.y / 2, 0)
			add_child(bench)
	var bm2 := CapsuleMesh.new()
	bm2.radius = 0.17
	bm2.height = 0.75
	var hm := SphereMesh.new()
	hm.radius = 0.11
	hm.height = 0.24
	bodies = _multi(bm2)
	heads = _multi(hm)
	var n := PER_SIDE * 2
	bodies.multimesh.instance_count = n
	heads.multimesh.instance_count = n
	var i := 0
	for side in [-1, 1]:
		for k in PER_SIDE:
			var tier := k % TIERS
			var x: float = side * (hx + 1.0 + tier * 0.8)
			var z := -6.6 + 13.2 * (k / TIERS) / float(PER_SIDE / TIERS - 1) + _rng.randf_range(-0.15, 0.15)
			if _rng.randf() < 0.15:
				z += 0.35                # gaps and clumps, not a grid
			_seats.append(Vector3(x, 0.42 + tier * 0.4, z))
			_phase.append(_rng.randf() * TAU)
			bodies.multimesh.set_instance_color(i, SHIRTS[_rng.randi() % SHIRTS.size()])
			heads.multimesh.set_instance_color(i, SKINS[_rng.randi() % SKINS.size()])
			i += 1
	_place(0.0)


## FOCUS: the crowd dims with the rest (ADR-013).
func set_focus(a: float) -> void:
	var k := 1.0 - a
	for mi in [bodies, heads]:
		((mi as MultiMeshInstance3D).multimesh.mesh.surface_get_material(0) as StandardMaterial3D).albedo_color = Color(k, k, k)


func _multi(mesh: PrimitiveMesh) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mesh.material = mat
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## A point's end: `strength` 0..1 (a long rally or a winner is near 1).
func react(strength: float) -> void:
	cheer = maxf(cheer, clampf(strength, 0.2, 1.0))


func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_t += delta
	cheer = maxf(cheer - delta * 0.45, 0.0)
	_place(_t)
	last_usec = Time.get_ticks_usec() - t0
	Perf.add("crowd", last_usec)


func _place(t: float) -> void:
	for i in _seats.size():
		var s := _seats[i]
		var p := _phase[i]
		var sway := sin(t * 1.3 + p) * 0.03
		var jump := maxf(sin(t * 9.0 + p), 0.0) * 0.35 * cheer
		var rise := cheer * 0.25               # standing up
		var body := Vector3(s.x, s.y + 0.4 + rise + jump, s.z + sway)
		bodies.multimesh.set_instance_transform(i, Transform3D(Basis(), body))
		heads.multimesh.set_instance_transform(i, Transform3D(Basis(), body + Vector3(0, 0.5, 0)))
