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


# --- design/COACHING.md C-3..C-18 ------------------------------------------------------

func _main() -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	return main


func test_a_coach_pins_the_target_and_picks_the_feed() -> void:
	# Through the sim's commands (deterministic, replayable): C-8, C-9.
	var s := Settings.new()
	s.partner_targets = true
	var sim := Sim.new(s.partner_config())
	var bot := Bot.new(sim, 0)
	sim.step([bot.input()], [[K.CMD_PIN_TARGET, -1500000, -1200000, 1]])
	var d := sim.drill
	check(d.target_pinned and d.target_x == -1500000 and d.target_z == -1200000, "the coach's target, there")
	sim.step([bot.input()], [[K.CMD_FEED_TO, 1000000, 1500000]])
	check(d.feed_set, "a feed chosen")
	var landed := Vector2i(-1, -1)
	for i in 3000:
		sim.step([bot.input()])
		for e in sim.drain_events():
			if e[0] == K.EVENT_BOUNCE and e[2] > 0 and landed.x == -1 and not d.feed_set:
				landed = Vector2i(e[1], e[2])
	check(not d.feed_set, "used on the partner's next ball")
	check(absi(landed.x - 1000000) < 250000 and absi(landed.y - 1500000) < 250000,
		"it landed there: %s" % str(landed))
	eq([d.target_x, d.target_z], [-1500000, -1200000], "the pinned target stayed put, hits and misses alike")
	sim.step([bot.input()], [[K.CMD_PIN_TARGET, 0, 0, 0]])
	check(not d.target_pinned, "let go, it moves again")
	# A drill without a board gets one.
	s.partner_targets = false
	var sim2 := Sim.new(s.partner_config())
	sim2.step([], [[K.CMD_PIN_TARGET, 0, -1500000, 1]])
	check(sim2.drill.targets, "a board appears where the coach put it")


func test_shots_carry_what_the_coach_reads() -> void:
	var s := Settings.new()
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(s.partner_config(), false)
	var shots: Array = []
	v.shot_done.connect(func(info: Dictionary) -> void: shots.append(info))
	for i in 3600:
		v._process(MatchView.DT)
	var hit := shots.filter(func(x: Dictionary) -> bool: return x.get("hit", false))
	check(hit.size() >= 4, "hits: %d" % hit.size())
	for k in ["side", "behind", "clear", "path", "in_path", "me"]:
		check(hit.any(func(x: Dictionary) -> bool: return x.has(k)), "a shot has its %s" % k)
	for x in hit:
		if x.has("clear") and x["result"] != "NET":
			check(float(x["clear"]) > 0.0, "over the net: %.2f m" % float(x["clear"]))
	v.queue_free()


func test_cues_challenges_marks_in_the_headset() -> void:
	var main := _main()
	main._coach_on(false)
	main._start(main.settings.partner_config(), false)
	var v: MatchView = main.view
	main._on_coach({"type": "cue", "text": "paddle up<script>"})
	check(v.cue_label != null and v.cue_label.visible, "the cue shows")
	eq(v.cue_label.text, "PADDLE UPSCRIPT", "upper case, letters only")
	main._on_coach({"type": "challenge", "kind": "good", "n": 2})
	check(v.challenge_label.visible and v.challenge_label.text.contains("0 / 2"), "the challenge shows")
	main.desk.on_shot({"good": true, "ring": 0})
	main.desk.on_shot({"good": false, "ring": 0})
	main.desk.on_shot({"good": true, "ring": 0})
	check(main.desk.challenge["done"], "two good: done")
	eq(v.challenge_label.text, "CHALLENGE DONE!", "and said so")
	main._on_coach({"type": "mark", "shape": "zone", "ax": -2, "az": -2, "bx": 0, "bz": -0.5})
	main._on_coach({"type": "mark", "shape": "line", "ax": -2, "az": -1.8, "bx": 2, "bz": -1.8})
	eq(v.marks.get_child_count(), 2, "two marks on the court")
	main._on_pressed("again")
	main._start(main.settings.partner_config(), false)
	eq(main.view.marks.get_child_count(), 2, "and back on a new drill")
	main._on_coach({"type": "clear_marks"})
	eq(main.view.marks.get_child_count(), 0, "cleared")
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))


