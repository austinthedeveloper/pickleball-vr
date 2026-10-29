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

const RATE_TICKS := [380, 270, 190, 130]   ## feed to feed
const RATE_NAMES := ["SLOW", "NORMAL", "FAST", "RAPID"]

## How hard the machine feeds (ADR-007): a drive's pace over the ground,
## um/tick (8 to 17 m/s); dinks and lobs scale with it.
const SPEED_PACE := [70000, 95000, 120000, 145000]
const SPEED_NAMES := ["SLOW", "MEDIUM", "FAST", "BLAZING"]

## Where the machine stands: AUTO puts it at the far kitchen line for
## dinks (a dink from the baseline is a lob) and on the baseline otherwise.
const AT_AUTO := 0
const AT_BASELINE := 1
const AT_KITCHEN := 2
const AT_NAMES := ["AUTO", "BASELINE", "KITCHEN"]
const BASELINE_Z := -(K.COURT_HALF_LENGTH + 300000)
const KITCHEN_Z := -(K.KITCHEN_DEPTH + 500000)

## At the net (this close to it, or under a VOLLEY rule), drives come
## through the air at this height where you stand: volleys, not bounces.
const NET_ZONE := K.KITCHEN_DEPTH + 1600000
const VOLLEY_Y := 1000000

## Where a return must land to count, on the machine's side.
const ZONE_ANY := 0
const ZONE_KITCHEN := 1             ## the dink zone: their kitchen and 75 cm past its line
const ZONE_DEEP := 2                 ## the back third
const ZONE_LEFT := 3                 ## your left as you face the net (-x)
const ZONE_RIGHT := 4
const ZONE_NAMES := ["ANY", "KITCHEN", "DEEP", "LEFT", "RIGHT"]
## A dink that lands just past the kitchen line is still a good dink
## (ADR-010 amended twice): the zone runs 75 cm (2.5 ft) past it.
static var DINK_PAST := 750000        ## tuned (Tune); DINK_ZONE follows it
static var DINK_ZONE := K.KITCHEN_DEPTH + DINK_PAST

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
const RESULT_POPUP := 9              ## RESETS: it crossed the net too high
const RESULT_SPOT := 10              ## CALL THE SPOT: in their kitchen, off the spot
const RESULT_LANE := 11              ## LINE AND CROSS: the other lane
const RESULT_ATTACK := 12            ## ATTACK OR DINK: you dinked a ball to put away
const RESULT_PATIENT := 13           ## ATTACK OR DINK: you sped up a ball to dink
const RESULT_TEXT := ["GOOD!", "NET", "OUT", "MISSED THE ZONE", "MISSED", "LET IT BOUNCE",
	"VOLLEY IT", "KITCHEN!", "MORE TOPSPIN", "POP-UP!", "MISSED THE SPOT", "WRONG LANE",
	"ATTACK THAT!", "BE PATIENT"]

## The partner's drills (ADR-010, 014, 016, 017).
const KIND_DINKS := 0
const KIND_HANDS := 1
const KIND_RESETS := 2
const KIND_SPOTS := 3                ## CALL THE SPOT: dink to the spot that lights
const KIND_LANES := 4                ## LINE AND CROSS: only one half of their kitchen counts
const KIND_VOLLEYS := 5              ## VOLLEY DINKS: take floaters out of the air, to a spot
const KIND_ATTACK := 6               ## ATTACK OR DINK: speed up the high ones, dink the rest
const KIND_NAMES := ["DINKS", "HANDS", "RESETS", "CALL THE SPOT", "LINE AND CROSS", "VOLLEY DINKS",
	"ATTACK OR DINK"]
const KIND_COUNTS := ["DINKS", "HANDS", "RESETS", "SPOTS", "LANES", "VOLLEYS", "GOOD CALLS"]
## CALL THE SPOT: the spot is a dartboard (ADR-019) this big, and when it
## lights: EASY as they hit, MEDIUM as the ball crosses the net, HARD as it
## bounces on your side.
static var SPOT_RADIUS := [1000000, 850000, 700000]
## A dartboard's rings, from the outside in: the outer ring, the inner
## ring, the bullseye, at these fractions of its radius; each scores its
## number (1, 2, 3).
static var RING_EDGES := [100, 66, 33]
const RING_TEXT := ["", "+1", "+2", "BULLSEYE! +3"]
## Practice judges the kitchen from your headset, and you lean: you're in
## only when your head is this far past the line (ADR-019).
static var KITCHEN_LEAN := 450000
## LINE AND CROSS: which lane counts.
const LANE_LINE := 0
const LANE_CROSS := 1
const LANE_ALTERNATE := 2
const LANE_NAMES := ["LINE", "CROSS", "ALTERNATE"]
## VOLLEY DINKS: a floater through your kitchen line at this height, slow.
const FLOAT_Y := [850000, 750000, 650000]
static var FLOAT_PACE := [36000, 42000, 48000]
## ATTACK OR DINK: 30% come up high, landing in your kitchen to sit up at
## your line.
## DIFFICULTY is how little higher they are than the rest (over the net:
## 1 m against 30 cm on EASY, 55 against 12 on HARD). A speed-up is a ball
## you send back at 7 m/s or more over the ground.
static var ATTACK_HIGH_PCT := 30
const ATTACK_HIGH_CLEAR := [1000000, 750000, 550000]
const ATTACK_LOW_CLEAR := [300000, 200000, K.NET_CLEAR]
const SPEEDUP_V := 58333

const WAIT := 0
const FLY := 1                       ## fed, coming to you
const RETURN := 2                    ## you hit it, going back
const SERVING := 3                   ## SERVE: the ball in your hand or tossed
const DONE := 4                      ## the lesson's goal is met
const PARTNER := 5                   ## DINK PARTNER: your ball's on their side, they're going for it
const SETUP := 6                     ## the partner shows the next ball, drops it and hits it

