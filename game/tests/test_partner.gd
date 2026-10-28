## DINK PARTNER and floor targets (ADR-010).
extends TestSuite


func _partner(level := 1, targets := false) -> Array:
	var s := Settings.new()
	s.partner_level = level
	s.partner_targets = targets
	var cfg := s.partner_config()
	var sim := Sim.new(cfg)
	return [sim, Bot.new(sim, 0)]


func test_the_partner_keeps_the_rally_going() -> void:
	var m := _partner()
	var sim: Sim = m[0]
	var bot: Bot = m[1]
	eq(sim.active_slots(), [0, 2] as Array[int], "you and the partner")
	var partner_hits := 0
	var near := 0
	var far := 0
	for i in 9000:
		sim.step([bot.input()])
		for e in sim.drain_events():
			if e[0] == K.EVENT_HIT and e[1] == 2:
				partner_hits += 1
			elif e[0] == K.EVENT_BOUNCE and e[2] > 0 and sim.drill.stage == Drill.FLY:
				# The partner's dink coming down on your side: in your kitchen, near your line.
				if e[2] <= K.KITCHEN_DEPTH and absi(e[1] - sim.players[0].x) < 1200000:
					near += 1
				else:
					far += 1
	check(partner_hits >= 20, "the partner plays: %d hits" % partner_hits)
	check(sim.drill.best_rally >= 8, "real rallies: best %d" % sim.drill.best_rally)
	check(near >= far * 4, "its dinks come to you, in your kitchen: %d near, %d not" % [near, far])
	check(sim.drill.good >= 10, "your dinks counted: %d" % sim.drill.good)


func test_difficulty_is_how_low_it_skims() -> void:
	var peaks := []
	for level in 3:
		var m := _partner(level)
		var sim: Sim = m[0]
		var bot: Bot = m[1]
		var top := 0
		var tops := 0
		var n := 0
		for i in 6000:
			sim.step([bot.input()])
			if sim.drill.stage == Drill.FLY:
				top = maxi(top, sim.ball.y)
			for e in sim.drain_events():
				if e[0] == K.EVENT_HIT and e[1] == 0:
					tops += top
					n += 1
					top = 0
		peaks.append(tops / maxi(n, 1))
	check(peaks[0] > peaks[1] and peaks[1] > peaks[2], "EASY floats higher than MEDIUM, than HARD: %s" % str(peaks))


func test_targets_sit_in_the_zone_and_count() -> void:
	var m := _partner(1, true)
	var sim: Sim = m[0]
	var hits := 0
	for i in 9000:
		sim.step([(m[1] as Bot).input()])
		var d := sim.drill
		check(d.target_z < 0 and -d.target_z <= K.KITCHEN_DEPTH and absi(d.target_x) <= K.COURT_HALF_WIDTH,
			"the partner's target is in their kitchen")
		for e in sim.drain_events():
			if e[0] == K.EVENT_TARGET:
				hits += 1
		if asserts > 50:
			asserts = 50                 # one check per tick is plenty; keep the count readable
	check(hits >= 5 and hits == sim.drill.target_hits, "the bot, aiming at it, hits targets: %d" % hits)


func test_machine_targets_follow_return_to() -> void:
	for zone in [Drill.ZONE_DEEP, Drill.ZONE_LEFT, Drill.ZONE_RIGHT, Drill.ZONE_KITCHEN]:
		var d := Drill.new()
		d.targets = true
		d.zone = zone
		var cfg := SimTypes.MatchConfig.new()
		cfg.drill = d
		var sim := Sim.new(cfg)
		for k in 20:
			sim.drill._new_target(sim)
			check(sim.drill.in_zone(sim.drill.target_x, sim.drill.target_z),
				"%s target inside the zone: %d, %d" % [Drill.ZONE_NAMES[zone], sim.drill.target_x, sim.drill.target_z])


func test_partner_deterministic() -> void:
	var a := _partner(2, true)
	var b := _partner(2, true)
	for i in 4000:
		(a[0] as Sim).step([(a[1] as Bot).input()])
		(b[0] as Sim).step([(b[1] as Bot).input()])
	eq((a[0] as Sim).snapshot(), (b[0] as Sim).snapshot(), "same rally")


func test_dink_partner_menu_flow() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	check(main.menu.row("to_partner").size() > 0, "PRACTICE PARTNER on MAIN")
	main.lobby("partner")
	check(main.view.sim.drill.partner and main.view.partner_avatar != null, "the lobby demos the partner")
	main.menu.select("level")
	main.menu.change(1)
	eq(main.settings.partner_level, 2, "HARD")
	main._start(main.settings.partner_config(), false)
	check(main.view.floor_target != null and main.view.machine == null, "a target, no machine")
	main.view.sim.drill.best = 9
	main._on_pause()
	main._on_pressed("lobby")
	eq(main.settings.partner_best, 9, "best rally kept")
	main.queue_free()


