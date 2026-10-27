## Aiming and prediction: the velocity that lands a ball on a spot, where
## a ball in flight comes down. The CPUs, the shot assist and the bot all
## aim with these, so they agree with Ball.step exactly.
class_name Aim
extends RefCounted

const MAX_FLIGHT := 480
const SOLVE_PASSES := 10
const SOLVE_TOL := 2000             ## um: close enough to stop
const DRAG_K_Q16 := 2602            ## the drag k (0.0397 /m), per metre, Q16
## The solver aims the centre a millimetre under bounce height, so the
## bounce falls on tick n: corrections under n um round away to nothing.
const LAND_Y := K.BALL_RADIUS - 1000


## A ball's flight to its first bounce or the net:
## [ticks, x, z, hit_net, lowest clearance over the tape (um)].
static func landing(b: Ball) -> Array[int]:
	var t := b.copy()
	t.held = false
	var clear := K.M * 10
	for i in MAX_FLIGHT:
		var pz := t.z
		var ev := t.step()
		if (pz > 0 and t.z <= 0) or (pz < 0 and t.z >= 0) or ev & Ball.EV_NET:
			var cy := t.ev_y if ev & Ball.EV_NET else t.y
			var cx := t.ev_x if ev & Ball.EV_NET else t.x
			clear = mini(clear, cy - K.BALL_RADIUS - K.net_height(cx))
		if ev & Ball.EV_NET:
			return [i + 1, t.x, t.z, 1, clear]
		if ev & Ball.EV_BOUNCE:
			return [i + 1, t.x, t.z, 0, clear]
	return [MAX_FLIGHT, t.x, t.z, 0, clear]


## Topspin of `mag` urad/tick for a ball travelling along (dx, dz); a
## negative `mag` is backspin.
static func topspin(dx: int, dz: int, mag: int) -> Array[int]:
	var d := Fx.length(dx, 0, dz)
	if d == 0:
		return [0, 0, 0]
	return [dz * mag / d, 0, -dx * mag / d]


## The velocity from (x, y, z) that lands on (tx, tz) in `ticks` with spin
## `w`, drag, Magnus and all. The first guess is the no-drag answer; then
## secant steps, each axis's slope (how far its end point moved per um/tick
## of change) measured from the last two passes, so drag doesn't make it
## creep (ADR-009). Stops within SOLVE_TOL.
static func solve(x: int, y: int, z: int, tx: int, tz: int, ticks: int,
		w: Array[int] = [0, 0, 0], ty := LAND_Y) -> Array[int]:
	var n := maxi(ticks, 4)
	# Drag shortens a shot by about 1 / (1 + 0.62 kD) of its no-drag reach
	# (fitted across the game's dinks, drives and lobs), and an end point
	# moves n / (1 + kD0) per um/tick: start the guess and the slopes there.
	var d := Fx.length(tx - x, 0, tz - z)
	var kd := d * DRAG_K_Q16 / K.M                  # k times the distance, Q16
	var reach := 256 * 65536 / (65536 + kd * 62 / 100)          # Q8
	var kd0 := kd * 256 / reach
	var s0 := n * 256 * 65536 / (65536 + kd0)                   # Q8
	var slope: Array[int] = [s0, s0, s0]            # end-point um per um/tick, Q8
	var v: Array[int] = [(tx - x) * 256 / (n * reach), 0, (tz - z) * 256 / (n * reach)]
	# Semi-implicit Euler: y_n = y + n vy - g n (n + 1) / 2.
	v[1] = (ty - y + K.GRAVITY * n * (n + 1) / 2) / n
	var target: Array[int] = [tx, ty, tz]
	var last_v: Array[int] = [0, 0, 0]
	var last_end: Array[int] = [0, 0, 0]
	var b := Ball.new()
	for k in SOLVE_PASSES:
		b.place(x, y, z)
		b.launch(v[0], v[1], v[2])
		b.set_spin(w[0], w[1], w[2])
		for i in n:
			b.fly()
		var end: Array[int] = [b.x, b.y, b.z]
		var done := true
		for a in 3:
			if absi(target[a] - end[a]) > SOLVE_TOL:
				done = false
		if done:
			break
		for a in 3:
			if k > 0 and v[a] != last_v[a]:
				var sl := (end[a] - last_end[a]) * 256 / (v[a] - last_v[a])
				if sl > n * 64:                  # sane (a quarter of no-drag or more): use it
					slope[a] = sl
			last_v[a] = v[a]
			last_end[a] = end[a]
			v[a] += (target[a] - end[a]) * 256 / slope[a]
	return v


## A shot from (x, y, z) to (tx, tz) at about `pace` um/tick over the
## ground with spin `w`, lofted until it clears the net by NET_CLEAR.
## Returns the velocity.
static func shot(x: int, y: int, z: int, tx: int, tz: int, pace: int,
		w: Array[int] = [0, 0, 0], clear := K.NET_CLEAR) -> Array[int]:
	var dist := Fx.length(tx - x, 0, tz - z)
	var ticks := clampi(dist / maxi(pace, 1000), 12, 300)
	var v := solve(x, y, z, tx, tz, ticks, w)
	if (z > 0) == (tz > 0):
		return v                     # no net between
	var b := Ball.new()
	for i in 12:
		b.place(x, y, z)
		b.launch(v[0], v[1], v[2])
		b.set_spin(w[0], w[1], w[2])
		var l := landing(b)
		if l[3] == 0 and l[4] >= clear:
			return v
		ticks = ticks * 9 / 8 + 2
		v = solve(x, y, z, tx, tz, ticks, w)
	return v


## A ball from (x, y, z) that passes (tx, ty, tz) in the air at about
## `pace` um/tick (the ball machine's volley feed, ADR-007): raised 10 cm
## at a time until it clears the tape by NET_CLEAR. Returns the velocity.
static func through(x: int, y: int, z: int, tx: int, ty: int, tz: int, pace: int,
		w: Array[int] = [0, 0, 0]) -> Array[int]:
	var ticks := clampi(Fx.length(tx - x, ty - y, tz - z) / maxi(pace, 1000), 6, 300)
	var v := solve(x, y, z, tx, tz, ticks, w, ty)
	var b := Ball.new()
	for k in 8:
		b.place(x, y, z)
		b.launch(v[0], v[1], v[2])
		b.set_spin(w[0], w[1], w[2])
		var clear := K.M
		for i in ticks:
			var pz := b.z
			b.fly()
			if (pz > 0) != (b.z > 0):
				clear = b.y - K.BALL_RADIUS - K.net_height(b.x)
				break
		if clear >= K.NET_CLEAR:
			return v
		ty += 100000
		v = solve(x, y, z, tx, tz, ticks, w, ty)
	return v
