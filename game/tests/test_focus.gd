## FOCUS (ADR-013): a long rally dims everything but the court.
extends TestSuite


func test_the_port_kits_numbers() -> void:
	eq(Focus.amount(14), 0.0, "nothing before 15 shots")
	near(int(Focus.amount(15) * 100), 13, 0, "a first step at 15")
	near(int(Focus.amount(20) * 100), 26, 0, "darker every 5")
	eq(Focus.amount(200), Focus.MAX, "never black")


func test_practice_counts_your_shots_double() -> void:
	var sim := Sim.new(Settings.new().partner_config())
	sim.drill.streak = 7
	eq(Focus.amount(Focus.shots_of(sim)), 0.0, "7 dinks in a row: not yet")
	sim.drill.streak = 8
	check(Focus.amount(Focus.shots_of(sim)) > 0.0, "the 8th: focus begins (the port kit's 15, halved)")


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
