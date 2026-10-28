## A match on screen: the sim stepped at 120 Hz from the rig's input (the
## headset's, or flat mode's with the bot swinging), and everything drawn
## from it. Presentation never writes to the sim: it calls step() with
## inputs and commands (port ADR-102) and reads the rest.
class_name MatchView
extends Node3D

const DT := 1.0 / K.TICK_HZ
const MAX_TICKS_PER_FRAME := 8
## The lobby's spectator spot: behind the near baseline, outside the fence.
const SPECTATE := Vector3(-3.0, 0, 9.4)

signal match_over(winner: int)
signal drill_done
signal pause_requested

var sim: Sim
var bot: Bot
var xr: XrRig
var flat: FlatRig
var demo := false
var spectate := false
var left_handed := false
var menu: Menu3D
var them := "CPU"
var crowd: Crowd
var world: World
var announcer: Announcer
var paddle_tilt := 0.0               ## degrees: the paddle's angle in the hand (XR)
var paddle_twist := 0.0              ## degrees, about the handle (paddle profiles, ADR-015)
var paddle_reach := 0.0              ## metres along the handle
var board: Scoreboard
var avatars: Array[Avatar] = []
var ball_mesh: MeshInstance3D
## The ball's trail (ADR-012): fading copies at its last few spots, shown
## when it's moving fast enough to lose.
const TRAIL := 7
const TRAIL_SPEED := 7.0             ## m/s
var _trail: MultiMeshInstance3D
var _trail_at: Array[Vector3] = []
var shadow: MeshInstance3D
var sound := {}
var input_log: Array = []            ## every tick's human input, as arrays
var _acc := 0.0
var _commands: Array = []
var _last_phase := -1
var _quip := RandomNumberGenerator.new()     # display only: which quip
var machine: Machine
var floor_target: FloorTarget
var partner_avatar: Avatar
var lesson_label: Label3D
var zone_mesh: MeshInstance3D
var paused := false                  ## the sim isn't stepped while a pause menu is up
var focus := 0.0                     ## FOCUS (ADR-013): how dim the world is now
var _placed := false                 ## XR: turned to the court and moved to the start, once tracked
var _inherited := false              ## XR: the play space came over from the last view
var _stay := false                   ## ...and you're on the same spot (the lobby, rebuilt)


func setup(cfg: SimTypes.MatchConfig, use_xr: bool, demo_mode := false, spectating := false) -> void:
	sim = Sim.new(cfg)
	spectate = spectating
	demo = demo_mode or spectating
	bot = Bot.new(sim, 0)
	if cfg.opponent >= 0:
		them = String(Opponents.team(cfg.opponent)["team"])
	world = World.new()
	world.venue = cfg.venue
	add_child(world)
	if use_xr:
		xr = XrRig.new()
		xr.left_handed = left_handed
		xr.paddle_tilt = paddle_tilt
		xr.paddle_twist = paddle_twist
		xr.paddle_reach = paddle_reach
		add_child(xr)
		var openxr := XRServer.find_interface("OpenXR")
		if openxr and openxr.has_signal("pose_recentered"):
			openxr.pose_recentered.connect(_on_recentered)
	else:
		flat = FlatRig.new()
		flat.demo = demo
		flat.spectate = spectate
		add_child(flat)
		bot.auto_move = demo
		bot.auto_serve = demo
		bot.rest_side = 300000
		bot.rest_y = 1250000
		bot.rest_forward = 600000
	const SHIRTS := [Color(0.85, 0.15, 0.2), Color(0.95, 0.85, 0.2), Color(0.95, 0.55, 0.12), Color(0.55, 0.25, 0.75)]
	for s in sim.active_slots():
		if (sim.players[s].cpu or spectate) and not sim.drill:
			var a := Avatar.new()
			a.slot = s
			a.shirt = SHIRTS[s]
			a.skin = Avatar.SKINS[(s * 7 + maxi(cfg.opponent, 0)) % Avatar.SKINS.size()]
			a.hair = Avatar.HAIRS[(s * 5 + maxi(cfg.opponent, 0) * 3) % Avatar.HAIRS.size()]
			a.cap = s % 2 == 0
			if cfg.opponent >= 0 and s >= 2:
				a.shirt = Opponents.shirt(cfg.opponent, s)
			add_child(a)
			avatars.append(a)
	board = Scoreboard.new()
	board.them = them
	add_child(board)
	ball_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = K.BALL_RADIUS / float(K.M)
	sm.height = sm.radius * 2
	sm.radial_segments = 16
	sm.rings = 8
	ball_mesh.mesh = sm
	ball_mesh.material_override = Look.ball_material()
	add_child(ball_mesh)
	_trail_init(sm.radius)
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
	crowd = Crowd.new()
	add_child(crowd)
	announcer = Announcer.new()
	add_child(announcer)
	if sim.drill:
		_practice_court()
	if spectate:
		if flat:
			flat.recenter(SPECTATE)
	elif flat:
		flat.recenter(_start_spot())
	if cfg.opponent >= 0 and not spectate:
		board.announce(String(Opponents.team(cfg.opponent)["intro"]), Color(1, 0.9, 0.5), 3.5)


