## Aim.shot lands where it's told, over the net.
extends TestSuite


func test_shots_land_on_target() -> void:
	var cases := [
		[0, 900000, 6000000, 1500000, -5500000, 120000],
		[-2000000, 600000, 2200000, 2500000, -1200000, 40000],
		[2500000, 1200000, 6500000, -2500000, -6000000, 150000],
		[0, 400000, 1000000, 0, -1500000, 30000],
	]
	for c in cases:
		var v := Aim.shot(c[0], c[1], c[2], c[3], c[4], c[5])
		var b := Ball.new()
		b.place(c[0], c[1], c[2])
		b.launch(v[0], v[1], v[2])
		var l := Aim.landing(b)
		eq(l[3], 0, "no net %s" % str(c))
		near(l[1], c[3], 60000, "x %s" % str(c))
		near(l[2], c[4], 60000, "z %s" % str(c))
		check(l[4] >= K.NET_CLEAR - 20000, "clears the tape: %d" % l[4])


func test_isqrt_exact() -> void:
	for n in [0, 1, 2, 3, 4, 15, 16, 17, 99999999, 100000000, 1 << 40, (1 << 40) + 1]:
		var r := Fx.isqrt(n)
		check(r * r <= n and (r + 1) * (r + 1) > n, "isqrt(%d) = %d" % [n, r])