## Every fresh partner feed has a lead-in you can read (ADR-016 amended):
## the ball held up in their hand, then dropped and struck as it falls,
## so you see where it comes from and when; the shot itself stays fast.
static var HOLD_TICKS := 42               ## 0.35 s held up
const HOLD_Y := 1200000             ## chest high, in front of the free hand
const DROP_VY := 12000               ## a little lift as it leaves the hand (1.4 m/s)

## DINK PARTNER (ADR-010): a CPU at their kitchen line who only wants the
## rally to go on: every ball it reaches comes back as a dink about a metre
## in front of you, never away from you, never a winner.
const PARTNER_Z := -(K.KITCHEN_DEPTH + 350000)
static var PARTNER_SPEED := 30000         ## 3.6 m/s
const PARTNER_REACT := 22            ## ticks after your hit it starts moving (0.18 s)
## HANDS (ADR-014): both at the kitchen line, keeping it alive in the air.
## The partner volleys at you at DIFFICULTY's pace (7, 10, 13 m/s), waist to
## chest high, and reads your volley faster than a dink.
static var HANDS_PACE := [65000, 93000, 120000]   ## 7.8, 11.2, 14.4 m/s
## A rally starts soft and straight at you, then speeds up: the feed at
## 5 m/s, then a jump (the reply to your first ball is already half way
## to full pace), full by your HANDS_RAMP'th ball back (ADR-014 amended).
static var HANDS_FEED := 42000
const HANDS_RAMP := 3
const HANDS_REACT := 12              ## 0.1 s
const HANDS_HEIGHT := 950000         ## where it comes at you, give or take 15 cm
const HANDS_HIGH := 1800000          ## a chest-high volley is still a volley to plan for
## RESETS (ADR-016): you in the transition zone, the partner at their
## kitchen line driving at you, hard and low (a speed-up). Block it soft
## into their dink zone, under the pop-up line. DIFFICULTY is the drive's
## pace (9, 11, 13 m/s) and how low the line is over the net (60, 45, 30 cm).
const RESET_SPOT_Z := K.KITCHEN_DEPTH + 1800000   ## mid-court, about 3.9 m from the net
static var RESET_PACE := [75000, 92000, 108000]
const RESET_HEIGHT := 550000         ## at you: shins to hips, give or take 20 cm
static var POPUP_OVER := [600000, 450000, 300000]
## A dink's difficulty is how low it skims the tape: EASY floats 60 cm
## over it (slow, a big bounce), HARD skims 12 cm (fast and low).
const PARTNER_CLEAR := [600000, 300000, K.NET_CLEAR]
static var PARTNER_PACE := [30000, 38000, 46000]
const PACE_NAMES := ["EASY", "MEDIUM", "HARD"]
## SPREAD: how far to your side its dinks come, um: [nearest, furthest].
const SPREADS := [[100000, 350000], [250000, 750000], [500000, 1200000]]
const SPREAD_NAMES := ["TIGHT", "NORMAL", "WIDE"]
## Floor targets: a dartboard on their side; land on it for points.
static var TARGET_RADIUS := 800000
## You've crossed to the other side once you're this far past the middle.
const SIDE_SWITCH := 400000

## The machine: centred, the nozzle at 90 cm.
const MACHINE_Y := 900000
const FIRST_FEED := 150
const MIN_GAP := 70                  ## after a result, before the next feed
const GIVE_UP := 600                 ## a feed nobody hits, from the feed
const RETURN_GIVE_UP := 480          ## a return that never comes down, from the hit

## Settings (from Settings or a lesson).
var shot := SHOT_DRIVE
var target := TARGET_AT_YOU
var rate := 1
var speed := 1
var machine_at := AT_AUTO
var zone := ZONE_ANY
var rules := 0
var partner := false                 ## DINK PARTNER instead of the machine
var partner_pace := 1
var cross := false                   ## the partner stands diagonally across, not straight
var kind := KIND_DINKS               ## which partner drill (KIND_*)
var lane := LANE_ALTERNATE           ## LINE AND CROSS: which lane counts
## HANDS (ADR-014): volleys at each other, not dinks.
var hands: bool:
	get: return kind == KIND_HANDS
## RESETS (ADR-016): drives at you; reset them into the kitchen.
var resets: bool:
	get: return kind == KIND_RESETS
## A spot lights on their side for each of the partner's shots.
var spots: bool:
	get: return kind == KIND_SPOTS or kind == KIND_VOLLEYS
var lanes: bool:
	get: return kind == KIND_LANES
var attack: bool:
	get: return kind == KIND_ATTACK
var spread := 1
var targets := false                 ## floor targets on
var goal := 0                        ## good returns to finish; 0 runs forever
## A timed run (ADR-022): this many ticks from the first feed, then DONE and
## a score. 0 is free play, forever.
var time_limit := 0
const TIMES := [0, 60, 120, 180]     ## seconds: the MODE row
const TIME_NAMES := ["FREE PLAY", "1 MIN", "2 MIN", "3 MIN"]
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
var hit_at := 0
var machine_z := BASELINE_Z
var partner_plan := -1               ## the tick the partner means to hit
var read_at := 0                     ## when the partner reads your shot
var target_x := 0
var target_z := 0
var target_hits := 0
## The coach's ball machine (C-21): where it stands, where its balls
## bounce, how fast, with what spin, how high over the net, how often.
var coach_feed := false
var machine_x := 0
var bounce_x := 0
var bounce_z := 4000000
var feed_pace := 66667
var feed_spin := 0
var feed_clear := 500000
var feed_every := 420
const FEED_PACE_RANGE := [25000, 170000]   ## 3 to 20 m/s
const FEED_SPIN_MAX := 600000
const FEED_CLEAR_RANGE := [50000, 3000000]
const FEED_EVERY_RANGE := [150, 960]       ## 1.25 to 8 s
var target_pinned := false           ## a coach put the target there: it stays (C-8)
var feed_set := false                ## a coach chose where the partner's next ball goes (C-9)
var feed_x := 0
var feed_z := 0
var target_side := 0                 ## the half (sign of x) a partner drill's target is in
var ends_at := -1                    ## a timed run's last tick
var points := 0                      ## dartboard points (spots and floor targets)
var last_ring := 0                   ## the ring the last ball landed in (0 off the board)
var last_off := -1                   ## how far it landed from the board's centre, um (-1: no board)
var toss_at := 0                     ## SETUP: when the held ball is dropped
var spot_lit := false                ## CALL THE SPOT: the spot (target_x, target_z) is showing
var spot_i := -1                     ## which spot
var lane_cross := false              ## LINE AND CROSS: this ball's lane is the cross one
var high_ball := false               ## ATTACK OR DINK: this one is up to put away
var you_fast := false                ## ATTACK OR DINK: your last ball was a speed-up
var rally := 0                       ## DINK PARTNER: your hits back this rally
var best_rally := 0