func test_cross_court_partner_stands_diagonal() -> void:
	var s := Settings.new()
	s.partner_cross = true
	s.partner_targets = true
	var sim := Sim.new(s.partner_config())
	var bot := Bot.new(sim, 0)
	check(sim.players[0].x > 0, "you start in your right court")
	check(sim.players[2].x < 0, "the partner diagonally across (their right is -x): %d" % sim.players[2].x)
	var near := 0
	for i in 6000:
		sim.step([bot.input()])
		check(sim.drill.target_x < 0, "targets in the partner's half")
		if asserts > 40:
			asserts = 40
		for e in sim.drain_events():
			if e[0] == K.EVENT_BOUNCE and e[2] > 0 and sim.drill.stage == Drill.FLY \
					and absi(e[1] - sim.players[0].x) < 1200000:
				near += 1
	check(near >= 8, "its dinks still come to you: %d" % near)
	check(sim.drill.best_rally >= 5, "cross-court rallies: %d" % sim.drill.best_rally)


func test_a_ball_outside_their_kitchen_resets_the_count_but_not_the_rally() -> void:
	var sim := Sim.new(Settings.new().partner_config())
	var d := sim.drill
	d.streak = 7
	d.stage = Drill.RETURN
	sim.ball.place(0, 30000, -4 * K.M)       # in court, past their kitchen
	sim.ball.launch(0, -5000, -20000)
	sim.step([null])
	eq(d.last_result, Drill.RESULT_ZONE, "missed the zone")
	eq(d.streak, 0, "the count starts again")
	eq(d.stage, Drill.PARTNER, "but the partner still plays it")


func test_announcer_says_the_number() -> void:
	var a := Announcer.new()
	runner.root.add_child(a)
	a.say(["rally_15_1"], Announcer.HIGH)
	eq(a.said, ["rally_15_1"] as Array[String], "the clip that says FIFTEEN, exactly")
	a.queue_free()


## How far to the side each of the partner's fresh dinks passes you, in um
## (you standing still on your spot, never hitting).
func _passes(cross: bool) -> Array:
	var s := Settings.new()
	s.partner_cross = cross
	var sim := Sim.new(s.partner_config())
	var h := SimTypes.HumanInput.new()
	h.head_x = sim.players[0].x
	h.head_z = sim.players[0].z
	h.paddle_z = 9 * K.M
	var out := []
	var fed := false
	for i in 6000:
		sim.step([h])
		for e in sim.drain_events():
			if e[0] == K.EVENT_HIT and e[1] == 2:
				fed = true
		if fed and sim.ball.z >= sim.players[0].z:
			out.append(sim.ball.x - sim.players[0].x)
			fed = false
	return out


func test_dinks_reach_you_cross_court_too() -> void:
	for cross in [false, true]:
		var p := _passes(cross)
		check(p.size() >= 6, "fed: %d" % p.size())
		var wide := 0
		var sides := {}
		for d in p:
			check(absi(d) <= 900000, "%s: within reach, %.2f m to the side" % ["CROSS" if cross else "ACROSS", d / 1e6])
			if absi(d) > 250000:
				wide += 1
				sides[signi(d)] = true
		# NORMAL spread: mostly to a side, both sides, not dead centre each time.
		check(wide * 2 >= p.size() and sides.size() == 2, "%s spread: %s" % ["CROSS" if cross else "ACROSS", str(p)])


func test_the_partner_moves_before_your_ball_bounces() -> void:
	var sim := Sim.new(Settings.new().partner_config())
	var bot := Bot.new(sim, 0)
	var early := 0
	var late := 0
	var start := Vector2.ZERO
	var watching := false
	for i in 8000:
		sim.step([bot.input()])
		var q := sim.players[2]
		for e in sim.drain_events():
			if e[0] == K.EVENT_HIT and e[1] == 0:
				start = Vector2(q.x, q.z)
				watching = true
			elif e[0] == K.EVENT_BOUNCE and e[2] < 0 and watching:
				watching = false
				if Vector2(q.x, q.z).distance_to(start) > 300000:
					early += 1
				else:
					late += 1
	check(early >= 8 and early > late * 3, "it reads your shot and goes: %d early, %d not" % [early, late])


func _hands(level: int) -> Array:
	var s := Settings.new()
	s.partner_hands = true
	s.partner_level = level
	var sim := Sim.new(s.partner_config())
	return [sim, Bot.new(sim, 0)]


