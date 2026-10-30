## The match: rules, serve, rally, score, the CPUs. Pure and exact
## (ADR-002): ints only, no Nodes, no clock; the one source of variety is
## the seeded generator in its own state. The rules are the port kit's
## (SNES ADR-n / port ADR-055), in 3D: the same faults, the same
## two-bounce rule, no volleys from your own kitchen.
class_name Sim
extends RefCounted

var config: SimTypes.MatchConfig
var ball := Ball.new()
var players: Array[SimTypes.Player] = []
var tick := 0
var phase := K.PHASE_SERVE_SETUP
var phase_timer := 0
var score: Array[int] = [0, 0]
var serving_team := 0
var server_slot := 0
var receiver_slot := 2
var required_bounce := K.REQUIRED_BOUNCE_NONE
var serve_pending := false           ## the serve's first bounce is checked
var bounce_count := 0                ## since the last hit
var last_hitter := K.NO_SLOT
var last_fault := K.FAULT_NONE
var point_winner := K.NO_TEAM
var match_winner := K.NO_TEAM
var still_ticks := 0
var shots := 0                       ## hits this rally
var best_rally := 0                  ## FRIENDLY DINK: the most returns in a rally
## The last human contact's distance from the face's centre (um): the
## view's haptics and sound read it.
var last_offset := 0
## The last human contact, for the view's swing log (debug builds; not
## state: never read back by the sim): [paddle vx, vy, vz, normal x, y, z
## (Q14, toward where it pushes), ball in vx, vy, vz, raw out vx, vy, vz
## (before the assist), y, z].
var last_contact: Array[int] = []
var rng := 1
var events: Array = []
var drill: Drill                     ## practice (ADR-007); null in a match


func _init(cfg: SimTypes.MatchConfig = null) -> void:
	config = cfg if cfg else SimTypes.MatchConfig.new()
	if config.drill:
		drill = Drill.new()
		drill.copy_settings_from(config.drill)
	for i in K.MAX_PLAYERS:
		var p := SimTypes.Player.new()
		p.slot = i
		p.team = i >> 1
		players.append(p)
	new_match()


## The active slots: singles plays 0 and 2, doubles all four.
func active_slots() -> Array[int]:
	if drill:
		return [0, 2] if drill.partner else [0]
	if config.doubles:
		return [0, 1, 2, 3]
	return [0, 2]


func is_active(slot: int) -> bool:
	if drill:
		return slot == 0 or (drill.partner and slot == 2)
	return config.doubles or slot == 0 or slot == 2


func is_human(slot: int) -> bool:
	if config.doubles:
		return slot < config.humans
	return slot == 0 and config.humans >= 1 or slot == 2 and config.humans >= 2


func new_match() -> void:
	rng = config.seed & 0x7fffffff
	tick = 0
	score = [0, 0]
	serving_team = config.first_server
	match_winner = K.NO_TEAM
	point_winner = K.NO_TEAM
	best_rally = 0
	events = []
	for p in players:
		p.cpu = not is_human(p.slot)
		p.court_right = p.slot % 2 == 0       # slots 0 and 2 start on the right
		p.cooldown = 0
		p.plan_tick = -1
		p.swing_tick = -1
	if drill:
		drill.reset(self)
		return
	_serve_setup()


func random(n: int) -> int:
	rng = Fx.lcg(rng)
	return Fx.lcg_bits(rng) % maxi(n, 1)


## -range..range
func scatter(r: int) -> int:
	if r <= 0:
		return 0
	rng = Fx.lcg(rng)
	return Fx.lcg_bits(rng) * (2 * r) / 0x7fff - r


func emit(kind: int, a: int, b: int, c: int) -> void:
	events.append([kind, a, b, c, tick])


func drain_events() -> Array:
	var e := events
	events = []
	return e


func set_phase(p: int) -> void:
	phase = p
	phase_timer = 0


# --- Serving ---------------------------------------------------------------

## FRIENDLY DINK: where both stand, behind their kitchen lines.
const FRIENDLY_BACK := 400000

## The player of `team` in its right court (if `right`) or left. Singles
## has one player, who serves and receives from either.
func _player_on(team: int, right: bool) -> int:
	if not config.doubles:
		return team * 2
	var a := team * 2
	return a if players[a].court_right == right else a + 1


## The serving side's player for this point: in doubles with rally scoring,
## the one in the right court on an even score, the left on odd.
func _server_for(team: int) -> int:
	return _player_on(team, serve_from_right())


## True when the server serves from their right-hand court.
func serve_from_right() -> bool:
	return score[serving_team] % 2 == 0


