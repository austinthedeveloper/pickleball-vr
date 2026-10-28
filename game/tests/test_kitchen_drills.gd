## The kitchen drills (ADR-017): CALL THE SPOT, LINE AND CROSS, VOLLEY
## DINKS and ATTACK OR DINK; and the swing log's mode names. Dartboards
## and the kitchen lean (ADR-019).
extends TestSuite


func _drill(kind: int, level := 1) -> Array:
	var s := Settings.new()
	s.partner_drill = kind
	s.partner_level = level
	var sim := Sim.new(s.partner_config())
	return [sim, Bot.new(sim, 0)]


func _run(m: Array, ticks: int) -> Dictionary:
	var sim: Sim = m[0]
	var bot: Bot = m[1]
	var res := {}
	for i in ticks:
		sim.step([bot.input()])
		for e in sim.drain_events():
			if e[0] == K.EVENT_DRILL:
				res[e[1]] = res.get(e[1], 0) + 1
	return res


func test_every_kitchen_drill_is_playable() -> void:
	for kind in [Drill.KIND_SPOTS, Drill.KIND_LANES, Drill.KIND_VOLLEYS, Drill.KIND_ATTACK]:
		for level in [0, 2]:
			var m := _drill(kind, level)
			_run(m, 12000)
			var d: Drill = (m[0] as Sim).drill
			check(d.good >= 20 and d.best >= 5, "%s %s: %d good, best %d" % [Drill.KIND_NAMES[kind],
				Drill.PACE_NAMES[level], d.good, d.best])


func test_kitchen_drills_are_deterministic() -> void:
	for kind in [Drill.KIND_SPOTS, Drill.KIND_LANES, Drill.KIND_VOLLEYS, Drill.KIND_ATTACK]:
		var a := _drill(kind, 2)
		var b := _drill(kind, 2)
		_run(a, 3000)
		_run(b, 3000)
		eq((a[0] as Sim).snapshot(), (b[0] as Sim).snapshot(), "%s: same run" % Drill.KIND_NAMES[kind])


func test_the_spot_lights_later_each_level() -> void:
	# EASY as they hit, MEDIUM as it crosses the net, HARD as it bounces.
	for level in 3:
		var m := _drill(Drill.KIND_SPOTS, level)
		var sim: Sim = m[0]
		var bot: Bot = m[1]
		var lit_at := []                 # where the ball was when the spot lit
		var was := false
		var spots := []
		var lit_on_hit := 0
		for i in 6000:
			sim.step([bot.input()])
			for e in sim.drain_events():
				if e[0] == K.EVENT_HIT and e[1] == 2:
					spots.append(sim.drill.spot_i)
					if sim.drill.spot_lit:
						lit_on_hit += 1
			var d := sim.drill
			if d.spot_lit and not was and d.stage == Drill.FLY:
				lit_at.append([sim.ball.z, d.bounces])
			was = d.spot_lit
		if level == 0:
			check(spots.size() >= 5 and lit_on_hit == spots.size(), "EASY: lit as they hit, every time")
		else:
			check(lit_at.size() >= 5, "%s: spots lit" % Drill.PACE_NAMES[level])
		for l: Array in lit_at:
			match level:
				0: check(l[0] < 0, "EASY: lit on their side, as they hit")
				1: check(l[0] > 0 and l[0] < 300000 and l[1] == 0, "MEDIUM: lit at the net: %s" % str(l))
				2: check(l[1] == 1, "HARD: lit at the bounce")
		for i in range(1, spots.size()):
			check(spots[i] != spots[i - 1], "never the same spot twice running")
		if asserts > 80:
			asserts = 80