func copy_settings_from(o: Drill) -> void:
	shot = o.shot
	target = o.target
	rate = o.rate
	partner = o.partner
	partner_pace = o.partner_pace
	cross = o.cross
	kind = o.kind
	lane = o.lane
	spread = o.spread
	targets = o.targets
	speed = o.speed
	machine_at = o.machine_at
	zone = o.zone
	rules = o.rules
	goal = o.goal
	time_limit = o.time_limit
	spot_x = o.spot_x
	spot_z = o.spot_z


## Where the machine stands for these settings.
func machine_spot() -> int:
	match machine_at:
		AT_KITCHEN: return KITCHEN_Z
		AT_BASELINE: return BASELINE_Z
	return KITCHEN_Z if shot == SHOT_DINK else BASELINE_Z


func reset(sim: Sim) -> void:
	if not coach_feed:
		machine_z = machine_spot()       # the coach's machine stays where it was put
	stage = WAIT
	next_feed = sim.tick + FIRST_FEED
	feeds = 0
	good = 0
	streak = 0
	last_result = -1
	sim.ball.held = true
	sim.ball.place(machine_x, MACHINE_Y, machine_z)
	sim.phase = K.PHASE_LIVE
	sim.serving_team = 1
	sim.server_slot = 2
	sim.last_hitter = 2
	sim.players[0].x = spot_x
	sim.players[0].z = spot_z
	target_hits = 0
	ends_at = next_feed + time_limit if time_limit > 0 else -1
	points = 0
	last_ring = 0
	last_off = -1
	rally = 0
	if partner:
		var q := sim.players[2]
		q.x = partner_home_x(spot_x)
		q.z = PARTNER_Z
		q.swing_tick = -1
		sim.ball.place(0, 500000, PARTNER_Z)
	if targets:
		_new_target(sim)
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
	if ends_at >= 0 and stage != DONE and sim.tick >= ends_at:
		stage = DONE                     # time: the ball in the air plays out, nothing more counts
		sim.emit(K.EVENT_TIME_UP, score(), good, best)
	if partner and stage != PARTNER:
		if stage == RETURN and partner_plan >= 0:
			_partner_step(sim.players[2], sim.players[2].goal_x, sim.players[2].goal_z)
		else:
			_partner_home(sim)
	match stage:
		WAIT:
			if sim.tick >= next_feed:
				if shot == SHOT_SERVE:
					_serve_ready(sim)
				elif partner:
					_partner_setup(sim)
				else:
					_feed(sim)
			else:
				sim.ball.step()          # the last ball rolls on
		FLY:
			_fly(sim, p)
		RETURN:
			_return(sim)
		PARTNER:
			_partner(sim)
		SETUP:
			_setup(sim)
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
	if coach_feed:
		_coach_feed(sim)
		return
	var mz := machine_z
	var drive: int = SPEED_PACE[clampi(speed, 0, 3)]
	var tx := p.x
	match t:
		TARGET_FOREHAND: tx = p.x + 900000
		TARGET_BACKHAND: tx = p.x - 900000
	tx = clampi(tx + sim.scatter(250000), -K.COURT_HALF_WIDTH + 300000, K.COURT_HALF_WIDTH - 300000)
	aim_x = tx
	var b := sim.ball
	b.place(0, MACHINE_Y, mz)
	var at_you := t != TARGET_KITCHEN and t != TARGET_DEEP
	var volley := fed_shot == SHOT_DRIVE and at_you and (p.z <= NET_ZONE or rules & RULE_VOLLEY)
	var w: Array[int]
	var v: Array[int]
	if volley:
		# At the net: straight at you through the air, waist to chest high.
		var ty := VOLLEY_Y + sim.scatter(150000)
		w = Aim.topspin(tx, p.z - mz, 300000)
		v = Aim.through(0, MACHINE_Y, mz, tx, ty, p.z, drive, w)
	else:
		# Land a stride or two in front of you (the ball comes up to you).
		var lead := 2200000 if fed_shot != SHOT_LOB else 600000
		var tz := clampi(p.z - lead, 400000, K.COURT_HALF_LENGTH - 300000)
		if t == TARGET_KITCHEN:
			tz = K.KITCHEN_DEPTH * 6 / 10
		elif t == TARGET_DEEP:
			tz = K.COURT_HALF_LENGTH - 800000
		var pace: int = drive
		var spin := 450000
		match fed_shot:
			SHOT_DINK:
				pace = 34000 + drive / 10    # 5 to 6 m/s over the ground
				spin = -200000
				if t != TARGET_DEEP:
					# In your kitchen, about a metre in front of you.
					tz = clampi(p.z - 1100000, 900000, K.KITCHEN_DEPTH * 85 / 100)
			SHOT_LOB:
				pace = 30000 + drive / 4
				spin = 300000
		w = Aim.topspin(tx, tz - mz, spin)
		v = Aim.shot(0, MACHINE_Y, mz, tx, tz, pace, w)
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
	sim.emit(K.EVENT_FEED, tx, 1 if volley else 0, fed_shot)


