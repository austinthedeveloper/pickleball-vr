## Developer tuning (ADR-020): the tunables, their pages in the pause menu,
## the saved overrides, and that tune_sync.py can find each in the source.
extends TestSuite

const TEST_PATH := "user://test_tuning.cfg"


func _clean() -> void:
	Tune.reset()
	Tune.path = TEST_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_every_tunable_reads_and_steps() -> void:
	_clean()
	for e in Tune.ALL:
		var v := Tune.value(e[0])
		check(Tune.GROUPS.has(e[1]), "%s: a known group" % e[0])
		check(v >= int(e[8]) and v <= int(e[9]), "%s: its default %d is in range" % [e[0], v])
		check(Tune.steps(e[0]).has(v), "%s: its row can show the default" % e[0])
		check(Tune.text(e[0], v) != "", "%s reads as %s" % [e[0], Tune.text(e[0], v)])


func test_set_reset_save_load() -> void:
	_clean()
	var was := Tune.value("spot_medium")
	Tune.set_value("spot_medium", 600000)
	eq(Drill.SPOT_RADIUS[1], 600000, "the sim sees it at once")
	Tune.set_value("dink_past", 900000)
	eq(Drill.DINK_ZONE, K.KITCHEN_DEPTH + 900000, "the dink zone follows its distance past the line")
	Tune.set_value("lean", 99999999)
	eq(Drill.KITCHEN_LEAN, 1000000, "clamped to its range")
	Tune.save()
	Tune.reset()
	eq(Drill.SPOT_RADIUS[1], was, "reset: the source's value")
	Tune.load_saved()
	eq(Drill.SPOT_RADIUS[1], 600000, "loaded back")
	eq(Drill.DINK_ZONE, K.KITCHEN_DEPTH + 900000, "with the zone")
	var cf := ConfigFile.new()
	cf.load(TEST_PATH)
	eq(cf.get_value("where", "spot_medium"), "sim/drill.gd:SPOT_RADIUS:1", "where it lives, for sync")
	eq(cf.get_value("default", "spot_medium"), was, "and what it was")
	check(not cf.has_section_key("tune", "spot_easy"), "only what's changed is saved")
	_clean()


func test_each_tunable_is_a_plain_static_var() -> void:
	# tune_sync.py rewrites `static var NAME := literal`: an int, or a list of ints.
	var re := RegEx.create_from_string("(?m)^static var (\\w+) := (\\[[-0-9, ]+\\]|-?\\d+)")
	for e in Tune.ALL:
		var src := FileAccess.get_file_as_string(e[3])
		var found := false
		for m in re.search_all(src):
			if m.get_string(1) == e[4]:
				found = true
				var lit := m.get_string(2)
				check(lit.begins_with("[") == (int(e[5]) >= 0), "%s: a list only when indexed" % e[0])
		check(found, "%s: `static var %s := literal` in %s" % [e[0], e[4], e[3]])


func test_tuning_pages_from_pause() -> void:
	_clean()
	Settings.dev = true
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	main._start(main.settings.partner_config(), false)
	main._on_pause()
	check(main.view.menu.row("to_tune").size() > 0, "PAUSED offers TUNING")
	main._on_pressed("to_tune")
	eq(main.view.menu.title, "TUNING", "the groups")
	main._on_pressed("tune_TARGETS")
	var m: Menu3D = main.view.menu
	eq(m.title, "TUNING: TARGETS", "a group's numbers")
	m.select("tune:spot_easy")
	var before: int = Drill.SPOT_RADIUS[0]
	m.change(1)
	eq(Drill.SPOT_RADIUS[0], before + 50000, "a step: 5 cm bigger")
	check(String(m.rows[m.selected]["values"][m.value("tune:spot_easy")]).ends_with("*"), "marked as changed")
	check(FileAccess.file_exists(TEST_PATH), "saved")
	main._on_pressed("tune_reset:TARGETS")
	eq(Drill.SPOT_RADIUS[0], before, "RESET TARGETS")
	main._on_pressed("tune_back:TARGETS")
	eq(main.view.menu.title, "TUNING", "BACK to the groups")
	main._on_pressed("tune_back:")
	eq(main.view.menu.title, "PAUSED", "and to PAUSED")
	main._on_pressed("resume")
	check(not main.view.paused, "playing again")
	main.queue_free()
	Settings.dev = false
	_clean()