## Practice: the machine, the return zone, no crowd.
func _practice_court() -> void:
	if sim.drill.partner:
		partner_avatar = Avatar.new()
		partner_avatar.slot = 2
		partner_avatar.shirt = Color(0.2, 0.62, 0.55)
		add_child(partner_avatar)
		avatars.append(partner_avatar)
	else:
		machine = Machine.new()
		add_child(machine)
	if sim.drill.targets:
		floor_target = FloorTarget.new()
		add_child(floor_target)
	crowd.visible = false
	crowd.process_mode = Node.PROCESS_MODE_DISABLED
	board.drill = true
	var d := sim.drill
	if d.zone != Drill.ZONE_ANY:
		var hw := K.COURT_HALF_WIDTH / float(K.M)
		var hl := K.COURT_HALF_LENGTH / float(K.M)
		var kd := K.KITCHEN_DEPTH / float(K.M)
		var r := Rect2(-hw, -hl, hw * 2, hl - kd)
		match d.zone:
			Drill.ZONE_KITCHEN:
				var dz := Drill.DINK_ZONE / float(K.M)
				r = Rect2(-hw, -dz, hw * 2, dz)
			Drill.ZONE_DEEP: r = Rect2(-hw, -hl, hw * 2, hl / 3)
			Drill.ZONE_LEFT: r = Rect2(-hw, -hl, hw, hl)
			Drill.ZONE_RIGHT: r = Rect2(0, -hl, hw, hl)
		zone_mesh = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(r.size.x, 0.004, r.size.y)
		zone_mesh.mesh = bm
		var mat := World.material(Color(1.0, 0.85, 0.2, 0.35))
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		zone_mesh.material_override = mat
		zone_mesh.position = Vector3(r.get_center().x, 0.022, r.get_center().y)
		add_child(zone_mesh)


## A lesson's title and instructions, standing over the far court.
func show_lesson(title: String, lines: Array) -> void:
	if lesson_label == null:
		lesson_label = Label3D.new()
		lesson_label.font_size = 64
		lesson_label.pixel_size = 0.0035
		lesson_label.outline_size = 14
		lesson_label.modulate = Color(1, 0.95, 0.8)
		lesson_label.position = Vector3(0, 3.0, -4.0)
		lesson_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(lesson_label)
	lesson_label.text = title + "\n\n" + "\n".join(lines)


func _start_spot() -> Vector3:
	if sim.drill:
		return World.m(sim.drill.spot_x, 0, sim.drill.spot_z)
	return _spot(0)


## The headset's first tracked frame: face down the court and stand on the
## start (the spectator spot, the drill's spot, or your serve spot). Before
## tracking starts the head reads as the origin, so this waits for it.
func _place_xr() -> void:
	if _placed or not xr.tracking():
		return
	_placed = true
	if _inherited:
		# Facing the court already: only move if this view stands you
		# somewhere new (into a match, back to the lobby), never when the
		# lobby rebuilds for a changed option.
		if not _stay:
			xr.recenter(SPECTATE if spectate else _start_spot())
		return
	xr.face_court()
	xr.recenter(SPECTATE if spectate else _start_spot())


## The play space as the last view left it (main passes it on), so a new
## view doesn't turn or move you. `stay`: and keep you where you are.
func inherit_rig(t: Transform3D, stay: bool) -> void:
	if xr == null:
		return
	xr.global_transform = t
	_inherited = true
	_stay = stay


## The headset's own recenter (hold the Meta button): the runtime moved
## your play space, so face the court again and stand where you were.
func _on_recentered() -> void:
	if xr == null:
		return
	xr.face_court()
	if spectate:
		xr.recenter(SPECTATE)
	else:
		xr.recenter(World.m(sim.players[0].x, 0, sim.players[0].z))


