## The venue, built in code (ADR-008): sky and light, the ground, the court
## in the port kit's preset colours (port ADR-022/027, data/court_colors.json),
## lines, net, and the venue's own surroundings. Set `venue` (Venues.*)
## before adding it. Real sizes: one unit is a metre.
class_name World
extends Node3D

## The port kit's presets (court_colors.json), 0-255.
const SURFACES := {"BLUE": [38, 92, 168], "NAVY": [34, 52, 112], "GREEN": [46, 122, 72],
	"PURPLE": [96, 64, 140], "CLAY": [176, 84, 52], "AQUA": [20, 130, 140]}
const SURROUNDS := {"GRASS": [86, 150, 70], "BRICK": [150, 70, 50], "ASPHALT": [70, 72, 78],
	"MAPLE": [216, 168, 104], "PARK": [51, 115, 77]}
const LINES := {"WHITE": [245, 245, 240], "CYAN": [120, 240, 255]}

## Each venue: its court (the port kit's venues.json grounds), the ground
## around it, its sky and its sound.
const VENUES := [
	{"surface": "BLUE", "kitchen": "NAVY", "surround": "PARK", "lines": "WHITE",
		"ground": [74, 133, 56], "sky": "day", "ambience": "park"},
	{"surface": "GREEN", "kitchen": "BLUE", "surround": "GRASS", "lines": "WHITE",
		"ground": [80, 140, 64], "sky": "lake", "ambience": "lakeside"},
	{"surface": "BLUE", "kitchen": "CLAY", "surround": "BRICK", "lines": "WHITE",
		"ground": [186, 140, 96], "sky": "sunset", "ambience": "sunset"},
	{"surface": "CLAY", "kitchen": "GREEN", "surround": "MAPLE", "lines": "WHITE",
		"ground": [200, 156, 98], "sky": "indoor", "ambience": "gym"},
	{"surface": "NAVY", "kitchen": "PURPLE", "surround": "ASPHALT", "lines": "CYAN",
		"ground": [88, 88, 96], "sky": "space", "ambience": "space"},
]

const FENCE := Color(0.10, 0.16, 0.12, 0.18)

var venue := Venues.PARK
var line_color := Color(0.96, 0.96, 0.94)
## FOCUS (ADR-013): the surroundings' materials and their own colours, so
## they can dim; the court, its lines and the net aren't among them.
var _scenery := true
var _dim: Array = []                 ## [material, base colour]
var _env: Environment
var _sky_mat: ProceduralSkyMaterial
var _sky_base: Array[Color] = []
var _bg_base := Color.BLACK
var _ambient_base := 1.0


## um to metres, in Godot's axes (the sim's are the same).
static func m(x: int, y: int, z: int) -> Vector3:
	return Vector3(x, y, z) / float(K.M)


static func um(v: Vector3) -> Array[int]:
	return [roundi(v.x * K.M), roundi(v.y * K.M), roundi(v.z * K.M)]


static func c8(rgb: Array) -> Color:
	return Color8(int(rgb[0]), int(rgb[1]), int(rgb[2]))


static func ambience(v: int) -> String:
	return "res://assets/audio/ambience_%s.ogg" % VENUES[clampi(v, 0, VENUES.size() - 1)]["ambience"]