func _fly(sim: Sim, p: SimTypes.Player) -> void:
	var bx := sim.ball.x
	var by := sim.ball.y
	var bz := sim.ball.z
	var ev := sim.ball.step()
	if ev & Ball.EV_BOUNCE:
		bounces += 1
		sim.bounce_count = bounces
		sim.emit(K.EVENT_BOUNCE, sim.ball.ev_x, sim.ball.ev_z, 0)
	if spots and not spot_lit:
		spot_lit = bounces > 0 if partner_pace >= 2 else bz <= 0 and sim.ball.z > 0
	if bounces >= 2 or sim.ball.rolling or sim.ball.z > K.COURT_HALF_LENGTH + 4 * K.M \
			or sim.tick - fed_at > GIVE_UP:
		_result(sim, RESULT_MISSED)
		return
	if p.cooldown > 0 or not sim.paddle_contact(p, bx, by, bz):
		return
	var volley := bounces == 0
	hit_at = sim.tick
	last_ring = 0                        # this ball hasn't found a board yet
	last_off = -1
	spot_lit = spot_lit or spots         # too late to call it now: show it
	you_fast = Fx.length(sim.ball.vx, 0, sim.ball.vz) >= SPEEDUP_V
	p.cooldown = K.PADDLE_COOLDOWN
	sim.emit(K.EVENT_HIT, 0, sim.ball.speed(), 1 if volley else 0)
	sim.last_hitter = 0
	sim.bounce_count = 0
	if volley and rules & RULE_NO_VOLLEY:
		_result(sim, RESULT_VOLLEY)
	elif not volley and rules & RULE_VOLLEY:
		_result(sim, RESULT_BOUNCE)
	elif volley and rules & RULE_KITCHEN and in_kitchen(p):
		_result(sim, RESULT_KITCHEN)
	else:
		stage = RETURN
		if partner and not resets:
			_partner_reads(sim)


func _return(sim: Sim) -> void:
	if partner and not resets and partner_plan == -1 and sim.tick >= read_at:
		_partner_plan(sim)
	var z0 := sim.ball.z
	var ev := sim.ball.step()
	if ev & Ball.EV_NET:
		sim.emit(K.EVENT_NET, sim.ball.ev_x, sim.ball.ev_y, 0)
		_result(sim, RESULT_NET)
		return
	if resets and z0 > 0 and sim.ball.z <= 0 and sim.ball.y > popup_y():
		_result(sim, RESULT_POPUP)       # they'd put that away
		return
	if not (ev & Ball.EV_BOUNCE):
		if hands and _partner_takes_it(sim):
			return
		if sim.tick - hit_at > RETURN_GIVE_UP:
			_result(sim, RESULT_OUT)
		return
	var x := sim.ball.ev_x
	var z := sim.ball.ev_z
	sim.emit(K.EVENT_BOUNCE, x, z, 0)
	if z > 0:
		_result(sim, RESULT_NET)
		return
	if not K.in_court(x, z):
		_result(sim, RESULT_OUT)
		return
	last_ring = 0
	last_off = -1
	if targets:
		last_off = Fx.length(x - target_x, 0, z - target_z)
		last_ring = ring(last_off, TARGET_RADIUS)
		if last_ring > 0:
			target_hits += 1
			points += last_ring
			sim.emit(K.EVENT_TARGET, x, z, last_ring)
			_new_target(sim)
	var r := RESULT_GOOD
	if partner:
		r = _placed(x, z)
	elif not in_zone(x, z):
		r = RESULT_ZONE
	elif rules & RULE_TOPSPIN and not _topspin(sim.ball):
		r = RESULT_SPIN
	if resets or attack and you_fast:
		_result(sim, r)                  # a fresh ball: a reset's a feed loop, a speed-up ends it
		return
	if partner:
		rally += 1
		best_rally = maxi(best_rally, rally)
	_result(sim, r, partner)        # with a partner, an in-court ball plays on
	if partner and stage == WAIT:
		_partner_chase(sim)


## The ball (just bounced, its spin halved) had topspin along its travel.
func _topspin(b: Ball) -> bool:
	var t := Aim.topspin(b.vx, b.vz, 1000)
	return (t[0] * b.wx + t[2] * b.wz) / 1000 > 60000


## RESETS: a ball higher than this over the net is a pop-up.
## A run's score (ADR-022): a point for each good ball, and a dartboard's
## points on top.
func score() -> int:
	return good + points


## A timed run's ticks left (0 when free play or over).
func time_left(sim: Sim) -> int:
	return clampi(ends_at - sim.tick, 0, time_limit) if ends_at >= 0 else 0


func popup_y() -> int:
	return K.NET_HEIGHT_CENTER + POPUP_OVER[clampi(partner_pace, 0, 2)]


func in_zone(x: int, z: int) -> bool:
	match zone:
		ZONE_KITCHEN: return -z <= DINK_ZONE
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


func _result(sim: Sim, r: int, rally_on := false) -> void:
	last_result = r
	if targets and last_ring == 0 and hit_at > fed_at:
		_new_target(sim)                 # missed it: somewhere new to try (ADR-019)
	if partner and not rally_on:
		rally = 0
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
	next_feed = maxi(fed_at + (feed_every if coach_feed else RATE_TICKS[clampi(rate, 0, 3)]), sim.tick + MIN_GAP)
	if partner:
		next_feed = sim.tick + MIN_GAP * 2   # the partner picks up a fresh ball


# --- DINK PARTNER -------------------------------------------------------------

## A fresh rally: the partner holds the ball up, then drops it.
func _partner_setup(sim: Sim) -> void:
	var q := sim.players[2]
	stage = SETUP
	toss_at = sim.tick + HOLD_TICKS
	var b := sim.ball
	b.held = true
	b.place(_hold_x(q), HOLD_Y, q.z + 350000)
	b.launch(0, 0, 0)
	b.set_spin(0, 0, 0)
	partner_plan = toss_at + _drop_ticks()