## Show a menu panel in front of you, pointed at with the laser or mouse.
func show_menu(m: Menu3D) -> void:
	if menu and menu != m:
		menu.queue_free()
	menu = m
	if m.get_parent() == null:
		add_child(m)
	var head := xr.head_position() if xr else flat.head_position()
	var fwd := xr.forward() if xr else flat.forward()
	if spectate:
		# The lobby's panel stands at a fixed spot beside the spectator
		# spot (the headset may not be tracking yet when it's built).
		head = SPECTATE + Vector3(0, FlatRig.EYE, 0)
		fwd = Vector3.FORWARD
	var right := fwd.cross(Vector3.UP)
	var at := head + fwd * 1.7 + right * (0.6 if spectate else 0.0)
	at.y = head.y - 0.1
	m.global_position = at
	m.look_at(at + (at - head) * Vector3(1, 0, 1), Vector3.UP)
	m.visible = true


func hide_menu() -> void:
	if menu:
		menu.visible = false


## Each sound family is its variants (0_hit, 0_hit_2 ..), one 3D player
## each, a variant picked per play (display only: the view's own roll).
const FAMILIES := {"0_hit": 4, "0_hit_drive": 4, "0_hit_soft": 4, "0_hit_slice": 3,
	"0_hit_smash": 2, "1_bounce": 3, "2_net": 1, "3_whistle": 1, "4_applause": 1}


func _sounds() -> void:
	for n in FAMILIES:
		var p := AudioStreamPlayer3D.new()
		var variants: Array[AudioStream] = []
		for v in int(FAMILIES[n]):
			variants.append(load("res://assets/audio/%s%s.wav" % [n, "" if v == 0 else "_%d" % (v + 1)]))
		p.stream = variants[0]
		p.set_meta("variants", variants)
		p.unit_size = 6.0
		p.max_polyphony = 2
		add_child(p)
		sound[n] = p
	var amb := AudioStreamPlayer.new()
	var stream: AudioStreamOggVorbis = load(World.ambience(world.venue))
	stream.loop = true
	amb.stream = stream
	amb.volume_db = -10.0
	add_child(amb)
	if not DisplayServer.get_name() == "headless":
		amb.play.call_deferred()


func _play(n: String, at: Vector3, pitch := 1.0, db := 0.0) -> void:
	var p: AudioStreamPlayer3D = sound[n]
	var variants: Array = p.get_meta("variants")
	p.stream = variants[_quip.randi() % variants.size()]
	p.global_position = at
	p.pitch_scale = pitch
	p.volume_db = db
	p.play()


## The hit's sound from the shot it made: a smash, a slice (backspin), a
## soft touch, a drive, or the plain pop.
func _hit_sound(speed: int) -> String:
	var b := sim.ball
	if b.vy < -40000 and speed > 110000 and b.y > 1400000:
		return "0_hit_smash"
	var top := Aim.topspin(b.vx, b.vz, 1)
	var along := top[0] * b.wx + top[2] * b.wz
	if along < -200000 and speed > 45000:
		return "0_hit_slice"
	if speed < 55000:
		return "0_hit_soft"
	if speed > 115000:
		return "0_hit_drive"
	return "0_hit"


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
	var t0 := Time.get_ticks_usec()
	if xr:
		xr.begin_frame(delta)
		_place_xr()
	else:
		flat.begin_frame(delta)
		if flat.serve_pressed and not (menu and menu.visible):
			bot.serve_now = true
	var pause := xr.pause_pressed if xr else flat.pause_pressed
	if pause and not spectate and not paused:
		pause_requested.emit()
	_drive_menu()
	if paused:
		_draw(0.0)
		return
	var t1 := Time.get_ticks_usec()
	Perf.add("input", t1 - t0)
	_acc = minf(_acc + delta, DT * MAX_TICKS_PER_FRAME)
	var n := int(_acc / DT)
	_acc -= n * DT
	for j in n:
		_tick(float(j + 1) / n, j == 0)
	var t2 := Time.get_ticks_usec()
	_draw(delta)
	var t3 := Time.get_ticks_usec()
	Perf.add("draw", t3 - t2)
	Perf.frame(t3 - t0 + crowd.last_usec, n, delta)