## Where a slot stands to start the point: [x, z].
func serve_spot(slot: int) -> Array[int]:
	var team := slot >> 1
	var side := K.side_sign(team)
	var right := serve_from_right()
	if config.doubles:
		return _doubles_spot(slot)
	if config.friendly:
		return [0, side * (K.KITCHEN_DEPTH + FRIENDLY_BACK)]
	if team == serving_team:
		var sx := K.right_sign(team) * (1 if right else -1) * (K.COURT_HALF_WIDTH / 3)
		return [sx, side * (K.COURT_HALF_LENGTH + 350000)]
	# The receiver, diagonally opposite: their own right when the server's is.
	var rx := K.right_sign(team) * (1 if right else -1) * (K.COURT_HALF_WIDTH / 2)
	return [rx, side * (K.COURT_HALF_LENGTH + 250000)]


## Doubles: the server and partner back; the receiver back, partner at the
## kitchen line. Each in their own court (right or left).
func _doubles_spot(slot: int) -> Array[int]:
	var p := players[slot]
	var team := p.team
	var side := K.side_sign(team)
	var lane := K.right_sign(team) * (1 if p.court_right else -1)
	var depth := K.COURT_HALF_LENGTH + 250000
	if team == serving_team:
		if slot == _server_for(team):
			return [lane * K.COURT_HALF_WIDTH / 3, side * (K.COURT_HALF_LENGTH + 350000)]
		return [lane * K.COURT_HALF_WIDTH / 2, side * (K.COURT_HALF_LENGTH - 200000)]
	if p.court_right != serve_from_right():
		depth = K.KITCHEN_DEPTH + 300000          # the receiver's partner
	return [lane * K.COURT_HALF_WIDTH / 2, side * depth]


## True if `slot` should take a ball at x: in singles always; in doubles
## the serve is the receiver's, and after it whoever is nearer the ball's
## line (the right-court player on a tie).
func covers(slot: int, x: int) -> bool:
	if not config.doubles:
		return true
	if required_bounce == K.REQUIRED_BOUNCE_SERVE:
		return slot == receiver_slot
	var p := players[slot]
	var mate := players[slot ^ 1]
	var dm := absi(x - p.x)
	var dt := absi(x - mate.x)
	if dm != dt:
		return dm < dt
	return p.court_right


## True if (x, z) is in the box the current serve must land in.
func in_service_box(x: int, z: int) -> bool:
	var recv := 1 - serving_team
	var d := z * K.side_sign(recv)
	if d <= K.KITCHEN_DEPTH or d > K.COURT_HALF_LENGTH or absi(x) > K.COURT_HALF_WIDTH:
		return false
	var box_sign := K.right_sign(recv) * (1 if serve_from_right() else -1)
	return x * box_sign >= -K.LINE_WIDTH / 2


func _serve_setup() -> void:
	server_slot = _server_for(serving_team)
	receiver_slot = _player_on(1 - serving_team, serve_from_right())
	required_bounce = K.REQUIRED_BOUNCE_NONE
	serve_pending = false
	bounce_count = 0
	last_hitter = K.NO_SLOT
	last_fault = K.FAULT_NONE
	still_ticks = 0
	shots = 0
	for s in active_slots():
		var p := players[s]
		var spot := serve_spot(s)
		p.goal_x = spot[0]
		p.goal_z = spot[1]
		p.plan_tick = -1
		if p.cpu:
			p.x = spot[0]
			p.z = spot[1]
	var sv := players[server_slot]
	ball.held = true
	ball.place(sv.x, 800000, sv.z - K.side_sign(sv.team) * 300000)
	set_phase(K.PHASE_SERVE_SETUP)


func _serve_struck(slot: int) -> void:
	# FRIENDLY DINK starts with a dink off a drop: no box, no bounce rule.
	required_bounce = K.REQUIRED_BOUNCE_NONE if config.friendly else K.REQUIRED_BOUNCE_SERVE
	serve_pending = not config.friendly
	bounce_count = 0
	last_hitter = slot
	shots = 1
	players[slot].cooldown = K.PADDLE_COOLDOWN
	_others_react(slot)
	emit(K.EVENT_SERVE, slot, 0, 0)
	emit(K.EVENT_HIT, slot, ball.speed(), 0)
	set_phase(K.PHASE_LIVE)


func _cpu_serve(p: SimTypes.Player) -> void:
	var recv := 1 - p.team
	var box_sign := K.right_sign(recv) * (1 if serve_from_right() else -1)
	var st := style(p.slot)
	var tx := box_sign * K.COURT_HALF_WIDTH / 2 + scatter(_error(p) / 2)
	var tz := K.side_sign(recv) * (K.COURT_HALF_LENGTH - 1500000 + scatter(_error(p) / 2))
	ball.place(p.x - K.right_sign(p.team) * 350000, 700000, p.z - K.side_sign(p.team) * 300000)
	var w := Aim.topspin(tx - ball.x, tz - ball.z, 300000)
	var v := Aim.shot(ball.x, ball.y, ball.z, tx, tz, st.serve_pace, w)
	ball.launch(v[0], v[1], v[2])
	ball.set_spin(w[0], w[1], w[2])
	p.swing_tick = tick
	_serve_struck(p.slot)


