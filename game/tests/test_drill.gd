## Practice (ADR-007): the machine feeds, returns count, lessons finish.
extends TestSuite


func _drill(shot := Drill.SHOT_DRIVE, target := Drill.TARGET_AT_YOU, rules := 0, goal := 0,
		zone := Drill.ZONE_ANY) -> Array:
	var d := Drill.new()
	d.shot = shot
	d.target = target
	d.rules = rules
	d.goal = goal
	d.zone = zone
	if shot == Drill.SHOT_SERVE:
		var sp := d.serve_spot()
		d.spot_x = sp[0]
		d.spot_z = sp[1]
	var cfg := SimTypes.MatchConfig.new()
	cfg.drill = d
	var sim := Sim.new(cfg)
	return [sim, Bot.new(sim, 0)]


func _results(sim: Sim, bot: Bot, ticks: int) -> Array:
	var out := []
	for i in ticks:
		sim.step([bot.input() if bot else null])
		for e in sim.drain_events():
			if e[0] == K.EVENT_DRILL:
				out.append(e[1])
	return out


func test_machine_feeds_and_the_bot_returns() -> void:
	var m := _drill()
	var sim: Sim = m[0]
	eq(sim.active_slots(), [0] as Array[int], "you alone")
	var r := _results(sim, m[1], 4000)
	check(r.size() >= 12, "fed and resolved: %d" % r.size())
	var good := r.count(Drill.RESULT_GOOD)
	check(good * 10 >= r.size() * 6, "most returns good: %s" % str(r))
	eq(sim.drill.feeds, r.size() + (1 if sim.drill.stage != Drill.WAIT else 0), "one result a feed")
	check(sim.drill.best >= 2, "a streak")


func test_every_shot_and_target_feeds_in() -> void:
	for shot in [Drill.SHOT_DRIVE, Drill.SHOT_DINK, Drill.SHOT_LOB, Drill.SHOT_MIX]:
		for target in Drill.TARGET_NAMES.size():
			var m := _drill(shot, target)
			var sim: Sim = m[0]
			var landed := false
			for i in 600:
				sim.step([null])
				for e in sim.drain_events():
					if e[0] == K.EVENT_BOUNCE and not landed:
						landed = true
						check(e[2] > 0 and K.in_court(e[1], e[2]),
							"%s to %s lands in on your side: %d, %d" % [Drill.SHOT_NAMES[shot], Drill.TARGET_NAMES[target], e[1], e[2]])
				if landed:
					break
			check(landed, "%s %s fed" % [shot, target])


func test_unreturned_feed_is_missed() -> void:
	var m := _drill()
	var r := _results(m[0], null, 900)
	check(r.size() >= 2 and r.count(Drill.RESULT_MISSED) == r.size(), "nobody home: %s" % str(r))
	eq((m[0] as Sim).drill.streak, 0, "no streak")


func test_no_volley_lesson_lets_it_bounce() -> void:
	var m := _drill(Drill.SHOT_DRIVE, Drill.TARGET_AT_YOU, Drill.RULE_NO_VOLLEY, 3)
	var r := _results(m[0], m[1], 6000)
	check(not r.has(Drill.RESULT_VOLLEY), "the bot let it bounce: %s" % str(r))
	eq((m[0] as Sim).drill.stage, Drill.DONE, "three good: the lesson's done")


func test_serve_lesson() -> void:
	var m := _drill(Drill.SHOT_SERVE, 0, 0, 3)
	var sim: Sim = m[0]
	eq(sim.phase, K.PHASE_SERVE, "the ball in your hand")
	var r := _results(sim, m[1], 6000)
	check(r.count(Drill.RESULT_GOOD) >= 3, "three serves in the box: %s" % str(r))
	eq(sim.drill.stage, Drill.DONE, "done")


func test_zones() -> void:
	var d := Drill.new()
	d.zone = Drill.ZONE_KITCHEN
	check(d.in_zone(0, -1 * K.M) and not d.in_zone(0, -4 * K.M), "kitchen")
	check(d.in_zone(0, -(K.KITCHEN_DEPTH + 700000)), "a dink 70 cm past the kitchen line counts")
	check(not d.in_zone(0, -(K.KITCHEN_DEPTH + 900000)), "90 cm past it doesn't")
	d.zone = Drill.ZONE_DEEP
	check(d.in_zone(0, -6 * K.M) and not d.in_zone(0, -3 * K.M), "deep")
	d.zone = Drill.ZONE_LEFT
	check(d.in_zone(-1, -3 * K.M) and not d.in_zone(500000, -3 * K.M), "left")


func test_drill_deterministic() -> void:
	var a := _drill(Drill.SHOT_MIX, Drill.TARGET_RANDOM)
	var b := _drill(Drill.SHOT_MIX, Drill.TARGET_RANDOM)
	for i in 3000:
		(a[0] as Sim).step([(a[1] as Bot).input()])
		(b[0] as Sim).step([(b[1] as Bot).input()])
	eq((a[0] as Sim).snapshot(), (b[0] as Sim).snapshot(), "same drill")


