## The paddle face: swept contact, the bounce off it, the assist.
extends TestSuite


## A live sim with the ball at (0, 1 m, 1.5 m) flying at the near side.
func _live(assist := K.ASSIST_OFF) -> Sim:
	var cfg := SimTypes.MatchConfig.new()
	cfg.assist = assist
	var sim := Sim.new(cfg)
	sim.phase = K.PHASE_LIVE
	sim.last_hitter = 2
	sim.required_bounce = K.REQUIRED_BOUNCE_NONE
	sim.ball.held = false
	sim.ball.place(0, 1 * K.M, 1500000)
	sim.ball.launch(0, 0, 50000)
	return sim


func _input(z: int, nz := -K.Q14, head_z := 3 * K.M) -> SimTypes.HumanInput:
	var h := SimTypes.HumanInput.new()
	h.head_x = 0
	h.head_z = head_z
	h.paddle_x = 0
	h.paddle_y = 1 * K.M
	h.paddle_z = z
	h.normal = [0, 0, nz]
	return h


func test_a_still_paddle_returns_the_ball() -> void:
	var sim := _live()
	var hit := false
	for i in 40:
		sim.step([_input(2 * K.M)])
		for e in sim.drain_events():
			if e[0] == K.EVENT_HIT:
				hit = true
		if hit:
			break
	check(hit, "contact")
	check(sim.ball.vz < 0, "the ball goes back toward the net: %d" % sim.ball.vz)
	near(-sim.ball.vz, 50000 * K.PADDLE_E_256 / 256, 2000, "restitution")
	eq(sim.last_hitter, 0, "the human hit it")


func test_backhand_face_works_too() -> void:
	# The normal facing away from the ball: the other face hits.
	var sim := _live()
	for i in 40:
		sim.step([_input(2 * K.M, K.Q14)])
	check(sim.ball.vz < 0, "back toward the net")


func test_a_fast_swing_cannot_tunnel() -> void:
	# The paddle jumps 40 cm in a tick through a still ball: still a hit.
	var sim := _live()
	sim.ball.place(0, 1 * K.M, 2 * K.M)
	sim.ball.launch(0, 0, 0)
	var g := K.GRAVITY
	sim.step([_input(2400000)])
	sim.ball.place(0, 1 * K.M, 2 * K.M)
	sim.ball.launch(0, g, 0)          # cancel this tick's gravity
	sim.step([_input(2000000 - 200000)])
	check(sim.ball.vz < -300000 / 2, "driven off: %d" % sim.ball.vz)


func test_miss_beside_the_face() -> void:
	var sim := _live()
	for i in 40:
		var h := _input(2 * K.M)
		h.paddle_x = 400000          # 40 cm wide of the ball
		sim.step([h])
	check(sim.last_hitter == 2, "no contact")


func test_assist_pulls_a_long_shot_in() -> void:
	var raw := _live(K.ASSIST_OFF)
	var full := _live(K.ASSIST_FULL)
	for s in [raw, full]:
		var sim: Sim = s
		sim.ball.launch(0, 0, 0)
		sim.ball.place(0, 1 * K.M, 2 * K.M)
	# A hard flat swing: out the back without help.
	for s in [raw, full]:
		var sim: Sim = s
		sim.step([_input(2300000)])
		var h := _input(2000000)
		h.paddle_y = 1 * K.M
		sim.step([h])
	var lr: Array[int] = Aim.landing(raw.ball)
	var lf: Array[int] = Aim.landing(full.ball)
	check(lr[3] == 1 or not K.in_court(lr[1], lr[2]) or lr[2] > 0, "unassisted misses: %s" % str(lr))
	eq(lf[3], 0, "assisted clears the net")
	check(K.in_court(lf[1], lf[2]) and lf[2] < 0, "assisted lands in: %s" % str(lf))


func test_mid_assist_rescues_depth_but_keeps_your_aim() -> void:
	# The same hard swing, angled to your right: long without help; at MID
	# it lands in, and still to the right of centre.
	var raw := _live(K.ASSIST_OFF)
	var mid := _live(K.ASSIST_MID)
	for s in [raw, mid]:
		var sim: Sim = s
		sim.ball.launch(0, 0, 0)
		sim.ball.place(0, 1 * K.M, 2 * K.M)
		var h := _input(2300000)
		h.normal = Fx.unit_q14(2000, 0, -K.Q14)
		sim.step([h])
		var g := _input(2000000)
		g.normal = h.normal
		g.paddle_x = -120000
		sim.step([g])
	var lr: Array[int] = Aim.landing(raw.ball)
	var lm: Array[int] = Aim.landing(mid.ball)
	check(lr[3] == 1 or not K.in_court(lr[1], lr[2]), "unassisted misses: %s" % str(lr))
	check(lm[3] == 0 and K.in_court(lm[1], lm[2]) and lm[2] < 0, "MID lands it in: %s" % str(lm))
	check(lm[1] > 0, "and it still goes where the face pointed (right): %d" % lm[1])
