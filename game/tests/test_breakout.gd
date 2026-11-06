## BRICK BREAK (ADR-030): the wall returns every ball to you, bricks break,
## missed balls cost one of three, levels clear, and the bot can play it.
extends TestSuite


func _game(level := 0, assist := K.ASSIST_MID, difficulty := 1) -> Sim:
	var cfg := SimTypes.MatchConfig.new()
	cfg.assist = assist
	cfg.breakout = Breakout.new()
	cfg.breakout.start_level = level
	cfg.breakout.difficulty = difficulty
	return Sim.new(cfg)


func _events(sim: Sim, kind: int) -> Array:
	return sim.drain_events().filter(func(e: Array) -> bool: return e[0] == kind)


## The ball on its way to the wall from where you'd hit it, at (x, y).
func _send(sim: Sim, x: int, y: int) -> void:
	var bo := sim.breakout
	bo.stage = Breakout.GOING
	bo.stage_at = sim.tick
	sim.set_phase(K.PHASE_LIVE)
	sim.last_hitter = 0
	sim.ball.place(0, 900000, 4000000)
	var v := Aim.through(0, 900000, 4000000, x, y, Breakout.WALL_Z, 100000)
	sim.ball.launch(v[0], v[1], v[2])


func _step_until(sim: Sim, cond: Callable, limit := 2000) -> int:
	for i in limit:
		if cond.call():
			return i
		sim.step([null])
	return -1


func test_the_first_level() -> void:
	var sim := _game()
	var bo := sim.breakout
	eq(sim.active_slots(), [0] as Array[int], "you alone")
	eq(bo.hp.size(), Breakout.COLS * Breakout.ROWS, "a full grid")
	eq(bo.bricks_left, 21, "three rows of seven")
	eq(bo.hp.slice(0, 7), [1, 1, 1, 1, 1, 1, 1], "the bottom row: one hit each")
	eq(bo.hp[Breakout.COLS * 3], 0, "nothing above the third row")
	eq(bo.lives, Breakout.LIVES, "three balls")
	check(sim.ball.held and sim.phase == K.PHASE_SERVE, "a ball waits at the launcher")
	near(sim.ball.z, Breakout.WALL_Z, 100000, "at the wall")
	var l4 := Breakout.new()
	l4.load_level(3)
	eq(l4.hp[Breakout.COLS * 5 + 1], Breakout.STEEL, "level 4's top row has steel")
	eq(l4.bricks_left, 7 * 6 - 3, "steel isn't counted to clear")


func test_the_launcher_feeds_you() -> void:
	var sim := _game()
	var ticks := _step_until(sim, func() -> bool: return sim.breakout.stage == Breakout.COMING)
	near(ticks, Breakout.FIRST_HOLD, 2, "after the hold")
	eq(sim.last_hitter, 2, "the bot sees it coming")
	var l := Aim.landing(sim.ball)
	check(l[3] == 0 and K.in_court(l[1], l[2]) and l[2] > 0, "it lands in your court: %s" % str(l))


func test_a_brick_breaks_and_the_ball_comes_back() -> void:
	var sim := _game()
	var bo := sim.breakout
	sim.drain_events()
	var at := Breakout.brick_at(9)       # the second row, third brick
	_send(sim, at[0], at[1])
	_step_until(sim, func() -> bool: return bo.stage != Breakout.GOING)
	eq(bo.stage, Breakout.COMING, "back to you")
	eq(bo.hp[9], 0, "broken")
	eq(bo.bricks_left, 20, "one fewer")
	eq(bo.score, Breakout.HIT_POINTS + Breakout.BREAK_POINTS + Breakout.ROW_POINTS, "scored")
	var bricks := _events(sim, K.EVENT_BRICK)
	eq(bricks.size(), 1, "one brick event")
	eq(bricks[0].slice(1, 3), [9, 0], "brick 9, nothing left of it")
	check(sim.ball.vz > 0, "coming back")
	var l := Aim.landing(sim.ball)
	check(l[3] == 0, "over the net")
	check(l[2] >= Breakout.RETURN_NEAR - 300000 and l[2] <= Breakout.RETURN_FAR + 300000,
		"lands in the return band: %d" % l[2])
	check(absi(l[1]) <= K.COURT_HALF_WIDTH - Breakout.RETURN_MARGIN + 100000, "inside the sidelines: %d" % l[1])