func test_sliders_and_workouts() -> void:
	var main := _main()
	main.settings.partner_drill = Drill.KIND_SPOTS
	main.settings.partner_level = 2
	var ids: Array = main.coach_state()["tunes"].map(func(t: Dictionary) -> String: return t["id"])
	check(ids.has("dink_hard") and ids.has("spot_hard") and not ids.has("spot_easy"), "the drill's sliders, its level: %s" % str(ids))
	var was := Tune.value("spot_hard")
	main._on_coach({"type": "tune", "id": "spot_hard", "value": was + 100000})
	eq(Tune.value("spot_hard"), was + 100000, "a slider moves it, live")
	main._on_coach({"type": "tune_reset"})
	eq(Tune.value("spot_hard"), was, "RESET")
	var steps := [{"drill": Drill.KIND_DINKS, "level": 0, "time": 1, "targets": true},
		{"drill": Drill.KIND_RESETS, "level": 1, "time": 0, "targets": false}]
	main._on_coach({"type": "workout_save", "name": "warm up!", "steps": steps})
	eq(main.settings.workouts.size(), 1, "saved")
	eq(main.settings.workouts[0]["name"], "WARM UP!", "its name")
	eq(main.settings.workouts[0]["steps"][1]["time"], 1, "every step is timed")
	main._on_coach({"type": "workout_run", "name": "WARM UP!"})
	eq(main.desk.workout["step"], 0, "running from the first drill")
	eq(main.settings.partner_drill, Drill.KIND_DINKS, "its drill set")
	main._start(main.settings.partner_config(), false)   # what the deferred start does
	main.desk.on_time_up(10, 10, 3)
	eq(main.desk.workout["step"], 1, "time's up: on to the next")
	check(main.view.cue_label.text.begins_with("NEXT: RESETS"), "and the headset says what's next")
	main.desk._run_step()
	eq(main.settings.partner_drill, Drill.KIND_RESETS, "the next drill set")
	main.desk.on_time_up(5, 5, 1)
	check(main.desk.workout.is_empty(), "the last one: done")
	main._on_coach({"type": "workout_delete", "name": "WARM UP!"})
	eq(main.settings.workouts.size(), 0, "deleted")
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))


func test_sessions_and_players() -> void:
	var main := _main()
	for i in 7:
		main.desk.on_shot({"type": "shot", "good": i % 2 == 0, "result": "GOOD!", "mode": "DINKS MEDIUM",
			"clear": 0.3, "path": [[0, 1, 0]]})
	var list := Sessions.list(main.settings.player)
	eq(list.size(), 1, "a session saved")
	eq(list[0]["shots"], 5, "written every five shots")
	main.desk.session.save()
	var full := Sessions.read(String(list[0]["id"]))
	eq((full["shots"] as Array).size(), 7, "all of them")
	check(not (full["shots"][0] as Dictionary).has("path"), "replay paths stay live")
	main._on_coach({"type": "player", "name": "ann"})
	eq(main.settings.player, "ANN", "a new player")
	check(main.settings.players.has("PLAYER 1") and main.settings.players.has("ANN"), "both kept")
	main.desk.on_shot({"good": true, "result": "GOOD!"})
	main.desk.session.save()
	eq(Sessions.list("ANN").size(), 1, "her own session")
	eq(Sessions.list("PLAYER 1").size(), 1, "his untouched")
	main.settings.add_run("X 1 MIN", 30, 20, 5, "")
	main._on_coach({"type": "player", "name": "PLAYER 1"})
	check(not main.settings.records.has("X 1 MIN"), "records are each player's own")
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))


func test_old_records_go_to_the_first_player() -> void:
	var c := ConfigFile.new()
	c.set_value("records", "runs", {"DINKS EASY 1 MIN": [[12, "", 12, 4]]})
	var s := Settings.new()
	c.save(s.path)
	s.load_settings()
	eq(s.player, "PLAYER 1", "the first player")
	eq(s.recent_scores("DINKS EASY 1 MIN"), [12] as Array[int], "keeps the runs from before profiles")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.path))


# --- The coach's ball machine (C-21) -----------------------------------------------------

