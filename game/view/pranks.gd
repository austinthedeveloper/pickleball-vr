## Pranks (ADR-025, design/COACHING.md C-23): what a kid on the coach's
## phone can do to you. A soundboard, the announcer's calls, silly balls and
## paddles, weather, the partner's antics, their voice in your headset and
## their face on the partner. Display only: the ball and paddle you see
## change, the ones the sim plays with never do.
##
## Nothing here shakes, flips or darkens the world, moves you or throws a
## ball from behind: in a headset those make people lunge or feel sick.
class_name Pranks
extends Node3D

## The soundboard: id -> the button's text. "cheer" is the applause.
const SOUNDS := {"airhorn": "AIRHORN", "boo": "BOO", "cheer": "CHEER", "rimshot": "BA-DUM-TSS",
	"trombone": "SAD TROMBONE", "boing": "BOING", "whoopee": "WHOOPEE", "slide": "SLIDE WHISTLE"}
## The announcer's calls, wherever the ball really landed.
const CALLS := {"out": "OUT!", "net": "NET!", "kitchen": "KITCHEN!", "ace": "ACE!", "winner": "WINNER!"}
const BALLS := {"": "NORMAL", "duck": "RUBBER DUCK", "melon": "WATERMELON", "pea": "PEA", "beach": "BEACH BALL",
	"face": "THEIR FACE"}
const PADDLES := {"": "NORMAL", "pan": "FRYING PAN", "baguette": "BAGUETTE", "swatter": "FLY SWATTER",
	"hand": "FOAM HAND"}
const WEATHER := {"": "CLEAR", "snow": "SNOW", "bubbles": "BUBBLES"}
const ANTICS := {"dance": "DANCE", "flex": "FLEX", "wave": "WAVE", "jump": "JUMP FOR JOY"}
const ANTIC_SECONDS := {"dance": 5.0, "flex": 3.0, "wave": 3.0, "jump": 3.0}
## The court the weather falls over, metres.
const SKY := Vector3(5.0, 0.1, 9.0)

var view: MatchView
var ball := ""
var paddle := ""
var weather := ""
var face: ImageTexture               ## their photo, cut round (null: none)
var done: Array[String] = []         ## what's been played or done, "kind:id" (for tests)
var _board: AudioStreamPlayer
var _voice: AudioStreamPlayer3D
var _sky: CPUParticles3D
var _confetti: CPUParticles3D
var _streams := {}


func _ready() -> void:
	_board = AudioStreamPlayer.new()
	_board.volume_db = -3.0
	add_child(_board)
	_voice = AudioStreamPlayer3D.new()
	_voice.unit_size = 12.0
	_voice.volume_db = 4.0
	add_child(_voice)


# --- The soundboard -------------------------------------------------------------------

func sound(id: String) -> void:
	if not SOUNDS.has(id):
		return
	_board.stream = _stream(id)
	_board.play()
	done.append("sound:" + id)


func _stream(id: String) -> AudioStream:
	if not _streams.has(id):
		_streams[id] = load("res://assets/audio/4_applause.wav" if id == "cheer" else "res://assets/audio/prank/%s.wav" % id)
	return _streams[id]


## An announcer's call, as loud as a real one.
func call_out(id: String) -> void:
	if CALLS.has(id) and view.announcer:
		view.announcer.say([id], Announcer.TOP)
		done.append("call:" + id)


## A ball hit: the duck squeaks, the pan clangs (yours only).
func on_hit(at: Vector3, yours: bool) -> void:
	if ball == "duck":
		_play_at("squeak", at, 1.0 + randf() * 0.15)
	if paddle == "pan" and yours:
		_play_at("clang", at, 0.95 + randf() * 0.1)


## A bounce: the watermelon splats, the beach ball boings.
func on_bounce(at: Vector3) -> void:
	if ball == "melon":
		_play_at("splat", at, 1.0)
	elif ball == "beach":
		_play_at("boing", at, 1.4)


func _play_at(id: String, at: Vector3, pitch: float) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = _stream(id)
	p.pitch_scale = pitch
	p.unit_size = 6.0
	add_child(p)
	p.global_position = at
	p.finished.connect(p.queue_free)
	p.play()


# --- Their voice ----------------------------------------------------------------------

