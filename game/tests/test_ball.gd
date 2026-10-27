## The ball's flight: gravity, drag, the bounce, the net.
extends TestSuite


func test_drop_bounces_to_about_forty_percent() -> void:
	# The rulebook's test: dropped from 78 in, back up 30 to 34 in.
	var b := Ball.new()
	b.place(0, 1981200, 3 * K.M)
	var peak := 0
	var bounced := false
	for i in 400:
		var ev := b.step()
		if ev & Ball.EV_BOUNCE:
			if bounced:
				break
			bounced = true
		if bounced:
			peak = maxi(peak, b.y)
	check(bounced, "it bounced")
	check(peak > 762000 and peak < 863600, "peak %d um in 30..34 in" % peak)


func test_free_fall_matches_gravity() -> void:
	var b := Ball.new()
	b.place(0, 5 * K.M, 3 * K.M)
	for i in K.TICK_HZ / 2:
		b.step()
	# Half a second: 1.23 m without drag, a little less with it.
	var fell := 5 * K.M - b.y
	check(fell > 1150000 and fell < 1240000, "fell %d" % fell)


func test_drag_slows_a_drive() -> void:
	var b := Ball.new()
	b.place(0, 1 * K.M, 6 * K.M)
	b.launch(0, 0, -150000)          # 18 m/s
	for i in K.TICK_HZ / 2:
		b.step()
	check(absi(b.vz) < 150000 * 85 / 100, "lost over 15%% in half a second: %d" % b.vz)


func test_net_stops_a_low_ball() -> void:
	var b := Ball.new()
	b.place(0, 500000, 1 * K.M)
	b.launch(0, 0, -60000)
	var hit := false
	for i in 60:
		if b.step() & Ball.EV_NET:
			hit = true
			break
	check(hit, "it hit the net")
	check(b.z > 0, "and stayed on its side")


func test_a_high_ball_clears_the_net() -> void:
	var b := Ball.new()
	b.place(0, 1300000, 1 * K.M)
	b.launch(0, 0, -60000)
	for i in 60:
		check(not (b.step() & Ball.EV_NET), "no net")
		if b.z < -K.M:
			break
	check(b.z < 0, "crossed")


func test_mirror_symmetry() -> void:
	# The sim must not favour a side: mirrored throws land mirrored.
	var a := Ball.new()
	var m := Ball.new()
	a.place(1200000, 900000, 5 * K.M)
	m.place(-1200000, 900000, -5 * K.M)
	a.launch(-11000, 30000, -90000)
	m.launch(11000, 30000, 90000)
	for i in 300:
		a.step()
		m.step()
		eq(a.x, -m.x, "x")
		eq(a.z, -m.z, "z")
		eq(a.y, m.y, "y")
		if a.rolling:
			break
