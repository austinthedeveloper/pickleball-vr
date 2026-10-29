## The crowd: bleachers outside the fence on both sidelines, and the people
## on them. Everyone is one spectator mesh (a seated person: legs, a torso,
## arms resting on the knees, a neck, a head with hair), drawn by MultiMesh
## in their own shirt, skin, trousers and hair (crowd.gdshader). Those
## cheering are drawn from a second mesh with their arms up, so the
## headset pays two draw calls for everyone. They sway while they watch
## and jump up on a point; how high, and for how long, follows how good the
## rally was.
class_name Crowd
extends Node3D

const PER_SIDE := 54
const TIERS := 3
const SHIRTS := [Color(0.85, 0.2, 0.2), Color(0.2, 0.45, 0.85), Color(0.95, 0.8, 0.2),
	Color(0.3, 0.7, 0.35), Color(0.9, 0.5, 0.15), Color(0.6, 0.3, 0.75), Color(0.92, 0.92, 0.9)]
const SHADER := preload("res://view/crowd.gdshader")
const SHIRT := 0.0
const SKIN := 0.25
const PANTS := 0.5
const HAIR := 0.75
const ARMS_UP_AT := 0.35             ## cheering this hard, the arms go up

var bodies: MultiMeshInstance3D      ## seated, arms down
var cheering: MultiMeshInstance3D    ## the same people, arms up (hidden below the stands until they cheer)
var cheer := 0.0                     ## 0..1, how hard they're cheering now
var arms_up := 0                     ## how many have their arms up now
var last_usec := 0                   ## this frame's cost (Perf)
var _seats: Array[Vector3] = []
var _phase: Array[float] = []
var _face: Array[Basis] = []
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _mat: ShaderMaterial


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
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	bodies = _multi(spectator(false))
	cheering = _multi(spectator(true))
	var n := PER_SIDE * 2
	bodies.multimesh.instance_count = n
	cheering.multimesh.instance_count = n
	var i := 0
	for side in [-1, 1]:
		for k in PER_SIDE:
			var tier := k % TIERS
			var x: float = side * (hx + 1.0 + tier * 0.8)
			var z := -6.6 + 13.2 * (k / TIERS) / float(PER_SIDE / TIERS - 1) + _rng.randf_range(-0.15, 0.15)
			if _rng.randf() < 0.15:
				z += 0.35                # gaps and clumps, not a grid
			_seats.append(Vector3(x - side * 0.1, 0.42 + tier * 0.4, z))
			_phase.append(_rng.randf() * TAU)
			# Facing the court, each a little turned.
			_face.append(Basis(Vector3.UP, -side * PI / 2 + _rng.randf_range(-0.35, 0.35)))
			var shirt: Color = SHIRTS[_rng.randi() % SHIRTS.size()]
			var looks := _rng.randi() % 64
			var custom := Color(shirt.r, shirt.g, shirt.b, looks / 64.0)
			bodies.multimesh.set_instance_custom_data(i, custom)
			cheering.multimesh.set_instance_custom_data(i, custom)
			i += 1
	_place(0.0)


## FOCUS: the crowd dims with the rest (ADR-013).
func set_focus(a: float) -> void:
	_mat.set_shader_parameter("dim", 1.0 - a)


func _multi(mesh: Mesh) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## One seated spectator, facing +Z, the seat at the origin: each part's
## vertices carry their part in UV.x (SHIRT, SKIN, PANTS, HAIR; not the
## colour, which the renderer converts to linear).
static func spectator(arms_up: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Thighs forward along the seat, shins down to the step below.
	for s in [-1, 1]:
		_box(st, Vector3(0.15, 0.14, 0.44), Vector3(s * 0.1, 0.07, 0.2), PANTS)
		_box(st, Vector3(0.12, 0.44, 0.13), Vector3(s * 0.1, -0.15, 0.4), PANTS)
		_box(st, Vector3(0.11, 0.07, 0.24), Vector3(s * 0.1, -0.38, 0.45), PANTS)   # shoes, dark
	# The torso, a little narrower at the waist, leaning in.
	var lean := Basis(Vector3.RIGHT, 0.12)
	_box(st, Vector3(0.34, 0.3, 0.2), Vector3(0, 0.24, 0.02), SHIRT, lean)
	_box(st, Vector3(0.4, 0.26, 0.22), Vector3(0, 0.5, 0.05), SHIRT, lean)
	# Neck, head, hair.
	_box(st, Vector3(0.09, 0.1, 0.09), Vector3(0, 0.68, 0.08), SKIN)
	var head := SphereMesh.new()
	head.radius = 0.105
	head.height = 0.25
	head.radial_segments = 10
	head.rings = 6
	_add(st, head, Transform3D(Basis(), Vector3(0, 0.83, 0.09)), SKIN)
	var hair := SphereMesh.new()
	hair.radius = 0.112
	hair.height = 0.13
	hair.is_hemisphere = true
	hair.radial_segments = 10
	hair.rings = 3
	_add(st, hair, Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3(0, 0.86, 0.07)), HAIR)
	# Arms: resting on the knees, or thrown up.
	for s in [-1, 1]:
		if arms_up:
			var up := Basis(Vector3.BACK, s * 0.35)
			_box(st, Vector3(0.09, 0.3, 0.09), Vector3(s * 0.27, 0.78, 0.06), SHIRT, up)
			_box(st, Vector3(0.075, 0.3, 0.075), Vector3(s * 0.37, 1.05, 0.06), SKIN, up)
		else:
			_box(st, Vector3(0.09, 0.3, 0.09), Vector3(s * 0.22, 0.47, 0.08), SHIRT, Basis(Vector3.RIGHT, 0.2))
			_box(st, Vector3(0.075, 0.075, 0.3), Vector3(s * 0.19, 0.3, 0.26), SKIN)
	st.generate_normals()
	return st.commit()


static func _box(st: SurfaceTool, size: Vector3, at: Vector3, part: float, rot := Basis()) -> void:
	var b := BoxMesh.new()
	b.size = size
	_add(st, b, Transform3D(rot, at), part)


static func _add(st: SurfaceTool, mesh: PrimitiveMesh, at: Transform3D, part: float) -> void:
	var a := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	for k in idx:
		st.set_uv(Vector2(part, 0))
		st.add_vertex(at * verts[k])


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


static var HIDDEN := Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(0, -50, 0))


func _place(t: float) -> void:
	arms_up = 0
	for i in _seats.size():
		var s := _seats[i]
		var p := _phase[i]
		var sway := sin(t * 1.3 + p) * 0.03
		var jump := maxf(sin(t * 9.0 + p), 0.0) * 0.35 * cheer
		var rise := cheer * 0.25               # standing up
		var at := Transform3D(_face[i], Vector3(s.x, s.y + rise + jump, s.z + sway))
		# The keenest throw their arms up first.
		var up := cheer > ARMS_UP_AT + 0.4 * fposmod(p, 1.0)
		arms_up += 1 if up else 0
		bodies.multimesh.set_instance_transform(i, HIDDEN if up else at)
		cheering.multimesh.set_instance_transform(i, at if up else HIDDEN)
