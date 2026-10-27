## The match on screen: it boots in flat mode, plays, and never writes to
## the sim (a bare sim fed the same inputs ends in the same state).
extends TestSuite


func _view(demo: bool) -> MatchView:
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(SimTypes.MatchConfig.new(), false, demo)
	return v


func test_view_never_writes_to_the_sim() -> void:
	var v := _view(true)
	for i in 3000:
		v._process(MatchView.DT)
	check(v.sim.tick >= 2990, "the view stepped the sim: %d" % v.sim.tick)
	var bare := Sim.new(SimTypes.MatchConfig.new())
	for a in v.input_log:
		bare.step([SimTypes.HumanInput.from_array(a)])
	eq(bare.snapshot(), v.sim.snapshot(), "view and bare sim agree")
	v.queue_free()


func test_demo_scores_points() -> void:
	var v := _view(true)
	var scored := false
	for i in 30000:
		v._process(MatchView.DT)
		if v.sim.score[0] + v.sim.score[1] > 0:
			scored = true
			break
	check(scored, "a point in the demo within four minutes")
	v.queue_free()


func test_flat_mode_serves_on_space_only() -> void:
	var v := _view(false)
	for i in 400:
		v._process(MatchView.DT)
	eq(v.sim.phase, K.PHASE_SERVE, "waiting on the server")
	v.bot.serve_now = true
	for i in 200:
		v._process(MatchView.DT)
	check(v.sim.phase == K.PHASE_LIVE or v.sim.phase == K.PHASE_POINT_RESULT, "served: phase %d" % v.sim.phase)
	v.queue_free()


func test_new_match_command() -> void:
	var v := _view(true)
	for i in 600:
		v._process(MatchView.DT)
	v.command([K.CMD_NEW_MATCH])
	v._process(MatchView.DT)
	eq(v.sim.tick, 1, "a fresh match")
	eq(v.sim.score, [0, 0] as Array[int], "from love")
	v.queue_free()


func test_main_scene_boots_flat() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main := scene.instantiate()
	runner.root.add_child(main)
	check(main.view != null, "a match view")
	check(main.view.flat != null and main.view.xr == null, "flat mode with no headset")
	main.queue_free()
