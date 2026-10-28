## The coach companion (ADR-023): the page over HTTP, the socket and its
## code, the shots the view reports, and the coach's commands in main.
extends TestSuite

const TEST_PORT := 18094


func _pump(c: Coach, frames: int, also: Callable = func() -> void: pass) -> void:
	for i in frames:
		c._process(0.02)
		also.call()
		OS.delay_msec(5)


func test_the_page_is_served() -> void:
	var c := Coach.new()
	c.port = TEST_PORT
	runner.root.add_child(c)
	check(c.listening(), "listening")
	eq(c.code.length(), 4, "a four-digit code")
	var tcp := StreamPeerTCP.new()
	tcp.connect_to_host("127.0.0.1", TEST_PORT)
	var reply := PackedByteArray()
	var sent := false
	_pump(c, 120, func() -> void:
		tcp.poll()
		if tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			if not sent:
				tcp.put_data("GET / HTTP/1.1\r\nHost: x\r\n\r\n".to_utf8_buffer())
				sent = true
			var n := tcp.get_available_bytes()
			if n > 0:
				reply.append_array(tcp.get_partial_data(n)[1]))
	var text := reply.get_string_from_utf8()
	check(text.begins_with("HTTP/1.1 200 OK"), "200 for /")
	check(text.contains("<title>Pickleball '94 Coach</title>"), "the coach page")
	eq(c._respond("GET /secret HTTP/1.1").get_string_from_utf8().get_slice("\r\n", 0), "HTTP/1.1 404 Not Found", "nothing else")
	c.queue_free()


func test_the_socket_wants_the_code() -> void:
	var c := Coach.new()
	c.port = TEST_PORT + 10
	runner.root.add_child(c)
	var got: Array = []
	c.command.connect(func(m: Dictionary) -> void: got.append(m))
	var ws := WebSocketPeer.new()
	ws.connect_to_url("ws://127.0.0.1:%d" % (TEST_PORT + 11))
	var inbox: Array = []
	var pump := func() -> void:
		ws.poll()
		while ws.get_available_packet_count() > 0:
			inbox.append(JSON.parse_string(ws.get_packet().get_string_from_utf8()))
	_pump(c, 100, pump)
	eq(ws.get_ready_state(), WebSocketPeer.STATE_OPEN, "connected")
	ws.send_text(JSON.stringify({"type": "set", "key": "drill", "value": 3}))
	_pump(c, 30, pump)
	eq(got.size(), 0, "nothing gets through before the code")
	ws.send_text(JSON.stringify({"type": "hello", "code": "x" + c.code}))
	_pump(c, 30, pump)
	check(inbox.any(func(m: Variant) -> bool: return m is Dictionary and m["type"] == "bad_code"), "a wrong code is told so")
	ws.send_text(JSON.stringify({"type": "hello", "code": c.code}))
	_pump(c, 30, pump)
	check(inbox.any(func(m: Variant) -> bool: return m is Dictionary and m["type"] == "welcome"), "the right one: welcome")
	eq(c.coaches(), 1, "one coach")
	ws.send_text(JSON.stringify({"type": "start"}))
	c.broadcast({"type": "state", "where": "lobby"})
	_pump(c, 30, pump)
	eq(got.size(), 1, "now the coach's messages come through")
	check(inbox.any(func(m: Variant) -> bool: return m is Dictionary and m["type"] == "state"), "and the state goes out")
	ws.close()
	c.queue_free()


func test_the_view_reports_your_shots() -> void:
	var s := Settings.new()
	s.partner_targets = true
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(s.partner_config(), false)
	var shots: Array = []
	v.shot_done.connect(func(info: Dictionary) -> void: shots.append(info))
	for i in 3600:
		v._process(MatchView.DT)
	check(shots.size() >= 5, "shots reported: %d" % shots.size())
	var landed := shots.filter(func(x: Dictionary) -> bool: return x.has("x"))
	check(not landed.is_empty(), "with where they landed")
	for x in landed:
		check(float(x["z"]) < 0.0, "on their side")
	var one: Dictionary = shots[0]
	for k in ["result", "good", "ring", "mode", "speed", "height"]:
		check(one.has(k), "a shot says its %s" % k)
	v.queue_free()


func test_the_coach_runs_the_drill() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	main._on_coach({"type": "set", "key": "drill", "value": Drill.KIND_SPOTS})
	main._on_coach({"type": "set", "key": "time", "value": 1})
	main._on_coach({"type": "set", "key": "level", "value": 9})
	eq(main.settings.partner_drill, Drill.KIND_SPOTS, "DRILL set")
	eq(main.settings.partner_time, 1, "MODE set")
	eq(main.settings.partner_level, 2, "clamped")
	var st: Dictionary = main.coach_state()
	eq(st["where"], "lobby", "in the lobby")
	eq(st["records"]["name"], "CALL THE SPOT HARD 1 MIN", "records for the setup")
	main._start(main.settings.partner_config(), false)
	st = main.coach_state()
	eq(st["where"], "playing", "playing")
	eq(st["run"]["left"], 60, "a minute on the clock")
	check(st.has("target"), "the spot")
	main._on_coach({"type": "pause"})
	check(main.view.paused, "PAUSE")
	eq(main.coach_state()["where"], "paused", "paused")
	main._on_coach({"type": "resume"})
	check(not main.view.paused, "RESUME")
	main._on_coach({"type": "nonsense"})
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))