func test_placing_is_judged() -> void:
	var d := Drill.new()
	d.partner = true
	d.zone = Drill.ZONE_KITCHEN
	d.kind = Drill.KIND_SPOTS
	d.partner_pace = 1
	d.target_x = 1500000
	d.target_z = -1000000
	eq(d._placed(1700000, -1100000), Drill.RESULT_GOOD, "on the spot")
	eq(d._placed(-1500000, -1000000), Drill.RESULT_SPOT, "in the kitchen, off the spot")
	eq(d._placed(0, -4000000), Drill.RESULT_ZONE, "deep")
	d.kind = Drill.KIND_LANES
	eq(d._placed(800000, -1500000), Drill.RESULT_GOOD, "in the lane")
	eq(d._placed(-800000, -1500000), Drill.RESULT_LANE, "the other lane")
	d.kind = Drill.KIND_ATTACK
	d.high_ball = true
	d.you_fast = true
	eq(d._placed(0, -4000000), Drill.RESULT_GOOD, "a high one put away, deep is fine")
	d.you_fast = false
	eq(d._placed(0, -1000000), Drill.RESULT_ATTACK, "a high one dinked")
	d.high_ball = false
	eq(d._placed(0, -1000000), Drill.RESULT_GOOD, "a low one dinked")
	d.you_fast = true
	eq(d._placed(0, -4000000), Drill.RESULT_PATIENT, "a low one sped up")


func test_lanes_alternate_or_stay() -> void:
	for lane in 3:
		var s := Settings.new()
		s.partner_drill = Drill.KIND_LANES
		s.partner_lane = lane
		var sim := Sim.new(s.partner_config())
		var bot := Bot.new(sim, 0)
		var xs := []
		for i in 6000:
			sim.step([bot.input()])
			for e in sim.drain_events():
				if e[0] == K.EVENT_HIT and e[1] == 2:
					xs.append(signi(sim.drill.target_x))
		check(xs.size() >= 6, "%s: lanes called" % Drill.LANE_NAMES[lane])
		var you := signi(sim.drill.spot_x)
		match lane:
			Drill.LANE_LINE: check(xs.all(func(x: int) -> bool: return x == you), "LINE: straight ahead")
			Drill.LANE_CROSS: check(xs.all(func(x: int) -> bool: return x == -you), "CROSS: the diagonal")
			_:
				for i in range(1, xs.size()):
					check(xs[i] == -xs[i - 1], "ALTERNATE: line, cross, line")
		if asserts > 60:
			asserts = 60


## Standing on the drill's spot, the paddle down at your feet: playing nothing.
func _stand(d: Drill) -> SimTypes.HumanInput:
	var h := SimTypes.HumanInput.new()
	h.head_x = d.spot_x
	h.head_z = d.spot_z
	h.paddle_x = d.spot_x + 2 * K.M
	h.paddle_z = d.spot_z + 2 * K.M
	return h


func test_volley_dinks_must_be_volleyed() -> void:
	var m := _drill(Drill.KIND_VOLLEYS)
	var sim: Sim = m[0]
	check(sim.drill.rules & Drill.RULE_VOLLEY and sim.drill.rules & Drill.RULE_KITCHEN, "out of the air, not from the kitchen")
	# Let one go: it bounces, and that's called.
	var got := -1
	for i in 2000:
		sim.step([_stand(sim.drill)])
		for e in sim.drain_events():
			if e[0] == K.EVENT_DRILL and got < 0:
				got = e[1]
	eq(got, Drill.RESULT_MISSED, "an unplayed floater")
	# The floater passes your line about waist high.
	var m2 := _drill(Drill.KIND_VOLLEYS, 0)
	var s2: Sim = m2[0]
	var heights := []
	var z0 := 0
	for i in 3000:
		z0 = s2.ball.z
		s2.step([_stand(s2.drill)])
		if s2.drill.stage == Drill.FLY and z0 < s2.players[0].z and s2.ball.z >= s2.players[0].z:
			heights.append(s2.ball.y)
	check(heights.size() >= 2, "floaters came")
	for y: int in heights:
		check(y > 600000 and y < 1100000, "waist high at your line: %d" % y)


