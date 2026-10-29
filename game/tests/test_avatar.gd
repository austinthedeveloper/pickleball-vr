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


## The body (ADR-018): the skeleton lands on the joints the avatar works
## out: the paddle hand at its grip, the feet on their spots.
func test_the_body_follows_the_joints() -> void:
	for female in [false, true]:
		var sim := Sim.new(Settings.new().partner_config())
		var a := Avatar.new()
		a.slot = 2
		a.female = female
		runner.root.add_child(a)
		for i in 60:
			a.show_from(sim, 1.0 / 72.0)
		var sk := a.figure.skel
		var hand := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_r"))
		var grip := hand.origin.distance_to(a._hand)
		check(grip < Avatar.PALM + 0.03, "the paddle hand is at the grip (%.3f m off)" % grip)
		for f in 2:
			var foot := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("foot_l" if f == 0 else "foot_r"))
			var off := Vector2(foot.origin.x - a._feet[f].x, foot.origin.z - a._feet[f].z).length()
			check(off < 0.05, "foot %d is on its spot (%.3f m off)" % [f, off])
			check(absf(foot.origin.y - a.figure.ankle_h) < 0.05, "and on the floor")
		a.queue_free()