# --- Rules (the port kit's rules_process_*) ----------------------------------

func needs_bounce(team: int) -> bool:
	if required_bounce == K.REQUIRED_BOUNCE_SERVE:
		return team != serving_team
	if required_bounce == K.REQUIRED_BOUNCE_RETURN:
		return team == serving_team
	return false


func _hitter_team() -> int:
	return K.NO_TEAM if last_hitter == K.NO_SLOT else last_hitter >> 1


func resolve_point(losing_team: int, fault: int) -> void:
	if phase == K.PHASE_POINT_RESULT or phase == K.PHASE_MATCH_RESULT:
		return
	if config.friendly:
		_rally_over(losing_team, fault)
		return
	var winner := 1 - losing_team
	point_winner = winner
	last_fault = fault
	if config.doubles and winner == serving_team:
		for s in [winner * 2, winner * 2 + 1]:
			players[s].court_right = not players[s].court_right   # the server's side switches
	score[winner] += 1               # rally scoring (the ROM's default)
	serving_team = winner
	if fault != K.FAULT_NONE and fault != K.FAULT_SECOND_BOUNCE:
		emit(K.EVENT_FAULT, fault, losing_team, 0)
	emit(K.EVENT_POINT, winner, score[0], score[1])
	set_phase(K.PHASE_POINT_RESULT)
	required_bounce = K.REQUIRED_BOUNCE_NONE


## FRIENDLY DINK: no point, the rally's count. Whoever missed has the ball
## and starts the next one.
func _rally_over(losing_team: int, fault: int) -> void:
	var rally := maxi(shots - 1, 0)
	best_rally = maxi(best_rally, rally)
	point_winner = 1 - losing_team
	last_fault = fault
	serving_team = losing_team
	if fault != K.FAULT_NONE and fault != K.FAULT_SECOND_BOUNCE:
		emit(K.EVENT_FAULT, fault, losing_team, 0)
	emit(K.EVENT_RALLY, rally, best_rally, losing_team)
	set_phase(K.PHASE_POINT_RESULT)
	required_bounce = K.REQUIRED_BOUNCE_NONE


func score_wins(s: int, other: int) -> bool:
	return s >= config.points_to_win and (not config.win_by_2 or s >= other + 2)


func team_won(team: int) -> bool:
	if config.friendly:
		return false
	return score_wins(score[team], score[team ^ 1])


## A hit by `slot` with the ball where it is: the faults a hit can make.
## Returns false if the point ended.
func _rules_hit(slot: int) -> bool:
	var team := slot >> 1
	if needs_bounce(team) and bounce_count == 0:
		resolve_point(team, K.FAULT_EARLY_VOLLEY)
		return false
	var p := players[slot]
	# FRIENDLY DINK leans as practice does (ADR-019): the head over the line.
	var lean := K.side_sign(team) * Drill.KITCHEN_LEAN if config.friendly else 0
	if bounce_count == 0 and K.in_kitchen(p.x, p.z + lean, team):
		resolve_point(team, K.FAULT_KITCHEN)
		return false
	return true


func _rules_bounce() -> void:
	var side := K.side_of_z(ball.ev_z)
	var hitter := _hitter_team()
	bounce_count += 1
	if serve_pending:
		serve_pending = false
		if side == hitter:
			resolve_point(hitter, K.FAULT_NET)
		elif not in_service_box(ball.ev_x, ball.ev_z):
			resolve_point(hitter, K.FAULT_OUT if not K.in_court(ball.ev_x, ball.ev_z)
				else K.FAULT_WRONG_BOX)
		else:
			required_bounce = K.REQUIRED_BOUNCE_RETURN
		return
	if bounce_count >= 2:
		resolve_point(side, K.FAULT_SECOND_BOUNCE)
		return
	if side == hitter:
		resolve_point(hitter, K.FAULT_NET)
		return
	if not K.in_court(ball.ev_x, ball.ev_z):
		resolve_point(hitter, K.FAULT_OUT)
		return
	if required_bounce == K.REQUIRED_BOUNCE_RETURN and side == serving_team:
		required_bounce = K.REQUIRED_BOUNCE_NONE


# --- Contact -------------------------------------------------------------------