## The held ball: a hand's width to the free hand's side of centre.
static func _hold_x(q: SimTypes.Player) -> int:
	return q.x - K.right_sign(q.team) * 100000


## Ticks from the drop to the strike: dinks low, a HANDS feed or a RESETS
## drive from the waist.
func _drop_ticks() -> int:
	var strike := HANDS_HEIGHT - 150000 if hands or resets else 500000
	var b := Ball.new()
	b.held = false
	b.place(0, HOLD_Y, 0)
	b.launch(0, DROP_VY, 0)
	for i in 120:
		b.step()
		if b.vy < 0 and b.y <= strike:
			return i + 1
	return 60


func _setup(sim: Sim) -> void:
	var q := sim.players[2]
	var b := sim.ball
	if sim.tick < toss_at:
		b.place(_hold_x(q), HOLD_Y, q.z + 350000)    # in the hand, following them
		return
	if sim.tick == toss_at:
		b.held = false
		b.launch(0, DROP_VY, 0)
	b.step()
	if sim.tick >= partner_plan:
		partner_plan = -1
		_partner_dink(sim, b.x, b.y, b.z)

## A dink from (x, y, z) to land about a metre in front of you, near your
## line: the partner's every shot.
func _partner_dink(sim: Sim, x: int, y: int, z: int) -> void:
	if hands:
		_partner_volley(sim, x, y, z)
		return
	if resets:
		_partner_drive(sim, x, y, z)
		return
	var level := clampi(partner_pace, 0, 2)
	var clear: int = PARTNER_CLEAR[level]
	var p := sim.players[0]
	# Bounce about a metre in front of you on the line from here to you, so
	# after the bounce the ball carries on to you, cross court too (a
	# bounce at your x would drift on past you, ADR-010 amended).
	var tz := clampi(p.z - 1000000 + sim.scatter(250000), 600000, K.KITCHEN_DEPTH * 85 / 100)
	match kind:
		KIND_VOLLEYS:
			_partner_floater(sim, x, y, z)
			_call_spot(sim)
			return
		KIND_SPOTS:
			_call_spot(sim)
		KIND_LANES:
			_call_lane(sim)
		KIND_ATTACK:
			high_ball = sim.random(100) < ATTACK_HIGH_PCT
			clear = ATTACK_HIGH_CLEAR[level] if high_ball else ATTACK_LOW_CLEAR[level]
			if high_ball:
				tz = K.KITCHEN_DEPTH - 600000 + sim.scatter(100000)   # sits up at your line
	_partner_shot(sim, x, y, z, tz, clear)


## The dink itself: to land at depth `tz` on your side, `clear` over the tape.
func _partner_shot(sim: Sim, x: int, y: int, z: int, tz: int, clear: int) -> void:
	var p := sim.players[0]
	var q := sim.players[2]
	# SPREAD: mostly to your forehand or backhand at a reach, now and then
	# at you (a target, never dead centre every time).
	var r: Array = SPREADS[clampi(spread, 0, SPREADS.size() - 1)]
	var off: int = r[0] + sim.random(r[1] - r[0] + 1)
	if sim.random(100) < 15:
		off = sim.random(150001)
	var want_x := p.x + (off if sim.random(2) == 0 else -off)
	var tx := clampi(x + (want_x - x) * (tz - z) / maxi(p.z - z, 1), -K.COURT_HALF_WIDTH + 300000,
		K.COURT_HALF_WIDTH - 300000)
	if feed_set:
		feed_set = false                 # the coach's spot, once
		tx = feed_x
		tz = feed_z
	var level := clampi(partner_pace, 0, 2)
	var pace: int = PARTNER_PACE[level]
	var w := Aim.topspin(tx - x, tz - z, -150000)
	var v := Aim.shot(x, y, z, tx, tz, pace, w, clear)
	var b := sim.ball
	b.place(x, maxi(y, K.BALL_RADIUS), z)
	b.launch(v[0], v[1], v[2])
	b.set_spin(w[0], w[1], w[2])
	aim_x = tx
	sim.required_bounce = K.REQUIRED_BOUNCE_NONE
	sim.last_hitter = 2
	sim.bounce_count = 0
	bounces = 0
	feeds += 1
	fed_at = sim.tick
	q.swing_tick = sim.tick
	stage = FLY
	sim.emit(K.EVENT_HIT, 2, b.speed(), 0)


## You've hit: the partner reads it after a moment (a person's reaction),
## then moves to meet it, letting it bounce (the two-bounce machinery
## makes the planner wait for the bounce).
func _partner_reads(sim: Sim) -> void:
	# Dinks: let it bounce (the two-bounce machinery makes the planner wait).
	# HANDS: take it out of the air.
	sim.required_bounce = K.REQUIRED_BOUNCE_NONE if hands else K.REQUIRED_BOUNCE_SERVE
	sim.serving_team = 0
	partner_plan = -1
	read_at = sim.tick + (HANDS_REACT if hands else PARTNER_REACT)


