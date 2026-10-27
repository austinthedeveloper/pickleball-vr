## Aiming and prediction: the velocity that lands a ball on a spot, where
## a ball in flight comes down. The CPUs, the shot assist and the bot all
## aim with these, so they agree with Ball.step exactly.
class_name Aim
extends RefCounted

const MAX_FLIGHT := 480
const SOLVE_PASSES := 10


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


## The velocity from (x, y, z) that lands on (tx, tz) in `ticks`, drag
## and all (Newton-ish passes on the no-drag answer).
static func solve(x: int, y: int, z: int, tx: int, tz: int, ticks: int) -> Array[int]:
	var n := maxi(ticks, 4)
	var vx := (tx - x) / n
	var vz := (tz - z) / n
	# Semi-implicit Euler: y_n = y + n vy - g n (n + 1) / 2.
	var vy := (K.BALL_RADIUS - y + K.GRAVITY * n * (n + 1) / 2) / n
	var b := Ball.new()
	for k in SOLVE_PASSES:
		b.place(x, y, z)
		b.launch(vx, vy, vz)
		var ex := 0
		var ey := 0
		var ez := 0
		for i in n:
			_fly(b)
		ex = tx - b.x
		ey = K.BALL_RADIUS - b.y
		ez = tz - b.z
		vx += ex / n
		vy += ey / n
		vz += ez / n
	return [vx, vy, vz]


## One step of flight with no net and no ground (the solver's).
static func _fly(b: Ball) -> void:
	var s := Fx.length(b.vx, b.vy, b.vz)
	b.vx -= Fx.drag(b.vx, s)
	b.vy -= Fx.drag(b.vy, s) + K.GRAVITY
	b.vz -= Fx.drag(b.vz, s)
	b.x += b.vx
	b.y += b.vy
	b.z += b.vz


## A shot from (x, y, z) to (tx, tz) at about `pace` um/tick over the
## ground, lofted until it clears the net by NET_CLEAR. Returns the
## velocity.
static func shot(x: int, y: int, z: int, tx: int, tz: int, pace: int) -> Array[int]:
	var dist := Fx.length(tx - x, 0, tz - z)
	var ticks := clampi(dist / maxi(pace, 1000), 12, 300)
	var v := solve(x, y, z, tx, tz, ticks)
	if (z > 0) == (tz > 0):
		return v                     # no net between
	var b := Ball.new()
	for i in 12:
		b.place(x, y, z)
		b.launch(v[0], v[1], v[2])
		var l := landing(b)
		if l[3] == 0 and l[4] >= K.NET_CLEAR:
			return v
		ticks = ticks * 9 / 8 + 2
		v = solve(x, y, z, tx, tz, ticks)
	return v
