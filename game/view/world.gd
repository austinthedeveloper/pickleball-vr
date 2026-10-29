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
## Passthrough (ADR-021): the court, its lines and the net in your room;
## no ground, sky or scenery. The headset shows the room where nothing's drawn.
var passthrough := false
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
	_sky("passthrough" if passthrough else String(d["sky"]))
	var hw := K.COURT_HALF_WIDTH / float(K.M)
	var hl := K.COURT_HALF_LENGTH / float(K.M)
	var kd := K.KITCHEN_DEPTH / float(K.M)
	var lw := K.LINE_WIDTH / float(K.M)
	line_color = c8(LINES[d["lines"]])
	var indoor := venue == Venues.GYM or venue == Venues.SPACE
	if not passthrough:
		_grain(_box(Vector3(0, -0.05, 0), Vector3(80, 0.1, 80), c8(d["ground"])), grass_texture() if not indoor else grain_texture(), 0.25)
		_grain(_box(Vector3(0, 0.0, 0), Vector3(hw * 2 + 6, 0.02, hl * 2 + 8), c8(SURROUNDS[d["surround"]])), grain_texture(), 0.6)
	_scenery = false                     # the court stays bright under FOCUS
	# The court: acrylic over the slab, its sand grain in the paint.
	_grain(_box(Vector3(0, 0.012, 0), Vector3(hw * 2, 0.004, hl * 2), c8(SURFACES[d["surface"]])), grain_texture(), 0.6)
	for s in [-1, 1]:
		_grain(_box(Vector3(0, 0.014, s * kd / 2), Vector3(hw * 2, 0.004, kd), c8(SURFACES[d["kitchen"]])), grain_texture(), 0.6)
	# Lines (measured to their outside edges, so inset half a width).
	var y := 0.017
	for s in [-1, 1]:
		for b in [[Vector3(s * (hw - lw / 2), y, 0), Vector3(lw, 0.003, hl * 2)],
				[Vector3(0, y, s * (hl - lw / 2)), Vector3(hw * 2, 0.003, lw)],
				[Vector3(0, y, s * (kd - lw / 2)), Vector3(hw * 2, 0.003, lw)],
				[Vector3(0, y, s * (kd + hl) / 2), Vector3(lw, 0.003, hl - kd)]]:
			_grain(_box(b[0], b[1], line_color), grain_texture(), 0.6)
	_net()
	_scenery = true
	if passthrough:
		return
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
	if kind == "passthrough":
		# Nothing behind the court: a clear background the headset fills
		# with the room; light that suits a room.
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(0, 0, 0, 0)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.85, 0.85, 0.85)
		e.ambient_light_energy = 0.6
		sun.rotation_degrees = Vector3(-70, -20, 0)
		sun.light_energy = 0.75
	elif kind == "indoor" or kind == "space":
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


## A box's material given a grain: the colour times a tiling texture laid
## in world space (`per_m` repeats a metre), sharp at a glancing angle.
func _grain(mi: MeshInstance3D, tex: Texture2D, per_m: float) -> MeshInstance3D:
	var m := mi.material_override as StandardMaterial3D
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * per_m
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.82
	return mi


static var _grain_tex: ImageTexture
static var _grass_tex: ImageTexture
static var _link_tex: ImageTexture


## A court's acrylic: fine sand speckle over a faint, broad mottle, around
## white (it multiplies the paint's colour).
static func grain_texture() -> ImageTexture:
	if _grain_tex:
		return _grain_tex
	var fine := FastNoiseLite.new()
	fine.seed = 94
	fine.frequency = 0.35
	var broad := FastNoiseLite.new()
	broad.seed = 1994
	broad.frequency = 0.012
	var a := fine.get_seamless_image(256, 256)
	var b := broad.get_seamless_image(256, 256)
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var v := 0.9 + 0.07 * a.get_pixel(x, y).r + 0.05 * b.get_pixel(x, y).r
			img.set_pixel(x, y, Color(v, v, v))
	img.generate_mipmaps()
	_grain_tex = ImageTexture.create_from_image(img)
	return _grain_tex