func test_the_angle_carries_on() -> void:
	# A ball to the wall's right comes back further right (mirrored, as off
	# a breakout paddle); one to its left, left.
	for s in [-1, 1]:
		var sim := _game()
		var bo := sim.breakout
		var at := Breakout.brick_at(s * 2 + 3)   # bottom row, two off the middle
		_send(sim, at[0], at[1])
		_step_until(sim, func() -> bool: return bo.stage != Breakout.GOING)
		var l := Aim.landing(sim.ball)
		check(l[1] * s > absi(at[0]), "side %d: lands at %d, out past %d" % [s, l[1], at[0]])


func test_high_comes_back_deep() -> void:
	var depth := []
	for i in [3, 3 + Breakout.COLS * 2]:
		var sim := _game()
		var bo := sim.breakout
		var at := Breakout.brick_at(i)
		_send(sim, at[0], at[1])
		_step_until(sim, func() -> bool: return bo.stage != Breakout.GOING)
		depth.append(Aim.landing(sim.ball)[2])
	check(depth[1] > depth[0] + 300000, "higher on the wall, deeper back: %s" % str(depth))


func test_the_glass_and_the_wall_behind() -> void:
	var sim := _game()
	var bo := sim.breakout
	sim.drain_events()
	# Over the bricks: the wall behind sends it back, no brick touched.
	_send(sim, 0, Breakout.BRICK_TOP + 400000)
	_step_until(sim, func() -> bool: return bo.stage != Breakout.GOING)
	eq(bo.stage, Breakout.COMING, "back off the wall")
	eq(bo.bricks_left, 21, "no brick")
	var walls := _events(sim, K.EVENT_WALL)
	check(walls.size() == 1 and walls[0][3] == 0, "off the back wall: %s" % str(walls))
	# Wide: off the glass, and on to the wall.
	_send(sim, K.COURT_HALF_WIDTH * 2, 700000)
	var crossed := false
	for i in 400:
		sim.step([null])
		crossed = crossed or absi(sim.ball.x) > K.COURT_HALF_WIDTH
		if bo.stage != Breakout.GOING:
			break
	check(not crossed, "never through the glass")
	eq(bo.stage, Breakout.COMING, "it still reaches the wall")
	var glass := _events(sim, K.EVENT_WALL).filter(func(e: Array) -> bool: return e[3] == 1)
	eq(glass.size(), 1, "one off the glass")


func test_three_misses_and_its_over() -> void:
	var sim := _game()
	var bo := sim.breakout
	var lost := 0
	var over: Array = []
	for i in 120 * 60:
		sim.step([null])                 # nobody swings
		for e in sim.drain_events():
			if e[0] == K.EVENT_LOST:
				lost += 1
				eq(e[1], Breakout.LOST_MISSED, "missed")
				eq(e[2], Breakout.LIVES - lost, "balls left")
			if e[0] == K.EVENT_GAME_OVER:
				over = e
		if bo.stage == Breakout.OVER:
			break
	eq(lost, Breakout.LIVES, "every ball lost")
	eq(sim.phase, K.PHASE_MATCH_RESULT, "game over")
	check(not over.is_empty(), "the game over event")
	sim.step([null], [[K.CMD_NEW_MATCH]])
	eq(bo.lives, Breakout.LIVES, "a new game")
	eq(bo.bricks_left, 21, "the wall rebuilt")


func test_into_the_net_costs_a_ball() -> void:
	var sim := _game()
	var bo := sim.breakout
	bo.stage = Breakout.GOING
	bo.stage_at = sim.tick
	sim.set_phase(K.PHASE_LIVE)
	sim.ball.place(0, 300000, 2000000)
	sim.ball.launch(0, 0, -60000)
	sim.drain_events()
	_step_until(sim, func() -> bool: return bo.stage != Breakout.GOING)
	eq(bo.stage, Breakout.LOST, "lost")
	eq(bo.last_lost, Breakout.LOST_NET, "in the net")
	eq(bo.lives, Breakout.LIVES - 1, "a ball gone")