func test_hands_is_volleys_at_you_at_every_level() -> void:
	var speeds := []
	for level in 3:
		var m := _hands(level)
		var sim: Sim = m[0]
		var bot: Bot = m[1]
		check(sim.drill.hands and sim.drill.partner, "HANDS is a partner drill")
		var partner_hits := 0
		var bounced := 0
		var fastest := 0
		for i in 9000:
			sim.step([bot.input()])
			for e in sim.drain_events():
				if e[0] == K.EVENT_HIT and e[1] == 2:
					partner_hits += 1
					fastest = maxi(fastest, Fx.length(sim.ball.vx, sim.ball.vy, sim.ball.vz))
				elif e[0] == K.EVENT_BOUNCE and e[2] > 0 and sim.drill.stage == Drill.FLY and sim.last_hitter == 2:
					bounced += 1             # the partner's ball reached you on the bounce
		check(partner_hits >= 30, "%s: the partner volleys back: %d hits" % [Drill.PACE_NAMES[level], partner_hits])
		check(sim.drill.best >= 15, "%s: playable, %d in a row" % [Drill.PACE_NAMES[level], sim.drill.best])
		check(bounced * 10 <= partner_hits, "%s: in the air, not bounced: %d of %d" % [Drill.PACE_NAMES[level], bounced, partner_hits])
		speeds.append(fastest)
	check(speeds[0] < speeds[1] and speeds[1] < speeds[2], "harder is faster: %s" % str(speeds))


func test_hands_partner_stands_at_their_kitchen() -> void:
	var m := _hands(1)
	var sim: Sim = m[0]
	var bot: Bot = m[1]
	var deepest := 0
	for i in 4000:
		sim.step([bot.input()])
		deepest = maxi(deepest, absi(sim.players[2].z))
	check(deepest < K.KITCHEN_DEPTH + 1500000, "up at the net, not back at the baseline: %d" % deepest)


func test_hands_deterministic() -> void:
	var a := _hands(2)
	var b := _hands(2)
	for i in 4000:
		(a[0] as Sim).step([(a[1] as Bot).input()])
		(b[0] as Sim).step([(b[1] as Bot).input()])
	eq((a[0] as Sim).snapshot(), (b[0] as Sim).snapshot(), "same rally")


func test_hands_menu_and_save() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	main.lobby("partner")
	main.menu.select("drill")
	main.menu.change(1)
	check(main.settings.partner_hands, "DRILL HANDS")
	main._start(main.settings.partner_config(), false)
	check(main.view.sim.drill.hands, "the match is HANDS")
	main.queue_free()
	var s := Settings.new()
	s.partner_hands = true
	s.save()
	var back := Settings.new()
	back.load_settings()
	check(back.partner_hands, "saved")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.path))


func _resets(level: int) -> Array:
	var s := Settings.new()
	s.partner_drill = 2
	s.partner_level = level
	var sim := Sim.new(s.partner_config())
	return [sim, Bot.new(sim, 0)]


func test_resets_drive_at_you_in_transition() -> void:
	var m := _resets(1)
	var sim: Sim = m[0]
	var bot: Bot = m[1]
	check(sim.drill.resets and sim.drill.zone == Drill.ZONE_KITCHEN, "RESETS: back into their kitchen")
	near(sim.players[0].z, Drill.RESET_SPOT_Z, 0, "you start mid-court")
	var drives := 0
	var fastest := 0
	var partner_returns := 0
	for i in 12000:
		var stage := sim.drill.stage
		sim.step([bot.input()])
		for e in sim.drain_events():
			if e[0] == K.EVENT_HIT and e[1] == 2:
				if stage == Drill.SETUP:
					drives += 1
					fastest = maxi(fastest, Fx.length(sim.ball.vx, 0, sim.ball.vz))
				else:
					partner_returns += 1
	check(drives >= 20, "the partner feeds drive after drive: %d" % drives)
	check(fastest >= Drill.RESET_PACE[1] * 9 / 10, "hard: %d um/tick" % fastest)
	eq(partner_returns, 0, "it never plays your reset: a fresh drive each time")
	check(sim.drill.best >= 10, "resets in a row: %d" % sim.drill.best)


func test_a_pop_up_is_called() -> void:
	var m := _resets(1)
	var sim: Sim = m[0]
	var d := sim.drill
	# Your reset crossing the net 20 cm over the line.
	d.stage = Drill.RETURN
	d.hit_at = sim.tick
	sim.last_hitter = 0
	sim.ball.held = false
	sim.ball.place(0, d.popup_y() + 200000, 30000)
	sim.ball.launch(0, 0, -60000)
	var got := -1
	for i in 5:
		sim.step([SimTypes.HumanInput.new()])
		for e in sim.drain_events():
			if e[0] == K.EVENT_DRILL:
				got = e[1]
	eq(got, Drill.RESULT_POPUP, "POP-UP!")
	eq(d.streak, 0, "the streak ends")


