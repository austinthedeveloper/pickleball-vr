## The coach tablet (design/COACHING.md C-22): beside PAUSED in a practice
## drill, the companion's core in the headset, through CoachDesk.
extends TestSuite


func _paused_drill() -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	runner.root.add_child(main)
	main._start(main.settings.partner_config(), false)
	main._on_pause()
	return main


func test_it_stands_beside_paused_in_a_drill() -> void:
	var main := _paused_drill()
	var t: CoachTablet = main.view.tablet
	check(t != null and t.visible, "PAUSED in a drill: the tablet")
	var head: Vector3 = main.view.flat.head_position()
	var to_menu: Vector3 = (main.view.menu.global_position - head) * Vector3(1, 0, 1)
	var to_tab: Vector3 = (t.global_position - head) * Vector3(1, 0, 1)
	check(rad_to_deg(to_menu.angle_to(to_tab)) > 35.0, "off to the side, not over the menu")
	main._on_pressed("resume")
	check(not t.visible, "RESUME: put away")
	main._start(main.settings.match_config(), false)
	main._on_pause()
	check(main.view.tablet == null, "a match: no tablet")
	main.queue_free()


func test_pointing_clicks_its_buttons() -> void:
	var main := _paused_drill()
	var t: CoachTablet = main.view.tablet
	t.lock = 0.0
	t.settle()
	var b: Button = t._mode_buttons["FEED"]
	var c := b.get_global_rect().get_center()
	# A ray from in front at that pixel.
	var local := Vector3((c.x / CoachTablet.PX.x - 0.5) * CoachTablet.SIZE.x, (0.5 - c.y / CoachTablet.PX.y) * CoachTablet.SIZE.y, 0)
	var at := t.global_transform * local
	var from := at + t.global_transform.basis.z * 1.0
	check(t.hit_px(from, at - from) != null, "the ray meets the tablet")
	check(t.point(from, at - from, true), "and it takes the click")
	eq(t.mode, "FEED", "the button pressed")
	check(not t.point(from + Vector3(9, 0, 0), at - from, true), "a ray past it misses")
	main.queue_free()


func test_its_taps_and_steps_go_through_the_desk() -> void:
	var main := _paused_drill()
	var t: CoachTablet = main.view.tablet
	t._set_mode("TARGET")
	t.tap(-1.4, -1.1)
	t._set_mode("FEED")
	t.tap(0.8, 1.6)
	main._on_pressed("resume")
	main.view._process(MatchView.DT * 2)
	var d: Drill = main.view.sim.drill
	check(d.target_pinned and d.target_x == -1400000, "TARGET: placed and pinned")
	check(d.feed_set and d.feed_x == 800000, "FEED: the next ball's spot")
	var was := float(main.settings.coach_machine["speed"])
	t._step("speed", 1)
	eq(float(main.settings.coach_machine["speed"]), was + 0.5, "SPEED +: half a metre a second")
	t._set_mode("BOUNCE")
	t.tap(-0.5, 2.5)
	eq(main.settings.coach_machine["bx"], -0.5, "BOUNCE: the machine's spot")
	t._set_mode("TARGET")
	t.tap(0.0, 2.0)
	check(d.target_x == -1400000, "a target tapped on your side: ignored")
	main.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))


func test_insights_read_the_shots() -> void:
	var shots: Array = []
	for i in 12:
		shots.append({"speed": 5.0, "good": i % 2 == 0, "result": "GOOD!" if i % 2 == 0 else "OUT",
			"clear": 0.6, "height": 0.5 if i % 2 == 0 else 0.3, "side": "FH" if i < 6 else "BH", "ready": 0.9})
	var lines := CoachDesk.insights(shots)
	check(lines.any(func(l: String) -> bool: return l.begins_with("BALLS CROSS 60 CM")), "too high over the net")
	check(lines.any(func(l: String) -> bool: return l.contains("LOWER CONTACT")), "misses off low contact")
	check(lines.any(func(l: String) -> bool: return l.contains("PADDLE UP AS THEY HIT: 100%")), "the ready paddle")
	eq(CoachDesk.insights([]), ["A FEW MORE SHOTS FIRST: INSIGHTS NEED 8."] as Array[String], "too few to say")


## The lead: in a partner drill it "was still showing the ball machine and
## the config values for it". Each drill gets its own controls.
func test_it_shows_the_drills_own_controls() -> void:
	var main := _paused_drill()
	var t: CoachTablet = main.view.tablet
	t.refresh()
	check(t._partner_box.visible and not t._machine_box.visible, "a partner drill: its pace and size, no machine")
	check(t._mode_buttons["FEED"].visible and not t._mode_buttons["MACHINE"].visible, "taps: target and feed")
	check(t._slider_ids.has("dink_medium"), "its pace: %s" % str(t._slider_ids))
	var was := Tune.value("dink_medium")
	t._tune(t._slider_ids.find("dink_medium"), 1)
	check(Tune.value("dink_medium") > was, "+ steps it up")
	Tune.reset()
	main._start(main.settings.machine_config(), false)
	main._on_pause()
	t = main.view.tablet
	t.refresh()
	check(t._machine_box.visible and not t._partner_box.visible, "the ball machine: its controls")
	check(t._mode_buttons["BOUNCE"].visible and not t._mode_buttons["FEED"].visible, "taps: target, machine, bounce")
	main.queue_free()