func _ready() -> void:
	var d: Dictionary = VENUES[clampi(venue, 0, VENUES.size() - 1)]
	_sky(String(d["sky"]))
	var hw := K.COURT_HALF_WIDTH / float(K.M)
	var hl := K.COURT_HALF_LENGTH / float(K.M)
	var kd := K.KITCHEN_DEPTH / float(K.M)
	var lw := K.LINE_WIDTH / float(K.M)
	line_color = c8(LINES[d["lines"]])
	_box(Vector3(0, -0.05, 0), Vector3(80, 0.1, 80), c8(d["ground"]))
	_box(Vector3(0, 0.0, 0), Vector3(hw * 2 + 6, 0.02, hl * 2 + 8), c8(SURROUNDS[d["surround"]]))
	_scenery = false                     # the court stays bright under FOCUS
	_box(Vector3(0, 0.012, 0), Vector3(hw * 2, 0.004, hl * 2), c8(SURFACES[d["surface"]]))
	for s in [-1, 1]:
		_box(Vector3(0, 0.014, s * kd / 2), Vector3(hw * 2, 0.004, kd), c8(SURFACES[d["kitchen"]]))
	# Lines (measured to their outside edges, so inset half a width).
	var y := 0.017
	for s in [-1, 1]:
		_box(Vector3(s * (hw - lw / 2), y, 0), Vector3(lw, 0.003, hl * 2), line_color)
		_box(Vector3(0, y, s * (hl - lw / 2)), Vector3(hw * 2, 0.003, lw), line_color)
		_box(Vector3(0, y, s * (kd - lw / 2)), Vector3(hw * 2, 0.003, lw), line_color)
		_box(Vector3(0, y, s * (kd + hl) / 2), Vector3(lw, 0.003, hl - kd), line_color)
	_net()
	_scenery = true
	match venue:
		Venues.LAKESIDE:
			_fences(hw + 3, hl + 4, FENCE)
			_lake()
			_trees(14, 18.0, 24.0, false)
		Venues.SUNSET:
			_fences(hw + 3, hl + 4, Color(0.2, 0.12, 0.08, 0.2))
			_mesas()
			_trees(12, 15.0, 22.0, true)
		Venues.GYM:
			_gym(hw + 6, hl + 6)
		Venues.SPACE:
			_fences(hw + 3, hl + 4, Color(0.4, 0.95, 1.0, 0.12))
			_stars()
		_:
			_fences(hw + 3, hl + 4, FENCE)
			_trees(28, 16.0, 26.0, false)


func _sky(kind: String) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	# One orthogonal shadow map over the court, not four splits (each split
	# draws the scene again: the Quest's biggest single cost, ADR-009).
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 24.0
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_white = 6.0
	if kind == "indoor" or kind == "space":
		e.background_mode = Environment.BG_COLOR
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		if kind == "indoor":
			e.background_color = Color(0.12, 0.1, 0.09)
			e.ambient_light_color = Color(0.85, 0.8, 0.72)
			e.ambient_light_energy = 0.55
			sun.rotation_degrees = Vector3(-88, 0, 0)    # the hall's lights, straight down
			sun.light_energy = 0.8
		else:
			e.background_color = Color(0.0, 0.0, 0.02)
			e.ambient_light_color = Color(0.55, 0.6, 0.85)
			e.ambient_light_energy = 0.5
			sun.rotation_degrees = Vector3(-40, 60, 0)
			sun.light_color = Color(1.0, 0.97, 0.9)
			sun.light_energy = 1.1
	else:
		var sky := Sky.new()
		var mat := ProceduralSkyMaterial.new()
		mat.sky_top_color = Color(0.30, 0.52, 0.86)
		mat.sky_horizon_color = Color(0.70, 0.82, 0.92)
		mat.ground_horizon_color = Color(0.55, 0.62, 0.55)
		mat.ground_bottom_color = Color(0.25, 0.35, 0.22)
		if kind == "lake":
			mat.sky_top_color = Color(0.22, 0.48, 0.88)
			mat.sky_horizon_color = Color(0.74, 0.86, 0.95)
		elif kind == "sunset":
			mat.sky_top_color = Color(0.32, 0.22, 0.5)
			mat.sky_horizon_color = Color(1.0, 0.55, 0.3)
			mat.ground_horizon_color = Color(0.7, 0.42, 0.3)
			mat.sun_angle_max = 30.0
			sun.rotation_degrees = Vector3(-12, 180, 0)  # low, behind the far baseline
			sun.light_color = Color(1.0, 0.7, 0.45)
			sun.light_energy = 1.05
		sky.sky_material = mat
		e.background_mode = Environment.BG_SKY
		e.sky = sky
		# Ambient from a fixed colour (the sky's own, averaged), not the sky
		# itself: FOCUS darkens the sky without dimming the lit court, the
		# players or your paddle (ADR-013).
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = (mat.sky_top_color + mat.sky_horizon_color * 2.0 + mat.ground_horizon_color) / 4.0
		e.ambient_light_energy = 0.55
	env.environment = e
	add_child(env)
	_env = e
	_bg_base = e.background_color
	_ambient_base = e.ambient_light_energy
	if e.sky:
		_sky_mat = e.sky.sky_material as ProceduralSkyMaterial
		_sky_base = [_sky_mat.sky_top_color, _sky_mat.sky_horizon_color, _sky_mat.ground_horizon_color,
			_sky_mat.ground_bottom_color]
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
	mi.material_override = _track(material(c))
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
	mi.material_override = _track(material(c))
	mi.position = at + Vector3(0, h / 2, 0)
	add_child(mi)
	return mi


