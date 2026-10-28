## Simulation constants. World units are micrometres (um) in Godot's axes:
## y up, the net on the plane z = 0, the near side (team 0, the human) at
## z > 0. Time is ticks at TICK_HZ; velocity is um per tick. Change a value
## here and the golden trace changes with it (ADR-002).
class_name K
extends RefCounted

const TICK_HZ := 120
const MM := 1000
const M := 1000000

# --- Court (USA Pickleball rulebook, section 2): 20 x 44 ft, the kitchen
# 7 ft deep, every line part of the area it bounds. Half sizes from the
# centre, measured to the outside of the lines.
const COURT_HALF_WIDTH := 3048000
const COURT_HALF_LENGTH := 6705600
const KITCHEN_DEPTH := 2133600
const LINE_WIDTH := 50800
const NET_HEIGHT_CENTER := 863600
const NET_HEIGHT_POST := 914400
const NET_POST_X := 3352800          ## posts 1 ft outside the sidelines
## Players stay this far behind the baseline at most, and off the net.
const RUNOFF_BACK := 3500000
const RUNOFF_SIDE := 2500000
const NET_GAP := 250000

# --- Ball: 74 mm, 26 g. Drag is k|v|v with k = rho Cd A / 2m ~ 0.040 /m,
# as um/tick^2 per (um/tick)^2, times 2^32.
const BALL_RADIUS := 37000
const GRAVITY := 681                 ## 9.807 m/s^2
const DRAG_Q32 := 171
const BOUNCE_VERTICAL_256 := 172     ## 0.67 (drag takes the rest): 78 in drop, back to 31
const BOUNCE_FRICTION_256 := 51      ## the bounce takes 0.2 of the slip at the contact
                                     ## (no spin: 0.80 of the speed along the ground kept)
const ROLL_VY := 1250                ## a bounce slower than 0.15 m/s rolls
const ROLL_FRICTION_256 := 250
const NET_KEEP_256 := 64             ## off the net: a quarter of the speed back

# --- Spin (ADR-006): angular velocity in urad/tick. Magnus: a = k (w x v)
# with k ~ 0.002 (a holed ball curves less than a tennis ball), times 2^32
# and per urad.
const MAGNUS_Q32 := 9
const SPIN_DECAY_256 := 255          ## per tick: about 0.6 left after a second
const SPIN_BOUNCE_KEEP_256 := 128
const SPIN_MAX := 1600000            ## 190 rad/s, about 1800 rpm
const SPIN_BRUSH_PCT := 40           ## of the paddle's brush across the ball that becomes spin
const SPIN_KEEP_ON_HIT_PCT := 25     ## of the incoming spin that survives a hit
const URAD := 1000000

# --- Paddle: the face as a disc (contact), 8 x 10 in; half thickness.
const PADDLE_FACE_RADIUS := 115000
const PADDLE_HALF_THICK := 8000
const PADDLE_E_256 := 128            ## paddle-ball restitution 0.5, mid-speed (see paddle_e)
## Restitution falls with the impact (ADR-003, tuned on the lead's logged
## swings): lively for touch, deader for a hard hit, like a real ball.
## 0.66 up to 4 m/s of closing speed, easing to 0.34 at 9 m/s and beyond.
const PADDLE_E_SOFT_256 := 169
const PADDLE_E_HARD_256 := 87
const PADDLE_SOFT_V := 33333         ## 4 m/s, um/tick
const PADDLE_HARD_V := 75000         ## 9 m/s
## A fast ball keeps its pace off a soft face (ADR-003 amended, the lead's
## blocks in HANDS): the incoming ball's own speed comes back with up to
## 0.6, not the hard-hit 0.34, when the face barely moves. It ramps in from
## 6 m/s of incoming speed (full at 9) and fades out as the swing reaches
## 5 m/s, so dinks and swings keep the tuning above.
const BLOCK_E_256 := 154
const BLOCK_FROM_V := 50000          ## 6 m/s
const BLOCK_FULL_V := 75000          ## 9 m/s
const BLOCK_SWING_V := 41667         ## 5 m/s: a full swing gets no block bonus
const PADDLE_EDGE_LOSS_PCT := 20     ## at the face's rim, 20% of that is lost (ADR-006; was 40)
## The face grips the ball: half the slide between them is taken out
## (a hollow ball rolling without slip would lose 60%). ADR-003 amended.
const PADDLE_GRIP_256 := 128
const PADDLE_COOLDOWN := 15          ## ticks before a paddle can hit again
const Q14 := 16384                   ## unit vectors are Q14