## The first bounce on your side of the machine's next ball, and how high it
## crossed the net: [x, z, net height].
func _machine_ball(m: Dictionary) -> Array:
	var s := Settings.new()
	var sim := Sim.new(s.machine_config())
	sim.step([], [CoachDesk.machine_command(m)])
	var net := -1
	var z_was := sim.ball.z
	for i in 900:
		sim.step([SimTypes.HumanInput.new()])
		if z_was < 0 and sim.ball.z >= 0 and sim.drill.stage == Drill.FLY:
			net = sim.ball.y - K.net_height(sim.ball.x)
		z_was = sim.ball.z
		for e in sim.drain_events():
			if e[0] == K.EVENT_BOUNCE and e[2] > 0:
				return [e[1], e[2], net]
	return []


func test_the_coach_machine_feeds_where_it_was_put() -> void:
	var base := {"x": -2.0, "z": -6.5, "bx": 1.0, "bz": 3.0, "speed": 10.0, "spin": 40, "clear": 0.4, "every": 3.0}
	for change in [{}, {"speed": 4.0}, {"speed": 18.0}, {"spin": -100}, {"spin": 100}, {"clear": 1.5},
			{"x": 2.5, "z": -3.0, "bx": -1.5, "bz": 5.5}]:
		var m: Dictionary = base.merged(change, true)
		var r := _machine_ball(m)
		check(not r.is_empty(), "%s: it bounced on your side" % str(change))
		if r.is_empty():
			continue
		var off := Vector2(r[0] / 1e6 - float(m["bx"]), r[1] / 1e6 - float(m["bz"])).length()
		check(off < 0.3, "%s: bounced %.2f m from the coach's spot" % [str(change), off])
		check(r[2] >= roundi(float(m["clear"]) * K.M) - 60000, "%s: over the net by %d um, asked %.2f m" % [str(change), r[2], float(m["clear"])])
	# Higher over the net is higher: the height control does what it says.
	var low := _machine_ball(base)
	var high := _machine_ball(base.merged({"clear": 1.5}, true))
	check(high[2] > low[2] + 600000, "1.5 m asked crosses higher than 0.4 m: %d vs %d" % [high[2], low[2]])


func test_the_coach_machine_stands_where_it_was_put() -> void:
	var main := _main()
	main.settings.coach_machine = {"x": 2.0, "z": -4.0, "bx": 0.0, "bz": 3.5, "speed": 9.0, "spin": 0, "clear": 0.5, "every": 2.0}
	main._on_coach({"type": "machine_start"})
	main._start(main.settings.machine_config(), false)   # what the deferred start does
	main.desk.on_new_view(main.view)
	main.view._process(MatchView.DT)
	var d: Drill = main.view.sim.drill
	check(d.coach_feed, "the coach's machine")
	eq([d.machine_x, d.machine_z, d.feed_every], [2000000, -4000000, 240], "where and how often")
	eq(d.mode_name(), "COACH MACHINE", "named for the log and the page")
	main._on_coach({"type": "machine_set", "bx": -1.0})
	main.view._process(MatchView.DT)
	eq(d.bounce_x, -1000000, "a change reaches the machine at once")
	eq(main.settings.coach_machine["bx"], -1.0, "and is kept")
	check(main.coach_state()["machine"]["on"], "the page sees it on")
	main.view.command([K.CMD_NEW_MATCH])
	main.view._process(MatchView.DT)
	eq([main.view.sim.drill.machine_x, main.view.sim.drill.machine_z], [2000000, -4000000], "RESTART keeps it where it was put")
	main._on_coach({"type": "menu"})
	check(not main.desk.machine_on, "MENU: the coach's machine is off")
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))


