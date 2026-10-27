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


## Where a dink-like ball goes off a face tilted `open_deg` up, swung `up`
## m/s up and `fwd` m/s forward, with no assist: [vy m/s, horizontal m/s].
func _lift(open_deg: float, up: float, fwd: float) -> Array:
	var cfg := SimTypes.MatchConfig.new()
	cfg.assist = K.ASSIST_OFF
	var sim := Sim.new(cfg)
	sim.phase = K.PHASE_LIVE
	sim.last_hitter = 2
	sim.ball.held = false
	var a := deg_to_rad(open_deg)
	var n := Vector3(0, sin(a), -cos(a))
	var contact := Vector3(0, 0.45, 2.3) * 1e6
	sim.ball.place(int(contact.x), int(contact.y + 10 * 12500), int(contact.z - 10 * 33333))
	sim.ball.launch(0, -12500, 33333)
	for t in 30:
		var h := SimTypes.HumanInput.new()
		h.head_z = 3300000
		var pc := contact - n * 45000 + Vector3(0, up, -fwd) * 1e6 / 120.0 * (t - 10)
		h.paddle_x = int(pc.x)
		h.paddle_y = int(pc.y)
		h.paddle_z = int(pc.z)
		h.normal = [int(n.x * K.Q14), int(n.y * K.Q14), int(n.z * K.Q14)]
		sim.step([h])
		if sim.last_hitter == 0:
			return [sim.ball.vy * 120 / 1e6, Vector2(sim.ball.vx, sim.ball.vz).length() * 120 / 1e6]
	return []


func test_a_low_to_high_swing_lifts_the_ball() -> void:
	# The face grips: lifting the paddle through the ball lifts the ball,
	# as with a real paddle (it used to only make spin).
	var flat := _lift(15.0, 0.0, 2.0)
	var lift := _lift(15.0, 2.0, 1.5)
	check(lift[0] > flat[0] + 0.8, "lifting adds %.1f m/s up (flat %.1f)" % [lift[0] - flat[0], flat[0]])
	var big := _lift(30.0, 3.5, 1.0)
	check(big[0] > 2.5, "an open face lifted hard: %.1f m/s up" % big[0])


## A stroke as the lead logged them on the Quest: the face `open_deg`
## open, the paddle `fwd` m/s forward and `up` m/s up, meeting a dink
## coming at 3.1 m/s, 0.55 m up and 2.2 m from the net. Assist OFF.
## Returns where it lands: "NET", "SHORT", "KITCHEN", "IN" or "OUT".
func _real_stroke(open_deg: float, fwd: float, up: float) -> String:
	var cfg := SimTypes.MatchConfig.new()
	cfg.assist = K.ASSIST_OFF
	var sim := Sim.new(cfg)
	sim.phase = K.PHASE_LIVE
	sim.last_hitter = 2
	var a := deg_to_rad(open_deg)
	var n := Vector3(0, sin(a), -cos(a))
	var contact := Vector3(0, 0.55, 2.2) * 1e6
	var vin := Vector3(0, 0.6, 3.1) * 1e6 / 120.0
	sim.ball.held = true
	sim.ball.place(0, 5 * K.M, -5 * K.M)
	for t in range(-1, 30):
		if t == 0:
			sim.ball.place(int(contact.x), int(contact.y - 10 * vin.y), int(contact.z - 10 * vin.z))
			sim.ball.launch(int(vin.x), int(vin.y + 10 * K.GRAVITY), int(vin.z))
		var h := SimTypes.HumanInput.new()
		h.head_z = 3300000
		var pc := contact - n * 45000 + Vector3(0, up, -fwd) * 1e6 / 120.0 * (maxi(t, 0) - 10)
		h.paddle_x = int(pc.x)
		h.paddle_y = int(pc.y)
		h.paddle_z = int(pc.z)
		h.normal = [int(n.x * K.Q14), int(n.y * K.Q14), int(n.z * K.Q14)]
		sim.step([h])
		if sim.last_hitter == 0:
			var l: Array[int] = Aim.landing(sim.ball)
			if l[3] == 1:
				return "NET"
			if l[2] > 0:
				return "SHORT"
			if not K.in_court(l[1], l[2]):
				return "OUT"
			return "KITCHEN" if -l[2] <= K.KITCHEN_DEPTH else "IN"
	return "MISS"


func test_the_leads_strokes_land() -> void:
	# From the lead's logged session (2026-10-27): their dinks went into the
	# net or short with a flat 0.5 restitution and a harsh sweet spot.
	eq(_real_stroke(30.0, 2.0, 1.4), "KITCHEN", "a typical gentle dink of theirs")
	eq(_real_stroke(33.0, 1.9, 1.5), "KITCHEN", "another")
	var firm := _real_stroke(30.0, 4.5, 3.0)
	check(firm == "IN" or firm == "KITCHEN", "a firm one lands in court: %s" % firm)