# --- Shot assist (ADR-003): how far a human's shot is pulled toward the
# nearest good one, in percent.
const ASSIST_OFF := 0
const ASSIST_LOW := 35
const ASSIST_MID := 65
const ASSIST_FULL := 100
const ASSIST_MARGIN := 300000        ## assisted shots land this far inside lines
const NET_CLEAR := 120000            ## aimed shots clear the tape by this much

# --- Players
const MAX_PLAYERS := 4
const NO_SLOT := -1
const NO_TEAM := -1
const HEAD_HEIGHT := 1650000         ## flat mode and the CPUs' eyes
const REACH := 950000                ## from a body to a ball it can hit
const REACH_LOW := 150000
const REACH_HIGH := 2300000

# --- Rules and phases (the SNES sim's, ported: port ADR-055 etc.)
const POINTS_TO_WIN := 5             ## the ROM's default (K.POINTS_TO_WIN)

const PHASE_SERVE_SETUP := 0
const PHASE_SERVE := 1               ## the server holds the ball
const PHASE_TOSS := 2                ## tossed or dropped, not yet struck
const PHASE_LIVE := 3
const PHASE_POINT_RESULT := 4
const PHASE_MATCH_RESULT := 5

const SETUP_TICKS := 60
const CPU_SERVE_TICKS := 150
const TOSS_TICKS := 360              ## a toss nobody hits is served again
const POINT_RESULT_TICKS := 270
const STILL_TICKS := 240             ## a ball that stops rolling ends the point

const REQUIRED_BOUNCE_NONE := 0
const REQUIRED_BOUNCE_SERVE := 1     ## the receiver lets the serve bounce
const REQUIRED_BOUNCE_RETURN := 2    ## the server lets the return bounce

const FAULT_NONE := 0
const FAULT_NET := 1
const FAULT_KITCHEN := 2
const FAULT_WRONG_BOX := 3
const FAULT_OUT := 4
const FAULT_SECOND_BOUNCE := 5
const FAULT_EARLY_VOLLEY := 6

# --- Commands: changes to a running match that aren't a pad's (port ADR-102)
const CMD_NEW_MATCH := 0

# --- Events: [kind, a, b, c, tick]
const EVENT_HIT := 0                 ## slot, speed um/tick, volley 0/1
const EVENT_BOUNCE := 1              ## x, z
const EVENT_NET := 2                 ## x, y
const EVENT_FAULT := 3               ## fault, losing team
const EVENT_POINT := 4               ## winning team
const EVENT_SERVE := 5               ## server slot
const EVENT_MATCH := 6               ## winning team
const EVENT_TOSS := 7                ## server slot
const EVENT_FEED := 8                ## the machine fed: target x, z, shot
const EVENT_DRILL := 9               ## a drill's result: result, streak, finished 0/1
const EVENT_TARGET := 10             ## a floor target hit: x, z, hits so far


static func fault_text(f: int) -> String:
	match f:
		FAULT_NET: return "NET!"
		FAULT_KITCHEN: return "KITCHEN!"
		FAULT_WRONG_BOX: return "FAULT!"
		FAULT_OUT: return "OUT!"
		FAULT_SECOND_BOUNCE: return "2 BOUNCES"
		FAULT_EARLY_VOLLEY: return "VOLLEY!"
	return ""


