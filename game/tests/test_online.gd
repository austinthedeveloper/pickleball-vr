## Dinking online (ADR-027): the sim's whole state saved and restored,
## two sessions through a delayed loopback with rollback, then through a
## stand-in relay (always runs) and the real relay server (pickleball-relay,
## beside the VR game, started with Node; skipped when either is missing,
## as on CI).
extends TestSuite

const FAKE_PORT := 24994 + 23
const NODE_PORT := 24994 + 24


## Two Bots dink for `ticks`, the inputs kept: [sim, [[a, b] per tick]].
func _dinked(ticks: int) -> Array:
	var sim := Sim.new(OnlineSession.friendly_config())
	var a := Bot.new(sim, 0)
	var b := Bot.new(sim, 2)
	var inputs := []
	for i in ticks:
		var h: Array = [a.input(), null, b.input()]
		inputs.append(h)
		sim.step(h)
	return [sim, inputs]


func test_a_saved_state_steps_as_before() -> void:
	var r := _dinked(1500)
	var sim: Sim = r[0]
	var saved := sim.save_state()
	var bots := [Bot.new(sim, 0), Bot.new(sim, 2)]
	var later := []
	var hashes := []
	for i in 2400:
		var h: Array = [bots[0].input(), null, bots[1].input()]
		later.append(h)
		sim.step(h)
		hashes.append(sim.state_hash())
	var copy := Sim.new(OnlineSession.friendly_config())
	copy.load_state(saved)
	var same := 0
	for i in later.size():
		copy.step(later[i])
		if copy.state_hash() == hashes[i]:
			same += 1
	eq(same, later.size(), "every tick the same after a load")
	check(sim.best_rally > 0, "it dinked (best %d)" % sim.best_rally)
	# And a load mid-rally into a sim that's somewhere else entirely.
	var other := Sim.new(OnlineSession.friendly_config(7))
	for i in 300:
		other.step([])
	other.load_state(saved)
	for i in later.size():
		other.step(later[i])
	eq(other.state_hash(), hashes[-1], "a busy sim loads it too")


func test_a_drill_saves_too() -> void:
	var s := Settings.new()
	var sim := Sim.new(s.partner_config())
	var bot := Bot.new(sim, 0)
	for i in 900:
		sim.step([bot.input()])
	var saved := sim.save_state()
	var later := []
	for i in 900:
		later.append([bot.input()])
		sim.step(later[-1])
	var copy := Sim.new(s.partner_config())
	copy.load_state(saved)
	for h in later:
		copy.step(h)
	eq(copy.state_hash(), sim.state_hash(), "the partner's drill after a load")


func test_without_pose_hides_only_that_pose() -> void:
	var sim := Sim.new(OnlineSession.friendly_config())
	var a := sim.snapshot(2)
	sim.players[2].px += 12345
	sim.players[2].x += 5000
	eq(sim.snapshot(2), a, "the friend's pose isn't shared")
	sim.players[0].px += 1
	check(sim.snapshot(2) != a, "yours is")
	var b := sim.snapshot(2)
	sim.ball.vx += 1
	check(sim.snapshot(2) != b, "the ball is")


func test_the_config_travels() -> void:
	var cfg := OnlineSession.friendly_config(4242)
	cfg.assist = 0
	var d := OnlineSession.config_to_dict(cfg)
	var back := OnlineSession.config_from_dict(JSON.parse_string(JSON.stringify(d)))
	check(back.friendly and back.humans == 2, "friendly, two humans")
	eq([back.seed, back.assist], [4242, 0], "seed and assist")
	var s1 := Sim.new(cfg)
	var s2 := Sim.new(back)
	eq(s1.state_hash(), s2.state_hash(), "the same sim")


## Two sessions on a loopback `latency` polls each way (a poll a tick),
## each a Bot playing from its own prediction. [host, guest, rallies].
func _online(latency: int, ticks: int, jitter: Array = []) -> Array:
	var links := LoopbackLink.pair(latency, jitter)
	var host := OnlineSession.new(links[0], true)
	var guest := OnlineSession.new(links[1], false)
	host.my_hello = OnlineSession.hello()
	guest.my_hello = OnlineSession.hello()
	for i in latency * 2 + 10:
		host.poll()
		guest.poll()
	eq([host.state, guest.state], [OnlineSession.CONNECTED, OnlineSession.CONNECTED], "HELLO both ways")
	host.begin({"cfg": OnlineSession.config_to_dict(OnlineSession.friendly_config(99)), "venue": 0})
	for i in latency + 4:
		host.poll()
		guest.poll()
	eq(guest.state, OnlineSession.PLAYING, "the guest got START")
	var bots := [Bot.new(host.rollback.pred, 0), Bot.new(guest.rollback.pred, 2)]
	var rallies := 0
	for i in ticks:
		for side in 2:
			var s: OnlineSession = [host, guest][side]
			var out := s.tick(bots[side].input())
			if side == 0:
				for evs in out["played"]:
					for e in evs:
						if e[0] == K.EVENT_RALLY:
							rallies += 1
		host.poll()
		guest.poll()
	return [host, guest, rallies]


