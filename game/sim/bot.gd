## A stand-in human: it makes the SimTypes.HumanInput a player would, a
## paddle swung through the ball on a planned path. It plays DEMO, the
## tests' rallies and flat mode's swing (where you move and aim, it swings).
## Pure like the sim: what it reads is the sim's state, what it gives is
## an input.
class_name Bot
extends RefCounted

const SWING_TICKS := 14
const FOLLOW_TICKS := 8
const SERVE_WAIT := 45
const MIN_LEAD := 10
const DRILL_ROAM := 1500000

var sim: Sim
var slot := 0
var auto_move := true                ## false: the head is yours (flat mode)
var speed := 30000                   ## 3.6 m/s
## false: the toss waits for `serve_now` (flat mode's key).
var auto_serve := true
var serve_now := false
## Where to aim on the far court (flat mode's crosshair); off by default.
var has_aim := false
var aim_x := 0
var aim_z := 0
## Your shot's pace over the ground, um/tick.
var pace := 105000
## Aim scatter (um), from the bot's own seeded generator; 0 aims true.
var error := 300000
## Percent of shots that go wrong: long, wide or into the net.
var miss := 14
var rng := 7
## The ready position, from the head (flat mode lifts it into view).
var rest_side := 400000
var rest_y := 950000
var rest_forward := 250000
## The body (head) when auto_move.
var head_x := 0
var head_z := 0

var _plan_tick := -1
var _plan_for := -2                  ## the shot number the plan answers
var _px := 0                         ## the face's centre at contact
var _py := 0
var _pz := 0
var _n: Array[int] = [0, 0, K.Q14]
var _ux := 0                         ## the face's velocity through the swing
var _uy := 0
var _uz := 0
var _last := SimTypes.HumanInput.new()
var _goal_x := 0
var _goal_z := 0
var _move_at := 0
var _move_for := -2


func _init(s: Sim, which := 0) -> void:
	sim = s
	slot = which
	var spot := sim.serve_spot(slot)
	if sim.drill:
		spot = [sim.drill.spot_x, sim.drill.spot_z]
	head_x = spot[0]
	head_z = spot[1]


func _team() -> int:
	return slot >> 1


## The input for the sim's next tick.
func input() -> SimTypes.HumanInput:
	var h := SimTypes.HumanInput.new()
	var team := _team()
	var side := K.side_sign(team)
	var fore := K.right_sign(team)
	var next := sim.tick + 1
	if sim.phase == K.PHASE_SERVE_SETUP:
		var spot := sim.serve_spot(slot)
		head_x = spot[0]
		head_z = spot[1]
		_plan_tick = -1
	elif auto_move:
		_move()
	h.head_x = head_x
	h.head_z = head_z
	# The free hand holds the ball out in front at the serve.
	h.hand_x = head_x - fore * 250000
	h.hand_y = 900000
	h.hand_z = head_z - side * 350000
	if sim.phase == K.PHASE_SERVE and sim.server_slot == slot and sim.phase_timer >= SERVE_WAIT \
			and (auto_serve or serve_now):
		serve_now = false
		h.toss = true
		h.hand_y = _last.hand_y + 22000      # a gentle toss up, 2.6 m/s
	_rest(h)
	_maybe_plan()
	if _plan_tick >= 0 and next >= _plan_tick - SWING_TICKS and next <= _plan_tick + FOLLOW_TICKS:
		var k := _plan_tick - next
		h.paddle_x = _px - _ux * k
		h.paddle_y = _py - _uy * k
		h.paddle_z = _pz - _uz * k
		h.normal = _n.duplicate()
	_last = h
	return h


## Where to wait across the court: the middle in singles, your own court
## in doubles.
func _lane_x() -> int:
	if not sim.config.doubles:
		return 0
	var p := sim.players[slot]
	return K.right_sign(_team()) * (1 if p.court_right else -1) * K.COURT_HALF_WIDTH / 2


## The paddle held ready by the body, face to the net.
func _rest(h: SimTypes.HumanInput) -> void:
	var team := _team()
	var side := K.side_sign(team)
	h.paddle_x = head_x + K.right_sign(team) * rest_side
	h.paddle_y = rest_y
	h.paddle_z = head_z - side * rest_forward
	h.normal = [0, 0, -side * K.Q14]