func test_attack_or_dink_mixes_high_and_low() -> void:
	var m := _drill(Drill.KIND_ATTACK, 0)
	var sim: Sim = m[0]
	var bot: Bot = m[1]
	var high := 0
	var low := 0
	var peaks_high := []
	var peaks_low := []
	var peak := 0
	for i in 12000:
		sim.step([bot.input()])
		if sim.drill.stage == Drill.FLY:
			peak = maxi(peak, sim.ball.y)
		for e in sim.drain_events():
			if e[0] == K.EVENT_HIT and e[1] == 2:
				peak = 0
				if sim.drill.high_ball:
					high += 1
				else:
					low += 1
			elif e[0] == K.EVENT_HIT and e[1] == 0:
				(peaks_high if sim.drill.high_ball else peaks_low).append(peak)
	check(high >= 5 and low >= high, "some high, mostly low: %d high, %d low" % [high, low])
	var mh: int = peaks_high.reduce(func(a: int, b: int) -> int: return a + b, 0) / maxi(peaks_high.size(), 1)
	var ml: int = peaks_low.reduce(func(a: int, b: int) -> int: return a + b, 0) / maxi(peaks_low.size(), 1)
	check(mh > ml + 300000, "the high ones are clearly higher on EASY: %d against %d" % [mh, ml])


func test_the_lane_row_and_mode_names() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	main.lobby("partner")
	check(main.menu.row("lane").is_empty(), "no LANE for DINKS")
	main.menu.select("drill")
	main.menu.change(Drill.KIND_LANES)
	main.lobby()
	check(main.menu.row("lane").size() > 0, "LANE for LINE AND CROSS")
	main._start(main.settings.partner_config(), false)
	check(main.view.zone_mesh != null, "the lane drawn")
	main.queue_free()
	var s := Settings.new()
	s.partner_drill = Drill.KIND_SPOTS
	s.partner_level = 2
	eq(s.partner_config().drill.mode_name(), "CALL THE SPOT HARD", "the log's mode")
	s.partner_drill = Drill.KIND_LANES
	s.partner_lane = Drill.LANE_CROSS
	eq(s.partner_config().drill.mode_name(), "LINE AND CROSS HARD CROSS", "with the lane")
	eq(s.machine_config().drill.mode_name(), "MACHINE DRIVE MEDIUM", "the machine")


func test_dartboard_rings_score() -> void:
	var r := 900000
	eq(Drill.ring(0, r), 3, "dead centre: the bullseye")
	eq(Drill.ring(r * 33 / 100, r), 3, "the bullseye's edge")
	eq(Drill.ring(r / 2, r), 2, "the inner ring")
	eq(Drill.ring(r * 9 / 10, r), 1, "the outer ring")
	eq(Drill.ring(r + 1, r), 0, "off the board")
	# A spot: on the board is good and scores its ring; off it isn't.
	var d := Drill.new()
	d.partner = true
	d.zone = Drill.ZONE_KITCHEN
	d.kind = Drill.KIND_SPOTS
	d.partner_pace = 1
	d.target_x = 1500000
	d.target_z = -1000000
	eq(d._placed(1500000, -1000000), Drill.RESULT_GOOD, "the bullseye")
	eq(d.points, 3, "3 points")
	eq(d._placed(1500000 + 700000, -1000000), Drill.RESULT_GOOD, "70 cm off: the outer ring, still on")
	eq(d.points, 4, "and 1 more")
	eq(d._placed(1500000 + 900000, -1000000), Drill.RESULT_SPOT, "90 cm off: off the board at MEDIUM")
	eq(d.last_ring, 0, "no ring")
	check(Drill.SPOT_RADIUS[0] > Drill.SPOT_RADIUS[2], "the board shrinks as it gets harder")


func test_leaning_over_the_kitchen_line_is_not_a_fault() -> void:
	var d := Drill.new()
	var p := SimTypes.Player.new()
	p.x = 0
	p.z = K.KITCHEN_DEPTH + 100000
	check(not d.in_kitchen(p), "behind the line")
	p.z = K.KITCHEN_DEPTH - 300000
	check(not d.in_kitchen(p), "head 30 cm over the line: leaning, not in")
	p.z = K.KITCHEN_DEPTH - 600000
	check(d.in_kitchen(p), "head 60 cm in: you stepped in")