func test_two_friends_dink_online() -> void:
	var r := _online(6, K.TICK_HZ * 90, [0, 1, 0, 3, 0, 0, 2])   # 50 ms each way, jitter
	var host: OnlineSession = r[0]
	var guest: OnlineSession = r[1]
	var hr := host.rollback
	var gr := guest.rollback
	eq([hr.desync, gr.desync], [-1, -1], "never out of sync")
	check(hr.checked >= 30 and gr.checked >= 30, "hashes compared: %d, %d" % [hr.checked, gr.checked])
	eq([hr.stalls, gr.stalls], [0, 0], "nobody waits at 100 ms")
	check(hr.truth.best_rally >= 4, "a real rally online: best %d" % hr.truth.best_rally)
	check(r[2] >= 3, "rallies end and start: %d" % r[2])
	check(hr.corrections > 0, "the friend's hits are corrections: %d, %d" % [hr.corrections, gr.corrections])
	check(hr.corrections < hr.confirmed / 20, "but not every tick: %d in %d" % [hr.corrections, hr.confirmed])
	check(hr.guessing() <= 16, "predicting %d ticks ahead" % hr.guessing())
	eq(host.state, OnlineSession.PLAYING, "still playing")
	guest.quit()
	for i in 10:
		host.poll()
	eq(host.reason, "YOUR FRIEND LEFT", "the host hears the guest go")


func test_a_slow_line_waits_rather_than_guess_forever() -> void:
	var r := _online(60, 600)                                # 500 ms each way
	var hr: Rollback = (r[0] as OnlineSession).rollback
	check(hr.stalls > 0, "the window fills: %d stalls" % hr.stalls)
	check(hr.guessing() <= Rollback.WINDOW, "never past the window")
	eq(hr.desync, -1, "and stays in sync")


func test_versions_must_match() -> void:
	var links := LoopbackLink.pair(1)
	var host := OnlineSession.new(links[0], true)
	var guest := OnlineSession.new(links[1], false)
	host.my_hello = OnlineSession.hello()
	guest.my_hello = OnlineSession.hello()
	guest.my_hello["version"] = "0.0.1"
	for i in 10:
		host.poll()
		guest.poll()
	check(host.closed() and guest.closed(), "both close")
	eq(guest.reason, "YOUR FRIEND HAS %s" % RelayLink.version(), "the friend's version, so you know who updates")
	eq(host.reason, "VERSIONS DIFFER", "and the friend is told")


## The relay's side of one room, as pickleball-relay frames it: the first
## to dial is the host (room BXKM), the second the guest (number 0).
class FakeRelay:
	var server := TCPServer.new()
	var peers: Array = []            ## [WebSocketPeer, greeted]

	func _init(port: int) -> void:
		server.listen(port, "127.0.0.1")

	func pump() -> void:
		while server.is_connection_available():
			var ws := WebSocketPeer.new()
			ws.accept_stream(server.take_connection())
			peers.append([ws, false])
		for i in peers.size():
			var ws: WebSocketPeer = peers[i][0]
			ws.poll()
			if ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
				continue
			if not peers[i][1]:
				peers[i][1] = true
				if i == 0:
					ws.send_text(JSON.stringify({"op": "room", "code": "BXKM"}))
				else:
					ws.send_text(JSON.stringify({"op": "welcome", "you": 0, "ver": ""}))
					(peers[0][0] as WebSocketPeer).send_text(JSON.stringify({"op": "joined", "guest": 0, "ver": ""}))
			while ws.get_available_packet_count() > 0:
				var b := ws.get_packet()
				if ws.was_string_packet() or peers.size() < 2:
					continue
				if i == 0:
					(peers[1][0] as WebSocketPeer).send(b.slice(1))
				else:
					var out := PackedByteArray([0])
					out.append_array(b)
					(peers[0][0] as WebSocketPeer).send(out)

	func stop() -> void:
		for p in peers:
			(p[0] as WebSocketPeer).close()
		server.stop()


