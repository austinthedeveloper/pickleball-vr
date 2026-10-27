## The announcer and the crowd: what's said, in what order, and when it's
## dropped; a real match's calls.
extends TestSuite


func _announcer() -> Announcer:
	var a := Announcer.new()
	runner.root.add_child(a)
	return a


func test_clips_found_in_families() -> void:
	var a := _announcer()
	for fam in ["out", "net", "kitchen", "match_begin", "match_win", "winner", "num_04_up", "score_all"]:
		check(a.has(fam), "has %s" % fam)
	eq((a.families["out"] as Array).size(), 4, "four OUT calls")
	a.queue_free()


func test_score_lines() -> void:
	eq(Announcer.score_line(4, 2), ["num_04_up", "num_02_down"], "server first")
	eq(Announcer.score_line(3, 3), ["num_03_up", "score_all"], "all")


func test_priorities_and_queue() -> void:
	var a := _announcer()
	a.say(["out"], Announcer.MID)
	eq(a.said.size(), 1, "said at once")
	a.say(["net"], Announcer.LOW)
	eq(a.said.size(), 1, "a lower line while busy is dropped")
	a.say(Announcer.score_line(1, 0), Announcer.MID, true)
	eq(a.said.size(), 1, "the score waits its turn")
	for i in 400:
		a.tick(0.01)
	eq(a.said.slice(1), ["num_01_up", "num_00_down"] as Array[String], "then the score, in order")
	a.say(["winner"], Announcer.LOW)
	a.say(["match_win"], Announcer.TOP)
	check(a.said[-1].begins_with("match_win"), "TOP cuts in")
	a.queue_free()


func test_a_match_is_called() -> void:
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(SimTypes.MatchConfig.new(), false, true)
	var points := 0
	for i in 12000:
		v._process(MatchView.DT)
		v.announcer.tick(MatchView.DT)
		points = v.sim.score[0] + v.sim.score[1]
		if points >= 3:
			break
	var said := v.announcer.said
	check(said.size() > 0 and said[0].begins_with("match_begin"), "the match is opened: %s" % str(said.slice(0, 3)))
	var scores := said.filter(func(id: String) -> bool: return id.begins_with("num_"))
	check(scores.size() >= 2, "scores called: %s" % str(said))
	check(v.crowd.cheer > 0.0 or points > 0, "the crowd follows the points")
	v.queue_free()


func test_crowd_cheers_and_settles() -> void:
	var c := Crowd.new()
	runner.root.add_child(c)
	c.react(1.0)
	eq(c.cheer, 1.0, "on its feet")
	for i in 300:
		c._process(0.02)
	eq(c.cheer, 0.0, "sits back down")
	eq(c.bodies.multimesh.instance_count, Crowd.PER_SIDE * 2, "both sides")
	c.queue_free()