## +1 if the team's side is z > 0.
## The swing curve (ADR-003, tuned on the lead's logged sessions): a VR
## controller weighs nothing, so touch comes out underhit and an average
## swing overhit. The face's effective speed for the hit, as straight
## segments through these points (m/s): 2.5 -> 3.05 (touch x1.22),
## 4.2 -> 4.0, 6.5 -> 4.15 (a bigger, unhurried swing levels off: a firm,
## controlled ball, not a long one), 9 -> 5.8, then +0.62 per m/s (a
## put-away still drives). Only the face's speed at contact counts, not
## how far it travelled. It only ever rises. um/tick.
const SWING_CURVE := [[0, 0], [20833, 25417], [35000, 33333], [54167, 34583], [75000, 48333]]
const SWING_TAIL_256 := 159          ## the slope past the last point, Q8


static func swing_eff(s: int) -> int:
	for i in range(1, SWING_CURVE.size()):
		var a: Array = SWING_CURVE[i - 1]
		var b: Array = SWING_CURVE[i]
		if s <= b[0]:
			return a[1] + (b[1] - a[1]) * (s - a[0]) / (b[0] - a[0])
	var last: Array = SWING_CURVE[-1]
	return last[1] + (s - last[0]) * SWING_TAIL_256 / 256


## The curve as a multiplier, Q8.
static func swing_gain(s: int) -> int:
	return swing_eff(s) * 256 / s if s > 0 else 312


## The face speed whose swing-curved speed is `eff` (the bot swings by it).
static func swing_for(eff: int) -> int:
	var lo := 0
	var hi := eff * 2 + 1000
	for k in 30:
		var mid := (lo + hi) / 2
		if swing_eff(mid) < eff:
			lo = mid + 1
		else:
			hi = mid
	return lo


## The paddle's restitution (Q8) at a closing speed of `v` um/tick.
static func paddle_e(v: int) -> int:
	var t := clampi(v - PADDLE_SOFT_V, 0, PADDLE_HARD_V - PADDLE_SOFT_V)
	return PADDLE_E_SOFT_256 - (PADDLE_E_SOFT_256 - PADDLE_E_HARD_256) * t / (PADDLE_HARD_V - PADDLE_SOFT_V)


## The restitution (Q8) the incoming ball's own normal speed `v_in` comes
## back with, when the face moves into it at `u` and the hit's restitution is
## `e`: `e`, raised toward BLOCK_E for a fast ball met by a still face.
static func block_e(e: int, v_in: int, u: int) -> int:
	var fast := clampi(v_in - BLOCK_FROM_V, 0, BLOCK_FULL_V - BLOCK_FROM_V)
	var lift := (BLOCK_E_256 - e) * fast / (BLOCK_FULL_V - BLOCK_FROM_V)
	if lift <= 0:
		return e
	return e + lift * clampi(BLOCK_SWING_V - u, 0, BLOCK_SWING_V) / BLOCK_SWING_V


static func side_sign(team: int) -> int:
	return 1 if team == 0 else -1


## The x sign of a team's right-hand court, as its players face the net.
static func right_sign(team: int) -> int:
	return 1 if team == 0 else -1


static func side_of_z(z: int) -> int:
	return 0 if z > 0 else 1


static func net_height(x: int) -> int:
	var ax := absi(x)
	if ax >= NET_POST_X:
		return NET_HEIGHT_POST
	return NET_HEIGHT_CENTER + (NET_HEIGHT_POST - NET_HEIGHT_CENTER) * ax / NET_POST_X


static func in_court(x: int, z: int) -> bool:
	return absi(x) <= COURT_HALF_WIDTH and absi(z) <= COURT_HALF_LENGTH


## The kitchen of `team` (its line in it).
static func in_kitchen(x: int, z: int, team: int) -> bool:
	var d := z * side_sign(team)
	return d >= 0 and d <= KITCHEN_DEPTH and absi(x) <= COURT_HALF_WIDTH