## A human paddle against the ball this tick, swept from last tick's poses.
## On contact the ball leaves the face and true is returned.
func paddle_contact(p: SimTypes.Player, bx0: int, by0: int, bz0: int) -> bool:
	var r0x := bx0 - p.qx
	var r0y := by0 - p.qy
	var r0z := bz0 - p.qz
	var r1x := ball.x - p.px
	var r1y := ball.y - p.py
	var r1z := ball.z - p.pz
	const NEAR := 700000
	if Fx.length(r1x, r1y, r1z) > NEAR and Fx.length(r0x, r0y, r0z) > NEAR:
		return false
	var n := p.normal
	var d0 := Fx.dot_q14(r0x, r0y, r0z, n)
	var d1 := Fx.dot_q14(r1x, r1y, r1z, n)
	var s := 1 if d0 >= 0 else -1
	var reach := K.BALL_RADIUS + K.PADDLE_HALF_THICK
	if s * d1 >= reach:
		return false
	var f := 0                       # Q16 of the tick at first touch
	if s * d0 > reach:
		f = (s * d0 - reach) * 65536 / (s * d0 - s * d1)
	var rx := r0x + (r1x - r0x) * f / 65536
	var ry := r0y + (r1y - r0y) * f / 65536
	var rz := r0z + (r1z - r0z) * f / 65536
	var rn := Fx.dot_q14(rx, ry, rz, n)
	var tx := rx - rn * n[0] / K.Q14
	var ty := ry - rn * n[1] / K.Q14
	var tz := rz - rn * n[2] / K.Q14
	var face := K.PADDLE_FACE_RADIUS + K.BALL_RADIUS / 2
	var off2 := tx * tx + ty * ty + tz * tz
	if off2 > face * face:
		return false
	var nn: Array[int] = [n[0] * s, n[1] * s, n[2] * s]
	# The face's travel this tick (where it touched) and its effective speed
	# for the hit: the swing curve (ADR-003) for a controller with no weight.
	var mx := p.px - p.qx
	var my := p.py - p.qy
	var mz := p.pz - p.qz
	var sm := Fx.length(mx, my, mz)
	var se := K.swing_eff(sm)
	var ux := mx * se / maxi(sm, 1)
	var uy := my * se / maxi(sm, 1)
	var uz := mz * se / maxi(sm, 1)
	var vn := Fx.dot_q14(ball.vx - ux, ball.vy - uy, ball.vz - uz, nn)
	if vn >= 0:
		return false                 # already leaving the face
	# The sweet spot (ADR-006): restitution falls off toward the rim.
	var fr := K.PADDLE_FACE_RADIUS
	var e0 := K.paddle_e(-vn)
	var e := e0 - e0 * K.PADDLE_EDGE_LOSS_PCT * mini(off2, fr * fr) / (100 * fr * fr)
	var j := -vn * (256 + e) / 256
	# A fast ball met by a still face keeps more of its pace (a block).
	var vb := Fx.dot_q14(ball.vx, ball.vy, ball.vz, nn)
	var un := Fx.dot_q14(ux, uy, uz, nn)
	if vb < 0:
		var eb := K.block_e(e0, -vb, maxi(un, 0))
		eb -= eb * K.PADDLE_EDGE_LOSS_PCT * mini(off2, fr * fr) / (100 * fr * fr)
		j += -vb * (eb - e) / 256
	var vx := ball.vx + j * nn[0] / K.Q14
	var vy := ball.vy + j * nn[1] / K.Q14
	var vz := ball.vz + j * nn[2] / K.Q14
	# Spin: the face brushing across the ball, plus some of what it had.
	var bx := ux - ball.vx
	var by := uy - ball.vy
	var bz := uz - ball.vz
	var bn := Fx.dot_q14(bx, by, bz, nn)
	bx -= bn * nn[0] / K.Q14
	by -= bn * nn[1] / K.Q14
	bz -= bn * nn[2] / K.Q14
	# Grip (ADR-003 amended): the face drags the ball along with it, taking
	# PADDLE_GRIP of the slide between them. A low-to-high swing lifts the
	# ball, as it does with a real paddle; the rest of the slide is spin.
	vx += bx * K.PADDLE_GRIP_256 / 256
	vy += by * K.PADDLE_GRIP_256 / 256
	vz += bz * K.PADDLE_GRIP_256 / 256
	var k := K.URAD / 100 * K.SPIN_BRUSH_PCT / K.BALL_RADIUS
	var keep := K.SPIN_KEEP_ON_HIT_PCT
	var swx := (by * nn[2] - bz * nn[1]) / K.Q14 * k + ball.wx * keep / 100
	var swy := (bz * nn[0] - bx * nn[2]) / K.Q14 * k + ball.wy * keep / 100
	var swz := (bx * nn[1] - by * nn[0]) / K.Q14 * k + ball.wz * keep / 100
	last_offset = Fx.isqrt(off2)
	# Leave from the face at the moment of touch.
	var cx := p.qx + mx * f / 65536
	var cy := p.qy + my * f / 65536
	var cz := p.qz + mz * f / 65536
	ball.x = cx + tx + reach * nn[0] / K.Q14
	ball.y = maxi(cy + ty + reach * nn[1] / K.Q14, K.BALL_RADIUS)
	ball.z = cz + tz + reach * nn[2] / K.Q14
	ball.set_spin(swx, swy, swz)
	last_contact = [ux, uy, uz, nn[0], nn[1], nn[2], ball.vx, ball.vy, ball.vz, vx, vy, vz, ball.y, ball.z,
		Fx.isqrt(off2), e]
	var v := _assist(p.team, [vx, vy, vz])
	ball.launch(v[0], v[1], v[2])
	return true


