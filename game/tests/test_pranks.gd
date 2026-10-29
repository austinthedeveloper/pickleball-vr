## Pranks (ADR-025, design/COACHING.md C-23): the phone's PRANKS tab through
## the desk, the cooldowns and MERCY, the looks kept across drills, the
## voice and the photo, and none of it touching the sim.
extends TestSuite


func _main() -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	main._coach_on(false)
	return main


func _done(main: Node) -> void:
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))


func _prank(main: Node, what: String, id := "", more := {}) -> void:
	var msg := {"type": "prank", "what": what, "id": id}
	msg.merge(more)
	main._on_coach(msg)


func _photo() -> String:
	var img := Image.create(64, 48, false, Image.FORMAT_RGB8)
	img.fill(Color(0.9, 0.5, 0.3))
	return Marshalls.raw_to_base64(img.save_jpg_to_buffer())


func test_pranks_never_write_to_the_sim() -> void:
	var s := Settings.new()
	s.partner_targets = true
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(s.partner_config(), false)
	var p := v.pranks
	p.set_ball("duck")
	p.set_paddle("pan")
	p.set_weather("snow")
	p.confetti()
	p.sound("airhorn")
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	check(p.set_face(img.save_jpg_to_buffer()), "a photo")
	p.voice(_tone(1600), 16000)
	for i in 1500:
		if i % 300 == 0:
			p.antic(["dance", "flex", "wave", "jump"][i / 300 % 4])
		if i == 700:
			p.set_ball("melon")
		v._process(MatchView.DT)
	var bare := Sim.new(s.partner_config())
	for a in v.input_log:
		bare.step([SimTypes.HumanInput.from_array(a)])
	eq(bare.snapshot(), v.sim.snapshot(), "pranks and a bare sim agree")
	v.queue_free()


