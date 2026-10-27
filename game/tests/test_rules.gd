## The rules: serve box, two-bounce, the kitchen, out, scoring.
extends TestSuite


func _sim() -> Sim:
	var sim := Sim.new()
	return sim


func test_serve_box_is_diagonal() -> void:
	var sim := _sim()
	sim.serving_team = 0
	sim.score = [0, 0]                # even: from the right (+x for the near side)
	var spot := sim.serve_spot(0)
	check(spot[0] > 0 and spot[1] > K.COURT_HALF_LENGTH, "server behind the right baseline")
	check(sim.in_service_box(-1500000, -4 * K.M), "diagonal box in")
	check(not sim.in_service_box(1500000, -4 * K.M), "straight box out")
	check(not sim.in_service_box(-1500000, -K.KITCHEN_DEPTH), "kitchen line is short")
	check(sim.in_service_box(0, -4 * K.M), "the centreline is in")
	sim.score = [1, 0]
	check(sim.in_service_box(1500000, -4 * K.M), "odd score: the other box")


func test_far_side_serves_mirror() -> void:
	var sim := _sim()
	sim.serving_team = 1
	sim.score = [0, 0]
	var spot := sim.serve_spot(2)
	check(spot[0] < 0 and spot[1] < -K.COURT_HALF_LENGTH, "far server on their right")
	check(sim.in_service_box(1500000, 4 * K.M), "into the near side's right box")


func _rally_at(sim: Sim, hitter: int, required: int) -> void:
	sim.phase = K.PHASE_LIVE
	sim.last_hitter = hitter
	sim.required_bounce = required
	sim.serve_pending = false
	sim.bounce_count = 0
	sim.ball.held = false


func _bounce_at(sim: Sim, x: int, z: int) -> void:
	sim.ball.place(x, 50000, z)
	sim.ball.launch(0, -20000, 0)
	sim.step([])


func test_out_is_the_hitters_fault() -> void:
	var sim := _sim()
	_rally_at(sim, 2, K.REQUIRED_BOUNCE_NONE)
	_bounce_at(sim, 0, 7 * K.M)
	eq(sim.phase, K.PHASE_POINT_RESULT, "point over")
	eq(sim.point_winner, 0, "near side wins")
	eq(sim.last_fault, K.FAULT_OUT, "out")
	eq(sim.score, [1, 0] as Array[int], "rally scoring")


func test_lines_are_in() -> void:
	var sim := _sim()
	_rally_at(sim, 2, K.REQUIRED_BOUNCE_NONE)
	_bounce_at(sim, K.COURT_HALF_WIDTH, K.COURT_HALF_LENGTH)
	eq(sim.phase, K.PHASE_LIVE, "corner is in")


func test_two_bounces_lose() -> void:
	var sim := _sim()
	_rally_at(sim, 2, K.REQUIRED_BOUNCE_NONE)
	_bounce_at(sim, 0, 3 * K.M)
	_bounce_at(sim, 0, 3 * K.M)
	eq(sim.point_winner, 1, "far side wins")
	eq(sim.last_fault, K.FAULT_SECOND_BOUNCE, "two bounces")


func test_serve_into_wrong_box() -> void:
	var sim := _sim()
	_rally_at(sim, 0, K.REQUIRED_BOUNCE_SERVE)
	sim.serving_team = 0
	sim.serve_pending = true
	_bounce_at(sim, 1500000, -4 * K.M)
	eq(sim.last_fault, K.FAULT_WRONG_BOX, "wrong box")
	eq(sim.point_winner, 1, "receiver wins")


func test_serve_in_then_return_must_bounce() -> void:
	var sim := _sim()
	_rally_at(sim, 0, K.REQUIRED_BOUNCE_SERVE)
	sim.serving_team = 0
	sim.serve_pending = true
	_bounce_at(sim, -1500000, -4 * K.M)
	eq(sim.phase, K.PHASE_LIVE, "good serve")
	eq(sim.required_bounce, K.REQUIRED_BOUNCE_RETURN, "the return must bounce")
	check(sim.needs_bounce(0), "server waits")
	check(not sim.needs_bounce(1), "receiver may hit it")


func test_volley_from_the_kitchen_is_a_fault() -> void:
	var sim := _sim()
	_rally_at(sim, 2, K.REQUIRED_BOUNCE_NONE)
	var p := sim.players[0]
	p.x = 0
	p.z = 1 * K.M                     # in the near kitchen
	sim.bounce_count = 0
	check(not sim._rules_hit(0), "fault")
	eq(sim.last_fault, K.FAULT_KITCHEN, "kitchen")


func test_early_volley_on_the_return() -> void:
	var sim := _sim()
	_rally_at(sim, 2, K.REQUIRED_BOUNCE_SERVE)
	sim.serving_team = 1
	sim.players[0].z = 5 * K.M
	check(not sim._rules_hit(0), "fault")
	eq(sim.last_fault, K.FAULT_EARLY_VOLLEY, "volley")


func test_winning_and_win_by_two() -> void:
	var sim := _sim()
	sim.score = [5, 4]
	check(sim.team_won(0), "five wins")
	sim.config.win_by_2 = true
	check(not sim.team_won(0), "by two")
	sim.score = [6, 4]
	check(sim.team_won(0), "six-four")
