## Practice (ADR-007, after port ADR-028): a ball machine on the far
## baseline feeds the chosen shot to the chosen target, and a return that
## lands in (in the chosen zone) counts. HOW TO PLAY's lessons are drills
## with rules and a goal. No points, no serving order. Pure like the sim:
## it lives in the sim's state and runs from Sim.step.
class_name Drill
extends RefCounted

const SHOT_DRIVE := 0
const SHOT_DINK := 1
const SHOT_LOB := 2
const SHOT_MIX := 3
const SHOT_SERVE := 4                ## no feed: you serve into the box
const SHOT_NAMES := ["DRIVE", "DINK", "LOB", "MIX", "SERVE"]

const TARGET_AT_YOU := 0
const TARGET_FOREHAND := 1
const TARGET_BACKHAND := 2
const TARGET_KITCHEN := 3
const TARGET_DEEP := 4
const TARGET_RANDOM := 5
const TARGET_NAMES := ["AT YOU", "FOREHAND", "BACKHAND", "KITCHEN", "DEEP", "RANDOM"]

const RATE_TICKS := [380, 270, 190]  ## SLOW, NORMAL, FAST: feed to feed
const RATE_NAMES := ["SLOW", "NORMAL", "FAST"]

## Where a return must land to count, on the machine's side.
const ZONE_ANY := 0
const ZONE_KITCHEN := 1
const ZONE_DEEP := 2                 ## the back third
const ZONE_LEFT := 3                 ## your left as you face the net (-x)
const ZONE_RIGHT := 4
const ZONE_NAMES := ["ANY", "KITCHEN", "DEEP", "LEFT", "RIGHT"]

## Lesson rules.
const RULE_NO_VOLLEY := 1            ## let it bounce first
const RULE_VOLLEY := 2               ## take it out of the air
const RULE_KITCHEN := 4              ## no volley from the kitchen
const RULE_TOPSPIN := 8              ## the return has topspin

const RESULT_GOOD := 0
const RESULT_NET := 1
const RESULT_OUT := 2
const RESULT_ZONE := 3               ## in, but not in the zone
const RESULT_MISSED := 4             ## never hit it
const RESULT_VOLLEY := 5             ## volleyed under NO_VOLLEY
const RESULT_BOUNCE := 6             ## let it bounce under VOLLEY
const RESULT_KITCHEN := 7
const RESULT_SPIN := 8               ## no topspin under TOPSPIN
const RESULT_TEXT := ["GOOD!", "NET", "OUT", "MISSED THE ZONE", "MISSED", "LET IT BOUNCE",
	"VOLLEY IT", "KITCHEN!", "MORE TOPSPIN"]

const WAIT := 0
const FLY := 1                       ## fed, coming to you
const RETURN := 2                    ## you hit it, going back
const SERVING := 3                   ## SERVE: the ball in your hand or tossed
const DONE := 4                      ## the lesson's goal is met

## The machine: on the far baseline, centred, the nozzle at 90 cm.
const MACHINE_Z := -(K.COURT_HALF_LENGTH + 300000)
const MACHINE_Y := 900000
const FIRST_FEED := 150
const MIN_GAP := 70                  ## after a result, before the next feed
const GIVE_UP := 420                 ## a feed that never resolves

## Settings (from Settings or a lesson).
var shot := SHOT_DRIVE
var target := TARGET_AT_YOU
var rate := 1
var zone := ZONE_ANY
var rules := 0
var goal := 0                        ## good returns to finish; 0 runs forever
## The spot you start on (a lesson's), um; x, z.
var spot_x := 0
var spot_z := K.COURT_HALF_LENGTH - 500000

## State.
var stage := WAIT
var next_feed := FIRST_FEED
var fed_at := 0
var fed_shot := SHOT_DRIVE
var bounces := 0
var feeds := 0
var good := 0
var streak := 0
var best := 0
var last_result := -1
var aim_x := 0                       ## where the last feed was aimed (the nozzle turns)


func copy_settings_from(o: Drill) -> void:
	shot = o.shot
	target = o.target
	rate = o.rate
	zone = o.zone
	rules = o.rules
	goal = o.goal
	spot_x = o.spot_x
	spot_z = o.spot_z


func reset(sim: Sim) -> void:
	stage = WAIT
	next_feed = sim.tick + FIRST_FEED
	feeds = 0
	good = 0
	streak = 0
	last_result = -1
	sim.ball.held = true
	sim.ball.place(0, MACHINE_Y, MACHINE_Z)
	sim.phase = K.PHASE_LIVE
	sim.serving_team = 1
	sim.server_slot = 2
	sim.last_hitter = 2
	sim.players[0].x = spot_x
	sim.players[0].z = spot_z
	if shot == SHOT_SERVE:
		_serve_ready(sim)


