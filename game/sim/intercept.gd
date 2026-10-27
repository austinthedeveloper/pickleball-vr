## Where a player should meet the ball coming to their side: the first
## legal, comfortable point on its predicted path they can run to in time.
## The CPUs move by it; the bot (DEMO, flat mode, tests) swings by it.
class_name Intercept
extends RefCounted

const MAX_LOOK := 360
const COMFORT_HIGH := 1300000
const SIDE_STEP := 500000            ## the body stands this far off the ball
const BEHIND := 150000

## [ticks ahead, ball x, y, z, stance x, z] or [] when there is none.
static func plan(sim: Sim, team: int, body_x: int, body_z: int, speed: int,
		max_reach := -1, min_ticks := 1, high := COMFORT_HIGH) -> Array[int]:
	var b := sim.ball.copy()
	var bounces := sim.bounce_count
	var need_bounce := sim.needs_bounce(team)
	var side := K.side_sign(team)
	var fore := K.right_sign(team)
	var best: Array[int] = []
	var best_short := 1 << 40
	for i in range(1, MAX_LOOK):
		var ev := b.step()
		if ev & Ball.EV_NET:
			return []
		if ev & Ball.EV_BOUNCE:
			if K.side_of_z(b.ev_z) != team:
				return []
			bounces += 1
			if bounces >= 2:
				break
		if b.z * side <= 0 or i < min_ticks:
			continue
		if need_bounce and bounces == 0:
			continue
		if b.y < K.REACH_LOW or b.y > high:
			continue
		var sx := clampi(b.x - fore * SIDE_STEP, -K.COURT_HALF_WIDTH - K.RUNOFF_SIDE,
			K.COURT_HALF_WIDTH + K.RUNOFF_SIDE)
		var sd := clampi(b.z * side + BEHIND, K.NET_GAP, K.COURT_HALF_LENGTH + K.RUNOFF_BACK)
		var sz := sd * side
		if bounces == 0 and K.in_kitchen(sx, sz, team):
			continue                     # no volley from the kitchen: let it bounce
		var dist := Fx.length(sx - body_x, 0, sz - body_z)
		if max_reach >= 0:
			# Standing still (the flat-mode swing): only what's in reach now.
			if Fx.length(b.x - body_x, 0, b.z - body_z) <= max_reach:
				return [i, b.x, b.y, b.z, body_x, body_z]
			continue
		var need := dist / maxi(speed, 1)
		if need <= i:
			return [i, b.x, b.y, b.z, sx, sz]
		if need - i < best_short:
			best_short = need - i
			best = [i, b.x, b.y, b.z, sx, sz]
	return best