func _sphere(at: Vector3, r: float, squash: float, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2 * squash
	mi.mesh = sm
	mi.material_override = _track(material(c))
	mi.position = at
	add_child(mi)
	return mi


func _track(m: StandardMaterial3D) -> StandardMaterial3D:
	if _scenery:
		_dim.append([m, m.albedo_color])
	return m


## FOCUS: dim everything but the court by `a` (0 .. Focus.MAX). The sky
## darkens too; the ambient light it gives the court is held level.
func set_focus(a: float) -> void:
	var k := 1.0 - a
	for pair in _dim:
		var c: Color = pair[1]
		(pair[0] as StandardMaterial3D).albedo_color = Color(c.r * k, c.g * k, c.b * k, c.a)
	if _sky_mat:
		_sky_mat.sky_top_color = _sky_base[0] * k
		_sky_mat.sky_horizon_color = _sky_base[1] * k
		_sky_mat.ground_horizon_color = _sky_base[2] * k
		_sky_mat.ground_bottom_color = _sky_base[3] * k
	else:
		_env.background_color = _bg_base * k


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
		tape.material_override = material(Color(0.96, 0.96, 0.94))
		tape.position = Vector3((x0 + x1) / 2, (h0 + h1) / 2 - 0.025, 0)
		tape.rotation.z = atan2(h1 - h0, x1 - x0)
		add_child(tape)
	var net := MeshInstance3D.new()
	net.mesh = st.commit()
	var mat := material(Color(0.05, 0.05, 0.06, 0.55))
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	net.material_override = mat
	add_child(net)


func _fences(hx: float, hz: float, c: Color) -> void:
	var h := 3.0
	var post_c := Color(c.r, c.g, c.b).darkened(0.2)
	for s in [-1, 1]:
		var side := _box(Vector3(s * hx, h / 2, 0), Vector3(0.02, h, hz * 2), c)
		side.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var end := _box(Vector3(0, h / 2, s * hz), Vector3(hx * 2, h, 0.02), c)
		end.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in range(-4, 5):
			_cylinder(Vector3(s * hx, 0, i * hz / 4.0), 0.035, h, post_c)
			_cylinder(Vector3(i * hx / 4.0, 0, s * hz), 0.035, h, post_c)


## Round trees, or palms (SUNSET), in a ring around the court.
func _trees(count: int, near: float, far: float, palms: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1994 + venue              # the same venue every time
	for i in count:
		var a := TAU * i / count + rng.randf() * 0.15
		var r := rng.randf_range(near, far)
		var at := Vector3(cos(a) * r, 0, sin(a) * r * 1.2)
		if venue == Venues.LAKESIDE and at.z < -12.0:
			continue                     # the lake's there
		if palms:
			var h := rng.randf_range(4.0, 6.5)
			_cylinder(at, 0.14, h, Color(0.45, 0.33, 0.2))
			for k in 5:
				var leaf := _sphere(at + Vector3(0, h, 0), 1.3, 0.18, Color(0.2, 0.42, 0.18))
				leaf.rotation = Vector3(0.35, TAU * k / 5.0, 0)
				leaf.position += Vector3(cos(TAU * k / 5.0), -0.2, sin(TAU * k / 5.0)) * 0.7
			continue
		var h2 := rng.randf_range(2.0, 3.5)
		_cylinder(at, 0.18, h2, Color(0.36, 0.25, 0.15))
		var cr := rng.randf_range(1.4, 2.4)
		_sphere(at + Vector3(0, h2 + cr * 0.8, 0), cr, 1.1, Color(0.16, 0.38, 0.15).lightened(rng.randf() * 0.15))


## LAKESIDE: the water beyond the far fence, a dock, hills across it.
func _lake() -> void:
	var water := _box(Vector3(0, 0.02, -45), Vector3(140, 0.02, 64), Color(0.16, 0.42, 0.62))
	var wm := water.material_override as StandardMaterial3D
	wm.roughness = 0.15
	wm.metallic = 0.3
	_box(Vector3(0, 0.03, -13.4), Vector3(140, 0.04, 1.2), Color(0.78, 0.7, 0.5))      # the shore
	_box(Vector3(6, 0.25, -19), Vector3(1.6, 0.12, 10), Color(0.5, 0.36, 0.22))        # the dock
	for k in 4:
		for s in [-1, 1]:
			_cylinder(Vector3(6 + s * 0.7, -0.5, -15 - k * 3), 0.08, 0.8, Color(0.35, 0.25, 0.15))
	for i in 5:
		_sphere(Vector3(-50 + i * 25, -6, -78), 22.0, 0.55, Color(0.3, 0.45, 0.32).lightened(i * 0.04))


## SUNSET: red rock mesas on the horizon.
func _mesas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 9:
		var a := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(45.0, 70.0)
		var w := rng.randf_range(8.0, 18.0)
		var h := rng.randf_range(5.0, 12.0)
		_box(Vector3(cos(a) * r, h / 2, sin(a) * r), Vector3(w, h, w * 0.7), Color(0.62, 0.3, 0.2).darkened(rng.randf() * 0.2))


## GYM: a hall, walls and a roof with rows of lights, no fences.
func _gym(hx: float, hz: float) -> void:
	var h := 9.0
	var wall := Color(0.86, 0.84, 0.78)
	for s in [-1, 1]:
		_box(Vector3(s * hx, h / 2, 0), Vector3(0.3, h, hz * 2), wall)
		_box(Vector3(0, h / 2, s * hz), Vector3(hx * 2, h, 0.3), wall)
		_box(Vector3(0, 1.0, s * (hz - 0.2)), Vector3(hx * 2, 2.0, 0.1), Color(0.2, 0.3, 0.6))   # the padding
	_box(Vector3(0, h, 0), Vector3(hx * 2, 0.3, hz * 2), Color(0.5, 0.5, 0.52))
	for x in [-4.0, 0.0, 4.0]:
		for z in [-9.0, -3.0, 3.0, 9.0]:
			var lamp := _box(Vector3(x, h - 0.3, z), Vector3(1.6, 0.1, 0.5), Color(1, 1, 0.95))
			var lm := lamp.material_override as StandardMaterial3D
			lm.emission_enabled = true
			lm.emission = Color(1, 0.97, 0.88)
			lm.emission_energy_multiplier = 2.0
	# A banner on the far wall, the port kit's GYM BROS' home.
	var banner := Label3D.new()
	banner.text = "GYM BROS  -  HOME OF THE DINK"
	banner.font_size = 120
	banner.pixel_size = 0.006
	banner.modulate = Color(0.95, 0.8, 0.2)
	banner.position = Vector3(0, 6.0, -hz + 0.2)
	add_child(banner)


## SPACE: stars all round, a ringed planet, the moon underfoot.
func _stars() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.24
	sm.radial_segments = 4
	sm.rings = 2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1)
	sm.material = mat
	mm.mesh = sm
	mm.instance_count = 400
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in mm.instance_count:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.05, 1), rng.randf_range(-1, 1)).normalized()
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * rng.randf_range(0.5, 1.6)), d * 90.0))
	var stars := MultiMeshInstance3D.new()
	stars.multimesh = mm
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stars)
	var planet := _sphere(Vector3(-40, 28, -70), 14.0, 1.0, Color(0.85, 0.55, 0.35))
	planet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 18.0
	tm.outer_radius = 24.0
	ring.mesh = tm
	ring.material_override = material(Color(0.9, 0.8, 0.6, 0.6))
	ring.position = planet.position
	ring.rotation = Vector3(0.4, 0, 0.3)
	ring.scale = Vector3(1, 0.08, 1)             # a flat band, not a tyre
	add_child(ring)
	for i in 14:
		var a := TAU * i / 14.0
		_sphere(Vector3(cos(a) * 22.0, -0.6, sin(a) * 26.0), rng.randf_range(2.0, 4.0), 0.4, Color(0.4, 0.4, 0.44))