## The serve's spot: behind the right baseline, the box across.
func serve_spot() -> Array[int]:
	return [K.COURT_HALF_WIDTH / 3, K.COURT_HALF_LENGTH + 350000]


func _serve_ready(sim: Sim) -> void:
	stage = SERVING
	sim.serving_team = 0
	sim.server_slot = 0
	sim.score = [0, 0]
	sim.last_hitter = K.NO_SLOT
	sim.set_phase(K.PHASE_SERVE)


func update(sim: Sim, tossed: bool) -> void:
	var p := sim.players[0]
	match stage:
		WAIT:
			if sim.tick >= next_feed:
				if shot == SHOT_SERVE:
					_serve_ready(sim)
				else:
					_feed(sim)
			else:
				sim.ball.step()          # the last ball rolls on
		FLY:
			_fly(sim, p)
		RETURN:
			_return(sim)
		SERVING:
			_serving(sim, p, tossed)
		DONE:
			sim.ball.step()


func _feed(sim: Sim) -> void:
	var p := sim.players[0]
	fed_shot = shot
	if shot == SHOT_MIX:
		fed_shot = sim.random(3)
	var t := target
	if t == TARGET_RANDOM:
		t = sim.random(5)
	# Land a stride or two in front of you (the ball comes up to you).
	var lead := 2200000 if fed_shot != SHOT_LOB else 600000
	if rules & RULE_VOLLEY:
		lead = -1800000              # to volley: it lands behind you, passing you in the air
	var tz := clampi(p.z - lead, 400000, K.COURT_HALF_LENGTH - 300000)
	var tx := p.x
	match t:
		TARGET_FOREHAND: tx = p.x + 900000
		TARGET_BACKHAND: tx = p.x - 900000
		TARGET_KITCHEN:
			tz = K.KITCHEN_DEPTH * 6 / 10
		TARGET_DEEP:
			tz = K.COURT_HALF_LENGTH - 800000
	tx = clampi(tx + sim.scatter(250000), -K.COURT_HALF_WIDTH + 300000, K.COURT_HALF_WIDTH - 300000)
	var pace := 95000
	var spin := 450000
	match fed_shot:
		SHOT_DINK:
			pace = 38000
			spin = -200000
			if t != TARGET_DEEP:
				tz = mini(tz, K.KITCHEN_DEPTH * 7 / 10)
		SHOT_LOB:
			pace = 50000
			spin = 300000
	aim_x = tx
	var b := sim.ball
	b.place(0, MACHINE_Y, MACHINE_Z)
	var w := Aim.topspin(tx, tz - MACHINE_Z, spin)
	var v := Aim.shot(0, MACHINE_Y, MACHINE_Z, tx, tz, pace, w)
	b.launch(v[0], v[1], v[2])
	b.set_spin(w[0], w[1], w[2])
	# The two-bounce rule's machinery stands in for NO_VOLLEY: the bot and
	# the planner already let a "serve" bounce.
	sim.required_bounce = K.REQUIRED_BOUNCE_SERVE if rules & RULE_NO_VOLLEY else K.REQUIRED_BOUNCE_NONE
	sim.serving_team = 1
	sim.last_hitter = 2
	sim.bounce_count = 0
	bounces = 0
	feeds += 1
	fed_at = sim.tick
	stage = FLY
	sim.emit(K.EVENT_FEED, tx, tz, fed_shot)


func _fly(sim: Sim, p: SimTypes.Player) -> void:
	var bx := sim.ball.x
	var by := sim.ball.y
	var bz := sim.ball.z
	var ev := sim.ball.step()
	if ev & Ball.EV_BOUNCE:
		bounces += 1
		sim.bounce_count = bounces
		sim.emit(K.EVENT_BOUNCE, sim.ball.ev_x, sim.ball.ev_z, 0)
	if bounces >= 2 or sim.ball.rolling or sim.ball.z > K.COURT_HALF_LENGTH + 4 * K.M \
			or sim.tick - fed_at > GIVE_UP:
		_result(sim, RESULT_MISSED)
		return
	if p.cooldown > 0 or not sim.paddle_contact(p, bx, by, bz):
		return
	var volley := bounces == 0
	p.cooldown = K.PADDLE_COOLDOWN
	sim.emit(K.EVENT_HIT, 0, sim.ball.speed(), 1 if volley else 0)
	sim.last_hitter = 0
	sim.bounce_count = 0
	if volley and rules & RULE_NO_VOLLEY:
		_result(sim, RESULT_VOLLEY)
	elif not volley and rules & RULE_VOLLEY:
		_result(sim, RESULT_BOUNCE)
	elif volley and rules & RULE_KITCHEN and K.in_kitchen(p.x, p.z, 0):
		_result(sim, RESULT_KITCHEN)
	else:
		stage = RETURN