## Two sessions through a relay at `url` (pump: the fake's, or null):
## the room, HELLO, START, then `ticks` of two Bots dinking.
func _through(url: String, ticks: int, relay: FakeRelay = null) -> Array:
	var hl := RelayLink.new()
	check(hl.host(url), "the host dials")
	var host := OnlineSession.new(hl, true)
	host.my_hello = OnlineSession.hello()
	var n := 0
	while hl.room == "" and n < 2000:
		if relay:
			relay.pump()
		host.poll()
		OS.delay_msec(2)
		n += 1
	eq(hl.room.length(), 4, "the relay names a room (%s)" % hl.error)
	var gl := RelayLink.new()
	check(gl.join(hl.room.to_lower(), url), "the guest joins it")
	var guest := OnlineSession.new(gl, false)
	guest.my_hello = OnlineSession.hello()
	n = 0
	while (host.state != OnlineSession.CONNECTED or guest.state != OnlineSession.CONNECTED) and n < 2000:
		if relay:
			relay.pump()
		host.poll()
		guest.poll()
		OS.delay_msec(2)
		n += 1
	eq([host.state, guest.state], [OnlineSession.CONNECTED, OnlineSession.CONNECTED],
		"connected through the relay (%s %s)" % [host.reason, guest.reason])
	host.begin({"cfg": OnlineSession.config_to_dict(OnlineSession.friendly_config()), "venue": 0})
	n = 0
	while guest.state != OnlineSession.PLAYING and n < 2000:
		if relay:
			relay.pump()
		host.poll()
		guest.poll()
		OS.delay_msec(2)
		n += 1
	eq(guest.state, OnlineSession.PLAYING, "the guest plays")
	var bots := [Bot.new(host.rollback.pred, 0), Bot.new(guest.rollback.pred, 2)]
	# Real time: a tick every 1/120 s, so the line's own delay shows.
	var t0 := Time.get_ticks_usec()
	var done := 0
	while done < ticks:
		var due := int((Time.get_ticks_usec() - t0) * K.TICK_HZ / 1000000)
		while done < mini(due, ticks):
			host.tick(bots[0].input())
			guest.tick(bots[1].input())
			done += 1
		if relay:
			relay.pump()
		host.poll()
		guest.poll()
		OS.delay_msec(1)
	return [host, guest]


func test_two_friends_through_a_relay() -> void:
	var relay := FakeRelay.new(FAKE_PORT)
	var r := _through("ws://127.0.0.1:%d" % FAKE_PORT, K.TICK_HZ * 6, relay)
	var host: OnlineSession = r[0]
	var guest: OnlineSession = r[1]
	eq([host.rollback.desync, guest.rollback.desync], [-1, -1], "in sync")
	check(host.rollback.checked >= 2, "hashes compared: %d" % host.rollback.checked)
	check(host.rollback.confirmed >= K.TICK_HZ * 5, "confirmed %d ticks" % host.rollback.confirmed)
	check(host.link.rtt_ms() > 0, "the line measured: %d ms" % host.link.rtt_ms())
	host.quit()
	guest.quit()
	relay.stop()


## pickleball-relay's server.js, beside the VR game ("" if it isn't there
## or Node isn't installed).
func _relay_server() -> String:
	var js := ProjectSettings.globalize_path("res://").path_join("../../pickleball-relay/server.js").simplify_path()
	if not FileAccess.file_exists(js):
		return ""
	var out := []
	if OS.execute("node", ["--version"], out) != 0:
		return ""
	return js


func test_two_friends_through_the_real_relay() -> void:
	var js := _relay_server()
	if js == "":
		check(true, "skipped: no ../pickleball-relay or no Node (as on CI)")
		return
	var pid := OS.create_process("node", ["-e",
		"require(%s).createRelay({log: () => {}}).listen(%d)" % [JSON.stringify(js), NODE_PORT]])
	check(pid > 0, "the relay starts")
	OS.delay_msec(700)
	var r := _through("ws://127.0.0.1:%d" % NODE_PORT, K.TICK_HZ * 6)
	var host: OnlineSession = r[0]
	var guest: OnlineSession = r[1]
	eq([host.rollback.desync, guest.rollback.desync], [-1, -1], "in sync")
	check(host.rollback.confirmed >= K.TICK_HZ * 5, "confirmed %d ticks" % host.rollback.confirmed)
	guest.quit()
	var n := 0
	while not host.closed() and n < 500:
		host.poll()
		OS.delay_msec(2)
		n += 1
	eq(host.reason, "YOUR FRIEND LEFT", "the host hears the guest go")
	OS.kill(pid)