## A stand-in for the relay (the port kit's design/RELAY.md): one socket,
## the headset's, with the relay's frames. The real relay has its own tests.
class FakeRelay:
	var server := TCPServer.new()
	var ws: WebSocketPeer
	var text: Array = []             ## the headset's control messages
	var binary: Array = []           ## its frames to coaches

	func _init(port: int) -> void:
		server.listen(port, "127.0.0.1")

	func pump() -> void:
		if server.is_connection_available():
			ws = WebSocketPeer.new()
			ws.inbound_buffer_size = 1 << 20
			ws.accept_stream(server.take_connection())
		if ws == null:
			return
		ws.poll()
		while ws.get_available_packet_count() > 0:
			var b := ws.get_packet()
			if ws.was_string_packet():
				text.append(JSON.parse_string(b.get_string_from_utf8()))
			else:
				binary.append(b)

	func say(msg: Dictionary) -> void:
		ws.send_text(JSON.stringify(msg))

	func from_guest(g: int, msg: Dictionary) -> void:
		var out := PackedByteArray([g])
		out.append_array(JSON.stringify(msg).to_utf8_buffer())
		ws.send(out)


func test_anywhere_through_the_relay() -> void:
	var c := Coach.new()
	c.port = TEST_PORT + 20
	runner.root.add_child(c)
	var relay := FakeRelay.new(TEST_PORT + 25)
	var got: Array = []
	c.command.connect(func(m: Dictionary) -> void: got.append(m))
	var changes := [0]
	c.room_changed.connect(func() -> void: changes[0] += 1)
	c.set_relay("ws://127.0.0.1:%d" % (TEST_PORT + 25))
	_pump(c, 60, relay.pump)
	check(relay.ws != null and relay.ws.get_ready_state() == WebSocketPeer.STATE_OPEN, "the headset dials the relay")
	relay.say({"op": "room", "code": "BXKM"})
	_pump(c, 30, relay.pump)
	eq(c.room, "BXKM", "the room")
	eq(changes[0], 1, "the COACH page hears of it")
	var page: Array = relay.text.filter(func(m: Variant) -> bool: return m is Dictionary and m["op"] == "page")
	check(page.size() == 1 and String(page[0]["html"]).contains("<title>Pickleball '94 Coach</title>"), "and the relay gets the page")
	# A coach joins through the relay: the code first, as on the Wi-Fi.
	relay.say({"op": "joined", "guest": 2, "ver": ""})
	relay.from_guest(2, {"type": "start"})
	relay.from_guest(2, {"type": "hello", "code": c.code})
	_pump(c, 30, relay.pump)
	eq(got.size(), 0, "nothing before the code")
	eq(c.coaches(), 1, "one coach, anywhere")
	var first: PackedByteArray = relay.binary[-1]
	eq(first[0], 2, "the reply goes to that coach")
	eq(JSON.parse_string(first.slice(1).get_string_from_utf8()), {"type": "welcome"}, "welcome")
	relay.from_guest(2, {"type": "start"})
	c.broadcast({"type": "state", "where": "lobby"})
	_pump(c, 30, relay.pump)
	eq(got, [{"type": "start"}], "the coach's command comes through")
	var last: PackedByteArray = relay.binary[-1]
	eq([last[0], JSON.parse_string(last.slice(1).get_string_from_utf8())["type"]], [2, "state"], "and the state goes out")
	relay.say({"op": "left", "guest": 2})
	_pump(c, 30, relay.pump)
	eq(c.coaches(), 0, "the coach left")
	# The relay goes away: the room's gone, and the headset dials again.
	relay.ws.close()
	_pump(c, 40, relay.pump)
	eq(c.room, "", "no room")
	eq(changes[0], 2, "the COACH page hears that too")
	relay.ws = null
	_pump(c, 160, relay.pump)
	check(relay.ws != null, "dialled again")
	c.set_relay("")
	_pump(c, 20, relay.pump)
	c.queue_free()
	relay.server.stop()


func test_the_coach_page_offers_anywhere() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	main.settings.coach = true
	main.settings.coach_anywhere = true
	main._coach_on(true)
	main.coach.set_relay("")                     # no internet in tests
	main.lobby("coach")
	eq(main.menu.value("anywhere"), 1, "COACH FROM ANYWHERE on")
	eq(main.menu.row("info_room")["label"], "ANYWHERE   CONNECTING...", "waiting for a room")
	main.coach.room = "BXKM"
	main._on_room()
	eq(main.menu.row("info_room")["label"], "ANYWHERE   ROOM BXKM", "then the room, in place")
	main._on_changed("anywhere", 0)
	check(not main.settings.coach_anywhere and main.coach.relay == "", "off: no relay")
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))
