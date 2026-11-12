## Bounce marks (VR-106): a scuff for each bounce; close calls glow.
extends TestSuite


func test_close_calls() -> void:
	check(not BounceMarks.close_call(0, -3000000), "the middle of the court")
	check(BounceMarks.close_call(K.COURT_HALF_WIDTH - 20000, -3000000), "just in, by the sideline")
	check(BounceMarks.close_call(K.COURT_HALF_WIDTH + 60000, 2000000), "just out, by the sideline")
	check(BounceMarks.close_call(500000, -K.COURT_HALF_LENGTH - 40000), "just past the baseline")
	check(not BounceMarks.close_call(K.COURT_HALF_WIDTH + 600000, 0), "well out is no call")
	check(not BounceMarks.close_call(K.COURT_HALF_WIDTH, K.COURT_HALF_LENGTH + 900000), "nowhere near a corner")


func test_the_view_marks_bounces() -> void:
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(Settings.new().match_config(), false, true)
	var m := v.marks_on_court
	m.add(0, -3000000)
	check(m._marks.any(func(x: MeshInstance3D) -> bool: return x.visible), "a scuff where it bounced")
	eq(m.glowing(), 0, "no glow in mid-court")
	m.add(K.COURT_HALF_WIDTH + 20000, -3000000)
	eq(m.glowing(), 1, "a close call glows")
	for i in 200:
		m._process(1.0 / 60.0)
	check(m._marks.all(func(x: MeshInstance3D) -> bool: return not x.visible), "and fades away")
	# The demo's own bounces leave marks.
	var before := m._next
	for i in 3000:
		v._process(MatchView.DT)
	check(m._next != before or m.close_calls > 0 or m._marks.any(func(x: MeshInstance3D) -> bool: return x.visible),
		"bounces in play leave marks")
	v.queue_free()
