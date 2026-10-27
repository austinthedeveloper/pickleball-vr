## The park, built in code: sky and sun, grass, the court in the port
## kit's two-tone colours (port ADR-022/027), lines, net, fences, trees.
## Real sizes: one unit is a metre.
class_name World
extends Node3D

const COURT := Color(0.16, 0.36, 0.62)
const KITCHEN := Color(0.22, 0.46, 0.72)
const SURROUND := Color(0.20, 0.45, 0.30)
const GRASS := Color(0.29, 0.52, 0.22)
const LINE := Color(0.96, 0.96, 0.94)
const FENCE := Color(0.10, 0.16, 0.12, 0.18)


## um to metres, in Godot's axes (the sim's are the same).
static func m(x: int, y: int, z: int) -> Vector3:
	return Vector3(x, y, z) / float(K.M)


static func um(v: Vector3) -> Array[int]:
	return [roundi(v.x * K.M), roundi(v.y * K.M), roundi(v.z * K.M)]


func _ready() -> void:
	_sky()
	var hw := K.COURT_HALF_WIDTH / float(K.M)
	var hl := K.COURT_HALF_LENGTH / float(K.M)
	var kd := K.KITCHEN_DEPTH / float(K.M)
	var lw := K.LINE_WIDTH / float(K.M)
	_box(Vector3(0, -0.05, 0), Vector3(80, 0.1, 80), GRASS)
	_box(Vector3(0, 0.0, 0), Vector3(hw * 2 + 6, 0.02, hl * 2 + 8), SURROUND)
	_box(Vector3(0, 0.012, 0), Vector3(hw * 2, 0.004, hl * 2), COURT)
	for s in [-1, 1]:
		_box(Vector3(0, 0.014, s * kd / 2), Vector3(hw * 2, 0.004, kd), KITCHEN)
	# Lines (measured to their outside edges, so inset half a width).
	var y := 0.017
	for s in [-1, 1]:
		_box(Vector3(s * (hw - lw / 2), y, 0), Vector3(lw, 0.003, hl * 2), LINE)
		_box(Vector3(0, y, s * (hl - lw / 2)), Vector3(hw * 2, 0.003, lw), LINE)
		_box(Vector3(0, y, s * (kd - lw / 2)), Vector3(hw * 2, 0.003, lw), LINE)
		_box(Vector3(0, y, s * (kd + hl) / 2), Vector3(lw, 0.003, hl - kd), LINE)
	_net()
	_fences(hw + 3, hl + 4)
	_trees()


func _sky() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = Color(0.30, 0.52, 0.86)
	mat.sky_horizon_color = Color(0.70, 0.82, 0.92)
	mat.ground_horizon_color = Color(0.55, 0.62, 0.55)
	mat.ground_bottom_color = Color(0.25, 0.35, 0.22)
	sky.sky_material = mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_white = 6.0
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 30.0
	add_child(sun)


static func material(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.9
	if c.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


func _box(at: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = material(c)
	mi.position = at
	add_child(mi)
	return mi


func _cylinder(at: Vector3, r: float, h: float, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = material(c)
	mi.position = at + Vector3(0, h / 2, 0)
	add_child(mi)
	return mi


func _net() -> void:
	var post := K.NET_POST_X / float(K.M)
	var top := K.NET_HEIGHT_POST / float(K.M)
	var mid := K.NET_HEIGHT_CENTER / float(K.M)
	for s in [-1, 1]:
		_cylinder(Vector3(s * post, 0, 0), 0.04, top + 0.03, Color(0.2, 0.2, 0.22))
	# The mesh: a strip of quads that sags to the centre's height.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 16
	for i in n:
		var x0 := -post + 2 * post * i / n
		var x1 := -post + 2 * post * (i + 1) / n
		var h0 := mid + (top - mid) * absf(x0) / post
		var h1 := mid + (top - mid) * absf(x1) / post
		for v in [Vector3(x0, 0.08, 0), Vector3(x1, 0.08, 0), Vector3(x1, h1 - 0.05, 0),
				Vector3(x0, 0.08, 0), Vector3(x1, h1 - 0.05, 0), Vector3(x0, h0 - 0.05, 0)]:
			st.add_vertex(v)
		var tape := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var len := Vector2(x1 - x0, h1 - h0).length()
		bm.size = Vector3(len, 0.05, 0.012)
		tape.mesh = bm
		tape.material_override = material(LINE)
		tape.position = Vector3((x0 + x1) / 2, (h0 + h1) / 2 - 0.025, 0)
		tape.rotation.z = atan2(h1 - h0, x1 - x0)
		add_child(tape)
	var net := MeshInstance3D.new()
	net.mesh = st.commit()
	var mat := material(Color(0.05, 0.05, 0.06, 0.55))
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	net.material_override = mat
	add_child(net)


func _fences(hx: float, hz: float) -> void:
	var h := 3.0
	var post_c := Color(0.15, 0.2, 0.16)
	for s in [-1, 1]:
		var side := _box(Vector3(s * hx, h / 2, 0), Vector3(0.02, h, hz * 2), FENCE)
		side.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var end := _box(Vector3(0, h / 2, s * hz), Vector3(hx * 2, h, 0.02), FENCE)
		end.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in range(-4, 5):
			_cylinder(Vector3(s * hx, 0, i * hz / 4.0), 0.035, h, post_c)
			_cylinder(Vector3(i * hx / 4.0, 0, s * hz), 0.035, h, post_c)


func _trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1994                  # the same park every time
	for i in 28:
		var a := TAU * i / 28.0 + rng.randf() * 0.15
		var r := rng.randf_range(16.0, 26.0)
		var at := Vector3(cos(a) * r, 0, sin(a) * r * 1.2)
		var h := rng.randf_range(2.0, 3.5)
		_cylinder(at, 0.18, h, Color(0.36, 0.25, 0.15))
		var crown := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var cr := rng.randf_range(1.4, 2.4)
		sm.radius = cr
		sm.height = cr * 2.2
		crown.mesh = sm
		crown.material_override = material(Color(0.16, 0.38, 0.15).lightened(rng.randf() * 0.15))
		crown.position = at + Vector3(0, h + cr * 0.8, 0)
		add_child(crown)
