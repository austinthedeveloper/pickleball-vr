## BRICK BREAK (ADR-030): breakout on the court. A wall of bricks stands
## across the far court with glass either side of it, and every ball that
## reaches the wall comes back over the net to you: off the brick it broke
## or off the wall behind. The angle you hit it at carries on (it leaves the
## wall mirrored, as off a breakout paddle) and the height it met the wall
## at says how deep it comes back. Break every brick for the next level; a
## ball you don't get back to the wall costs one of your three. Pure like
## the sim: it lives in the sim's state and runs from Sim.step.
class_name Breakout
extends RefCounted

## The wall: the court's width, this far past the net (4.5 m).
const WALL_Z := -(K.KITCHEN_DEPTH + 2400000)
const COLS := 7
const ROWS := 6
const BRICK_W := 2 * K.COURT_HALF_WIDTH / COLS     ## 87 cm
const BRICK_H := 300000
const BRICK_BOTTOM := 300000         ## the bottom row's foot, 30 cm up
const BRICK_TOP := BRICK_BOTTOM + ROWS * BRICK_H   ## 2.1 m
## The wall behind the bricks and the glass are drawn this high; the sim
## returns a ball off them however high it is.
const WALL_TOP := 3000000
## A brick's hits: 1 to 3, or steel (never breaks, never needed).
const STEEL := -1

## The levels, top row first: . nothing, 1-3 a brick's hits, # steel.
## After the last they come round again, faster.
const LEVELS := [
	[".......", ".......", ".......", "1111111", "1111111", "1111111"],
	[".......", ".......", "2222222", "1111111", "1111111", "1111111"],
	[".......", "3.3.3.3", "2222222", "2111112", "1111111", "1111111"],
	["1#1#1#1", "2222222", "3333333", "2222222", "1111111", "1111111"],
	["3333333", "2#2#2#2", "2222222", "1111111", "1#1#1#1", "1111111"],
]

const LIVES := 3
## Where you stand to start: the middle, a stride inside the baseline.
const SPOT_Z := K.COURT_HALF_LENGTH - 600000
## The launcher in the middle of the wall: a ball shows there, then comes.
const LAUNCH_Y := 1200000
const FIRST_HOLD := 180              ## 1.5 s at the start of a level
const HOLD_TICKS := 90
const FEED_PACE := 45000             ## 5.4 m/s: the launcher's ball is an easy one
## The wall's return: its pace over the ground by DIFFICULTY (6, 7.4, 9
## m/s), a little faster each level up to five.
const RETURN_PACE := [50000, 62000, 75000]
const LEVEL_PACE := 3000
## It lands between these depths on your side: a ball that met the wall
## low comes back short, one high comes back deep.
const RETURN_NEAR := K.KITCHEN_DEPTH + 1200000
const RETURN_FAR := K.COURT_HALF_LENGTH - 1200000
const RETURN_MARGIN := 350000        ## and this far inside the sidelines
const GLASS_KEEP_256 := 230          ## off the glass: 0.9 of the speed across kept
## How long a ball may take before it counts as lost: coming to you
## (unplayed), and going to the wall (it never gets there).
const COMING_GIVE_UP := 600
const GOING_GIVE_UP := 420
const LOST_TICKS := 150
const CLEAR_TICKS := 300
## What a ball does to the score.
const HIT_POINTS := 10               ## every hit on a brick
const BREAK_POINTS := 50             ## a brick broken, and ROW_POINTS a row up
const ROW_POINTS := 10
const CLEAR_POINTS := 250            ## a level cleared, times its number
## The assist (ADR-003's, aimed at the wall): a shot is pulled to meet
## it in the bricks' band, never under this pace over the ground.
const ASSIST_MIN_PACE := 45000
const PROBE_TICKS := 300

const SERVE := 0                     ## the ball at the launcher
const COMING := 1                    ## off the wall (or the launcher), coming to you
const GOING := 2                     ## you hit it, going to the wall
const LOST := 3                      ## a ball lost, the next one soon
const CLEAR := 4                     ## the level's bricks are gone
const OVER := 5                      ## no balls left

const LOST_MISSED := 0               ## it got past you, or bounced twice
const LOST_NET := 1
const LOST_SHORT := 2                ## it died on their side, short of the wall
const LOST_OUT := 3                  ## wide of the glass, or over everything
const LOST_TEXT := ["MISSED", "NET", "SHORT", "OUT"]

## Settings.
var difficulty := 1
var start_level := 0

