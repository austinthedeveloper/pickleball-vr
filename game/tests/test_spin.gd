## Spin (ADR-006): Magnus in flight, the kick off the bounce, spin off the
## paddle's brush, the sweet spot.
extends TestSuite


func _throw(spin: int) -> Ball:
	var b := Ball.new()
	b.place(0, 1 * K.M, 2 * K.M)
	b.launch(0, 30000, -110000)
	var w := Aim.topspin(0, -1, spin)
	b.set_spin(w[0], w[1], w[2])
	return b


func test_topspin_dives_backspin_floats() -> void:
	var flat: Array[int] = Aim.landing(_throw(0))
	var top: Array[int] = Aim.landing(_throw(1200000))
	var back: Array[int] = Aim.landing(_throw(-1200000))
	check(top[2] > flat[2] + 300000, "topspin lands shorter: %d vs %d" % [top[2], flat[2]])
	check(back[2] < flat[2] - 300000, "backspin carries: %d vs %d" % [back[2], flat[2]])


func test_topspin_kicks_off_the_bounce() -> void:
	var speeds := []
	for spin in [1200000, -1200000]:
		var b := Ball.new()
		b.place(0, 300000, 0)
		b.launch(0, -40000, -80000)
		var w := Aim.topspin(0, -1, spin)
		b.set_spin(w[0], w[1], w[2])
		for i in 60:
			if b.step() & Ball.EV_BOUNCE:
				break
		speeds.append(-b.vz)
	check(speeds[0] > speeds[1] + 3000, "topspin skids on, backspin checks up: %s" % str(speeds))


func test_no_spin_bounce_is_unchanged() -> void:
	var b := Ball.new()
	b.place(0, 300000, 0)
	b.launch(0, -40000, -80000)
	for i in 60:
		if b.step() & Ball.EV_BOUNCE:
			break
	near(-b.vz, 80000 * 205 / 256, 2500, "0.8 of the planar speed kept")


func test_spinning_shots_still_land_on_target() -> void:
	for spin in [600000, -250000]:
		var w := Aim.topspin(1500000, -11500000, spin)
		var v := Aim.shot(0, 900000, 6000000, 1500000, -5500000, 110000, w)
		var b := Ball.new()
		b.place(0, 900000, 6000000)
		b.launch(v[0], v[1], v[2])
		b.set_spin(w[0], w[1], w[2])
		var l: Array[int] = Aim.landing(b)
		near(l[1], 1500000, 80000, "x with spin %d" % spin)
		near(l[2], -5500000, 80000, "z with spin %d" % spin)


## A live sim with the ball coming straight at a still paddle at z = 2 m.
func _live() -> Sim:
	var cfg := SimTypes.MatchConfig.new()
	cfg.assist = K.ASSIST_OFF
	var sim := Sim.new(cfg)
	sim.phase = K.PHASE_LIVE
	sim.last_hitter = 2
	sim.ball.held = false
	sim.ball.place(0, 1 * K.M, 1500000)
	sim.ball.launch(0, K.GRAVITY, 50000)
	return sim


func _swing(sim: Sim, dy: int, off_x := 0) -> void:
	for i in 40:
		var h := SimTypes.HumanInput.new()
		h.head_z = 3 * K.M
		h.paddle_x = off_x
		h.paddle_y = 1 * K.M + dy * (i - 9)
		h.paddle_z = 2 * K.M
		h.normal = [0, 0, -K.Q14]
		sim.step([h])
		if sim.last_hitter == 0:
			return


func test_brushing_up_makes_topspin() -> void:
	var sim := _live()
	_swing(sim, 20000)
	eq(sim.last_hitter, 0, "hit")
	check(sim.ball.wx < -200000, "topspin (wx < 0 going -z): %d" % sim.ball.wx)
	var down := _live()
	_swing(down, -20000)
	check(down.ball.wx > 200000, "brushing down cuts backspin: %d" % down.ball.wx)


func test_the_sweet_spot_is_livelier() -> void:
	var centre := _live()
	_swing(centre, 0)
	var edge := _live()
	_swing(edge, 0, 100000)
	eq(edge.last_hitter, 0, "the rim still hits")
	check(-centre.ball.vz > -edge.ball.vz + 2000, "centre %d faster than rim %d" % [-centre.ball.vz, -edge.ball.vz])
	check(edge.last_offset > 80000 and centre.last_offset < 40000,
		"offsets reported: %d, %d" % [edge.last_offset, centre.last_offset])