func _drive_menu() -> void:
	var on := menu != null and menu.visible
	if xr:
		xr.show_laser(on)
	if not on:
		return
	if menu.locked():
		return
	var ray: Array[Vector3] = xr.pointer() if xr else flat.pointer()
	var click := xr.click if xr else flat.click
	var nav := xr.nav if xr else flat.nav
	if nav.y != 0:
		menu.move(nav.y)
	if nav.x != 0:
		menu.change(nav.x)
	menu.point(ray[0], ray[1], click)


func _tick(alpha: float, first: bool) -> void:
	var h: SimTypes.HumanInput
	if xr and not demo:
		h = xr.sample(alpha, first)
	else:
		# The bot plays: flat mode's swing, DEMO, and the lobby's demo (in
		# the headset too: there you watch, your controllers only point).
		if flat and not demo:
			var head := World.um(flat.head)
			bot.head_x = head[0]
			bot.head_z = head[2]
			bot.has_aim = true
			var aim := World.um(flat.aim)
			bot.aim_x = aim[0]
			bot.aim_z = aim[2]
			bot.pace = 40000 if flat.soft else 105000
		var tb := Time.get_ticks_usec()
		h = bot.input()
		Perf.add("bot", Time.get_ticks_usec() - tb)
		if flat:
			flat.show_paddle(h)
	input_log.append(h.to_array())
	var ts := Time.get_ticks_usec()
	sim.step([h], _commands)
	Perf.add("sim", Time.get_ticks_usec() - ts)
	_commands = []
	if sim.phase != _last_phase:
		_on_phase(sim.phase)
		_last_phase = sim.phase
	for e in sim.drain_events():
		_on_event(e)


func _on_phase(p: int) -> void:
	if p == K.PHASE_SERVE and not spectate and not sim.drill:
		if sim.score[0] + sim.score[1] == 0 and announcer.said.is_empty():
			announcer.say(["match_begin", "match_doubles" if sim.config.doubles else "match_singles"], Announcer.TOP)
		else:
			var srv := sim.serving_team
			announcer.say(Announcer.score_line(sim.score[srv], sim.score[1 - srv]), Announcer.MID, true)
			for t in [srv, 1 - srv]:
				if sim.score_wins(sim.score[t] + 1, sim.score[1 - t]):
					announcer.say(["match_point"], Announcer.HIGH, true)
					break
	if p == K.PHASE_SERVE_SETUP:
		if xr:
			if _placed and not spectate:
				xr.recenter(_spot(0))      # to your serve or return spot (the lobby stays put)
		elif not demo:
			flat.recenter(_spot(0))