func test_the_assist_finds_the_wall() -> void:
	# A soft, flat push that would die in the net reaches the wall with the
	# assist, in the bricks' band.
	var sim := _game(0, K.ASSIST_FULL)
	sim.ball.place(0, 800000, 4500000)
	var v := sim.breakout.assist(sim, [0, 3000, -40000])
	var b := sim.ball.copy()
	b.launch(v[0], v[1], v[2])
	var y := -1
	for i in 400:
		var ev := b.step()
		if ev & Ball.EV_NET:
			break
		if b.z <= Breakout.WALL_Z:
			y = b.y
			break
	check(y >= Breakout.BRICK_BOTTOM and y <= Breakout.BRICK_TOP, "met the wall in the bricks: %d" % y)
	var off := _game(0, K.ASSIST_OFF)
	eq(off.breakout.assist(off, [0, 3000, -40000]), [0, 3000, -40000] as Array[int], "OFF leaves it alone")


func test_the_bot_clears_a_level() -> void:
	var sim := _game()
	var bot := Bot.new(sim, 0)
	var cleared := -1
	for i in 120 * 120:
		sim.step([bot.input()])
		for e in sim.drain_events():
			if e[0] == K.EVENT_LEVEL:
				cleared = e[1]
		if cleared > 0:
			break
	eq(cleared, 1, "level 1 cleared within two minutes")
	check(sim.breakout.lives > 0, "with a ball to spare")
	_step_until(sim, func() -> bool: return sim.breakout.stage == Breakout.SERVE, Breakout.CLEAR_TICKS + 10)
	eq(sim.breakout.level, 1, "on to level 2")
	eq(sim.breakout.bricks_left, 28, "its wall")


func test_same_inputs_same_game() -> void:
	var a := _game(2)
	var b := _game(2)
	var bot := Bot.new(a, 0)
	var inputs: Array = []
	for i in 3000:
		var h := bot.input()
		inputs.append(h.to_array())
		a.step([h])
	var mid := b.save_state()
	for i in 1500:
		b.step([SimTypes.HumanInput.from_array(inputs[i])])
	var saved := b.save_state()
	var c := _game(2)
	c.load_state(saved)
	for i in range(1500, 3000):
		b.step([SimTypes.HumanInput.from_array(inputs[i])])
		c.step([SimTypes.HumanInput.from_array(inputs[i])])
	eq(b.snapshot(), a.snapshot(), "replayed exactly")
	eq(c.snapshot(), a.snapshot(), "and from a saved state")
	check(mid.size() == 5 and not (mid[4] as Dictionary).is_empty(), "the state carries the wall")
	check(a.breakout.hits > 0, "it was played")


func test_the_view_draws_the_wall() -> void:
	var cfg := SimTypes.MatchConfig.new()
	cfg.breakout = Breakout.new()
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(cfg, false, true)
	check(v.brick_wall != null and v.machine == null, "the wall, no machine")
	check(not v.crowd.visible, "no crowd")
	for i in 2400:
		v._process(MatchView.DT)
	check(v.sim.tick >= 2390, "it played")
	check(v.sim.breakout.broken > 0, "the demo breaks bricks")
	var bare := Sim.new(cfg)
	for a in v.input_log:
		bare.step([SimTypes.HumanInput.from_array(a)])
	eq(bare.snapshot(), v.sim.snapshot(), "view and bare sim agree")
	v.queue_free()


func test_lobby_to_brick_break_and_back() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	check(main.menu.row("to_breakout").size() > 0, "on MAIN")
	main.lobby("breakout")
	check(main.view.sim.breakout != null and main.view.spectate, "the page demos the wall")
	main.menu.select("blevel")
	main.menu.change(1)
	eq(main.settings.breakout_level, 1, "level 2 chosen")
	main._start(main.settings.breakout_config(), false)
	eq(main.view.sim.breakout.level, 1, "starts on level 2")
	main.view.sim.breakout.score = 1234
	main._on_breakout_over(1234, 2)
	eq(main.settings.breakout_best, 1234, "the best kept")
	eq(main.view.menu.title, "NEW BEST!   1234", "the game over menu")
	main._on_pressed("again")
	main.view._process(MatchView.DT)
	eq(main.view.sim.breakout.score, 0, "PLAY AGAIN: a new game")
	eq(main._back_page(), "breakout", "MENU goes back to BRICK BREAK")
	main.queue_free()