## State.
var stage := SERVE
var stage_at := 0
var hold := FIRST_HOLD
var level := 0
var lives := LIVES
var score := 0
var hp: Array[int] = []
var bricks_left := 0
var broken := 0                      ## bricks broken this game
var hits := 0                        ## your hits that reached the wall
var far_bounces := 0                 ## your ball's bounces on their side
var last_lost := -1
var last_brick := -1


func copy_settings_from(o: Breakout) -> void:
	difficulty = o.difficulty
	start_level = o.start_level


func reset(sim: Sim) -> void:
	level = start_level
	lives = LIVES
	score = 0
	broken = 0
	hits = 0
	last_lost = -1
	last_brick = -1
	load_level(level)
	_serve(sim, FIRST_HOLD)


func load_level(n: int) -> void:
	var rows: Array = LEVELS[n % LEVELS.size()]
	hp = []
	bricks_left = 0
	for r in ROWS:
		var line: String = rows[ROWS - 1 - r]
		for c in COLS:
			var ch := line[c]
			var h := STEEL if ch == "#" else (ch.to_int() if ch.is_valid_int() else 0)
			hp.append(h)
			if h > 0:
				bricks_left += 1


## A brick's centre on the wall: [x, y].
static func brick_at(i: int) -> Array[int]:
	var c := i % COLS
	var r := i / COLS
	return [-K.COURT_HALF_WIDTH + c * BRICK_W + BRICK_W / 2, BRICK_BOTTOM + r * BRICK_H + BRICK_H / 2]


## The brick at (x, y) on the wall, or -1 (none there, or broken).
func brick_index(x: int, y: int) -> int:
	var dx := x + K.COURT_HALF_WIDTH
	var dy := y - BRICK_BOTTOM
	if dx < 0 or dy < 0:
		return -1
	var c := dx / BRICK_W
	var r := dy / BRICK_H
	if c >= COLS or r >= ROWS:
		return -1
	var i := r * COLS + c
	return i if hp[i] != 0 else -1


## `t` folded back and forth into -w..w, as a ball between two walls.
static func fold(t: int, w: int) -> int:
	var period := 4 * w
	var u := posmod(t + w, period)
	if u > 2 * w:
		u = period - u
	return u - w


func return_pace() -> int:
	return RETURN_PACE[clampi(difficulty, 0, 2)] + mini(level, 5) * LEVEL_PACE


func update(sim: Sim) -> void:
	var t := sim.tick - stage_at
	match stage:
		SERVE:
			sim.ball.held = true
			if t >= hold:
				_launch(sim)
		COMING, GOING:
			_play(sim)
		LOST:
			sim.ball.step()
			if t >= LOST_TICKS:
				if lives <= 0:
					_over(sim)
				else:
					_serve(sim, HOLD_TICKS)
		CLEAR:
			sim.ball.step()
			if t >= CLEAR_TICKS:
				level += 1
				load_level(level)
				_serve(sim, FIRST_HOLD)
		OVER:
			sim.ball.step()


func _set_stage(sim: Sim, s: int) -> void:
	stage = s
	stage_at = sim.tick


## The ball at the launcher, held for `ticks`.
func _serve(sim: Sim, ticks: int) -> void:
	_set_stage(sim, SERVE)
	hold = ticks
	sim.set_phase(K.PHASE_SERVE)
	sim.server_slot = 2                  # the wall serves (the bot never tosses)
	sim.last_hitter = K.NO_SLOT
	sim.bounce_count = 0
	sim.ball.held = true
	sim.ball.place(0, LAUNCH_Y, WALL_Z + K.BALL_RADIUS)


func _launch(sim: Sim) -> void:
	var b := sim.ball
	var tx := sim.scatter(K.COURT_HALF_WIDTH / 2)
	var v := Aim.shot(b.x, b.y, b.z, tx, (RETURN_NEAR + RETURN_FAR) / 2, FEED_PACE)
	b.launch(v[0], v[1], v[2])
	sim.emit(K.EVENT_LAUNCH, tx, 0, 0)
	_coming(sim)


## The ball's on its way to you (off the wall or the launcher).
func _coming(sim: Sim) -> void:
	_set_stage(sim, COMING)
	sim.set_phase(K.PHASE_LIVE)
	sim.last_hitter = 2
	sim.bounce_count = 0
	sim.still_ticks = 0
	sim.shots += 1