func _on_event(e: Array) -> void:
	var at := World.m(sim.ball.x, sim.ball.y, sim.ball.z)
	match int(e[0]):
		K.EVENT_FEED:
			machine.kick()
			_play("0_hit_soft", machine.global_position + Vector3(0, 0.9, 0), 0.8, -3.0)
		K.EVENT_TARGET:
			if floor_target:
				floor_target.flare()
			board.announce("TARGET!", Color(1, 0.85, 0.2), 1.0)
			_play("4_applause", World.m(e[1], 0, e[2]), 1.3, -10.0)
		K.EVENT_DRILL:
			var r: int = e[1]
			var rallying := sim.drill.partner and r == Drill.RESULT_GOOD
			if rallying:
				# The clips that say the number, so the call matches the board.
				const COUNT_CALLS := {10: "rally_10_1", 15: "rally_15_1", 20: "rally_20_1",
					25: "rally_25", 30: "rally_30_1"}
				var n: int = e[2]                # the streak
				if COUNT_CALLS.has(n):
					announcer.say([COUNT_CALLS[n]], Announcer.HIGH)
			else:
				board.announce(Drill.RESULT_TEXT[r], Color(0.5, 1, 0.5) if r == Drill.RESULT_GOOD else Color(1, 0.5, 0.35), 1.2)
			const CALLS := {Drill.RESULT_OUT: "out", Drill.RESULT_NET: "net", Drill.RESULT_KITCHEN: "kitchen",
				Drill.RESULT_VOLLEY: "early_volley"}
			if CALLS.has(r):
				announcer.say([CALLS[r]], Announcer.MID)
			if e[3] == 1:
				_play("4_applause", Vector3(0, 2, 0))
				announcer.say(["winner"], Announcer.TOP)
				board.announce("LESSON COMPLETE!", Color(1, 0.9, 0.2), 4.0)
				drill_done.emit()
			elif r == Drill.RESULT_GOOD and e[2] in [10, 20, 30]:
				announcer.say(["rally_%d_1" % e[2]], Announcer.HIGH)
		K.EVENT_HIT:
			var speed: int = e[2]
			if e[1] == 0 and Perf.on and not demo:     # your swings, not the lobby's bot
				_log_swing()
			_play(_hit_sound(speed), at, 0.96 + 0.08 * _quip.randf())
			if xr and e[1] == 0:
				# Crisp from the sweet spot, a duller, longer buzz off the rim.
				var off := clampf(sim.last_offset / float(K.PADDLE_FACE_RADIUS), 0.0, 1.0)
				xr.pulse((0.35 + speed / 250000.0) * (1.0 - 0.4 * off), 0.04 + 0.06 * off)
		K.EVENT_BOUNCE:
			_play("1_bounce", World.m(e[1], 0, e[2]), 1.0, -4.0)
		K.EVENT_NET:
			_play("2_net", World.m(e[1], e[2], 0))
		K.EVENT_FAULT:
			board.announce(K.fault_text(e[1]), Color(1, 0.4, 0.3))
			const CALLS := {K.FAULT_OUT: "out", K.FAULT_NET: "net", K.FAULT_KITCHEN: "kitchen",
				K.FAULT_EARLY_VOLLEY: "early_volley", K.FAULT_WRONG_BOX: "wrong_box"}
			if not spectate and CALLS.has(int(e[1])):
				announcer.say([CALLS[int(e[1])]], Announcer.MID)
		K.EVENT_POINT:
			_play("3_whistle", Vector3(0, 2, 0), 1.0, -6.0)
			var good := sim.last_fault == K.FAULT_SECOND_BOUNCE
			crowd.react(sim.shots / 14.0 + (0.35 if good else 0.0))
			if sim.shots >= 8 or good:
				_play("4_applause", Vector3(-7, 1, 0), 1.0, linear_to_db(clampf(sim.shots / 16.0 + 0.3, 0.3, 1.0)))
			if not spectate:
				if good and sim.shots == 1:
					announcer.say(["ace"], Announcer.HIGH)
				elif good:
					announcer.say(["winner"], Announcer.MID)
				for r in [30, 20, 15, 10]:
					if sim.shots >= r:
						announcer.say(["rally_%d" % r], Announcer.HIGH, true)
						break
			if sim.last_fault == K.FAULT_NONE or sim.last_fault == K.FAULT_SECOND_BOUNCE:
				board.announce("POINT YOU" if e[1] == 0 else "POINT CPU",
					Color(0.5, 1, 0.5) if e[1] == 0 else Color(1, 0.8, 0.3))
			elif e[1] == 0 and sim.config.opponent >= 0 and not spectate and _quip.randi() % 3 == 0:
				var quips: Array = Opponents.team(sim.config.opponent)["quips"]
				board.announce(String(quips[_quip.randi() % quips.size()]), Color(1, 0.8, 0.4), 2.2)
		K.EVENT_MATCH:
			_play("4_applause", Vector3(0, 2, 0))
			crowd.react(1.0)
			if not spectate:
				announcer.say(["match_win" if e[1] == 0 else "match_loss"], Announcer.TOP)
				var line := "YOU WIN!" if e[1] == 0 else "%s WIN" % them
				board.announce(line, Color(1, 0.9, 0.2), 4.0)
				match_over.emit(e[1])
			else:
				command([K.CMD_NEW_MATCH])       # the lobby's demo plays on


func _draw(delta: float) -> void:
	var b := World.m(sim.ball.x, sim.ball.y, sim.ball.z)
	var held_by_you := not sim.players[0].cpu and sim.server_slot == 0 \
		and (sim.phase == K.PHASE_SERVE or sim.phase == K.PHASE_SERVE_SETUP)
	if xr:
		xr.show_held_ball(held_by_you)
		ball_mesh.visible = not held_by_you
	_focus(delta)
	ball_mesh.global_position = b
	ball_mesh.rotation += Vector3(sim.ball.wx, sim.ball.wy, sim.ball.wz) / float(K.URAD) * delta * K.TICK_HZ
	_trail_draw(b, delta)
	shadow.global_position = Vector3(b.x, 0.02, b.z)
	var s := clampf(1.0 - b.y / 4.0, 0.35, 1.0)
	shadow.scale = Vector3(s * 1.4, 1, s * 1.4)
	for a in avatars:
		a.show_from(sim, delta)
	if machine:
		machine.show_from(sim, delta)
	if floor_target:
		floor_target.show_from(sim, delta)
	board.show_from(sim, delta)
	if flat and demo and not spectate:
		flat.head = World.m(bot.head_x, 0, bot.head_z) + Vector3(0, FlatRig.EYE, 0)


