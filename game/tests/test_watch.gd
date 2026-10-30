## COACH VIEW (ADR-028): a coach's game replays the player's drill from
## their stream. The stream on its own, then two whole games: the player
## in a drill with COACH FROM ANYWHERE on, the coach watching, through the
## Coach node and a stand-in relay.
extends TestSuite

const FAKE_PORT := 24994 + 33


## The player's side, by hand: a partner drill a Bot plays, its ticks
## tapped as MatchView taps them. [sim, bot].
func _player() -> Array:
	var s := Settings.new()
	var sim := Sim.new(s.partner_config())
	return [sim, Bot.new(sim, 0)]


func _tick(sim: Sim, bot: Bot, cmds: Array = []) -> Array:
	var h := bot.input()
	sim.step([h], cmds)
	return [sim.tick, h.to_array(), cmds, sim.state_hash() if sim.tick % Watch.HASH_EVERY == 0 else 0]


func test_a_drill_replays_exactly_from_its_stream() -> void:
	var p := _player()
	var sim: Sim = p[0]
	var bot: Bot = p[1]
	for i in 700:
		_tick(sim, bot)                  # the coach joins mid-drill
	var feed := Watch.Feed.new()
	var w := Watch.new()
	w.on_message(feed.start(sim, {"player": "ALEX"}))
	check(w.sim != null, "the state builds the drill")
	eq(w.sim.state_hash(), sim.state_hash(), "the same drill, as it is now")
	var at_tick := {}
	for i in 2400:
		var cmds: Array = [[K.CMD_PIN_TARGET, 500000, -1500000, 1]] if i == 300 else []
		feed.add(_tick(sim, bot, cmds))
		at_tick[sim.tick] = sim.state_hash()
		var m := feed.take()
		if not m.is_empty():
			w.on_message(bytes_to_var(var_to_bytes(m)))   # as it crosses the line
		for k in w.due():
			w.step()
	while w.buffered() > 0:
		w.step()
	check(sim.tick - w.sim.tick < Watch.BATCH, "caught up to what was sent: %d behind" % (sim.tick - w.sim.tick))
	eq(w.sim.state_hash(), at_tick.get(w.sim.tick, 0), "the replay is the drill, tick for tick")
	eq(w.resyncs, 0, "no hash ever differed")
	check(not w.need_state, "never out of step")
	check(sim.drill.partner and w.sim.drill.partner, "a partner drill on both")


func test_the_config_travels_whole() -> void:
	var s := Settings.new()
	s.opponent = 5
	s.doubles = true
	var cfg := s.match_config()
	var back := Watch.config_load(bytes_to_var(var_to_bytes(Watch.config_save(cfg))))
	eq(Sim.new(back).state_hash(), Sim.new(cfg).state_hash(), "a ladder match, its CPUs' styles too")
	var pc := s.partner_config()
	var pb := Watch.config_load(bytes_to_var(var_to_bytes(Watch.config_save(pc))))
	eq(Sim.new(pb).state_hash(), Sim.new(pc).state_hash(), "a drill's settings")


func test_a_drift_asks_for_the_state_again() -> void:
	var p := _player()
	var sim: Sim = p[0]
	var bot: Bot = p[1]
	var feed := Watch.Feed.new()
	var w := Watch.new()
	w.on_message(feed.start(sim, {}))
	for i in Watch.HASH_EVERY + Watch.BATCH:
		var e := _tick(sim, bot)
		if e[3] != 0:
			e[3] = int(e[3]) + 1             # the player's hash, not the replay's
		feed.add(e)
	w.on_message(feed.take(true))
	while w.buffered() > 0:
		w.step()
	check(w.need_state, "out of step: it asks again")
	w.on_message(feed.start(sim, {}))
	check(not w.need_state, "and a new state settles it")
	eq(w.sim.state_hash(), sim.state_hash(), "back in step")


func test_a_gap_asks_for_the_state_again() -> void:
	var p := _player()
	var feed := Watch.Feed.new()
	var w := Watch.new()
	w.on_message(feed.start(p[0], {}))
	for i in Watch.BATCH:
		feed.add(_tick(p[0], p[1]))
	feed.take()                          # sent, and lost
	for i in Watch.BATCH:
		feed.add(_tick(p[0], p[1]))
	var second := feed.take()
	w.on_message(second)                 # the first never came
	check(w.need_state, "a missing batch: the state again")


