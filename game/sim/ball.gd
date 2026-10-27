## The ball: flight under gravity and air drag, the net, the bounce. Plain
## ints, no allocation per step, so prediction (aim, CPUs, the bot) can
## run hundreds of steps a tick.
class_name Ball
extends RefCounted

const EV_BOUNCE := 1
const EV_NET := 2

var x := 0
var y := K.BALL_RADIUS
var z := 0
var vx := 0
var vy := 0
var vz := 0
var held := false          ## in a server's hand: no flight
var rolling := false
## Where the last event happened.
var ev_x := 0
var ev_y := 0
var ev_z := 0


func copy() -> Ball:
	var b := Ball.new()
	b.copy_from(self)
	return b


func copy_from(o: Ball) -> void:
	x = o.x
	y = o.y
	z = o.z
	vx = o.vx
	vy = o.vy
	vz = o.vz
	held = o.held
	rolling = o.rolling
	ev_x = o.ev_x
	ev_y = o.ev_y
	ev_z = o.ev_z


func place(px: int, py: int, pz: int) -> void:
	x = px
	y = py
	z = pz
	vx = 0
	vy = 0
	vz = 0
	rolling = false


func launch(nvx: int, nvy: int, nvz: int) -> void:
	vx = nvx
	vy = nvy
	vz = nvz
	held = false
	rolling = false


func speed() -> int:
	return Fx.length(vx, vy, vz)


## One tick. Returns EV_* bits.
func step() -> int:
	if held:
		return 0
	if rolling:
		vx = vx * K.ROLL_FRICTION_256 / 256
		vz = vz * K.ROLL_FRICTION_256 / 256
		x += vx
		z += vz
		return 0
	var px := x
	var pz := z
	var s := Fx.length(vx, vy, vz)
	vx -= Fx.drag(vx, s)
	vy -= Fx.drag(vy, s) + K.GRAVITY
	vz -= Fx.drag(vz, s)
	x += vx
	y += vy
	z += vz
	var ev := 0
	# The net: the centre crossed z = 0 this tick, low enough to touch the tape.
	if (pz > 0 and z <= 0) or (pz < 0 and z >= 0):
		var cx := px + (x - px) * pz / (pz - z)
		var cy := y - vy + vy * pz / (pz - z)
		if absi(cx) <= K.NET_POST_X and cy - K.BALL_RADIUS < K.net_height(cx):
			x = cx
			y = cy
			z = K.BALL_RADIUS if pz > 0 else -K.BALL_RADIUS
			vx = vx * K.NET_KEEP_256 / 256
			vy = mini(vy, 0) * K.NET_KEEP_256 / 256
			vz = -vz * K.NET_KEEP_256 / 256
			ev_x = cx
			ev_y = cy
			ev_z = 0
			ev |= EV_NET
	if y < K.BALL_RADIUS and vy < 0:
		y = 2 * K.BALL_RADIUS - y
		vy = -vy * K.BOUNCE_VERTICAL_256 / 256
		vx = vx * K.BOUNCE_PLANAR_256 / 256
		vz = vz * K.BOUNCE_PLANAR_256 / 256
		if vy < K.ROLL_VY:
			vy = 0
			y = K.BALL_RADIUS
			rolling = true
		ev_x = x
		ev_y = 0
		ev_z = z
		ev |= EV_BOUNCE
	return ev
