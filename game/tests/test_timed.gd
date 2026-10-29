## Timed runs and records (ADR-022): MODE sets a clock, the run ends with a
## score (good balls plus dartboard points), and every run is kept.
extends TestSuite


func _timed(kind: int, seconds: int) -> Array:
	var s := Settings.new()
	s.partner_drill = kind
	s.partner_time = Drill.TIMES.find(seconds)
	var sim := Sim.new(s.partner_config())
	return [sim, Bot.new(sim, 0)]


func test_the_clock_ends_the_run_with_a_score() -> void:
	var m := _timed(Drill.KIND_SPOTS, 60)
	var sim: Sim = m[0]
	var d := sim.drill
	eq(d.time_limit, 60 * K.TICK_HZ, "1 MIN")
	var ups := []
	var results_after := 0
	for i in 60 * K.TICK_HZ + 600:
		sim.step([(m[1] as Bot).input()])
		for e in sim.drain_events():
			if e[0] == K.EVENT_TIME_UP:
				ups.append(e)
				eq(sim.tick, d.ends_at, "on the minute")
			elif e[0] == K.EVENT_DRILL and not ups.is_empty():
				results_after += 1
	eq(ups.size(), 1, "time's up once")
	eq(d.stage, Drill.DONE, "the run is over")
	check(d.good > 0 and d.points > 0, "the bot scored: %d good, %d points" % [d.good, d.points])
	eq(ups[0][1], d.good + d.points, "the score: good balls plus the board's points")
	eq(results_after, 0, "nothing counts after the clock")
	eq(d.time_left(sim), 0, "no time left")


func test_free_play_runs_forever() -> void:
	var m := _timed(Drill.KIND_DINKS, 0)
	var sim: Sim = m[0]
	for i in 200 * K.TICK_HZ:
		sim.step([(m[1] as Bot).input()])
	check(sim.drill.stage != Drill.DONE and sim.drill.ends_at == -1, "FREE PLAY never ends")


func test_records_keep_every_run() -> void:
	var s := Settings.new()
	eq(s.add_run("X 1 MIN", 30, 20, 5, "2026-10-28 10:00"), [1, 1] as Array[int], "the first run is the best")
	eq(s.add_run("X 1 MIN", 25, 18, 4, "2026-10-28 10:05"), [2, 2] as Array[int], "a worse one places 2nd")
	eq(s.add_run("X 1 MIN", 41, 30, 9, "2026-10-28 10:10"), [1, 3] as Array[int], "a new best")
	eq(s.best_runs("X 1 MIN", 2).map(func(r: Array) -> int: return r[0]), [41, 30], "best first")
	eq(s.recent_scores("X 1 MIN"), [30, 25, 41] as Array[int], "the last runs, oldest first")
	for i in Settings.RUNS_KEPT + 10:
		s.add_run("Y", i, 0, 0, "")
	eq((s.records["Y"] as Array).size(), Settings.RUNS_KEPT, "only the last %d kept" % Settings.RUNS_KEPT)
	s.save()
	var t := Settings.new()
	t.load_settings()
	eq(t.recent_scores("X 1 MIN"), [30, 25, 41] as Array[int], "saved")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.path))


func test_run_names_tell_drills_apart() -> void:
	var a := Drill.new()
	a.partner = true
	a.kind = Drill.KIND_SPOTS
	a.partner_pace = 2
	a.time_limit = 120 * K.TICK_HZ
	eq(Settings.run_name(a), "CALL THE SPOT HARD 2 MIN", "drill, level, time")
	a.kind = Drill.KIND_DINKS
	a.targets = true
	eq(Settings.run_name(a), "DINKS HARD TARGETS 2 MIN", "targets count separately")


func test_mode_row_time_up_screen_and_records() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	main.lobby("partner")
	main.menu.select("ptime")
	main.menu.change(1)
	eq(main.settings.partner_time, 1, "MODE: 1 MIN")
	main.lobby()
	eq(main.view.sim.drill.time_limit, 0, "the lobby's demo still plays on")
	main._start(main.settings.partner_config(), false)
	eq(main.view.sim.drill.time_limit, 60 * K.TICK_HZ, "a timed run")
	main.view.sim.drill.good = 12
	main._on_time_up(12, 12, 4)
	eq(main.view.menu.title, "TIME!   SCORE 12", "the score")
	check(main.view.menu.row("again").size() > 0 and main.view.menu.row("lobby").size() > 0, "AGAIN or MENU")
	main._on_time_up(15, 15, 6)
	eq(main.view.menu.row("info_best")["label"], "NEW BEST!", "beaten")
	main._on_pressed("lobby")
	main.lobby("partner")
	main._on_pressed("to_records")
	main.lobby("records")
	check(String(main.menu.title).begins_with("RECORDS: DINKS"), "RECORDS for the drill set")
	check(String(main.menu.row("info_1")["label"]).contains("BEST 15  12"), "1 MIN's best runs")
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))