func test_an_online_match_isnt_watched_yet() -> void:
	var w := Watch.new()
	w.on_message(Watch.Feed.new().start(Sim.new(OnlineSession.friendly_config()), {"online": true}))
	check(w.sim == null and bool(w.info["online"]), "nothing to replay, and it says why")


func _frame(player: Node, coach_main: Node, relay: StandInRelay) -> void:
	relay.pump()
	player.desk.coach._process(MatchView.DT)
	player._process(MatchView.DT)
	player.view._process(MatchView.DT)
	player.desk._process(MatchView.DT)
	coach_main._process(MatchView.DT)
	if coach_main.view and coach_main.view.watch:
		coach_main.view._process(MatchView.DT)


func test_a_coach_watches_through_the_menus() -> void:
	var relay := StandInRelay.new(FAKE_PORT)
	var player: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(player)
	player.settings.coach = true
	player._coach_on(true)
	player.desk.coach.set_relay("ws://127.0.0.1:%d" % FAKE_PORT)
	player._start(player.settings.partner_config(), false)
	player.view.bot.auto_move = true         # the player plays (no mouse in a test)
	player.view.demo = true
	var n := 0
	while player.desk.coach.room == "" and n < 300:
		relay.pump()
		player.desk.coach._process(MatchView.DT)
		OS.delay_msec(2)
		n += 1
	eq(player.desk.coach.room, "BXKM", "the player's coach room")
	var coach_main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(coach_main)
	coach_main.relay_url = "ws://127.0.0.1:%d" % FAKE_PORT
	coach_main._letters = [RelayLink.ALPHABET.find("B"), RelayLink.ALPHABET.find("X"),
		RelayLink.ALPHABET.find("K"), RelayLink.ALPHABET.find("M")]
	coach_main.lobby("watch")
	coach_main._on_pressed("wjoin")
	coach_main.lobby("watch")
	n = 0
	while (coach_main.view == null or coach_main.view.watch == null) and n < 600:
		_frame(player, coach_main, relay)
		OS.delay_msec(2)
		n += 1
	check(coach_main.view.watch != null, "the drill on the coach's screen (%d frames)" % n)
	eq(player.desk.coach.watchers().size(), 1, "one game watching")
	var hashes := {}
	for i in 600:
		_frame(player, coach_main, relay)
		hashes[player.view.sim.tick] = player.view.sim.state_hash()
		OS.delay_msec(1)
	var w: Watch = coach_main.watching
	var behind: int = player.view.sim.tick - w.sim.tick
	check(behind >= 0 and behind <= Watch.LEAD + Watch.BATCH * 3, "a little behind the player: %d ticks" % behind)
	eq(w.sim.state_hash(), hashes.get(w.sim.tick, -1), "the coach sees the player's drill exactly")
	eq(w.resyncs, 0, "in step all along")
	var me: Avatar = null
	for a in coach_main.view.avatars:
		if a.slot == 0:
			me = a
	check(me != null and me.human, "the player on court, on their own paddle")
	check(coach_main.view.partner_avatar != null, "and the partner")
	# The coach's menu: the camera, and the replay playing on behind it.
	coach_main._on_pause()
	eq(coach_main.view.menu.title, "WATCHING", "the watching menu")
	coach_main.view.menu.select("wcam")
	coach_main.view.menu.change(1)
	eq(coach_main.view.cam_view, 1, "SIDE")
	# The player starts another drill: the coach's screen follows.
	var before: Sim = w.sim
	player._start(player.settings.machine_config(), false)
	player.desk._process(MatchView.DT)
	for i in 60:
		_frame(player, coach_main, relay)
		OS.delay_msec(2)
	check(coach_main.watching.sim != before and coach_main.view.sim.drill and not coach_main.view.sim.drill.partner,
		"the ball machine on the coach's screen too")
	# The coach stops.
	coach_main._on_pressed("wstop")
	coach_main.lobby("watch")
	check(coach_main.watching == null, "stopped watching")
	coach_main.queue_free()
	player.queue_free()
	relay.stop()
