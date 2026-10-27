## A match on screen: the sim stepped at 120 Hz from the rig's input (the
## headset's, or flat mode's with the bot swinging), and everything drawn
## from it. Presentation never writes to the sim: it calls step() with
## inputs and commands (port ADR-102) and reads the rest.
class_name MatchView
extends Node3D

const DT := 1.0 / K.TICK_HZ
const MAX_TICKS_PER_FRAME := 8

var sim: Sim
var bot: Bot
var xr: XrRig
var flat: FlatRig
var demo := false
var board: Scoreboard
var avatars: Array[Avatar] = []
var ball_mesh: MeshInstance3D
var shadow: MeshInstance3D
var sound := {}
var input_log: Array = []            ## every tick's human input, as arrays
var _acc := 0.0
var _commands: Array = []
var _last_phase := -1
var _menu_was := false


func setup(cfg: SimTypes.MatchConfig, use_xr: bool, demo_mode := false) -> void:
	sim = Sim.new(cfg)
	demo = demo_mode
	bot = Bot.new(sim, 0)
	add_child(World.new())
	if use_xr:
		xr = XrRig.new()
		add_child(xr)
	else:
		flat = FlatRig.new()
		flat.demo = demo
		add_child(flat)
		bot.auto_move = demo
		bot.auto_serve = demo
		bot.rest_side = 300000
		bot.rest_y = 1250000
		bot.rest_forward = 600000
	const SHIRTS := [Color(0.85, 0.15, 0.2), Color(0.95, 0.85, 0.2), Color(0.95, 0.55, 0.12), Color(0.55, 0.25, 0.75)]
	for s in sim.active_slots():
		if sim.players[s].cpu:
			var a := Avatar.new()
			a.slot = s
			a.shirt = SHIRTS[s]
			add_child(a)
			avatars.append(a)
	board = Scoreboard.new()
	add_child(board)
	ball_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = K.BALL_RADIUS / float(K.M)
	sm.height = sm.radius * 2
	sm.radial_segments = 16
	sm.rings = 8
	ball_mesh.mesh = sm
	var bmat := World.material(Color(0.88, 1.0, 0.12))
	bmat.emission_enabled = true
	bmat.emission = Color(0.3, 0.35, 0.0)
	ball_mesh.material_override = bmat
	add_child(ball_mesh)
	shadow = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = sm.radius
	cm.bottom_radius = sm.radius
	cm.height = 0.002
	shadow.mesh = cm
	var smat := World.material(Color(0, 0, 0, 0.45))
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = smat
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	_sounds()
	if flat:
		flat.recenter(_spot(0))


func _sounds() -> void:
	for n in ["0_hit", "0_hit_drive", "1_bounce", "2_net", "3_whistle", "4_applause"]:
		var p := AudioStreamPlayer3D.new()
		p.stream = load("res://assets/audio/%s.wav" % n)
		p.unit_size = 6.0
		add_child(p)
		sound[n] = p
	var amb := AudioStreamPlayer.new()
	var stream: AudioStreamOggVorbis = load("res://assets/audio/ambience_park.ogg")
	stream.loop = true
	amb.stream = stream
	amb.volume_db = -10.0
	add_child(amb)
	if not DisplayServer.get_name() == "headless":
		amb.play.call_deferred()


func _play(n: String, at: Vector3, pitch := 1.0) -> void:
	var p: AudioStreamPlayer3D = sound[n]
	p.global_position = at
	p.pitch_scale = pitch
	p.play()


## A change to the running match goes in on the next tick (port ADR-102).
func command(c: Array) -> void:
	_commands.append(c)


func _exit_tree() -> void:
	sim = null
	bot = null


func _spot(slot: int) -> Vector3:
	var s := sim.serve_spot(slot)
	return World.m(s[0], 0, s[1])


