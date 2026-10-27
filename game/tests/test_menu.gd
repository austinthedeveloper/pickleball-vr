## MATCH SETUP: the menu panel, the saved settings, the lobby's flow.
extends TestSuite


func _menu() -> Menu3D:
	var m := Menu3D.new()
	m.title = "TEST"
	m.add_row("mode", "MODE", ["SINGLES", "DOUBLES"])
	m.add_row("points", "POINTS", ["5", "7", "11"])
	m.add_row("play", "PLAY")
	runner.root.add_child(m)
	return m


func test_rows_by_id() -> void:
	var m := _menu()
	m.select("points")
	m.change(1)
	eq(m.value("points"), 1, "stepped")
	m.change(-2)
	eq(m.value("points"), 2, "wraps")
	var got := []
	m.pressed.connect(func(id: String) -> void: got.append(id))
	m.select("play")
	m.press()
	eq(got, ["play"], "PLAY pressed")
	m.queue_free()


func test_pointing_picks_the_row() -> void:
	var m := _menu()
	m.global_position = Vector3(0, 1.5, 0)
	# Labels face +z: point from in front at the second row.
	var y := 1.5 - Menu3D.ROW_H * 1.9
	eq(m.row_at(Vector3(0, y, 2), Vector3(0, 0, -1)), 1, "row 1")
	eq(m.row_at(Vector3(3, y, 2), Vector3(0, 0, -1)), -1, "off the panel")
	eq(m.row_at(Vector3(0, y, 2), Vector3(0, 0, 1)), -1, "pointing away")
	m.point(Vector3(0, 1.5 - Menu3D.ROW_H * 0.9, 2), Vector3(0, 0, -1), true)
	eq(m.value("mode"), 1, "a click steps a value row")
	m.queue_free()


func test_settings_round_trip() -> void:
	var s := Settings.new()
	s.doubles = true
	s.opponent = 7
	s.assist = 0
	s.points = 2
	s.left_handed = true
	s.save()
	var t := Settings.new()
	t.load_settings()
	check(t.doubles and t.opponent == 7 and t.assist == 0 and t.points == 2 and t.left_handed, "kept")
	var cfg := t.match_config()
	check(cfg.doubles, "doubles")
	eq(cfg.points_to_win, 11, "points")
	eq(cfg.assist, K.ASSIST_OFF, "assist")
	eq(cfg.opponent, 7, "the CHAMPS")
	check(cfg.styles[2] != null and cfg.styles[3] != null, "both opponents styled")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.path))


func test_ladder_imported() -> void:
	eq(Opponents.names().size(), 8, "eight teams")
	eq(Opponents.names()[0], "HENDERSON", "the first rung")
	var champs := SimTypes.CpuStyle.from_dict(Opponents.player(7, 2)["style"])
	var dad := SimTypes.CpuStyle.from_dict(Opponents.player(0, 2)["style"])
	check(champs.error < dad.error and champs.speed > dad.speed, "the CHAMPS outplay DAD")


func test_lobby_to_match_and_back() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	check(main.view.spectate and main.menu != null, "the lobby: a demo and MATCH SETUP")
	main.menu.select("mode")
	main.menu.change(1)
	check(main.settings.doubles, "doubles chosen")
	main.lobby()                     # what the deferred call does
	eq(main.view.sim.active_slots().size(), 4, "the lobby demo is doubles")
	main._start(false)
	check(not main.view.spectate and main.view.sim.config.doubles, "a doubles match")
	main._on_match_over(1)
	check(main.view.menu != null and main.view.menu.visible, "the end-of-match menu")
	main._on_pressed("rematch")
	main.view._process(MatchView.DT)
	eq(main.view.sim.tick, 1, "REMATCH: a new match")
	main.lobby()
	check(main.view.spectate, "back to the lobby")
	main.queue_free()
