## FRIENDLY DINK (ADR-027): two humans at their kitchen lines, rallies
## counted, no score. Two Bots stand in for the friends.
extends TestSuite


func _friendly() -> Sim:
	var cfg := SimTypes.MatchConfig.new()
	cfg.friendly = true
	cfg.humans = 2
	return Sim.new(cfg)


## Two friends dinking for `ticks`: [sim, rallies ([returns, best, missed]), events seen].
func _dink(ticks: int, seed := 7) -> Array:
	var sim := _friendly()
	var a := Bot.new(sim, 0)
	var b := Bot.new(sim, 2)
	a.rng = seed
	b.rng = seed * 31 + 5
	var rallies := []
	var seen := {}
	var human: Array = [null, null, null]
	for i in ticks:
		human[0] = a.input()
		human[2] = b.input()
		sim.step(human)
		for e in sim.drain_events():
			seen[e[0]] = true
			if e[0] == K.EVENT_RALLY:
				rallies.append([e[1], e[2], e[3]])
	return [sim, rallies, seen]


func test_both_are_human_and_start_at_the_kitchen() -> void:
	var sim := _friendly()
	check(not sim.players[0].cpu and not sim.players[2].cpu, "two humans")
	for s in [0, 2]:
		var spot := sim.serve_spot(s)
		var d: int = spot[1] * K.side_sign(s >> 1)
		check(d > K.KITCHEN_DEPTH and d < K.KITCHEN_DEPTH + K.M, "slot %d behind the kitchen line" % s)


func test_two_friends_dink_and_nobody_scores() -> void:
	var r := _dink(K.TICK_HZ * 180)
	var sim: Sim = r[0]
	var rallies: Array = r[1]
	var seen: Dictionary = r[2]
	check(rallies.size() >= 4, "rallies end and start again: %d" % rallies.size())
	check(sim.best_rally >= 6, "some go long: best %d" % sim.best_rally)
	var longest := 0
	for x in rallies:
		longest = maxi(longest, x[0])
	eq(sim.best_rally, longest, "the best is the longest")
	eq(sim.score, [0, 0] as Array[int], "no score")
	check(not seen.has(K.EVENT_POINT) and not seen.has(K.EVENT_MATCH), "no points, no match end")
	check(sim.phase != K.PHASE_MATCH_RESULT, "never over")


func test_the_start_is_a_dink_not_a_serve() -> void:
	var sim := _friendly()
	var a := Bot.new(sim, 0)
	var b := Bot.new(sim, 2)
	var landed := []
	for i in K.TICK_HZ * 8:
		sim.step([a.input(), null, b.input()])
		for e in sim.drain_events():
			if e[0] == K.EVENT_SERVE:
				eq(sim.required_bounce, K.REQUIRED_BOUNCE_NONE, "no two-bounce rule")
				check(not sim.serve_pending, "no service box")
			if e[0] == K.EVENT_BOUNCE and landed.is_empty():
				landed.append(e[2])
	check(not landed.is_empty(), "the start lands")
	if not landed.is_empty():
		var d: int = landed[0] * K.side_sign(1)
		check(d > 0 and d <= K.KITCHEN_DEPTH, "in their kitchen, short of any box: %.2f m" % (d / 1e6))


func test_whoever_missed_starts_the_next() -> void:
	var sim := _friendly()
	sim.phase = K.PHASE_LIVE
	sim.last_hitter = 2
	sim.shots = 5
	sim.bounce_count = 0
	sim.ball.held = false
	sim.ball.place(0, 50000, 7 * K.M)            # the far friend's ball, long
	sim.ball.launch(0, -20000, 0)
	sim.step([])
	eq(sim.phase, K.PHASE_POINT_RESULT, "the rally ends")
	eq(sim.last_fault, K.FAULT_OUT, "out")
	eq(sim.best_rally, 4, "four returns after the start")
	eq(sim.score, [0, 0] as Array[int], "no score")
	for i in K.POINT_RESULT_TICKS + 1:
		sim.step([])
	eq(sim.server_slot, 2, "the far friend starts the next")


func test_a_kitchen_volley_faults_but_a_lean_is_fine() -> void:
	for c in [[K.KITCHEN_DEPTH - 300000, true], [K.KITCHEN_DEPTH / 2, false]]:
		var sim := _friendly()
		sim.phase = K.PHASE_LIVE
		sim.last_hitter = 2
		sim.bounce_count = 0
		sim.players[0].z = c[0]
		eq(sim._rules_hit(0), c[1], "head %.2f m from the net" % (c[0] / 1e6))
		if not c[1]:
			eq(sim.last_fault, K.FAULT_KITCHEN, "KITCHEN!")


func test_friendly_is_deterministic() -> void:
	var r1 := _dink(K.TICK_HZ * 40, 3)
	var r2 := _dink(K.TICK_HZ * 40, 3)
	eq((r1[0] as Sim).state_hash(), (r2[0] as Sim).state_hash(), "same inputs, same state")
	eq(r1[1], r2[1], "same rallies")
