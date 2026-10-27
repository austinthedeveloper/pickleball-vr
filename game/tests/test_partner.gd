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
	check(main.menu.row("to_partner").size() > 0, "DINK PARTNER on MAIN")
	main.lobby("partner")
	check(main.view.sim.drill.partner and main.view.partner_avatar != null, "the lobby demos the partner")
	main.menu.select("level")
	main.menu.change(1)
	eq(main.settings.partner_level, 2, "HARD")
	main._start(main.settings.partner_config(), false)
	check(main.view.floor_target != null and main.view.machine == null, "a target, no machine")
	main.view.sim.drill.best_rally = 9
	main._on_pause()
	main._on_pressed("lobby")
	eq(main.settings.partner_best, 9, "best rally kept")
	main.queue_free()
