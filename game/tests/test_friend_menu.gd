## PLAY A FRIEND (ADR-027, VR-77): the page, the room's letters, HOST and
## JOIN through main, the match starting on both, the menu in it, leaving.
## Two mains in one tree over a loopback (the relay itself: test_online).
extends TestSuite


func _main(link: NetLink = null) -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	if link:
		main.friend_links = [link]
	runner.root.add_child(main)
	return main


## Both mains a frame on (and their views, when they're playing): the
## tree doesn't run inside a test.
func _frame(mains: Array) -> void:
	for m in mains:
		m._process(MatchView.DT)
		if m.view and not m.view.spectate:
			m.view._process(MatchView.DT)


func test_the_page_and_its_letters() -> void:
	var main := _main()
	main._on_pressed("to_friend")
	main.lobby("friend")
	eq(main.menu.title, "PLAY A FRIEND", "the page")
	check(not main.menu.row("fhost").is_empty(), "HOST")
	eq(main.menu.row("fjoin")["label"], "JOIN ROOM BBBB", "JOIN, the room so far")
	# B X K M as indices in the relay's alphabet, stepped to from B.
	for i in 4:
		main.menu.select("letter_%d" % i)
		var want: int = RelayLink.ALPHABET.find("BXKM"[i])
		main.menu.change(want - main.menu.value("letter_%d" % i))
	eq(main.friend_room(), "BXKM", "the letters spell the room")
	eq(main.menu.row("fjoin")["label"], "JOIN ROOM BXKM", "and JOIN says it")
	main.menu.select("letter_0")
	main.menu.change(-1)
	eq(main.friend_room()[0], "Z", "B steps back round to Z")
	main.queue_free()


func test_host_then_cancel() -> void:
	var links := LoopbackLink.pair(2)
	var main := _main(links[0])
	main.lobby("friend")
	main._on_pressed("fhost")
	main.lobby("friend")
	check(main.friend != null and main.friend.host, "a room opening")
	check(not main.menu.row("fcancel").is_empty(), "CANCEL")
	check(main.menu.row("fhost").is_empty(), "no HOST while it opens")
	main._on_pressed("fcancel")
	main.lobby("friend")
	check(main.friend == null, "let go")
	check(not main.menu.row("fhost").is_empty(), "the page again")
	main.queue_free()


func test_two_friends_through_main() -> void:
	var links := LoopbackLink.pair(4)
	var a := _main(links[0])
	var b := _main(links[1])
	a.lobby("friend")
	a._on_pressed("fhost")
	a.lobby("friend")
	b.lobby("friend")
	b._on_pressed("fjoin")
	b.lobby("friend")
	check(b.menu.row("info_room")["label"].begins_with("JOINING ROOM"), "the guest says it's joining")
	var n := 0
	while (a.view.spectate or b.view.spectate) and n < 200:
		_frame([a, b])
		n += 1
	check(not a.view.spectate and not b.view.spectate, "both in the match after %d frames" % n)
	eq([a.view.me, b.view.me], [0, 2], "the host near, the guest far")
	check(a.view.sim.config.friendly and b.view.sim.config.friendly, "FRIENDLY DINK")
	eq(b.view.sim.config.seed, a.view.sim.config.seed, "the host's match on both")
	check(a.friend == null and b.friend == null, "the sessions handed to the views")
	for i in 240:
		_frame([a, b])
	check(a.view.session.rollback.confirmed > 200, "playing: %d ticks" % a.view.session.rollback.confirmed)
	# The menu in the match doesn't stop it.
	a._on_pause()
	eq(a.view.menu.title.left(16), "PLAYING A FRIEND", "the online menu")
	var t: int = a.view.sim.tick
	_frame([a, b])
	_frame([a, b])
	check(a.view.sim.tick > t and not a.view.paused, "the match plays on behind it")
	a._on_pressed("fresume")
	check(not a.view.menu.visible, "BACK TO THE GAME")
	# The guest leaves; the host is told.
	var told := []
	a.view.online_closed.connect(func(r): told.append(r))
	b._on_pressed("lobby")
	b.lobby(b._back_page())
	eq(b.page, "friend", "the guest back on PLAY A FRIEND")
	for i in 20:
		_frame([a])
	eq(told, ["YOUR FRIEND LEFT"], "the host hears it")
	eq(a.view.menu.title, "YOUR FRIEND LEFT", "and sees it")
	check(a.view.menu.row("info_best")["label"].begins_with("BEST RALLY"), "with the best rally")
	var frozen: int = a.view.sim.tick
	_frame([a])
	eq(a.view.sim.tick, frozen, "the match stops")
	a._on_pressed("lobby")
	a.lobby(a._back_page())
	eq(a.page, "friend", "and MENU goes back to PLAY A FRIEND")
	a.queue_free()
	b.queue_free()


func test_a_refusal_is_said_on_the_page() -> void:
	var links := LoopbackLink.pair(1)
	var b := _main(links[1])
	b.lobby("friend")
	b._on_pressed("fjoin")
	links[0].close()                     # nobody there: the line closes
	for i in 10:
		b._process(MatchView.DT)
	b.lobby("friend")
	check(b.friend == null, "given up")
	check(not b.menu.row("info_note").is_empty(), "the reason on the page: %s" % b._friend_note)
	b.queue_free()


## Every line PLAY A FRIEND shows fits its panel (the label's text and a
## value's "< X >" side by side).
func test_every_line_fits() -> void:
	var main := _main()
	main.lobby("friend")
	var pages := [_lines(main)]
	for host in [true, false]:
		for room in ["", "BXKM"]:
			var l := RelayLink.new()
			l.room = room
			main.friend = OnlineSession.new(l, host)
			main.lobby("friend")
			pages.append(_lines(main))
	main.friend = null
	main._friend_note = "YOUR FRIEND HAS 0.10.11"
	main.lobby("friend")
	pages.append(_lines(main))
	main._friend_note = ""
	var font: Font = ThemeDB.fallback_font
	for lines in pages:
		for t in lines:
			var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x * 0.0018
			check(w <= Menu3D.WIDTH - 0.14, "fits: %s (%.2f m)" % [t, w])
	main.queue_free()


func _lines(main: Node) -> Array:
	var out := []
	for r in main.menu.rows:
		var t: String = r["label"]
		if not (r["values"] as Array).is_empty():
			t += "     < W >"
		out.append(t)
	return out