## HANDS: a firm volley straight at you through the air, to your forehand,
## backhand or body as SPREAD has it.
func _partner_volley(sim: Sim, x: int, y: int, z: int) -> void:
	var p := sim.players[0]
	var q := sim.players[2]
	var r: Array = SPREADS[clampi(spread, 0, SPREADS.size() - 1)]
	var off: int = r[0] + sim.random(r[1] - r[0] + 1)
	if sim.random(100) < 20 or rally == 0:
		off = sim.random(150001)         # the feed comes at you: you know where to look
	var tx := clampi(p.x + (off if sim.random(2) == 0 else -off), -K.COURT_HALF_WIDTH + 300000,
		K.COURT_HALF_WIDTH - 300000)
	var ty := HANDS_HEIGHT + sim.scatter(150000)
	var full: int = HANDS_PACE[clampi(partner_pace, 0, 2)]
	var pace := full
	if rally < HANDS_RAMP:
		pace = HANDS_FEED + (full - HANDS_FEED) * (rally + 1) / (HANDS_RAMP + 1) if rally > 0 else HANDS_FEED
	var w := Aim.topspin(tx - x, p.z - z, 250000)
	var v := Aim.through(x, maxi(y, 300000), z, tx, ty, p.z, pace, w)
	var b := sim.ball
	b.place(x, maxi(y, 300000), z)
	b.launch(v[0], v[1], v[2])
	b.set_spin(w[0], w[1], w[2])
	aim_x = tx
	sim.required_bounce = K.REQUIRED_BOUNCE_NONE
	sim.last_hitter = 2
	sim.bounce_count = 0
	bounces = 0
	feeds += 1
	fed_at = sim.tick
	q.swing_tick = sim.tick
	stage = FLY
	sim.emit(K.EVENT_HIT, 2, b.speed(), 0)


## HANDS: your volley reaching the partner in the air. Returns true if it
## volleyed it back (your shot counted, the rally goes on).
func _partner_takes_it(sim: Sim) -> bool:
	var b := sim.ball
	var q := sim.players[2]
	if bounces > 0 or b.z >= 0 or b.vz >= 0:
		return false
	if b.y < 250000 or b.y > 1900000 or Fx.length(b.x - q.x, 0, b.z - q.z) > K.REACH:
		return false
	if partner_plan >= 0 and sim.tick < partner_plan - 1 and b.z > q.z:
		return false                     # not yet: it meets the ball where it planned
	if sim.going_out(1):
		return false                     # going out: it leaves it
	rally += 1
	best_rally = maxi(best_rally, rally)
	_result(sim, RESULT_GOOD, true)
	_partner_volley(sim, b.x, b.y, b.z)
	return true


func _partner_plan(sim: Sim) -> void:
	var q := sim.players[2]
	var plan := Intercept.plan(sim, 1, q.x, q.z, PARTNER_SPEED, -1, 1, HANDS_HIGH if hands else Intercept.COMFORT_HIGH)
	if plan.is_empty():
		partner_plan = -2                # unreachable: it stays put and the bounce decides
		return
	partner_plan = sim.tick + plan[0]
	q.goal_x = plan[4]
	q.goal_z = plan[5]


## Your ball just bounced on their side, in: the partner refines its plan.
func _partner_chase(sim: Sim) -> void:
	var q := sim.players[2]
	stage = PARTNER
	bounces = 1
	sim.bounce_count = 1
	sim.last_hitter = 0
	sim.required_bounce = K.REQUIRED_BOUNCE_NONE
	var plan := Intercept.plan(sim, 1, q.x, q.z, PARTNER_SPEED)
	var had_plan := partner_plan >= 0
	partner_plan = -1
	if not plan.is_empty():
		partner_plan = sim.tick + plan[0]
		q.goal_x = plan[4]
		q.goal_z = plan[5]
	elif not had_plan:
		q.goal_x = q.x                   # no plan before or now: it stays put
		q.goal_z = q.z


func _partner(sim: Sim) -> void:
	var q := sim.players[2]
	var ev := sim.ball.step()
	if ev & Ball.EV_BOUNCE:
		bounces += 1
	_partner_step(q, q.goal_x, q.goal_z)
	var b := sim.ball
	if bounces >= 2 or b.rolling or b.z < -(K.COURT_HALF_LENGTH + 3 * K.M) or b.z > 0:
		stage = WAIT                     # out of its reach: a fresh ball
		next_feed = sim.tick + MIN_GAP * 2
		return
	var near := Fx.length(b.x - q.x, 0, b.z - q.z) <= K.REACH
	var height := b.y >= K.REACH_LOW and b.y <= 1500000
	if near and height and (partner_plan < 0 or sim.tick >= partner_plan - 1 or b.vy < 0 and b.y < 500000):
		_partner_dink(sim, b.x, b.y, b.z)


## Between shots the partner squares up to you along its kitchen line:
## straight across, or diagonally (CROSS COURT: the other half).
## A floor target sits in front of the partner, so when you cross to the
## other side (well past the middle), it follows.
func _partner_home(sim: Sim) -> void:
	_partner_step(sim.players[2], partner_home_x(sim.players[0].x), PARTNER_Z)
	var you_x := sim.players[0].x
	if targets and absi(you_x) > SIDE_SWITCH and signi(partner_home_x(you_x)) != target_side:
		_new_target(sim)


func partner_home_x(you_x: int) -> int:
	var x := clampi(you_x, -K.COURT_HALF_WIDTH / 2, K.COURT_HALF_WIDTH / 2)
	if cross:
		# You on the near side's right (+x) face a partner on their right (+x
		# for them is -x): the diagonal.
		return -signi(x if x != 0 else 1) * K.COURT_HALF_WIDTH / 2
	return x


func _partner_step(q: SimTypes.Player, gx: int, gz: int) -> void:
	var dx := gx - q.x
	var dz := gz - q.z
	var d := Fx.length(dx, 0, dz)
	if d <= PARTNER_SPEED:
		q.x = gx
		q.z = gz
	else:
		q.x += dx * PARTNER_SPEED / d
		q.z += dz * PARTNER_SPEED / d


# --- Floor targets -----------------------------------------------------------------