## Slower than this over the ground (6 m/s), a shot is soft: a dink or a drop.
const SOFT_PACE := 50000

## The shot assist (ADR-003): the human's shot pulled `config.assist`
## percent of the way to the same shot landed safely in.
func _assist(team: int, v: Array[int]) -> Array[int]:
	if config.assist <= 0:
		return v
	var probe := ball.copy()
	probe.launch(v[0], v[1], v[2])
	var l := Aim.landing(probe)
	var opp := K.side_sign(1 - team)
	var m := K.ASSIST_MARGIN
	var tx: int = clampi(l[1], -K.COURT_HALF_WIDTH + m, K.COURT_HALF_WIDTH - m)
	var depth: int = l[2] * opp
	var pace := maxi(Fx.length(v[0], 0, v[2]), 30000)
	if l[3] != 0 or depth <= 0:
		# Into the net or short: a soft shot is rescued as a drop into their
		# kitchen (a dink stays a dink), anything firmer to mid-court.
		depth = K.KITCHEN_DEPTH * 7 / 10 if pace < SOFT_PACE else K.KITCHEN_DEPTH + 1500000
	depth = clampi(depth, m, K.COURT_HALF_LENGTH - m)
	if phase == K.PHASE_TOSS and not config.friendly:
		var box := K.right_sign(1 - team) * (1 if serve_from_right() else -1)
		tx = box * clampi(tx * box, m, K.COURT_HALF_WIDTH - m)
		depth = clampi(depth, K.KITCHEN_DEPTH + m, K.COURT_HALF_LENGTH - m)
	var ideal := Aim.shot(ball.x, ball.y, ball.z, tx, depth * opp, pace, [ball.wx, ball.wy, ball.wz])
	# Aim (the line over the ground) is pulled `assist`; depth (the pace
	# over the ground and the arc) twice as hard (MID: all of it), since a swing's
	# length is the hardest thing to judge in a headset (ADR-003).
	var a := config.assist
	var ad := mini(100, a * 2)
	var dx := v[0] + (ideal[0] - v[0]) * a / 100
	var dz := v[2] + (ideal[2] - v[2]) * a / 100
	var dl := maxi(Fx.length(dx, 0, dz), 1)
	var raw_pace := Fx.length(v[0], 0, v[2])
	var good_pace := Fx.length(ideal[0], 0, ideal[2])
	var p := raw_pace + (good_pace - raw_pace) * ad / 100
	return [dx * p / dl, v[1] + (ideal[1] - v[1]) * ad / 100, dz * p / dl]


func _others_react(slot: int) -> void:
	for s in active_slots():
		var p := players[s]
		if p.cpu and p.team != slot >> 1:
			p.think_at = tick + style(s).reaction
			p.plan_tick = -1
			p.let_go = false


## True if the ball, flying to `team`, will come down out (or, on the
## serve, outside the box): a player lets it go.
func going_out(team: int) -> bool:
	if bounce_count > 0 or phase != K.PHASE_LIVE:
		return false
	var l := Aim.landing(ball)
	if l[3] != 0 or K.side_of_z(l[2]) != team:
		return false
	if serve_pending:
		return not in_service_box(l[1], l[2])
	return not K.in_court(l[1], l[2])


func _hit_by(slot: int) -> void:
	var volley := bounce_count == 0
	last_hitter = slot
	bounce_count = 0
	still_ticks = 0
	shots += 1
	players[slot].cooldown = K.PADDLE_COOLDOWN
	_others_react(slot)
	emit(K.EVENT_HIT, slot, ball.speed(), 1 if volley else 0)


# --- CPUs ------------------------------------------------------------------------

## A CPU's personality: its own if the config gives one (the ladder),
## else the config's default.
func style(slot: int) -> SimTypes.CpuStyle:
	var st: SimTypes.CpuStyle = config.styles[slot] if slot < config.styles.size() else null
	return st if st else config.style


func _error(p: SimTypes.Player) -> int:
	var e := style(p.slot).error
	match config.difficulty:
		0: return e * 16 / 10
		2: return e * 55 / 100
	return e


## Where a CPU waits while the ball is going away.
func _home(p: SimTypes.Player) -> Array[int]:
	var side := K.side_sign(p.team)
	var depth := K.COURT_HALF_LENGTH - 300000
	var waiting_return := required_bounce != K.REQUIRED_BOUNCE_NONE and p.team == serving_team
	if not waiting_return and shots >= 2 and (p.slot * 37 + score[0] * 11 + score[1] * 7) % 100 < style(p.slot).net_rush:
		depth = K.KITCHEN_DEPTH + 350000
	var x := 0
	if config.doubles:
		x = K.right_sign(p.team) * (1 if p.court_right else -1) * K.COURT_HALF_WIDTH / 2
	else:
		var opp := players[(1 - p.team) * 2]
		x = clampi(opp.x / 3, -K.COURT_HALF_WIDTH / 2, K.COURT_HALF_WIDTH / 2)
	return [x, depth * side]