func test_resets_harder_is_a_lower_line() -> void:
	var pops := []
	for level in 3:
		var m := _resets(level)
		var sim: Sim = m[0]
		var bot: Bot = m[1]
		var n := 0
		for i in 9000:
			sim.step([bot.input()])
			for e in sim.drain_events():
				if e[0] == K.EVENT_DRILL and e[1] == Drill.RESULT_POPUP:
					n += 1
		check(sim.drill.good >= 5, "%s: playable, %d resets" % [Drill.PACE_NAMES[level], sim.drill.good])
		pops.append(n)
	check(Drill.POPUP_OVER[0] > Drill.POPUP_OVER[1] and Drill.POPUP_OVER[1] > Drill.POPUP_OVER[2], "lower each level")
	check(pops[2] > pops[0], "HARD's line catches more pop-ups: %s" % str(pops))


func test_resets_menu_and_old_saves() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	main.lobby("partner")
	main.menu.select("drill")
	main.menu.change(2)
	eq(main.settings.partner_drill, 2, "DRILL RESETS")
	main._start(main.settings.partner_config(), false)
	check(main.view.sim.drill.resets and main.view.popup_line != null, "the drill, with its pop-up line")
	main.queue_free()
	var c := ConfigFile.new()
	c.set_value("partner", "hands", true)
	var s := Settings.new()
	c.save(s.path)
	s.load_settings()
	check(s.partner_hands and s.partner_drill == 1, "an older save's HANDS loads as HANDS")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.path))


func test_every_feed_has_a_lead_in() -> void:
	# The ball shows in the partner's hand, drops, and is struck as it
	# falls: you see where it comes from before it's fired (ADR-016).
	for drill in 3:
		var s := Settings.new()
		s.partner_drill = drill
		var sim := Sim.new(s.partner_config())
		var bot := Bot.new(sim, 0)
		var shown := -1
		var lead := []
		for i in 3000:
			var was := sim.drill.stage
			sim.step([bot.input()])
			if was != Drill.SETUP and sim.drill.stage == Drill.SETUP:
				shown = sim.tick
				near(sim.ball.z, sim.players[2].z + 350000, 1000, "in the partner's hand")
				near(sim.ball.y, Drill.HOLD_Y, 0, "held up where you can see it")
			for e in sim.drain_events():
				if e[0] == K.EVENT_HIT and e[1] == 2 and was == Drill.SETUP:
					lead.append(sim.tick - shown)
		check(lead.size() >= 3, "%s: feeds came" % Settings.PARTNER_DRILLS[drill])
		for t: int in lead:
			check(t >= 90 and t <= 130, "%s: shown %.2f s before it's hit" % [Settings.PARTNER_DRILLS[drill], t / 120.0])
		if asserts > 60:
			asserts = 60


## The lead switched sides in DINKS and the target stayed behind: it sits
## in front of the partner and follows you across (ADR-019).
func test_the_target_follows_you_across() -> void:
	for cross in [false, true]:
		var s := Settings.new()
		s.partner_targets = true
		s.partner_cross = cross
		var sim := Sim.new(s.partner_config())
		var d := sim.drill
		var h := SimTypes.HumanInput.new()
		h.head_x = sim.players[0].x
		h.head_z = sim.players[0].z
		h.paddle_z = 9 * K.M             # the paddle well out of the way
		for i in 30:
			sim.step([h])
		var side0 := d.target_side
		eq(signi(d.target_x), side0, "%s: the target in the partner's half" % ("CROSS" if cross else "ACROSS"))
		# You walk to the other side: across from it (ACROSS), or level with it (CROSS).
		h.head_x = -side0 * 1500000 if not cross else side0 * 1500000
		for i in 60:
			sim.step([h])
		eq(d.target_side, -side0, "it moved to the other half")
		eq(signi(d.target_x), -side0, "the board with it")


## A miss moves the target too, not only a hit (the lead: "the default
## target is pretty hard to hit"); it's never right at the net.
func test_a_miss_moves_the_target() -> void:
	var m := _partner(1, true)
	var sim: Sim = m[0]
	var d := sim.drill
	var moves := 0
	var hits := 0
	var misses_kept := 0
	var at := Vector2i(d.target_x, d.target_z)
	for i in 9000:
		sim.step([(m[1] as Bot).input()])
		for e in sim.drain_events():
			if e[0] == K.EVENT_TARGET:
				hits += 1
			elif e[0] == K.EVENT_DRILL and d.last_ring == 0 and d.hit_at > d.fed_at \
					and Vector2i(d.target_x, d.target_z) == at:
				misses_kept += 1
		if Vector2i(d.target_x, d.target_z) != at:
			moves += 1
			at = Vector2i(d.target_x, d.target_z)
			check(-d.target_z >= 900000, "not right at the net: %d" % -d.target_z)
	check(moves > hits, "it moves on misses as well as hits: %d moves, %d hits" % [moves, hits])
	eq(misses_kept, 0, "no miss leaves it where it was")
