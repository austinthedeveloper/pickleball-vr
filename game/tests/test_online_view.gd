## Dinking online, on screen (ADR-027, VR-76): two MatchViews in flat mode
## over a delayed loopback, the host at the near end and the guest at the
## far, each drawing its prediction with the friend's body on it.
extends TestSuite


## Two connected, started sessions on a loopback `latency` polls each way.
func _sessions(latency := 6) -> Array:
	var links := LoopbackLink.pair(latency, [0, 1, 0, 2])
	var host := OnlineSession.new(links[0], true)
	var guest := OnlineSession.new(links[1], false)
	host.my_hello = OnlineSession.hello()
	guest.my_hello = OnlineSession.hello()
	for i in latency * 2 + 10:
		host.poll()
		guest.poll()
	host.begin({"cfg": OnlineSession.config_to_dict(OnlineSession.friendly_config(5)), "venue": 0})
	for i in latency * 2 + 10:
		host.poll()
		guest.poll()
	return [host, guest]


## A flat view of `s`; `demo`: its Bot moves and aims too (no mouse in a test).
func _view(s: OnlineSession, demo := false) -> MatchView:
	var v := MatchView.new()
	runner.root.add_child(v)
	v.setup(s.rollback.pred.config, false, demo, false, s)
	v.bot.auto_serve = true                 # flat mode's Space, pressed for you
	return v


## [host view, guest view] after `frames` of both at 120 Hz.
func _play(frames: int, demo := false) -> Array:
	var s := _sessions()
	var a := _view(s[0], demo)
	var b := _view(s[1], demo)
	for i in frames:
		a._process(MatchView.DT)
		b._process(MatchView.DT)
	return [a, b]


func test_each_end_and_the_friend_on_it() -> void:
	var v := _play(10)
	var a: MatchView = v[0]
	var b: MatchView = v[1]
	eq([a.me, b.me], [0, 2], "the host near, the guest far")
	eq([a.flat.end, b.flat.end], [1, -1], "each rig at its end")
	check(a.flat.head.z > 0 and b.flat.head.z < 0, "standing there: %.1f, %.1f" % [a.flat.head.z, b.flat.head.z])
	check(b.flat.aim.z > 0, "the guest aims at the host's side")
	check(not a.board.far and b.board.far, "the board turned to the guest")
	eq(a.avatars.size(), 1, "one body on the host's court")
	eq(b.avatars.size(), 1, "and on the guest's")
	if a.avatars.size() == 1 and b.avatars.size() == 1:
		eq([a.avatars[0].slot, b.avatars[0].slot], [2, 0], "each draws the other")
		check(a.avatars[0].human and b.avatars[0].human, "as a human, not a CPU")
	a.queue_free()
	b.queue_free()


func test_two_views_dink_in_sync() -> void:
	var v := _play(K.TICK_HZ * 40, true)
	var a: MatchView = v[0]
	var b: MatchView = v[1]
	var ra := a.session.rollback
	var rb := b.session.rollback
	eq([ra.desync, rb.desync], [-1, -1], "never out of sync")
	check(ra.checked >= 10, "hashes compared: %d" % ra.checked)
	check(ra.truth.best_rally >= 2, "they rally on screen: best %d" % ra.truth.best_rally)
	# The friend's paddle is drawn where it is in the sim.
	var f := a.avatars[0]
	var p := a.sim.players[2]
	var face := f.paddle.transform * PaddleMesh.FACE_CENTER
	check(face.distance_to(World.m(p.px, p.py, p.pz)) < 0.01, "their paddle where theirs is: %.3f m off" % face.distance_to(World.m(p.px, p.py, p.pz)))
	# The view never writes to the sim: the inputs each view logged, played
	# into a bare sim, give the confirmed match.
	var bare := Sim.new(OnlineSession.friendly_config(5))
	var n := mini(ra.confirmed, mini(a.input_log.size(), b.input_log.size()))
	for i in n:
		bare.step([SimTypes.HumanInput.from_array(a.input_log[i]), null, SimTypes.HumanInput.from_array(b.input_log[i])])
	if n == ra.confirmed:
		eq(bare.snapshot(), ra.truth.snapshot(), "the logged inputs are the match (%d ticks)" % n)
	else:
		check(false, "the logs cover what's confirmed: %d of %d" % [n, ra.confirmed])
	a.queue_free()
	b.queue_free()


func test_an_event_plays_once() -> void:
	var s := _sessions()
	var a := _view(s[0])
	check(a._fresh([K.EVENT_HIT, 2, 50000, 0, 100]), "the friend's hit")
	check(not a._fresh([K.EVENT_HIT, 2, 50000, 0, 100]), "run again by a correction: not again")
	check(not a._fresh([K.EVENT_HIT, 2, 48000, 0, 102]), "a tick or two off: the same hit")
	check(a._fresh([K.EVENT_HIT, 0, 50000, 0, 101]), "yours is another")
	check(a._fresh([K.EVENT_HIT, 2, 50000, 0, 160]), "their next hit")
	a.queue_free()


func test_the_ball_eases_after_a_correction() -> void:
	var v := _play(K.TICK_HZ * 30, true)
	var a: MatchView = v[0]
	check(a.session.rollback.corrections > 0, "there were corrections: %d" % a.session.rollback.corrections)
	# Fake a lag and watch it go, the sim untouched.
	var before := a.sim.snapshot()
	a._ball_off = Vector3(0.3, 0, 0)
	a._draw(0.06)
	check(a._ball_off.length() < 0.16 and a._ball_off.length() > 0.1, "about half gone in 60 ms: %.3f" % a._ball_off.length())
	for i in 30:
		a._draw(0.016)
	eq(a._ball_off, Vector3.ZERO, "gone in half a second")
	eq(a.sim.snapshot(), before, "drawing touched nothing")
	a.queue_free()
	v[1].queue_free()


func test_the_friend_leaving_ends_it() -> void:
	var s := _sessions()
	var a := _view(s[0])
	var b := _view(s[1])
	var why := []
	a.online_closed.connect(func(r): why.append(r))
	for i in 60:
		a._process(MatchView.DT)
		b._process(MatchView.DT)
	b.queue_free()                          # the guest quits (its view leaves the tree)
	b._exit_tree()
	for i in 30:
		a._process(MatchView.DT)
	eq(why, ["YOUR FRIEND LEFT"], "the host hears it once")
	a.queue_free()