func _cpu_think(p: SimTypes.Player) -> void:
	var incoming := phase == K.PHASE_LIVE and _hitter_team() != p.team
	if not incoming:
		var h := _home(p)
		p.goal_x = h[0]
		p.goal_z = h[1]
		return
	if tick < p.think_at:
		return
	p.think_at = tick + 12
	if p.plan_tick < 0 and going_out(p.team):
		p.let_go = true
	if p.let_go:
		var h := _home(p)
		p.goal_x = h[0]
		p.goal_z = h[1]
		return
	var plan := Intercept.plan(self, p.team, p.x, p.z, style(p.slot).speed)
	if plan.is_empty():
		return
	if not covers(p.slot, plan[1]):
		p.plan_tick = -1
		var h := _home(p)
		p.goal_x = h[0]
		p.goal_z = h[1]
		return
	p.goal_x = plan[4]
	p.goal_z = plan[5]
	p.plan_tick = tick + plan[0]


func _cpu_move(p: SimTypes.Player) -> void:
	var dx := p.goal_x - p.x
	var dz := p.goal_z - p.z
	var d := Fx.length(dx, 0, dz)
	var sp := style(p.slot).speed
	if d <= sp:
		p.x = p.goal_x
		p.z = p.goal_z
	else:
		p.x += dx * sp / d
		p.z += dz * sp / d
	var side := K.side_sign(p.team)
	p.z = side * clampi(p.z * side, K.NET_GAP, K.COURT_HALF_LENGTH + K.RUNOFF_BACK)
	if config.doubles:
		# Teammates keep a stride apart, side by side (port separate_teammates).
		var mate := players[p.slot ^ 1]
		var gap := p.x - mate.x
		if absi(gap) < 900000 and Fx.length(gap, 0, p.z - mate.z) < 900000:
			var away := 1 if gap > 0 or (gap == 0 and p.court_right == (K.right_sign(p.team) > 0)) else -1
			p.x += away * (900000 - absi(gap)) / 2


## A CPU swings when the ball is in reach, legal and at (or past) its plan.
func _cpu_try_hit(p: SimTypes.Player) -> bool:
	if p.cooldown > 0 or p.let_go or _hitter_team() == p.team:
		return false
	var side := K.side_sign(p.team)
	if ball.z * side <= 0:
		return false
	if needs_bounce(p.team) and bounce_count == 0:
		return false
	if bounce_count == 0 and K.in_kitchen(p.x, p.z, p.team):
		return false
	if ball.y < K.REACH_LOW or ball.y > K.REACH_HIGH:
		return false
	if Fx.length(ball.x - p.x, 0, ball.z - p.z) > K.REACH:
		return false
	if not covers(p.slot, ball.x):
		return false
	var passing := ball.z * side >= p.z * side - 100000
	if p.plan_tick >= 0 and tick < p.plan_tick and not passing and ball.y > K.REACH_LOW * 2:
		return false
	if not _rules_hit(p.slot):
		return true
	_cpu_shot(p)
	p.swing_tick = tick
	_hit_by(p.slot)
	return true


func _cpu_shot(p: SimTypes.Player) -> void:
	var st := style(p.slot)
	var opp_team := 1 - p.team
	var opp := players[opp_team * 2]
	var os := K.side_sign(opp_team)
	var err := _error(p)
	var at_net := opp.z * os < K.KITCHEN_DEPTH + 900000
	var tx := -signi(opp.x) * (K.COURT_HALF_WIDTH - 450000) if opp.x != 0 else K.COURT_HALF_WIDTH / 2
	# BODY aims at the player (port aim "body"); MIX now and then.
	if st.aim == 1 or (st.aim == 2 and random(2) == 0):
		tx = clampi(opp.x, -K.COURT_HALF_WIDTH + 450000, K.COURT_HALF_WIDTH - 450000)
	if config.doubles:
		var o2 := players[opp_team * 2 + 1]
		at_net = at_net and o2.z * os < K.KITCHEN_DEPTH + 900000
		tx = (opp.x + o2.x) / 2                        # down the middle, between them
		if at_net:
			tx = -signi(ball.x + 1) * K.COURT_HALF_WIDTH / 2   # dinks go crosscourt
	var depth := K.COURT_HALF_LENGTH - 1000000
	var pace := st.drive_pace
	var roll := random(100)
	if at_net and roll < st.dink:
		depth = K.KITCHEN_DEPTH * 6 / 10
		pace = 40000
		tx = tx / 2
	elif at_net and roll < st.dink + st.lob:
		depth = K.COURT_HALF_LENGTH - 900000
		pace = 55000
	elif required_bounce == K.REQUIRED_BOUNCE_NONE and shots == 2 and roll < 40:
		depth = K.KITCHEN_DEPTH * 7 / 10      # the third-shot drop
		pace = 45000
	elif required_bounce != K.REQUIRED_BOUNCE_NONE:
		pace = st.drive_pace * 3 / 4          # returns go deep, not hard
	tx += scatter(err)
	depth += scatter(err)
	pace += scatter(pace / 10)
	# A mistake now and then: long, or wide.
	var miss: int = [15, 9, 5][clampi(config.difficulty, 0, 2)]
	if st.miss >= 0:
		miss = st.miss * [16, 10, 6][clampi(config.difficulty, 0, 2)] / 10
	if random(100) < miss:
		if random(2) == 0:
			depth = K.COURT_HALF_LENGTH + 500000
		else:
			tx = signi(tx + 1) * (K.COURT_HALF_WIDTH + 400000)
	depth = maxi(depth, 300000)
	# Spin by the shot (ADR-006): drives rolled over, lobs a little, dinks
	# and drops cut under.
	var spin := 600000
	if pace < 50000:
		spin = -250000
	elif pace < 70000:
		spin = 350000
	var w := Aim.topspin(tx - ball.x, depth * os - ball.z, spin)
	var v := Aim.shot(ball.x, ball.y, ball.z, tx, depth * os, pace, w)
	ball.launch(v[0], v[1], v[2])
	ball.set_spin(w[0], w[1], w[2])