## Grass: blades' streaks and patches of lighter and darker green.
static func grass_texture() -> ImageTexture:
	if _grass_tex:
		return _grass_tex
	var blades := FastNoiseLite.new()
	blades.seed = 7
	blades.frequency = 0.25
	var patches := FastNoiseLite.new()
	patches.seed = 8
	patches.frequency = 0.008
	var a := blades.get_seamless_image(256, 256)
	var b := patches.get_seamless_image(256, 256)
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var v := 0.78 + 0.22 * a.get_pixel(x, y).r * 0.8 + 0.25 * (b.get_pixel(x, y).r - 0.5)
			img.set_pixel(x, y, Color(v * 0.97, v, v * 0.9))
	img.generate_mipmaps()
	_grass_tex = ImageTexture.create_from_image(img)
	return _grass_tex


## Chain link: wire diamonds on clear, mipmapped so it greys with distance
## (as the net does).
static func link_texture() -> ImageTexture:
	if _link_tex:
		return _link_tex
	const N := 32
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.6, 0.62, 0.64, 0.05))
	for i in N:
		for w in 2:
			img.set_pixel((i + w) % N, i, Color(0.72, 0.74, 0.76, 1.0))
			img.set_pixel((N - 1 - i + w) % N, i, Color(0.72, 0.74, 0.76, 1.0))
	img.generate_mipmaps()
	_link_tex = ImageTexture.create_from_image(img)
	return _link_tex


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
	elif not passthrough:
		_env.background_color = _bg_base * k


## The net (a real one's parts): square-mesh cord sagging to the
## centre's height as the sim's net does, the white tape over the top, a
## centre strap down to the court, white bindings at the ends, and metal
## posts with caps, collars and a winder. The cord is a texture: from
## near you see the squares, far off it blends to a dark veil.
const NET_CELL := 0.045                ## the mesh's squares (1.75 in)
const NET_BOTTOM := 0.06               ## its lower edge, above the court
const TAPE := 0.05


func _net() -> void:
	var post := K.NET_POST_X / float(K.M)
	var top := K.NET_HEIGHT_POST / float(K.M)
	var mid := K.NET_HEIGHT_CENTER / float(K.M)
	var metal := material(Color(0.12, 0.13, 0.14))
	metal.metallic = 0.6
	metal.roughness = 0.35
	for s in [-1, 1]:
		var p := _cylinder(Vector3(s * post, 0, 0), 0.024, top + 0.04, Color.BLACK)
		p.material_override = _track(metal)
		var cap := _sphere(Vector3(s * post, top + 0.04, 0), 0.03, 0.6, Color.BLACK)
		cap.material_override = _track(metal)
		var collar := _cylinder(Vector3(s * post, 0, 0), 0.045, 0.02, Color(0.2, 0.2, 0.21))
		collar.material_override = _track(metal)
	# The winder: a small box with a handle on the right-hand post.
	var winder := _box(Vector3(post + 0.04, top - 0.1, 0), Vector3(0.05, 0.08, 0.06), Color.BLACK)
	winder.material_override = _track(metal)
	var handle := _box(Vector3(post + 0.075, top - 0.08, 0.035), Vector3(0.012, 0.012, 0.07), Color.BLACK)
	handle.material_override = _track(metal)
	# The mesh: two panels, post to centre, the top following the tape.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in [-1.0, 1.0]:
		var quad := [Vector3(s * post, NET_BOTTOM, 0), Vector3(0, NET_BOTTOM, 0),
			Vector3(0, mid - TAPE / 2, 0), Vector3(s * post, top - TAPE / 2, 0)]
		for k in [0, 1, 2, 0, 2, 3]:
			var v: Vector3 = quad[k]
			st.set_uv(Vector2(v.x / NET_CELL, -v.y / NET_CELL))
			st.add_vertex(v)
	var net := MeshInstance3D.new()
	net.mesh = st.commit()
	net.material_override = net_material()
	net.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(net)
	# The tape over the top, and a cord along the bottom.
	var white := material(Color(0.97, 0.97, 0.95))
	for s in [-1.0, 1.0]:
		_strip(Vector3(s * post, top - TAPE / 2, 0), Vector3(0, mid - TAPE / 2, 0), TAPE, 0.014, white)
		_strip(Vector3(s * post, NET_BOTTOM, 0), Vector3(0, NET_BOTTOM, 0), 0.008, 0.008, material(Color(0.08, 0.08, 0.09)))
		# The binding up each end, laced to the post.
		_strip(Vector3(s * (post - 0.02), NET_BOTTOM, 0), Vector3(s * (post - 0.02), top - TAPE, 0), 0.03, 0.012, white, true)
	# The centre strap, from the tape down to its anchor in the court.
	_strip(Vector3(0, mid, 0), Vector3(0, 0.0, 0), 0.05, 0.016, white, true)
	var anchor := _box(Vector3(0, 0.01, 0), Vector3(0.09, 0.02, 0.05), Color(0.25, 0.25, 0.26))
	anchor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A flat band from `a` to `b`, `w` wide (across, in the net's plane) and
## `t` thick. `upright`: the width runs along x (a vertical band).
func _strip(a: Vector3, b: Vector3, w: float, t: float, mat: Material, upright := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var d := b - a
	if upright:
		bm.size = Vector3(w, d.length(), t)
	else:
		bm.size = Vector3(d.length(), w, t)
		mi.rotation.z = atan2(d.y, d.x)
	mi.mesh = bm
	mi.material_override = mat
	mi.position = (a + b) / 2
	add_child(mi)
	return mi


static var _net_mat: StandardMaterial3D


## The net's cord: a square mesh painted into a small texture, mipmapped
## so it greys into a veil with distance.
static func net_material() -> StandardMaterial3D:
	if _net_mat:
		return _net_mat
	const N := 32
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.05, 0.05, 0.06, 0.06))
	var cord := Color(0.05, 0.05, 0.06, 1.0)
	for i in N:
		for w in 3:
			img.set_pixel(i, w, cord)
			img.set_pixel(w, i, cord)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_net_mat = m
	return m