func test_every_lesson_can_be_passed() -> void:
	for i in Lessons.count():
		var cfg := SimTypes.MatchConfig.new()
		cfg.drill = Lessons.drill(i)
		var sim := Sim.new(cfg)
		var bot := Bot.new(sim, 0)
		var t := 0
		while t < 15000 and sim.drill.stage != Drill.DONE:
			sim.step([bot.input()])
			t += 1
		eq(sim.drill.stage, Drill.DONE, "the bot passes %s (%d good of %d fed)" % [
			Lessons.lesson(i)["id"], sim.drill.good, sim.drill.feeds])


## Where a feed reaches you: [seconds after the feed, m/s, height m, apex m]
## at z = pz, or the bounce [seconds, z m, apex m] with `bounce`.
func _feed_reach(shot: int, pz: int, speed: int, at: int, bounce := false) -> Array:
	var d := Drill.new()
	d.shot = shot
	d.spot_z = pz
	d.speed = speed
	d.machine_at = at
	var cfg := SimTypes.MatchConfig.new()
	cfg.drill = d
	var sim := Sim.new(cfg)
	var h := SimTypes.HumanInput.new()
	h.head_z = pz
	h.paddle_z = 9 * K.M
	var fed := -1
	var top := 0
	for i in 900:
		sim.step([h])
		for e in sim.drain_events():
			if e[0] == K.EVENT_FEED:
				fed = sim.tick
			elif bounce and e[0] == K.EVENT_BOUNCE and fed > 0:
				return [(sim.tick - fed) / 120.0, e[2] / 1e6, top / 1e6]
		if fed > 0:
			top = maxi(top, sim.ball.y)
			if not bounce and sim.ball.z >= pz:
				return [(sim.tick - fed) / 120.0, sim.ball.speed() * 120 / 1e6, sim.ball.y / 1e6, top / 1e6]
	return []


func test_drives_at_the_net_come_through_the_air_fast() -> void:
	var r := _feed_reach(Drill.SHOT_DRIVE, 2500000, 1, Drill.AT_AUTO)
	check(r[1] > 9.0, "MEDIUM reaches you fast: %.1f m/s" % r[1])
	check(r[2] > 0.7 and r[2] < 1.4, "waist to chest high: %.2f m" % r[2])
	check(r[3] < 2.2, "not a lob: apex %.2f m" % r[3])
	var b := _feed_reach(Drill.SHOT_DRIVE, 2500000, 3, Drill.AT_KITCHEN)
	check(b[0] < 0.4, "BLAZING from the kitchen: %.2f s to react" % b[0])
	var back := _feed_reach(Drill.SHOT_DRIVE, 6200000, 1, Drill.AT_AUTO)
	check(back[2] < 1.0, "at the baseline it still bounces up to you: %.2f m" % back[2])


func test_dinks_come_from_the_kitchen_and_land_in_yours() -> void:
	var d := Drill.new()
	d.shot = Drill.SHOT_DINK
	eq(d.machine_spot(), Drill.KITCHEN_Z, "AUTO: dinks from the far kitchen line")
	d.shot = Drill.SHOT_DRIVE
	eq(d.machine_spot(), Drill.BASELINE_Z, "AUTO: drives from the baseline")
	var r := _feed_reach(Drill.SHOT_DINK, 2500000, 1, Drill.AT_AUTO, true)
	check(r[1] > 0.5 and r[1] < K.KITCHEN_DEPTH / 1e6, "lands in your kitchen: z %.2f" % r[1])
	check(r[2] < 1.7, "a dink's arc: apex %.2f m" % r[2])


func test_a_slow_return_still_counts() -> void:
	# The bug: the machine gave up 3.5 s after the feed, so a slow dink
	# rally was called OUT before the return came down.
	var m := _drill(Drill.SHOT_DINK, Drill.TARGET_AT_YOU)
	var sim: Sim = m[0]
	var bot: Bot = m[1]
	sim.drill.spot_z = 2500000
	bot.head_z = 2500000
	sim.drill.zone = Drill.ZONE_KITCHEN
	bot.miss = 0                     # no deliberate wide ones: only the timer could call OUT
	var r := _results(sim, bot, 5000)
	check(not r.has(Drill.RESULT_OUT), "no dink called OUT: %s" % str(r))
	check(r.count(Drill.RESULT_GOOD) * 10 >= r.size() * 6, "mostly good dinks: %s" % str(r))


func test_a_netted_soft_shot_is_rescued_into_their_kitchen() -> void:
	var cfg := SimTypes.MatchConfig.new()
	cfg.assist = K.ASSIST_MID
	var sim := Sim.new(cfg)
	sim.phase = K.PHASE_LIVE
	sim.ball.held = false
	sim.ball.place(0, 300000, 2 * K.M)
	var v := sim._assist(0, [0, 5000, -35000])     # a soft push, straight into the net
	sim.ball.launch(v[0], v[1], v[2])
	var l: Array[int] = Aim.landing(sim.ball)
	check(l[3] == 0 and l[2] < 0 and -l[2] <= K.KITCHEN_DEPTH, "drops into their kitchen: %s" % str(l))