# --- The step ---------------------------------------------------------------------

func _take_input(p: SimTypes.Player, h: SimTypes.HumanInput) -> void:
	p.qx = p.px
	p.qy = p.py
	p.qz = p.pz
	p.hand_qx = p.hand_x
	p.hand_qy = p.hand_y
	p.hand_qz = p.hand_z
	if h == null:
		return
	p.x = h.head_x
	p.z = h.head_z
	p.px = h.paddle_x
	p.py = h.paddle_y
	p.pz = h.paddle_z
	p.normal = h.normal.duplicate()
	p.hand_x = h.hand_x
	p.hand_y = h.hand_y
	p.hand_z = h.hand_z


## One tick. `human[slot]` is that human's SimTypes.HumanInput (or null);
## `commands` are [K.CMD_*, ...] arrays, applied first.
func step(human: Array = [], commands: Array = []) -> void:
	for c in commands:
		match int(c[0]):
			K.CMD_NEW_MATCH:
				new_match()
			K.CMD_PIN_TARGET:
				if drill:
					drill.pin_target(self, int(c[1]), int(c[2]), int(c[3]) != 0)
			K.CMD_FEED_TO:
				if drill:
					drill.feed_to(int(c[1]), int(c[2]))
			K.CMD_MACHINE:
				if drill:
					drill.coach_machine(c.slice(1))
	tick += 1
	phase_timer += 1
	var tossed := false
	for s in active_slots():
		var p := players[s]
		var h: SimTypes.HumanInput = human[s] if s < human.size() else null
		if not p.cpu:
			_take_input(p, h)
			tossed = tossed or (h != null and h.toss and s == server_slot)
		if p.cooldown > 0:
			p.cooldown -= 1
	if drill:
		drill.update(self, tossed)
		return
	match phase:
		K.PHASE_SERVE_SETUP:
			if phase_timer >= K.SETUP_TICKS:
				set_phase(K.PHASE_SERVE)
		K.PHASE_SERVE:
			_update_serve(tossed)
		K.PHASE_TOSS:
			_update_toss()
		K.PHASE_LIVE:
			_update_live()
		K.PHASE_POINT_RESULT:
			_update_ball_only()
			if phase_timer >= K.POINT_RESULT_TICKS:
				if team_won(point_winner):
					match_winner = point_winner
					emit(K.EVENT_MATCH, match_winner, score[0], score[1])
					set_phase(K.PHASE_MATCH_RESULT)
				else:
					_serve_setup()
		K.PHASE_MATCH_RESULT:
			_update_ball_only()
	for s in active_slots():
		var p := players[s]
		if p.cpu:
			if phase == K.PHASE_LIVE:
				_cpu_think(p)
			_cpu_move(p)


func _update_serve(tossed: bool) -> void:
	var sv := players[server_slot]
	if sv.cpu:
		if phase_timer >= K.CPU_SERVE_TICKS:
			_cpu_serve(sv)
		return
	ball.held = true
	ball.place(sv.hand_x, maxi(sv.hand_y, K.BALL_RADIUS), sv.hand_z)
	if tossed:
		ball.launch(sv.hand_x - sv.hand_qx, sv.hand_y - sv.hand_qy, sv.hand_z - sv.hand_qz)
		bounce_count = 0
		emit(K.EVENT_TOSS, server_slot, 0, 0)
		set_phase(K.PHASE_TOSS)


