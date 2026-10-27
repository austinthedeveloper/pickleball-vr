## The person's footwork (ADR-012): the feet carry the body; nothing
## stretches; display only.
extends TestSuite


## Moves the partner `metres` sideways at `speed` m/s, frame by frame;
## returns [worst lag of the feet behind the body (m), steps taken]. (The
## legs can't overstretch: the IK caps the reach at their length.)
func _run(speed: float, metres: float) -> Array:
	var sim := Sim.new(Settings.new().partner_config())
	var a := Avatar.new()
	a.slot = 2
	runner.root.add_child(a)
	var q := sim.players[2]
	var dt := 1.0 / 72.0
	for i in 30:                     # settle
		a.show_from(sim, dt)
	var lag := 0.0
	var steps := 0
	var was := [false, false]
	var frames := int(metres / speed / dt)
	for i in frames + 40:
		if i < frames:
			q.x += int(speed * dt * K.M)
		a.show_from(sim, dt)
		var body := World.m(q.x, 0, q.z)
		var mid: Vector3 = (a._feet[0] + a._feet[1]) / 2
		lag = maxf(lag, Vector2(body.x - mid.x, body.z - mid.z).length())
		for f in 2:
			var stepping: bool = a._step_t[f] >= 0.0
			if stepping and not was[f]:
				steps += 1
			was[f] = stepping
	a.queue_free()
	return [lag, steps]


func test_a_fast_shuffle_keeps_the_feet_under_the_body() -> void:
	# The old footwork trailed the body by 1.03 m in 5 steps: dragged along.
	var r := _run(3.5, 2.0)
	check(r[0] < 0.55, "the feet keep up (lag at most %.2f m)" % r[0])
	check(r[1] >= 7, "it steps to get there: %d steps" % r[1])


func test_standing_still_doesnt_shuffle() -> void:
	var r := _run(0.2, 0.05)
	check(r[1] <= 1, "no fidgeting: %d steps" % r[1])
