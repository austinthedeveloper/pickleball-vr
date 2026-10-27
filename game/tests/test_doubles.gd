## Doubles: rally-scoring rotation, the receiver, lanes, a whole match.
extends TestSuite


func _sim() -> Sim:
	var cfg := SimTypes.MatchConfig.new()
	cfg.doubles = true
	return Sim.new(cfg)


func test_four_players_at_the_serve() -> void:
	var sim := _sim()
	eq(sim.active_slots(), [0, 1, 2, 3] as Array[int], "four on court")
	eq(sim.server_slot, 0, "slot 0 serves first, from the right")
	eq(sim.receiver_slot, 2, "slot 2 receives, diagonally")
	check(sim.players[1].cpu and not sim.players[0].cpu, "a CPU partner")
	var srv := sim.serve_spot(0)
	var mate := sim.serve_spot(1)
	check(srv[0] > 0 and mate[0] < 0, "server right, partner left")
	var recv := sim.serve_spot(2)
	var rmate := sim.serve_spot(3)
	check(recv[0] < 0, "the far receiver on their right (-x)")
	check(absi(rmate[1]) < K.KITCHEN_DEPTH + 500000, "the receiver's partner up at the kitchen")


func test_serving_side_switches_when_it_scores() -> void:
	var sim := _sim()
	sim.phase = K.PHASE_LIVE
	sim.resolve_point(1, K.FAULT_OUT)     # the servers win
	eq(sim.score, [1, 0] as Array[int], "a point")
	check(not sim.players[0].court_right and sim.players[1].court_right, "they switched")
	sim._serve_setup()
	eq(sim.server_slot, 0, "odd score: the left-court player serves (slot 0 switched there)")
	check(not sim.serve_from_right(), "from the left")
	eq(sim.receiver_slot, 3, "the far left-court player receives")


func test_serve_passes_when_the_servers_lose() -> void:
	var sim := _sim()
	sim.phase = K.PHASE_LIVE
	sim.resolve_point(0, K.FAULT_OUT)
	eq(sim.serving_team, 1, "serve passes")
	check(sim.players[0].court_right, "the losers don't switch")
	check(sim.players[2].court_right, "nor do the new servers")
	sim._serve_setup()
	eq(sim.server_slot, 3, "their score is 1, odd: the left-court player, slot 3")


func test_only_the_receiver_takes_the_serve() -> void:
	var sim := _sim()
	sim.required_bounce = K.REQUIRED_BOUNCE_SERVE
	check(sim.covers(2, 0), "the receiver")
	check(not sim.covers(3, 0), "not the partner")
	sim.required_bounce = K.REQUIRED_BOUNCE_NONE
	sim.players[2].x = -1500000
	sim.players[3].x = 1500000
	check(sim.covers(3, 1200000) and not sim.covers(2, 1200000), "the nearer player after")


func test_a_doubles_match_finishes() -> void:
	var cfg := SimTypes.MatchConfig.new()
	cfg.doubles = true
	var sim := Sim.new(cfg)
	var bot := Bot.new(sim, 0)
	var hitters := {}
	for i in 200000:
		sim.step([bot.input()])
		for e in sim.drain_events():
			if e[0] == K.EVENT_HIT:
				hitters[e[1]] = hitters.get(e[1], 0) + 1
		if sim.phase == K.PHASE_MATCH_RESULT:
			break
	eq(sim.phase, K.PHASE_MATCH_RESULT, "finished")
	for s in 4:
		check(hitters.get(s, 0) > 3, "slot %d plays its share: %s" % [s, hitters])


func test_doubles_deterministic() -> void:
	var cfg := SimTypes.MatchConfig.new()
	cfg.doubles = true
	var a := Sim.new(cfg)
	var b := Sim.new(cfg)
	var ba := Bot.new(a, 0)
	var bb := Bot.new(b, 0)
	for i in 6000:
		a.step([ba.input()])
		b.step([bb.input()])
	eq(a.snapshot(), b.snapshot(), "same match")