func _incoming() -> bool:
	var team := _team()
	if sim.phase == K.PHASE_TOSS:
		return sim.server_slot == slot
	return sim.phase == K.PHASE_LIVE and sim.last_hitter >= 0 and sim.last_hitter >> 1 != team


func _move() -> void:
	var team := _team()
	var side := K.side_sign(team)
	var gx := _lane_x()
	var gz := side * (K.COURT_HALF_LENGTH - 300000)
	if sim.drill:
		gx = sim.drill.spot_x               # practice: back to your spot
		gz = sim.drill.spot_z
	if _incoming() and sim.phase == K.PHASE_LIVE:
		# Replan now and then, as the CPUs do (the plan costs a flight's prediction).
		var key := sim.shots * 4 + sim.bounce_count
		if key != _move_for or sim.tick >= _move_at:
			_move_for = key
			_move_at = sim.tick + 12
			var plan := Intercept.plan(sim, team, head_x, head_z, speed, -1, MIN_LEAD)
			if plan.is_empty():
				return
			if sim.covers(slot, plan[1]):
				_goal_x = plan[4]
				_goal_z = plan[5]
			else:
				_goal_x = _lane_x()
				_goal_z = side * (K.COURT_HALF_LENGTH - 300000)
		gx = _goal_x
		gz = _goal_z
	elif sim.phase != K.PHASE_LIVE:
		return
	elif sim.required_bounce == K.REQUIRED_BOUNCE_NONE and sim.shots >= 3 and not sim.drill:
		gz = side * (K.KITCHEN_DEPTH + 400000)
	if sim.drill:
		# Practice: step to the ball, but stay near your spot (a learner
		# doesn't charge the net to volley the machine).
		var ox := gx - sim.drill.spot_x
		var oz := gz - sim.drill.spot_z
		var od := Fx.length(ox, 0, oz)
		if od > DRILL_ROAM:
			gx = sim.drill.spot_x + ox * DRILL_ROAM / od
			gz = sim.drill.spot_z + oz * DRILL_ROAM / od
	var dx := gx - head_x
	var dz := gz - head_z
	var d := Fx.length(dx, 0, dz)
	if d <= speed:
		head_x = gx
		head_z = gz
	else:
		head_x += dx * speed / d
		head_z += dz * speed / d


## Plan a swing once per incoming shot (again if the ball's path changed).
func _maybe_plan() -> void:
	if not _incoming():
		if sim.phase != K.PHASE_LIVE and sim.phase != K.PHASE_TOSS:
			_plan_tick = -1
		elif _plan_tick >= 0 and sim.tick > _plan_tick + FOLLOW_TICKS:
			_plan_tick = -1
		return
	var key := sim.shots * 4 + (1 if sim.phase == K.PHASE_TOSS else 0) + sim.bounce_count * 2
	if key == _plan_for and _plan_tick > sim.tick:
		return
	var team := _team()
	if sim.phase == K.PHASE_LIVE and sim.going_out(team):
		_plan_for = key
		_plan_tick = -1
		return
	var reach := -1 if auto_move else K.REACH
	var lead := SERVE_WAIT / 2 if sim.phase == K.PHASE_TOSS else MIN_LEAD
	var plan := Intercept.plan(sim, team, head_x, head_z, speed, reach, lead)
	if plan.is_empty():
		return
	if sim.phase == K.PHASE_LIVE and not sim.covers(slot, plan[1]):
		_plan_for = key
		_plan_tick = -1
		return                       # the partner's ball
	_plan_for = key
	var i: int = plan[0]
	var b := sim.ball.copy()
	b.held = false
	for t in i:
		b.step()
	var target := _target(b)
	if error > 0 and not has_aim:
		target[0] += _scatter(error)
		target[1] += _scatter(error)
		if sim.phase == K.PHASE_LIVE and _scatter(50) + 50 < miss:
			# Wide, by enough that the assist (which saves depth, ADR-003)
			# can't pull it back in.
			target[0] = signi(target[0] + _scatter(1) + 1) * (K.COURT_HALF_WIDTH + 2600000)
	var v := Aim.shot(b.x, b.y, b.z, target[0], target[1], target[2])
	var dx: int = v[0] - b.vx
	var dy: int = v[1] - b.vy
	var dz: int = v[2] - b.vz
	# Brush up the back of a drive (topspin), down under a dink (backspin),
	# across the face. The face grips (ADR-003): the brush also carries the
	# ball PADDLE_GRIP of its way, so the normal swing makes up the rest.
	var brush := 26000 if target[2] >= 80000 else -9000
	var n0 := Fx.unit_q14(dx, dy, dz)
	var bt := _across_up(n0, brush)
	dx -= bt[0] * K.PADDLE_GRIP_256 / 256
	dy -= bt[1] * K.PADDLE_GRIP_256 / 256
	dz -= bt[2] * K.PADDLE_GRIP_256 / 256
	_n = Fx.unit_q14(dx, dy, dz)
	bt = _across_up(_n, brush)
	var dl := Fx.length(dx, dy, dz)
	var vin_n := Fx.dot_q14(b.vx, b.vy, b.vz, _n)
	# Restitution depends on the closing speed, which depends on the swing:
	# two passes settle it.
	var e := K.PADDLE_E_256
	var s := 0
	for k in 2:
		s = dl * 256 / (256 + e) + vin_n
		e = K.paddle_e(s - vin_n)
	# The face moves with the ball across itself (so the grip adds only
	# the brush), and into it along the normal.
	_ux = s * _n[0] / K.Q14 + (b.vx - vin_n * _n[0] / K.Q14) + bt[0]
	_uy = s * _n[1] / K.Q14 + (b.vy - vin_n * _n[1] / K.Q14) + bt[1]
	_uz = s * _n[2] / K.Q14 + (b.vz - vin_n * _n[2] / K.Q14) + bt[2]
	var rel := Fx.dot_q14(b.vx - _ux, b.vy - _uy, b.vz - _uz, _n)   # < 0: closing
	var gap := K.BALL_RADIUS + K.PADDLE_HALF_THICK + rel / 2
	_px = b.x - gap * _n[0] / K.Q14
	_py = b.y - gap * _n[1] / K.Q14
	_pz = b.z - gap * _n[2] / K.Q14
	_plan_tick = sim.tick + i


