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
## Spin, urad/tick (ADR-006).
var wx := 0
var wy := 0
var wz := 0
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
	wx = o.wx
	wy = o.wy
	wz = o.wz
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
	wx = 0
	wy = 0
	wz = 0
	rolling = false


func set_spin(nx: int, ny: int, nz: int) -> void:
	wx = clampi(nx, -K.SPIN_MAX, K.SPIN_MAX)
	wy = clampi(ny, -K.SPIN_MAX, K.SPIN_MAX)
	wz = clampi(nz, -K.SPIN_MAX, K.SPIN_MAX)


## Gravity, drag, Magnus and the spin's decay for one tick (no net, no
## ground): the flight Aim solves against.
func fly() -> void:
	var s := Fx.length(vx, vy, vz)
	var mx := Fx.mul_shift(wy * vz - wz * vy, K.MAGNUS_Q32, 32)
	var my := Fx.mul_shift(wz * vx - wx * vz, K.MAGNUS_Q32, 32)
	var mz := Fx.mul_shift(wx * vy - wy * vx, K.MAGNUS_Q32, 32)
	vx += mx - Fx.drag(vx, s)
	vy += my - Fx.drag(vy, s) - K.GRAVITY
	vz += mz - Fx.drag(vz, s)
	wx = wx * K.SPIN_DECAY_256 / 256
	wy = wy * K.SPIN_DECAY_256 / 256
	wz = wz * K.SPIN_DECAY_256 / 256
	x += vx
	y += vy
	z += vz


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
	fly()
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
		# Friction on the slip at the contact patch: topspin kicks on,
		# backspin checks up (ADR-006).
		var slip_x := vx + wz * K.BALL_RADIUS / K.URAD
		var slip_z := vz - wx * K.BALL_RADIUS / K.URAD
		vx -= slip_x * K.BOUNCE_FRICTION_256 / 256
		vz -= slip_z * K.BOUNCE_FRICTION_256 / 256
		wx = wx * K.SPIN_BOUNCE_KEEP_256 / 256
		wy = wy * K.SPIN_BOUNCE_KEEP_256 / 256
		wz = wz * K.SPIN_BOUNCE_KEEP_256 / 256
		if vy < K.ROLL_VY:
			vy = 0
			y = K.BALL_RADIUS
			rolling = true
		ev_x = x
		ev_y = 0
		ev_z = z
		ev |= EV_BOUNCE
	return ev