## A clip from the phone: 16-bit mono PCM at `rate`. It comes from the
## partner, who talks along, or from the middle of the net with no partner.
func voice(pcm: PackedByteArray, rate: int) -> float:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = pcm
	_voice.stream = w
	var talker := view.partner_avatar
	_voice.global_position = (talker.figure.at("Head") if talker and talker.figure else Vector3(0, 1.6, -0.5))
	_voice.play()
	var seconds := pcm.size() / 2.0 / rate
	done.append("voice")
	if talker:
		talker.antic("talk", seconds)
	return seconds


# --- Antics -----------------------------------------------------------------------------

## The partner (in a match, the other side) does a little something.
func antic(id: String) -> void:
	if not ANTICS.has(id):
		return
	for a in view.avatars:
		if a.slot >= 2:
			a.antic(id, ANTIC_SECONDS[id])
	done.append("antic:" + id)


# --- Balls -------------------------------------------------------------------------------

func set_ball(kind: String) -> void:
	ball = kind if BALLS.has(kind) and (kind != "face" or face != null) else ""
	_skin_ball(view.ball_mesh)
	if view.xr:
		_skin_ball(view.xr.held_ball)
	view._trail.visible = ball == ""         # the trail is the real ball's size


func _skin_ball(mi: MeshInstance3D) -> void:
	if not mi.has_meta("plain"):
		mi.set_meta("plain", [mi.mesh, mi.material_override])
	for c in mi.get_children():
		if c.has_meta("prank"):
			c.free()
	var plain: Array = mi.get_meta("plain")
	mi.mesh = plain[0]
	mi.material_override = plain[1]
	if ball == "":
		return
	var parts := ball_parts(ball, face)
	mi.mesh = parts[0][0]
	mi.material_override = parts[0][1]
	for i in range(1, parts.size()):
		var p := MeshInstance3D.new()
		p.mesh = parts[i][0]
		p.material_override = parts[i][1]
		p.position = parts[i][2]
		p.set_meta("prank", true)
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_child(p)


## A silly ball: [[mesh, material, position], ...], the first in the
## ball's own place.
static func ball_parts(kind: String, photo: Texture2D = null) -> Array:
	match kind:
		"duck":
			var yellow := _mat(Color(1.0, 0.85, 0.1), 0.5)
			var head := _sphere(0.032)
			var beak := _sphere(0.016)
			beak.height = 0.016
			var eye := _sphere(0.006)
			var eyes := _mat(Color(0.05, 0.05, 0.05), 0.3)
			return [[_sphere(0.05), yellow, Vector3.ZERO], [head, yellow, Vector3(0, 0.045, 0.028)],
				[beak, _mat(Color(1.0, 0.45, 0.05), 0.5), Vector3(0, 0.04, 0.064)],
				[eye, eyes, Vector3(0.016, 0.055, 0.052)], [eye, eyes, Vector3(-0.016, 0.055, 0.052)]]
		"melon":
			var m := _sphere(0.075)
			m.height = 0.12
			return [[m, _striped([Color(0.13, 0.4, 0.12), Color(0.35, 0.65, 0.25)], 12), Vector3.ZERO]]
		"pea":
			return [[_sphere(0.017), _mat(Color(0.45, 0.8, 0.2), 0.6), Vector3.ZERO]]
		"beach":
			return [[_sphere(0.14), _striped([Color(0.95, 0.15, 0.15), Color.WHITE, Color(0.15, 0.4, 0.95),
				Color.WHITE, Color(1.0, 0.85, 0.1), Color.WHITE], 6), Vector3.ZERO]]
		"face":
			# Always facing you: a flying face.
			var q := QuadMesh.new()
			q.size = Vector2(0.17, 0.17)
			var fm := StandardMaterial3D.new()
			fm.albedo_texture = photo
			fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			fm.cull_mode = BaseMaterial3D.CULL_DISABLED
			return [[q, fm, Vector3.ZERO]]
	return []


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2
	s.radial_segments = 16
	s.rings = 8
	return s


static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := World.material(c)
	m.roughness = rough
	return m


## Stripes from pole to pole (round the sphere's u), `n` of them.
static func _striped(colors: Array, n: int) -> StandardMaterial3D:
	var img := Image.create(n * 8, 8, false, Image.FORMAT_RGB8)
	for x in img.get_width():
		img.fill_rect(Rect2i(x, 0, 1, 8), colors[(x / 8) % colors.size()])
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.5
	return m


# --- Paddles -----------------------------------------------------------------------------

func set_paddle(kind: String) -> void:
	paddle = kind if PADDLES.has(kind) else ""
	var pm: PaddleMesh = view.xr.paddle if view.xr else (view.flat.paddle if view.flat else null)
	if pm:
		pm.set_skin(paddle)