func _trail_init(r: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2
	sm.radial_segments = 8
	sm.rings = 4
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.material = m
	mm.mesh = sm
	mm.instance_count = TRAIL
	_trail = MultiMeshInstance3D.new()
	_trail.multimesh = mm
	_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_trail)


func _trail_draw(b: Vector3, delta: float) -> void:
	_trail_at.push_front(b)
	if _trail_at.size() > TRAIL + 1:
		_trail_at.pop_back()
	var fast := sim.ball.speed() * K.TICK_HZ / float(K.M) > TRAIL_SPEED and not sim.ball.held
	var mm := _trail.multimesh
	for i in TRAIL:
		var show := fast and i + 1 < _trail_at.size()
		var f := 1.0 - float(i + 1) / (TRAIL + 1)
		var at: Vector3 = _trail_at[i + 1] if show else Vector3(0, -10, 0)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * (0.4 + 0.5 * f)), at))
		mm.set_instance_color(i, Color(Look.BALL, 0.45 * f))


## Debug builds: one line per human hit, for tuning the paddle to real
## swings, to the log and to SWING_LOG on the device (game/tools/swings.sh
## reads it). Forward is toward the net.
const SWING_LOG := "user://swings.log"
func _log_swing() -> void:
	var c := sim.last_contact
	if c.size() < 16:
		return
	var fwd := -K.side_sign(0)             # the near side faces -z
	var u := Vector3(c[0], c[1], c[2]) * K.TICK_HZ / float(K.M)
	var n := Vector3(c[3], c[4], c[5]) / float(K.Q14)
	var vin := Vector3(c[6], c[7], c[8]) * K.TICK_HZ / float(K.M)
	var raw := Vector3(c[9], c[10], c[11]) * K.TICK_HZ / float(K.M)
	var out := Vector3(sim.ball.vx, sim.ball.vy, sim.ball.vz) * K.TICK_HZ / float(K.M)
	var probe := sim.ball.copy()
	probe.launch(c[9], c[10], c[11])
	var lr: Array[int] = Aim.landing(probe)
	var la: Array[int] = Aim.landing(sim.ball)
	var line := ("SWING off-centre %d mm, bounce-back %.2f | paddle %.1f m/s (fwd %.1f up %.1f side %.1f) face open %d yaw %d | at %.2f m high, %.1f m from net | in %.1f m/s | raw out %.1f m/s at %d deg -> %s | assisted -> %s" % [
		c[14] / 1000, c[15] / 256.0, u.length(), u.z * fwd, u.y, u.x, roundi(rad_to_deg(asin(clampf(n.y, -1, 1)))),
		roundi(rad_to_deg(atan2(n.x, n.z * fwd))), c[12] / 1e6, absf(c[13]) / 1e6, vin.length(),
		raw.length(), roundi(rad_to_deg(atan2(raw.y, Vector2(raw.x, raw.z).length()))), _where(lr), _where(la)])
	print(line)
	# Also to a file: the Quest's log buffer is only minutes long.
	# Read it with game/tools/swings.sh.
	var f := FileAccess.open(SWING_LOG, FileAccess.READ_WRITE if FileAccess.file_exists(SWING_LOG) else FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line("%s assist=%d %s" % [Time.get_datetime_string_from_system(), sim.config.assist, line])


func _where(l: Array[int]) -> String:
	if l[3] == 1:
		return "NET"
	var d := -l[2] / 1e6
	if d < 0.0:
		return "SHORT (own side)"
	if not K.in_court(l[1], l[2]):
		return "OUT %.1f m" % d
	return "IN %.1f m" % d


## FOCUS (ADR-013): ease toward the rally's darkness; not in the lobby.
func _focus(delta: float) -> void:
	var want := 0.0 if spectate else Focus.amount(Focus.shots_of(sim))
	var rate := Focus.EASE_IN if want > focus else Focus.EASE_OUT
	var was := focus
	focus = move_toward(focus, want, rate * delta * Focus.MAX)
	if not is_equal_approx(focus, was):
		world.set_focus(focus)
		crowd.set_focus(focus)