func _return(sim: Sim) -> void:
	var ev := sim.ball.step()
	if ev & Ball.EV_NET:
		sim.emit(K.EVENT_NET, sim.ball.ev_x, sim.ball.ev_y, 0)
		_result(sim, RESULT_NET)
		return
	if not (ev & Ball.EV_BOUNCE):
		if sim.tick - fed_at > GIVE_UP:
			_result(sim, RESULT_OUT)
		return
	var x := sim.ball.ev_x
	var z := sim.ball.ev_z
	sim.emit(K.EVENT_BOUNCE, x, z, 0)
	if z > 0:
		_result(sim, RESULT_NET)
	elif not K.in_court(x, z):
		_result(sim, RESULT_OUT)
	elif not in_zone(x, z):
		_result(sim, RESULT_ZONE)
	elif rules & RULE_TOPSPIN and not _topspin(sim.ball):
		_result(sim, RESULT_SPIN)
	else:
		_result(sim, RESULT_GOOD)


## The ball (just bounced, its spin halved) had topspin along its travel.
func _topspin(b: Ball) -> bool:
	var t := Aim.topspin(b.vx, b.vz, 1000)
	return (t[0] * b.wx + t[2] * b.wz) / 1000 > 60000


func in_zone(x: int, z: int) -> bool:
	match zone:
		ZONE_KITCHEN: return -z <= K.KITCHEN_DEPTH
		ZONE_DEEP: return -z >= K.COURT_HALF_LENGTH * 2 / 3
		ZONE_LEFT: return x <= 0
		ZONE_RIGHT: return x >= 0
	return true


## SERVE: hold, toss, hit; counts if it lands in the box.
func _serving(sim: Sim, p: SimTypes.Player, tossed: bool) -> void:
	if sim.phase == K.PHASE_SERVE:
		sim.ball.held = true
		sim.ball.place(p.hand_x, maxi(p.hand_y, K.BALL_RADIUS), p.hand_z)
		if tossed:
			sim.ball.launch(p.hand_x - p.hand_qx, p.hand_y - p.hand_qy, p.hand_z - p.hand_qz)
			sim.bounce_count = 0
			bounces = 0
			fed_at = sim.tick
			sim.emit(K.EVENT_TOSS, 0, 0, 0)
			sim.set_phase(K.PHASE_TOSS)
		return
	if sim.phase == K.PHASE_TOSS:
		var bx := sim.ball.x
		var by := sim.ball.y
		var bz := sim.ball.z
		var ev := sim.ball.step()
		if ev & Ball.EV_BOUNCE:
			bounces += 1
			sim.bounce_count = bounces
		if bounces <= 1 and sim.paddle_contact(p, bx, by, bz):
			sim.emit(K.EVENT_HIT, 0, sim.ball.speed(), 0)
			sim.last_hitter = 0
			sim.set_phase(K.PHASE_LIVE)
			feeds += 1
			return
		if bounces >= 2 or sim.ball.rolling or sim.phase_timer >= K.TOSS_TICKS:
			sim.set_phase(K.PHASE_SERVE)
		return
	# The serve in the air.
	var ev2 := sim.ball.step()
	if ev2 & Ball.EV_NET:
		sim.emit(K.EVENT_NET, sim.ball.ev_x, sim.ball.ev_y, 0)
		_result(sim, RESULT_NET)
	elif ev2 & Ball.EV_BOUNCE:
		var x := sim.ball.ev_x
		var z := sim.ball.ev_z
		sim.emit(K.EVENT_BOUNCE, x, z, 0)
		_result(sim, RESULT_GOOD if sim.in_service_box(x, z) else (RESULT_NET if z > 0 else RESULT_OUT))
	elif sim.tick - fed_at > GIVE_UP:
		_result(sim, RESULT_OUT)


func _result(sim: Sim, r: int) -> void:
	last_result = r
	if r == RESULT_GOOD:
		good += 1
		streak += 1
		best = maxi(best, streak)
	else:
		streak = 0
	var finished := goal > 0 and good >= goal
	sim.emit(K.EVENT_DRILL, r, streak, 1 if finished else 0)
	if finished:
		stage = DONE
		return
	if shot == SHOT_SERVE:
		stage = WAIT
		next_feed = sim.tick + MIN_GAP
		return
	stage = WAIT
	next_feed = maxi(fed_at + RATE_TICKS[clampi(rate, 0, 2)], sim.tick + MIN_GAP)


func snapshot() -> Array:
	return [stage, next_feed, fed_at, fed_shot, bounces, feeds, good, streak, best, last_result, aim_x]
