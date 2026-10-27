## Whole matches: the bot against the CPU, start to finish, the same every time.
extends TestSuite


func test_a_match_finishes_with_rallies() -> void:
	var m := bot_match()
	var sim: Sim = m[0]
	var bot: Bot = m[1]
	var hits := 0
	var points := 0
	var faults := {}
	var longest := 0
	var n := 0
	for i in 120000:
		sim.step([bot.input()])
		for e in sim.drain_events():
			if e[0] == K.EVENT_HIT:
				hits += 1
			elif e[0] == K.EVENT_POINT:
				points += 1
				longest = maxi(longest, sim.shots)
			elif e[0] == K.EVENT_FAULT:
				faults[e[1]] = faults.get(e[1], 0) + 1
		if sim.phase == K.PHASE_MATCH_RESULT:
			n = i
			break
	eq(sim.phase, K.PHASE_MATCH_RESULT, "finished")
	check(sim.match_winner == 0 or sim.match_winner == 1, "someone won")
	print("      %d points, %d hits, longest rally %d, faults %s, %d s" % [points, hits, longest, faults, n / K.TICK_HZ])
	check(float(hits) / points >= 3.0, "rallies average 3+ shots (%d hits / %d points)" % [hits, points])
	check(longest >= 6, "a rally of six or more")


func test_deterministic() -> void:
	var a := bot_match(7)
	var b := bot_match(7)
	for i in 6000:
		(a[0] as Sim).step([(a[1] as Bot).input()])
		(b[0] as Sim).step([(b[1] as Bot).input()])
	eq((a[0] as Sim).snapshot(), (b[0] as Sim).snapshot(), "same seed, same match")
	var c := bot_match(8)
	for i in 6000:
		(c[0] as Sim).step([(c[1] as Bot).input()])
	check((a[0] as Sim).state_hash() != (c[0] as Sim).state_hash(), "another seed differs")


func test_cpu_serves_into_the_box() -> void:
	for seed in [1, 2, 3, 4, 5]:
		var cfg := SimTypes.MatchConfig.new()
		cfg.seed = seed
		cfg.first_server = 1
		var sim := Sim.new(cfg)
		var bot := Bot.new(sim, 0)
		var landed := false
		for i in 600:
			sim.step([bot.input()])
			for e in sim.drain_events():
				if e[0] == K.EVENT_BOUNCE and not landed:
					landed = true
					check(sim.in_service_box(e[1], e[2]) or sim.last_fault == K.FAULT_NONE,
						"seed %d serve lands in the box (%d, %d)" % [seed, e[1], e[2]])
			if landed:
				break
		check(landed, "seed %d served" % seed)