func _play(sim: Sim) -> void:
	var b := sim.ball
	var bx := b.x
	var by := b.y
	var bz := b.z
	var ev := b.step()
	if ev & Ball.EV_NET:
		sim.emit(K.EVENT_NET, b.ev_x, b.ev_y, 0)
		if stage == GOING:
			_lose(sim, LOST_NET)
			return
	if ev & Ball.EV_BOUNCE:
		sim.emit(K.EVENT_BOUNCE, b.ev_x, b.ev_z, 0)
		if stage == COMING:
			if b.ev_z < 0:
				_serve(sim, HOLD_TICKS)      # the wall's ball died on its own side: a new one, free
				return
			sim.bounce_count += 1
			if sim.bounce_count >= 2:
				_lose(sim, LOST_MISSED)
				return
		elif b.ev_z > 0:
			_lose(sim, LOST_NET)             # yours never went over
			return
		else:
			far_bounces += 1
			if far_bounces >= 2:
				_lose(sim, LOST_SHORT)
				return
	# The glass, either side of their half: only from inside it.
	var glass := K.COURT_HALF_WIDTH - K.BALL_RADIUS
	if b.z < 0 and b.z > WALL_Z and absi(bx) <= glass and absi(b.x) > glass:
		var s := signi(b.x)
		b.x = s * (2 * glass - absi(b.x))
		b.vx = -b.vx * GLASS_KEEP_256 / 256
		b.wy = -b.wy
		sim.emit(K.EVENT_WALL, b.x, b.y, 1)
	if b.z <= WALL_Z + K.BALL_RADIUS and b.vz < 0 and absi(b.x) <= K.COURT_HALF_WIDTH:
		_wall(sim)
		return
	var t := sim.tick - stage_at
	var gone := b.y < -K.M or absi(b.x) > K.COURT_HALF_WIDTH + K.RUNOFF_SIDE * 2 \
		or b.z > K.COURT_HALF_LENGTH + K.RUNOFF_BACK or b.z < WALL_Z - K.M
	if stage == COMING:
		if gone or b.rolling or t >= COMING_GIVE_UP:
			_lose(sim, LOST_MISSED)
			return
		var p := sim.players[0]
		if p.cooldown == 0 and b.z > -200000 and sim.paddle_contact(p, bx, by, bz):
			_hit(sim)
		return
	if gone:
		_lose(sim, LOST_OUT)
	elif b.rolling or t >= GOING_GIVE_UP:
		_lose(sim, LOST_SHORT)


func _hit(sim: Sim) -> void:
	var volley := sim.bounce_count == 0
	_set_stage(sim, GOING)
	sim.last_hitter = 0
	sim.bounce_count = 0
	far_bounces = 0
	sim.shots += 1
	sim.players[0].cooldown = K.PADDLE_COOLDOWN
	sim.emit(K.EVENT_HIT, 0, sim.ball.speed(), 1 if volley else 0)


## The ball met the wall: a brick, or the wall behind them. Either way it
## comes back.
func _wall(sim: Sim) -> void:
	var b := sim.ball
	var x := b.x
	var y := b.y
	b.z = WALL_Z + K.BALL_RADIUS
	var i := brick_index(x, y)
	if stage == GOING:
		hits += 1
	if i >= 0:
		_brick(sim, i)
	else:
		sim.emit(K.EVENT_WALL, x, y, 0)
	_return(sim, x, y)
	if stage == GOING or stage == COMING:
		_coming(sim)


func _brick(sim: Sim, i: int) -> void:
	last_brick = i
	if hp[i] > 0:
		hp[i] -= 1
		score += HIT_POINTS
		if hp[i] == 0:
			bricks_left -= 1
			broken += 1
			score += BREAK_POINTS + (i / COLS) * ROW_POINTS
	sim.emit(K.EVENT_BRICK, i, hp[i], score)
	if bricks_left == 0:
		score += CLEAR_POINTS * (level + 1)
		_set_stage(sim, CLEAR)
		sim.set_phase(K.PHASE_POINT_RESULT)
		sim.emit(K.EVENT_LEVEL, level + 1, score, 0)


## Off the wall at (x, y): the angle it came in at carries on (folded
## between the sidelines), the height sets the depth, the pace is the
## level's.
func _return(sim: Sim, x: int, y: int) -> void:
	var b := sim.ball
	var band := BRICK_TOP - BRICK_BOTTOM
	var depth := RETURN_NEAR + (RETURN_FAR - RETURN_NEAR) * clampi(y - BRICK_BOTTOM, 0, band) / band
	var tx := x + b.vx * (depth - WALL_Z) / maxi(-b.vz, 1)
	tx = fold(tx, K.COURT_HALF_WIDTH - RETURN_MARGIN)
	var v := Aim.shot(x, y, b.z, tx, depth, return_pace())
	b.launch(v[0], v[1], v[2])
	b.set_spin(0, 0, 0)