## RESETS: a speed-up at you, low (shins to hips), to your forehand,
## backhand or body as SPREAD has it.
func _partner_drive(sim: Sim, x: int, y: int, z: int) -> void:
	var p := sim.players[0]
	var q := sim.players[2]
	var r: Array = SPREADS[clampi(spread, 0, SPREADS.size() - 1)]
	var off: int = r[0] + sim.random(r[1] - r[0] + 1)
	if sim.random(100) < 30:
		off = sim.random(150001)
	var tx := clampi(p.x + (off if sim.random(2) == 0 else -off), -K.COURT_HALF_WIDTH + 300000,
		K.COURT_HALF_WIDTH - 300000)
	var ty := RESET_HEIGHT + sim.scatter(200000)
	var pace: int = RESET_PACE[clampi(partner_pace, 0, 2)]
	var w := Aim.topspin(tx - x, p.z - z, 300000)
	var v := Aim.through(x, maxi(y, 300000), z, tx, ty, p.z, pace, w)
	var b := sim.ball
	b.place(x, maxi(y, 300000), z)
	b.launch(v[0], v[1], v[2])
	b.set_spin(w[0], w[1], w[2])
	aim_x = tx
	sim.required_bounce = K.REQUIRED_BOUNCE_NONE
	sim.last_hitter = 2
	sim.bounce_count = 0
	bounces = 0
	feeds += 1
	fed_at = sim.tick
	q.swing_tick = sim.tick
	stage = FLY
	sim.emit(K.EVENT_HIT, 2, b.speed(), 0)


## VOLLEY DINKS: a soft floater that passes you about waist high at your
## kitchen line (it would land behind you): take it out of the air.
func _partner_floater(sim: Sim, x: int, y: int, z: int) -> void:
	var p := sim.players[0]
	var q := sim.players[2]
	var level := clampi(partner_pace, 0, 2)
	var r: Array = SPREADS[clampi(spread, 0, SPREADS.size() - 1)]
	var off: int = r[0] + sim.random(r[1] - r[0] + 1)
	if sim.random(100) < 20:
		off = sim.random(150001)
	var tx := clampi(p.x + (off if sim.random(2) == 0 else -off), -K.COURT_HALF_WIDTH + 300000,
		K.COURT_HALF_WIDTH - 300000)
	var ty: int = FLOAT_Y[level] + sim.scatter(100000)
	var w := Aim.topspin(tx - x, p.z - z, -100000)
	var v := Aim.through(x, maxi(y, 300000), z, tx, ty, p.z, FLOAT_PACE[level], w)
	var b := sim.ball
	b.place(x, maxi(y, 300000), z)
	b.launch(v[0], v[1], v[2])
	b.set_spin(w[0], w[1], w[2])
	aim_x = tx
	sim.required_bounce = K.REQUIRED_BOUNCE_NONE
	sim.last_hitter = 2
	sim.bounce_count = 0
	bounces = 0
	feeds += 1
	fed_at = sim.tick
	q.swing_tick = sim.tick
	stage = FLY
	sim.emit(K.EVENT_HIT, 2, b.speed(), 0)


## CALL THE SPOT: one of four spots on their side for this ball: their
## left or right corner of the kitchen, the middle, or at their feet. It
## lights as they hit (EASY), as it crosses the net (MEDIUM) or as it
## bounces on your side (HARD); VOLLEY DINKS light it as they hit.
func _call_spot(sim: Sim) -> void:
	if target_pinned:
		spot_lit = partner_pace <= 0 or kind == KIND_VOLLEYS
		return
	var q := sim.players[2]
	var kd := K.KITCHEN_DEPTH
	var wx := K.COURT_HALF_WIDTH - 700000
	var at: Array = [[-wx, -kd * 55 / 100], [wx, -kd * 55 / 100], [0, -kd * 40 / 100],
		[clampi(q.x, -wx, wx), -(kd - 350000)]]
	var i := sim.random(at.size() - 1)
	if i >= spot_i and spot_i >= 0:
		i += 1                           # never the same spot twice running
	spot_i = i
	target_x = at[i][0]
	target_z = at[i][1]
	spot_lit = partner_pace <= 0 or kind == KIND_VOLLEYS


## A coach's target (C-8): there, and staying there (`pin`), or back to
## moving as the drill moves it. Their side, in court, a board's reach
## from the net. A drill without a board gets the floor target.
func pin_target(sim: Sim, x: int, z: int, pin: bool) -> void:
	target_pinned = pin
	if not pin:
		if targets:
			_new_target(sim)
		return
	if not spots and not lanes:
		targets = true
	target_x = clampi(x, -K.COURT_HALF_WIDTH + 300000, K.COURT_HALF_WIDTH - 300000)
	target_z = clampi(z, -(K.COURT_HALF_LENGTH - 300000), -300000)
	target_side = signi(target_x) if target_x != 0 else 1
	spot_lit = spot_lit or spots


## The coach's machine (C-21): [machine x, z, bounce x, z, pace, spin,
## clear, every], each kept in reach. The machine stands on their side;
## the ball bounces on yours.
func coach_machine(a: Array) -> void:
	if a.size() < 8:
		return
	coach_feed = true
	machine_x = clampi(int(a[0]), -K.COURT_HALF_WIDTH - 500000, K.COURT_HALF_WIDTH + 500000)
	machine_z = clampi(int(a[1]), -(K.COURT_HALF_LENGTH + 500000), -500000)
	bounce_x = clampi(int(a[2]), -K.COURT_HALF_WIDTH, K.COURT_HALF_WIDTH)
	bounce_z = clampi(int(a[3]), 300000, K.COURT_HALF_LENGTH)
	feed_pace = clampi(int(a[4]), FEED_PACE_RANGE[0], FEED_PACE_RANGE[1])
	feed_spin = clampi(int(a[5]), -FEED_SPIN_MAX, FEED_SPIN_MAX)
	feed_clear = clampi(int(a[6]), FEED_CLEAR_RANGE[0], FEED_CLEAR_RANGE[1])
	feed_every = clampi(int(a[7]), FEED_EVERY_RANGE[0], FEED_EVERY_RANGE[1])