## A silly paddle in the paddle's frame (PaddleMesh: handle along +z, the
## face up -z, its normal +x). The sim's paddle is where it always was.
static func paddle_skin(kind: String) -> Node3D:
	var n := Node3D.new()
	var fc := PaddleMesh.FACE_CENTER
	match kind:
		"pan":
			var metal := _mat(Color(0.13, 0.13, 0.14), 0.35)
			metal.metallic = 0.8
			var inside := _mat(Color(0.25, 0.25, 0.27), 0.6)
			_part(n, _cyl(0.145, 0.025), metal, fc + Vector3(0, 0, -0.04), Vector3(0, 0, PI / 2))
			_part(n, _cyl(0.128, 0.027), inside, fc + Vector3(0, 0, -0.04), Vector3(0, 0, PI / 2))
			_part(n, _cyl(0.016, 0.2), _mat(Color(0.08, 0.06, 0.05), 0.8), Vector3(0, 0, -0.01), Vector3(PI / 2, 0, 0))
		"baguette":
			var bread := _mat(Color(0.84, 0.58, 0.27), 0.85)
			var cap := CapsuleMesh.new()
			cap.radius = 0.036
			cap.height = 0.56
			_part(n, cap, bread, Vector3(0, 0, -0.2), Vector3(PI / 2, 0, 0))
			for k in 5:                  # the slashes, on both faces
				for s in [-1, 1]:
					var slash := BoxMesh.new()
					slash.size = Vector3(0.004, 0.012, 0.06)
					_part(n, slash, _mat(Color(0.96, 0.85, 0.62), 0.9), Vector3(s * 0.035, 0, -0.38 + k * 0.08), Vector3(0, 0, 0.5))
		"swatter":
			var green := _mat(Color(0.2, 0.85, 0.3), 0.6)
			_part(n, _cyl(0.006, 0.36), green, Vector3(0, 0, -0.12), Vector3(PI / 2, 0, 0))
			var face := BoxMesh.new()
			face.size = Vector3(0.004, 0.15, 0.15)
			var grid := StandardMaterial3D.new()
			grid.albedo_texture = _grid_texture()
			grid.albedo_color = Color(0.2, 0.85, 0.3)
			grid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			grid.cull_mode = BaseMaterial3D.CULL_DISABLED
			grid.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			_part(n, face, grid, Vector3(0, 0, -0.37), Vector3.ZERO)
		"hand":
			var foam := _mat(Color(0.55, 0.2, 0.85), 0.95)
			var palm := BoxMesh.new()
			palm.size = Vector3(0.07, 0.2, 0.2)
			_part(n, palm, foam, fc + Vector3(0, 0, 0.02), Vector3.ZERO)
			var finger := BoxMesh.new()
			finger.size = Vector3(0.06, 0.06, 0.2)
			_part(n, finger, foam, fc + Vector3(0, 0.05, -0.18), Vector3.ZERO)
			var thumb := BoxMesh.new()
			thumb.size = Vector3(0.06, 0.1, 0.05)
			_part(n, thumb, foam, fc + Vector3(0, -0.13, -0.02), Vector3(0.5, 0, 0))
			_part(n, _cyl(0.03, 0.12), foam, Vector3(0, 0, 0.0), Vector3(PI / 2, 0, 0))
			for s in [-1, 1]:            # "#1" on both sides
				var l := Label3D.new()
				l.text = "#1"
				l.font_size = 64
				l.pixel_size = 0.0012
				l.outline_size = 8
				l.modulate = Color(1, 0.9, 0.2)
				l.position = fc + Vector3(s * 0.037, 0, 0.03)
				l.rotation = Vector3(0, s * PI / 2, PI / 2 * -s)
				n.add_child(l)
	return n