func _process(delta: float) -> void:
	if sim == null:
		return
	var rig_menu := false
	if xr:
		xr.begin_frame(delta)
		rig_menu = xr.menu_pressed
	else:
		flat.begin_frame(delta)
		rig_menu = flat.menu_pressed and not _menu_was
		_menu_was = flat.menu_pressed
		if flat.serve_pressed:
			bot.serve_now = true
	if rig_menu and sim.phase == K.PHASE_MATCH_RESULT:
		command([K.CMD_NEW_MATCH])
	_acc = minf(_acc + delta, DT * MAX_TICKS_PER_FRAME)
	var n := int(_acc / DT)
	_acc -= n * DT
	for j in n:
		_tick(float(j + 1) / n, j == 0)
	_draw(delta)


func _tick(alpha: float, first: bool) -> void:
	var h: SimTypes.HumanInput
	if xr:
		h = xr.sample(alpha, first)
	else:
		if not demo:
			var head := World.um(flat.head)
			bot.head_x = head[0]
			bot.head_z = head[2]
			bot.has_aim = true
			var aim := World.um(flat.aim)
			bot.aim_x = aim[0]
			bot.aim_z = aim[2]
			bot.pace = 40000 if flat.soft else 105000
		h = bot.input()
		flat.show_paddle(h)
	input_log.append(h.to_array())
	sim.step([h], _commands)
	_commands = []
	if sim.phase != _last_phase:
		_on_phase(sim.phase)
		_last_phase = sim.phase
	for e in sim.drain_events():
		_on_event(e)


func _on_phase(p: int) -> void:
	if p == K.PHASE_SERVE_SETUP:
		if xr:
			if sim.tick <= 1:
				xr.face_court()
			xr.recenter(_spot(0))
		elif not demo:
			flat.recenter(_spot(0))


func _on_event(e: Array) -> void:
	var at := World.m(sim.ball.x, sim.ball.y, sim.ball.z)
	match int(e[0]):
		K.EVENT_HIT:
			var hard: bool = e[2] > 110000
			_play("0_hit_drive" if hard else "0_hit", at, 0.95 + 0.1 * (e[2] % 3))
			if xr and e[1] == 0:
				xr.pulse(0.4 + e[2] / 250000.0)
		K.EVENT_BOUNCE:
			_play("1_bounce", World.m(e[1], 0, e[2]))
		K.EVENT_NET:
			_play("2_net", World.m(e[1], e[2], 0))
		K.EVENT_FAULT:
			board.announce(K.fault_text(e[1]), Color(1, 0.4, 0.3))
		K.EVENT_POINT:
			_play("3_whistle", Vector3(0, 2, 0))
			if sim.last_fault == K.FAULT_NONE or sim.last_fault == K.FAULT_SECOND_BOUNCE:
				board.announce("POINT YOU" if e[1] == 0 else "POINT CPU",
					Color(0.5, 1, 0.5) if e[1] == 0 else Color(1, 0.8, 0.3))
		K.EVENT_MATCH:
			_play("4_applause", Vector3(0, 2, 0))
			board.announce("YOU WIN!" if e[1] == 0 else "CPU WINS", Color(1, 0.9, 0.2), 4.0)


func _draw(delta: float) -> void:
	var b := World.m(sim.ball.x, sim.ball.y, sim.ball.z)
	var held_by_you := not sim.players[0].cpu and sim.server_slot == 0 \
		and (sim.phase == K.PHASE_SERVE or sim.phase == K.PHASE_SERVE_SETUP)
	if xr:
		xr.show_held_ball(held_by_you)
		ball_mesh.visible = not held_by_you
	ball_mesh.global_position = b
	shadow.global_position = Vector3(b.x, 0.02, b.z)
	var s := clampf(1.0 - b.y / 4.0, 0.35, 1.0)
	shadow.scale = Vector3(s * 1.4, 1, s * 1.4)
	for a in avatars:
		a.show_from(sim, delta)
	board.show_from(sim, delta)
	if flat and demo:
		flat.head = World.m(bot.head_x, 0, bot.head_z) + Vector3(0, FlatRig.EYE, 0)