func _fences(hx: float, hz: float, c: Color) -> void:
	if venue == Venues.SPACE:
		_glass_fences(hx, hz, c)
		return
	# A court's fence: galvanised chain link on posts and a top rail, a dark
	# windscreen over its lower part.
	var h := 3.0
	var wind_h := 1.8
	var metal := material(Color(0.55, 0.57, 0.6))
	metal.metallic = 0.7
	metal.roughness = 0.45
	var link := StandardMaterial3D.new()
	link.albedo_texture = link_texture()
	link.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	link.cull_mode = BaseMaterial3D.CULL_DISABLED
	link.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	link.uv1_triplanar = true
	link.uv1_world_triplanar = true
	link.uv1_scale = Vector3.ONE / 0.06          # 6 cm diamonds
	_track(link)
	# Windscreen fabric: the venue's fence tint, as a dark, woven green.
	var screen := _track(material(Color(c.r, c.g, c.b).lerp(Color(0.1, 0.26, 0.17), 0.7)))
	screen.albedo_texture = grain_texture()
	screen.uv1_triplanar = true
	screen.uv1_world_triplanar = true
	screen.uv1_scale = Vector3.ONE * 2.0
	screen.roughness = 1.0
	for s in [-1, 1]:
		for side in [true, false]:
			# Windscreens on the ends only: the stands along the sides stay
			# in view, and LAKESIDE's far end keeps its lake.
			var screened: bool = not side and not (venue == Venues.LAKESIDE and s < 0)
			var low := wind_h if screened else 0.0
			var size := Vector3(0.02, h - low, hz * 2) if side else Vector3(hx * 2, h - low, 0.02)
			var at := Vector3(s * hx, low + (h - low) / 2, 0) if side else Vector3(0, low + (h - low) / 2, s * hz)
			var mesh := _box(at, size, Color.WHITE)
			mesh.material_override = link
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if screened:
				var ws := _box(Vector3(0, wind_h / 2, s * hz), Vector3(hx * 2, wind_h, 0.03), Color.WHITE)
				ws.material_override = screen
			# The top rail.
			var rail := _box(Vector3(s * hx, h, 0) if side else Vector3(0, h, s * hz),
				Vector3(0.05, 0.05, hz * 2) if side else Vector3(hx * 2, 0.05, 0.05), Color.WHITE)
			rail.material_override = metal
			rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in range(-4, 5):
			for p in [Vector3(s * hx, 0, i * hz / 4.0), Vector3(i * hx / 4.0, 0, s * hz)]:
				var post := _cylinder(p, 0.035, h + 0.03, Color.WHITE)
				post.material_override = metal