## A tossed (or dropped: the drop serve) ball the server hasn't hit yet.
func _update_toss() -> void:
	var bx := ball.x
	var by := ball.y
	var bz := ball.z
	var ev := ball.step()
	if ev & Ball.EV_BOUNCE:
		bounce_count += 1
		emit(K.EVENT_BOUNCE, ball.ev_x, ball.ev_z, 0)
	var sv := players[server_slot]
	if bounce_count <= 1 and paddle_contact(sv, bx, by, bz):
		_serve_struck(server_slot)
		return
	if bounce_count >= 2 or ball.rolling or phase_timer >= K.TOSS_TICKS:
		set_phase(K.PHASE_SERVE)         # no fault: hold it and go again


func _update_live() -> void:
	var bx := ball.x
	var by := ball.y
	var bz := ball.z
	var ev := ball.step()
	if ev & Ball.EV_NET:
		emit(K.EVENT_NET, ball.ev_x, ball.ev_y, 0)
	if ev & Ball.EV_BOUNCE:
		emit(K.EVENT_BOUNCE, ball.ev_x, ball.ev_z, 0)
		_rules_bounce()
		if phase != K.PHASE_LIVE:
			return
	if ball.rolling:
		still_ticks += 1
		if still_ticks >= K.STILL_TICKS / 8:
			resolve_point(K.side_of_z(ball.z), K.FAULT_SECOND_BOUNCE)
			return
	if absi(ball.x) > 30 * K.M or absi(ball.z) > 30 * K.M or ball.y < -K.M:
		resolve_point(maxi(_hitter_team(), 0), K.FAULT_OUT)
		return
	for s in active_slots():
		var p := players[s]
		if p.cpu:
			if _cpu_try_hit(p):
				return
			continue
		if p.cooldown > 0:
			continue
		if ball.z * K.side_sign(p.team) < -200000:
			continue                     # reaching over the net
		if _hitter_team() == p.team and bounce_count == 0:
			continue                     # your side's shot on its way out
		if paddle_contact(p, bx, by, bz):
			if _rules_hit(s):
				_hit_by(s)
			return


func _update_ball_only() -> void:
	ball.step()


# --- Inspection --------------------------------------------------------------------

## Everything that decides the future, as ints (tests, golden traces).
## `without_pose`: that slot's head and paddle as zeros, and a held ball's
## place too (it's in the server's hand): rollback's check that a guessed
## pose changed nothing shared (ADR-027).
func snapshot(without_pose := -1) -> Array:
	var a: Array = [tick, phase, phase_timer, score[0], score[1], serving_team, server_slot,
		required_bounce, 1 if serve_pending else 0, bounce_count, last_hitter, last_fault,
		point_winner, match_winner, shots, rng, receiver_slot,
		ball.x, ball.y, ball.z, ball.vx, ball.vy, ball.vz, ball.wx, ball.wy, ball.wz,
		1 if ball.held else 0]
	if without_pose >= 0 and ball.held:
		a[17] = 0
		a[18] = 0
		a[19] = 0
	for s in active_slots():
		var p := players[s]
		if s == without_pose:
			a.append_array([0, 0, 0, 0, 0])
		else:
			a.append_array([p.x, p.z, p.px, p.py, p.pz])
		a.append_array([p.cooldown, p.goal_x, p.goal_z, p.plan_tick,
			1 if p.court_right else 0, 1 if p.let_go else 0])
	if drill:
		a.append_array(drill.snapshot())
	if config.friendly:
		a.append(best_rally)
	return a


func state_hash() -> int:
	return hash(snapshot())


## The whole state (ADR-027, for rollback): load_state(save_state()) leaves
## the sim stepping exactly as before. The config is shared, not saved.
func save_state() -> Array:
	var ps := []
	for p in players:
		ps.append(_vars(p))
	return [_vars(self, ["config", "ball", "players", "drill"]), _vars(ball), ps,
		_vars(drill) if drill else {}]


func load_state(state: Array) -> void:
	_set_vars(self, state[0])
	_set_vars(ball, state[1])
	for i in players.size():
		_set_vars(players[i], state[2][i])
	if drill:
		_set_vars(drill, state[3])


static var _names := {}              ## script -> its variables' names


## An object's script variables, deep-copied (less `skip`).
static func _vars(o: Object, skip: Array = []) -> Dictionary:
	var sc: Script = o.get_script()
	if not _names.has(sc):
		var n := []
		for p in o.get_property_list():
			if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				n.append(p["name"])
		_names[sc] = n
	var d := {}
	for k in _names[sc]:
		if k in skip:
			continue
		var v = o.get(k)
		d[k] = v.duplicate(true) if v is Array or v is Dictionary else v
	return d


static func _set_vars(o: Object, d: Dictionary) -> void:
	for k in d:
		var v = d[k]
		o.set(k, v.duplicate(true) if v is Array or v is Dictionary else v)