static func _part(n: Node3D, mesh: Mesh, mat: Material, at: Vector3, rot: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.rotation = rot
	n.add_child(mi)


static func _cyl(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 20
	return c


static func _grid_texture() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	for y in 32:
		for x in 32:
			if x % 4 != 0 and y % 4 != 0 and x > 1 and y > 1 and x < 30 and y < 30:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


# --- Weather ------------------------------------------------------------------------------

func set_weather(kind: String) -> void:
	weather = kind if WEATHER.has(kind) else ""
	if _sky:
		_sky.free()
		_sky = null
	if weather == "":
		return
	_sky = CPUParticles3D.new()
	_sky.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_sky.direction = Vector3.UP
	if weather == "snow":
		_sky.amount = 500
		_sky.lifetime = 9.0
		_sky.preprocess = 9.0
		_sky.position = Vector3(0, 6.0, 0)
		_sky.emission_box_extents = SKY
		_sky.gravity = Vector3(0, -0.65, 0)
		_sky.initial_velocity_min = 0.0
		_sky.initial_velocity_max = 0.15
		_sky.spread = 180.0
		_sky.mesh = _flake(0.04, Color(1, 1, 1, 0.9))
	else:
		_sky.amount = 70
		_sky.lifetime = 9.0
		_sky.preprocess = 9.0
		_sky.position = Vector3(0, 0.3, 0)
		_sky.emission_box_extents = Vector3(SKY.x, 0.2, SKY.z)
		_sky.gravity = Vector3(0, 0.18, 0)
		_sky.initial_velocity_min = 0.05
		_sky.initial_velocity_max = 0.3
		_sky.spread = 60.0
		_sky.scale_amount_min = 0.6
		_sky.scale_amount_max = 1.4
		_sky.mesh = _bubble()
	add_child(_sky)


static func _flake(size: float, c: Color) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	q.material = m
	return q


static func _bubble() -> SphereMesh:
	var s := _sphere(0.06)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.75, 0.9, 1.0, 0.22)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	m.metallic_specular = 1.0
	m.rim_enabled = true
	m.rim = 1.0
	m.emission_enabled = true
	m.emission = Color(0.25, 0.3, 0.45)
	s.material = m
	return s


## A burst of confetti over the net.
func confetti() -> void:
	if _confetti == null:
		_confetti = CPUParticles3D.new()
		_confetti.one_shot = true
		_confetti.emitting = false
		_confetti.amount = 260
		_confetti.lifetime = 4.5
		_confetti.explosiveness = 0.92
		_confetti.position = Vector3(0, 3.2, -0.5)
		_confetti.direction = Vector3.UP
		_confetti.spread = 75.0
		_confetti.initial_velocity_min = 2.5
		_confetti.initial_velocity_max = 5.5
		_confetti.gravity = Vector3(0, -2.2, 0)
		_confetti.damping_min = 1.2
		_confetti.damping_max = 2.2
		_confetti.angle_min = 0.0
		_confetti.angle_max = 360.0
		_confetti.angular_velocity_min = -400.0
		_confetti.angular_velocity_max = 400.0
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
		g.colors = PackedColorArray([Color(1, 0.2, 0.3), Color(1, 0.8, 0.1), Color(0.2, 0.8, 0.3), Color(0.2, 0.6, 1),
			Color(0.8, 0.3, 1), Color(1, 0.5, 0.1)])
		_confetti.color_initial_ramp = g
		var q := _flake(0.05, Color.WHITE)
		q.size = Vector2(0.05, 0.03)
		_confetti.mesh = q
		add_child(_confetti)
	_confetti.restart()
	done.append("confetti")


# --- Their face --------------------------------------------------------------------------

## A photo from the phone (JPEG bytes): cut round, on the partner's face and
## the bullseye. False if it isn't a picture.
func set_face(jpg: PackedByteArray) -> bool:
	var img := Image.new()
	if jpg.size() < 4 or jpg[0] != 0xFF or jpg[1] != 0xD8 or img.load_jpg_from_buffer(jpg) != OK:
		return false
	face = ImageTexture.create_from_image(round_cut(img))
	show_face()
	return true


## The photo, square, with everything outside the circle clear.
static func round_cut(img: Image) -> Image:
	var side := mini(img.get_width(), img.get_height())
	var sq := img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))
	sq.resize(128, 128)
	sq.convert(Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var d := Vector2(x - 63.5, y - 63.5).length()
			if d > 64.0:
				sq.set_pixel(x, y, Color(0, 0, 0, 0))
			elif d > 60.0:
				sq.set_pixel(x, y, Color(1, 1, 1))   # a white rim, like a cut-out
	return sq


func show_face() -> void:
	for a in view.avatars:
		if a.slot >= 2:
			a.set_mask(face)
	if view.floor_target:
		view.floor_target.set_face(face)
	if ball == "face":
		set_ball("face")


func clear_face() -> void:
	face = null
	show_face()
	if ball == "face":
		set_ball("")


## Everything back as it was (mercy, or COACH MODE off).
func clear() -> void:
	set_ball("")
	set_paddle("")
	set_weather("")
	clear_face()
	_board.stop()
	_voice.stop()
	for a in view.avatars:
		a.antic("", 0.0)