## SPACE's fence: glowing glass panels, as before.
func _glass_fences(hx: float, hz: float, c: Color) -> void:
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


## Trees, or palms (SUNSET), in a ring around the court. A tree is a
## tapered trunk with a crown of several clumps, darker below; all the
## trunks are one draw, all the clumps another (MultiMesh), so a ring of
## them costs the Quest two draw calls.
func _trees(count: int, near: float, far: float, palms: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1994 + venue              # the same venue every time
	var trunks: Array[Transform3D] = []
	var trunk_c: Array[Color] = []
	var clumps: Array[Transform3D] = []
	var clump_c: Array[Color] = []
	for i in count:
		var a := TAU * i / count + rng.randf() * 0.15
		var r := rng.randf_range(near, far)
		var at := Vector3(cos(a) * r, 0, sin(a) * r * 1.2)
		if venue == Venues.LAKESIDE and at.z < -12.0:
			continue                     # the lake's there
		if palms:
			var h := rng.randf_range(4.0, 6.5)
			var lean := rng.randf_range(-0.12, 0.12)
			trunks.append(Transform3D(Basis(Vector3.FORWARD, lean).scaled(Vector3(0.75, h, 0.75)), at + Vector3(sin(-lean) * h / 2, h / 2, 0)))
			trunk_c.append(Color(0.48, 0.36, 0.22))
			var top := at + Vector3(sin(-lean) * h, h, 0)
			for k in 7:
				var yaw := TAU * k / 7.0 + rng.randf() * 0.3
				var frond := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, 0.45)
				clumps.append(Transform3D(frond.scaled(Vector3(0.35, 0.08, 1.6)), top + Vector3(cos(yaw), -0.25, sin(yaw)) * 0.9 * Vector3(1, 1, 1)))
				clump_c.append(Color(0.2, 0.42, 0.18).lightened(rng.randf() * 0.1))
			continue
		var h2 := rng.randf_range(2.2, 3.6)
		trunks.append(Transform3D(Basis().scaled(Vector3(1, h2, 1)), at + Vector3(0, h2 / 2, 0)))
		trunk_c.append(Color(0.36, 0.25, 0.15).darkened(rng.randf() * 0.15))
		var cr := rng.randf_range(1.4, 2.3)
		var green := Color(0.17, 0.4, 0.16).lightened(rng.randf() * 0.12)
		var crown := at + Vector3(0, h2 + cr * 0.7, 0)
		for k in 6:
			# Clumps round the crown, the lower ones darker (in their own shade).
			var off := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 0.7), rng.randf_range(-1, 1)) * cr * 0.55
			var size := cr * rng.randf_range(0.55, 0.8)
			clumps.append(Transform3D(Basis().scaled(Vector3(size, size * 0.85, size)), crown + off))
			clump_c.append(green.darkened(0.25 * clampf(0.5 - off.y / cr, 0.0, 1.0)))
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.1
	trunk_mesh.bottom_radius = 0.2
	trunk_mesh.height = 1.0
	trunk_mesh.radial_segments = 8
	trunk_mesh.rings = 1
	var clump_mesh := SphereMesh.new()
	clump_mesh.radius = 1.0
	clump_mesh.height = 2.0
	clump_mesh.radial_segments = 10
	clump_mesh.rings = 6
	_multi(trunk_mesh, trunks, trunk_c, 0.95)
	_multi(clump_mesh, clumps, clump_c, 0.9)


## One draw for many copies of `mesh`, each its own transform and colour.
func _multi(mesh: Mesh, at: Array[Transform3D], colors: Array[Color], rough: float) -> void:
	if at.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = at.size()
	for i in at.size():
		mm.set_instance_transform(i, at[i])
		mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var m := _track(material(Color.WHITE))
	m.vertex_color_use_as_albedo = true
	m.roughness = rough
	mmi.material_override = m
	add_child(mmi)


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