## `amount` um/tick up across a face with normal `n` (up, less its part
## along the normal).
static func _across_up(n: Array[int], amount: int) -> Array[int]:
	return [amount * (-n[1] * n[0] / K.Q14) / K.Q14, amount * (K.Q14 - n[1] * n[1] / K.Q14) / K.Q14,
		amount * (-n[1] * n[2] / K.Q14) / K.Q14]


func _scatter(r: int) -> int:
	rng = Fx.lcg(rng)
	return Fx.lcg_bits(rng) * (2 * r) / 0x7fff - r


## [x, z, pace] for the shot from ball `b`.
func _target(b: Ball) -> Array[int]:
	var team := _team()
	var opp := 1 - team
	var os := K.side_sign(opp)
	if sim.phase == K.PHASE_TOSS:
		var box := K.right_sign(opp) * (1 if sim.serve_from_right() else -1)
		return [box * K.COURT_HALF_WIDTH / 2, os * (K.COURT_HALF_LENGTH - 1500000), 95000]
	if has_aim:
		return [aim_x, aim_z, pace]
	if sim.drill:
		# Practice: at the floor target if there is one, else to the zone
		# the drill asks for.
		if sim.drill.targets:
			var soft := sim.drill.zone == Drill.ZONE_KITCHEN or sim.drill.partner
			return [sim.drill.target_x, sim.drill.target_z, 40000 if soft else pace]
		match sim.drill.zone:
			Drill.ZONE_KITCHEN: return [0, os * K.KITCHEN_DEPTH * 6 / 10, 40000]
			Drill.ZONE_LEFT: return [-K.COURT_HALF_WIDTH / 2, os * (K.COURT_HALF_LENGTH - 1500000), pace]
			Drill.ZONE_RIGHT: return [K.COURT_HALF_WIDTH / 2, os * (K.COURT_HALF_LENGTH - 1500000), pace]
		return [0, os * (K.COURT_HALF_LENGTH - 1100000), pace]
	var o := sim.players[opp * 2]
	var tx := -signi(o.x) * (K.COURT_HALF_WIDTH - 1000000) if o.x != 0 else 0
	if absi(o.z) < K.KITCHEN_DEPTH + 900000 and b.y < 900000:
		return [tx / 2, os * K.KITCHEN_DEPTH * 6 / 10, 40000]
	return [tx, os * (K.COURT_HALF_LENGTH - 1100000), pace]