## A ball from the coach's machine: from where it stands to bounce where
## the coach put it, at its pace, spin and height over the net.
func _coach_feed(sim: Sim) -> void:
	fed_shot = SHOT_DRIVE
	aim_x = bounce_x
	var w := Aim.topspin(bounce_x - machine_x, bounce_z - machine_z, feed_spin)
	var v := Aim.shot(machine_x, MACHINE_Y, machine_z, bounce_x, bounce_z, feed_pace, w, feed_clear)
	var b := sim.ball
	b.place(machine_x, MACHINE_Y, machine_z)
	b.launch(v[0], v[1], v[2])
	b.set_spin(w[0], w[1], w[2])
	sim.required_bounce = K.REQUIRED_BOUNCE_SERVE if rules & RULE_NO_VOLLEY else K.REQUIRED_BOUNCE_NONE
	sim.serving_team = 1
	sim.last_hitter = 2
	sim.bounce_count = 0
	bounces = 0
	feeds += 1
	fed_at = sim.tick
	stage = FLY
	sim.emit(K.EVENT_FEED, bounce_x, 0, fed_shot)


## A coach's spot for the partner's next ball (C-9): your side, in court.
func feed_to(x: int, z: int) -> void:
	feed_set = true
	feed_x = clampi(x, -K.COURT_HALF_WIDTH + 300000, K.COURT_HALF_WIDTH - 300000)
	feed_z = clampi(z, 600000, K.COURT_HALF_LENGTH - 300000)


## The dartboard ring at `off` um from the centre of one `radius` across:
## 3 the bullseye .. 1 the outer ring, 0 off it.
static func ring(off: int, radius: int) -> int:
	var r := 0
	for i in RING_EDGES.size():
		if off * 100 <= radius * RING_EDGES[i]:
			r = i + 1
	return r


## You, in your kitchen as practice judges it: the head past the line by
## more than a lean.
func in_kitchen(p: SimTypes.Player) -> bool:
	return K.in_kitchen(p.x, p.z + KITCHEN_LEAN, 0)


func spot_radius() -> int:
	return SPOT_RADIUS[clampi(partner_pace, 0, 2)]


## LINE AND CROSS: the lane for this ball, half their dink zone: straight
## ahead of you (LINE) or the diagonal (CROSS).
func _call_lane(sim: Sim) -> void:
	match lane:
		LANE_LINE: lane_cross = false
		LANE_CROSS: lane_cross = true
		_: lane_cross = not lane_cross
	var you := signi(sim.players[0].x) if sim.players[0].x != 0 else 1
	var s := -you if lane_cross else you
	target_x = s * K.COURT_HALF_WIDTH / 2
	target_z = -DINK_ZONE / 2
	spot_lit = true


## Where this drill's ball counts: GOOD, or why not (it landed in court on
## their side at (x, z)).
func _placed(x: int, z: int) -> int:
	if attack:
		if you_fast:
			return RESULT_GOOD if high_ball else RESULT_PATIENT
		if high_ball:
			return RESULT_ATTACK
	if not in_zone(x, z):
		return RESULT_ZONE
	if spots:
		last_off = Fx.length(x - target_x, 0, z - target_z)
		last_ring = ring(last_off, spot_radius())
		if last_ring == 0:
			return RESULT_SPOT
		points += last_ring
	if lanes and signi(x) != signi(target_x):
		return RESULT_LANE
	return RESULT_GOOD


## The mode and level, for the swing log (ADR-017).
func mode_name() -> String:
	if partner:
		var n: String = KIND_NAMES[kind] + " " + PACE_NAMES[clampi(partner_pace, 0, 2)]
		return n + " " + LANE_NAMES[lane] if lanes else n
	if goal > 0:
		return "LESSON"
	if coach_feed:
		return "COACH MACHINE"
	return "MACHINE %s %s" % [SHOT_NAMES[shot], SPEED_NAMES[clampi(speed, 0, SPEED_NAMES.size() - 1)]]


## A new target in the return zone (their kitchen for a partner), not on
## top of the last one.
func _new_target(sim: Sim) -> void:
	if target_pinned:
		return
	var hw := K.COURT_HALF_WIDTH - 600000
	var lo := 1000000
	var hi := K.COURT_HALF_LENGTH - 600000
	var xlo := -hw
	var xhi := hw
	var z2 := zone if not partner else ZONE_KITCHEN
	if partner:
		# The partner's half of their kitchen: across from you, or the
		# diagonal (CROSS COURT); wherever you are now.
		var you_x := sim.players[0].x
		var px := partner_home_x(you_x if you_x != 0 else spot_x)
		target_side = signi(px) if px != 0 else 1
		xlo = 400000 if target_side > 0 else -hw
		xhi = hw if target_side > 0 else -400000
	match z2:
		ZONE_KITCHEN:
			lo = 900000                  # not a hair over the net: a dink you can drop there
			hi = DINK_ZONE - 450000
		ZONE_DEEP:
			lo = K.COURT_HALF_LENGTH * 2 / 3 + 400000
		ZONE_LEFT:
			xhi = -400000
		ZONE_RIGHT:
			xlo = 400000
	var last_x := target_x
	for k in 4:
		target_x = xlo + sim.random(xhi - xlo + 1)
		target_z = -(lo + sim.random(hi - lo + 1))
		if absi(target_x - last_x) > 1000000:
			break


func snapshot() -> Array:
	return [stage, next_feed, fed_at, fed_shot, bounces, feeds, good, streak, best, last_result, aim_x,
		hit_at, machine_z, partner_plan, read_at, target_x, target_z, target_hits, rally, best_rally,
		1 if partner else 0, kind, lane, toss_at, 1 if spot_lit else 0, spot_i, 1 if lane_cross else 0,
		1 if high_ball else 0, 1 if you_fast else 0, points, last_ring, last_off, target_side, time_limit, ends_at,
		1 if target_pinned else 0, 1 if feed_set else 0, feed_x, feed_z,
		1 if coach_feed else 0, machine_x, bounce_x, bounce_z, feed_pace, feed_spin, feed_clear, feed_every]
