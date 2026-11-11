## ZEN (ADR-031): past FOCUS, HUSH quiets the world and DRIFT dissolves it.
extends TestSuite


func _view(lobby := false) -> MatchView:
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(Settings.new().partner_config(), false, lobby, lobby)
	return v


func _run(v: MatchView, streak: int, seconds: float) -> void:
	v.sim.drill.streak = streak
	for i in int(seconds * 60):
		v._focus(1.0 / 60.0)


func test_the_stages_come_after_focus() -> void:
	eq(Zen.hush_of(Zen.HUSH_AT), 0.0, "HUSH starts at its count")
	eq(Zen.hush_of(Zen.HUSH_AT + Zen.HUSH_SPAN), 1.0, "...and fills")
	eq(Zen.drift_of(Zen.DRIFT_AT - 1), 0.0, "DRIFT later")
	check(Zen.DRIFT_AT >= Zen.HUSH_AT, "DRIFT comes after HUSH")
	var focus_full := Focus.AT + int(ceil((Focus.MAX / Focus.ALPHA - 1) * Focus.STEP))
	check(Zen.HUSH_AT >= focus_full, "HUSH starts once FOCUS is as dark as it gets (%d)" % focus_full)


func test_a_deep_streak_hushes_and_drifts() -> void:
	var v := _view()
	var amb_bus := AudioServer.get_bus_index(Zen.BUS)
	check(amb_bus >= 0, "the world's sound has its bus")
	var loud := AudioServer.get_bus_volume_db(amb_bus)
	var lines: StandardMaterial3D = v.world._lines[0]
	eq(lines.emission_energy_multiplier, 0.0, "lines don't glow at the start")
	_run(v, 15, 1.0)
	check(v.zen.drift == 0.0, "15 in a row: no drift yet")
	_run(v, 30, 4.0)
	check(v.zen.hush > 0.95, "30 in a row: hushed (%.2f)" % v.zen.hush)
	check(v.zen.drift > 0.95, "...and drifted (%.2f)" % v.zen.drift)
	check(AudioServer.get_bus_volume_db(amb_bus) < loud - 10.0, "the ambience faded")
	check(v.zen.drone_on(), "the drone is in")
	check(v.zen.hit_cut() < -6.0, "the hits' own sound dropped")
	check(v.zen.quiet(), "no counting aloud")
	check(lines.emission_energy_multiplier > 0.5, "the lines glow")
	check(v.world._env.fog_depth_begin < 20.0, "the void closes in past the court")
	check(v.world._env.fog_depth_begin > 10.0, "...but not on it")
	v.queue_free()


func test_the_exhale() -> void:
	var v := _view()
	_run(v, 30, 4.0)
	eq(v.zen.bells, 0, "no bell while the rally lasts")
	_run(v, 0, 5.0)
	eq(v.zen.bells, 1, "one bell when it ends")
	eq(v.zen.hush, 0.0, "the sound came back")
	eq(v.zen.drift, 0.0, "the world came back")
	eq(v.world._lines[0].emission_energy_multiplier, 0.0, "the lines stopped glowing")
	eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(Zen.BUS)), 0.0, "the ambience at full")
	check(v.world._env.fog_depth_begin > 500.0, "the fog went out of sight")
	v.queue_free()


func test_a_short_streak_rings_no_bell() -> void:
	var v := _view()
	_run(v, 10, 3.0)
	_run(v, 0, 3.0)
	eq(v.zen.bells, 0, "FOCUS only: no bell")
	v.queue_free()


func test_bounces_ripple_only_in_drift() -> void:
	var v := _view()
	v.zen.on_bounce(Vector3(0, 0, -2))
	check(v.zen._ripples.all(func(r: MeshInstance3D) -> bool: return not r.visible), "no rings before DRIFT")
	_run(v, 30, 4.0)
	v.zen.on_bounce(Vector3(0, 0, -2))
	check(v.zen._ripples.any(func(r: MeshInstance3D) -> bool: return r.visible), "a ring under DRIFT")
	v.queue_free()


func test_not_in_the_lobby() -> void:
	var v := _view(true)
	_run(v, 40, 3.0)
	eq(v.zen.hush, 0.0, "the lobby's demo never hushes")
	eq(v.zen.drift, 0.0, "...or drifts")
	v.queue_free()


func test_the_sounds_are_there() -> void:
	for n in ["zen_drone", "zen_tone", "zen_bell"]:
		check(ResourceLoader.exists("res://assets/audio/%s.wav" % n), n)