func _tone(samples: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(samples * 2)
	for i in samples:
		b.encode_s16(i * 2, roundi(8000 * sin(TAU * 440.0 * i / 16000.0)))
	return b


func test_the_phone_plays_pranks_with_a_pause_between() -> void:
	var main := _main()
	main._start(main.settings.partner_config(), false)
	var p: Pranks = main.view.pranks
	_prank(main, "sound", "airhorn")
	_prank(main, "sound", "boo")                 # too soon: dropped
	_prank(main, "sound", "nope")
	eq(p.done, ["sound:airhorn"] as Array[String], "one sound, then a pause")
	main.desk._cool = {}
	_prank(main, "sound", "boo")
	_prank(main, "call", "out")
	_prank(main, "antic", "dance")
	_prank(main, "confetti")
	eq(p.done, ["sound:airhorn", "sound:boo", "call:out", "antic:dance", "confetti"] as Array[String], "each kind its own pause")
	eq(main.view.partner_avatar.antic_on(), "dance", "the partner dances")
	_prank(main, "ball", "duck")
	main.desk._cool = {}
	_prank(main, "paddle", "baguette")
	main.desk._cool = {}
	_prank(main, "weather", "bubbles")
	eq([p.ball, p.paddle, p.weather], ["duck", "baguette", "bubbles"], "the looks")
	eq(main.view.flat.paddle.skin, "baguette", "the paddle you see")
	var st: Dictionary = main.coach_state()["pranks"]
	eq([st["ball"], st["paddle"], st["weather"]], ["duck", "baguette", "bubbles"], "the phone sees them")
	check(st["partner"], "and that there's a partner")
	# A new drill: the looks stay on.
	main._on_pressed("again")
	main._start(main.settings.partner_config(), false)
	p = main.view.pranks
	eq([p.ball, p.paddle, p.weather], ["duck", "baguette", "bubbles"], "kept across drills")
	_done(main)


func test_mercy_and_the_off_switch() -> void:
	var main := _main()
	main._start(main.settings.partner_config(), false)
	main.desk.coach = Coach.new()                # the pause menu's MERCY row wants a coach
	main.desk.coach.port = 18294
	main.desk.add_child(main.desk.coach)
	_prank(main, "ball", "beach")
	main._on_pause()
	check(not main.view.menu.row("mercy").is_empty(), "MERCY on the pause menu")
	main._on_pressed("mercy")
	check(not main.view.paused, "back to playing")
	eq(main.view.pranks.ball, "", "every prank off")
	eq(main.view.cue_label.text, "NO PRANKS FOR A MINUTE", "and it says so")
	main.desk._cool = {}
	_prank(main, "sound", "airhorn")
	_prank(main, "ball", "duck")
	check(main.view.pranks.done.is_empty() and main.view.pranks.ball == "", "nothing for a minute")
	check(main.coach_state()["pranks"]["mercy"] > 55, "the phone counts it down")
	main.desk.mercy_until = 0
	main.settings.pranks = false
	_prank(main, "sound", "airhorn")
	check(main.view.pranks.done.is_empty(), "PRANKS off on the COACH page: none")
	main.settings.pranks = true
	_prank(main, "sound", "airhorn")
	eq(main.view.pranks.done.size(), 1, "on again")
	_done(main)


func test_their_face_and_their_voice() -> void:
	var main := _main()
	main._start(main.settings.partner_config(), false)
	var v: MatchView = main.view
	_prank(main, "face", "", {"jpg": Marshalls.utf8_to_base64("not a picture")})
	check(v.pranks.face == null, "not a picture: nothing")
	_prank(main, "face", "", {"jpg": _photo()})
	check(v.pranks.face != null, "the photo")
	check(v.partner_avatar._mask != null, "on the partner's face")
	var cut := v.pranks.face.get_image()
	eq(cut.get_pixel(0, 0).a, 0.0, "cut round: the corners clear")
	eq(cut.get_pixel(64, 64).a, 1.0, "the middle kept")
	_prank(main, "ball", "face")
	eq(v.pranks.ball, "face", "their face as the ball")
	main._on_pressed("again")
	main._start(main.settings.partner_config(), false)
	check(main.view.partner_avatar._mask != null and main.view.pranks.face != null, "kept on a new drill")
	_prank(main, "face_clear")
	check(main.view.partner_avatar._mask == null and main.view.pranks.ball == "", "taken off, and the ball with it")
	# The voice: 16-bit PCM at a sane rate, no longer than the limit.
	var pcm := Marshalls.raw_to_base64(_tone(8000))
	_prank(main, "voice", "", {"rate": 100, "pcm": pcm})
	_prank(main, "voice", "", {"rate": 16000, "pcm": Marshalls.raw_to_base64(_tone(16000 * 9))})
	check(not main.view.pranks.done.has("voice"), "a bad rate or too long: dropped")
	_prank(main, "voice", "", {"rate": 16000, "pcm": pcm})
	check(main.view.pranks.done.has("voice"), "played")
	eq(main.view.partner_avatar.antic_on(), "talk", "and the partner talks along")
	_done(main)


func test_a_big_message_gets_through_the_socket() -> void:
	# A voice clip is hundreds of kilobytes in one message.
	var c := Coach.new()
	c.port = 18394
	runner.root.add_child(c)
	var got: Array = []
	c.command.connect(func(m: Dictionary) -> void: got.append(m))
	var ws := WebSocketPeer.new()
	ws.outbound_buffer_size = 1 << 20
	ws.connect_to_url("ws://127.0.0.1:%d" % (c.port + 1))
	var pump := func() -> void: ws.poll()
	for i in 100:
		c._process(0.02)
		pump.call()
		OS.delay_msec(5)
	ws.send_text(JSON.stringify({"type": "hello", "code": c.code}))
	var big := Marshalls.raw_to_base64(_tone(16000 * 8))
	ws.send_text(JSON.stringify({"type": "prank", "what": "voice", "rate": 16000, "pcm": big}))
	for i in 200:
		c._process(0.02)
		pump.call()
		OS.delay_msec(5)
		if not got.is_empty():
			break
	eq(got.size(), 1, "the clip arrived")
	if got.size() == 1:
		eq(String(got[0]["pcm"]).length(), big.length(), "whole")
	c.queue_free()


func test_silly_paddles_and_balls_build() -> void:
	var pm := PaddleMesh.new()
	runner.root.add_child(pm)
	for kind in Pranks.PADDLES:
		pm.set_skin(kind)
		var shown := pm.get_children().filter(func(n: Node) -> bool: return (n as Node3D).visible)
		if kind == "":
			check(shown.size() > 3, "the real paddle back")
		else:
			eq(shown.size(), 1, "%s: only the silly one" % kind)
			check(pm.get_child(pm.get_child_count() - 1).get_child_count() > 0, "%s: built" % kind)
	pm.queue_free()
	for kind in Pranks.BALLS:
		if kind != "":
			check(not Pranks.ball_parts(kind, ImageTexture.new()).is_empty(), "%s: a ball" % kind)
	for id in Pranks.SOUNDS:
		var p := Pranks.new()
		check(p._stream(id) != null, "%s: a sound" % id)
		p.free()