func _lose(sim: Sim, why: int) -> void:
	lives -= 1
	last_lost = why
	_set_stage(sim, LOST)
	sim.set_phase(K.PHASE_POINT_RESULT)
	sim.emit(K.EVENT_LOST, why, lives, score)


func _over(sim: Sim) -> void:
	_set_stage(sim, OVER)
	sim.set_phase(K.PHASE_MATCH_RESULT)
	sim.emit(K.EVENT_GAME_OVER, score, level + 1, broken)


## The shot assist (ADR-003, ADR-030): the human's shot pulled
## `config.assist` percent of the way to the same shot meeting the wall in
## the bricks' band, where its line over the ground meets the wall (off
## the glass if that's where it's going: banks stay banks).
func assist(sim: Sim, v: Array[int]) -> Array[int]:
	var a := sim.config.assist
	if a <= 0:
		return v
	var b := sim.ball
	var probe := b.copy()
	probe.launch(v[0], v[1], v[2])
	var iy := (BRICK_BOTTOM + BRICK_TOP) / 2
	var bounces := 0
	for k in PROBE_TICKS:
		var ev := probe.step()
		if ev & Ball.EV_NET:
			break
		if ev & Ball.EV_BOUNCE:
			bounces += 1
			if bounces >= 2 or probe.ev_z > 0:
				break
		if probe.z <= WALL_Z:
			iy = probe.y
			break
	iy = clampi(iy, BRICK_BOTTOM + BRICK_H / 2, BRICK_TOP - BRICK_H / 2)
	var ix := b.x
	if v[2] < -1000:
		ix = b.x + v[0] * (WALL_Z - b.z) / v[2]
	ix = clampi(ix, -3 * K.COURT_HALF_WIDTH, 3 * K.COURT_HALF_WIDTH)
	var pace := maxi(Fx.length(v[0], 0, v[2]), ASSIST_MIN_PACE)
	var ideal := Aim.through(b.x, b.y, b.z, ix, iy, WALL_Z, pace)
	# As the match's assist: the line pulled `assist`, the pace and the arc
	# twice as hard.
	var ad := mini(100, a * 2)
	var dx := v[0] + (ideal[0] - v[0]) * a / 100
	var dz := v[2] + (ideal[2] - v[2]) * a / 100
	var dl := maxi(Fx.length(dx, 0, dz), 1)
	var raw_pace := Fx.length(v[0], 0, v[2])
	var good_pace := Fx.length(ideal[0], 0, ideal[2])
	var p := raw_pace + (good_pace - raw_pace) * ad / 100
	return [dx * p / dl, v[1] + (ideal[1] - v[1]) * ad / 100, dz * p / dl]


## The bot's brick: the lowest left standing, nearest the ball's line.
## [x, y] on the wall.
func bot_target(from_x: int) -> Array[int]:
	var best := -1
	var best_cost := 1 << 40
	for i in hp.size():
		if hp[i] <= 0:
			continue
		var at := brick_at(i)
		var cost := (i / COLS) * 4 * BRICK_W + absi(at[0] - from_x)
		if cost < best_cost:
			best_cost = cost
			best = i
	if best < 0:
		return [0, BRICK_BOTTOM + BRICK_H]
	return brick_at(best)


## Flat mode's crosshair on the far court, as a spot on the wall: across
## is across, and the further it is the higher.
static func wall_from_floor(x: int, z: int) -> Array[int]:
	var far := clampi(-z - 300000, 0, K.COURT_HALF_LENGTH - 600000)
	var band := BRICK_TOP - BRICK_BOTTOM - BRICK_H
	return [clampi(x, -K.COURT_HALF_WIDTH + BRICK_W / 2, K.COURT_HALF_WIDTH - BRICK_W / 2),
		BRICK_BOTTOM + BRICK_H / 2 + band * far / (K.COURT_HALF_LENGTH - 600000)]


func snapshot() -> Array:
	var a: Array = [stage, stage_at, hold, level, lives, score, bricks_left, broken, hits,
		far_bounces, last_lost, last_brick]
	a.append_array(hp)
	return a
