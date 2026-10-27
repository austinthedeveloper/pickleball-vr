## FOCUS (ADR-013): a long rally dims everything but the court.
extends TestSuite


func test_the_steps() -> void:
	eq(Focus.amount(9), 0.0, "nothing before 10 shots")
	near(int(round(Focus.amount(10) * 100)), 18, 0, "a first step at 10")
	near(int(round(Focus.amount(14) * 100)), 36, 0, "darker every 4")
	eq(Focus.amount(200), Focus.MAX, "never black")
	check(Focus.MAX >= 0.85, "deep enough to notice: %.2f" % Focus.MAX)


func test_practice_counts_your_shots_double() -> void:
	var sim := Sim.new(Settings.new().partner_config())
	sim.drill.streak = 4
	eq(Focus.amount(Focus.shots_of(sim)), 0.0, "4 dinks in a row: not yet")
	sim.drill.streak = 5
	check(Focus.amount(Focus.shots_of(sim)) > 0.0, "the 5th: focus begins")
	sim.drill.streak = 13
	eq(Focus.amount(Focus.shots_of(sim)), Focus.MAX, "13 in a row: as dark as it gets")


func test_a_long_streak_dims_the_world_not_the_court() -> void:
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(Settings.new().partner_config(), false, false)
	var w := v.world
	var scenery: StandardMaterial3D = w._dim[0][0]
	var lit := scenery.albedo_color
	var court: StandardMaterial3D = null
	for c in w.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).position == Vector3(0, 0.012, 0):
			court = (c as MeshInstance3D).material_override
	var court_lit := court.albedo_color
	v.sim.drill.streak = 12
	for i in 120:
		v._focus(1.0 / 60.0)
	check(v.focus > 0.2, "eased in: %.2f" % v.focus)
	check(scenery.albedo_color.v < lit.v * 0.8, "the surroundings dimmed")
	eq(court.albedo_color, court_lit, "the court didn't")
	v.sim.drill.streak = 0
	for i in 240:
		v._focus(1.0 / 60.0)
	eq(v.focus, 0.0, "eased out when the streak ended")
	check(scenery.albedo_color.is_equal_approx(lit), "and the world came back")
	v.queue_free()


func test_not_in_the_lobby() -> void:
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(Settings.new().partner_config(), false, true, true)
	v.sim.drill.streak = 20
	for i in 60:
		v._focus(1.0 / 60.0)
	eq(v.focus, 0.0, "the lobby's demo never dims")
	v.queue_free()
