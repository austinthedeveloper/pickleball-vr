# ADR-003: The paddle is the input; a shot assist helps it land

**Status:** Accepted (2026-10-27)

## Context

In first person there are no shot buttons. The racket is in your hand.
VR sports games that leave contact to raw physics feel honest, but
beginners net or overhit most shots. Controllers also report poses once
a frame (72-120 Hz), and a fast paddle moves 10+ cm between samples.

## Decision

- **A human's input per tick** (`SimTypes.HumanInput`): the head's ground
  position, the paddle face's centre and normal, the free hand's
  position, and "let go of the ball". The view samples the controllers,
  interpolates them to the sim's 120 Hz ticks, and quantises them to ints.
  Nothing else crosses into the sim.
- **Contact is swept.** The face is a disc (8 x 10 in paddle: 115 mm)
  of some thickness. Each tick the sim tests the ball's path against the
  face's motion since the last tick, so a fast swing can't tunnel. Both
  faces hit (forehand and backhand). The response is a restitution bounce
  off the moving face (e = 0.5), so paddle speed and angle set pace and
  direction.
- **The shot assist** (MATCH SETUP: OFF / LOW / MID / FULL = 0/35/65/100%,
  MID by default) works out where the raw shot would land, clamps that
  spot inside the lines (into the service box on a serve, over the net if
  it would net), and pulls the ball's velocity that share of the way
  toward the same-pace shot to that spot. Your aim and pace still count;
  the assist only rescues the miss.
- **Serving:** the ball sits in your free hand. Pull that hand's trigger
  to let go: lift as you pull for a toss, hold still for a drop (the drop
  serve is legal). Then hit it. A toss nobody hits is served again, with
  no fault.
- **Depth is assisted harder than aim** (amended 2026-10-27, after the
  first session on a Quest 3: most shots went long or short). The line
  over the ground blends at the setting's share. The pace over the ground
  and the arc blend at twice that, capped at 100%: all of it at MID, 70%
  at LOW. You aim; the game judges length, the hardest thing to feel in
  a headset. The bot's deliberate misses now go wide, since long misses
  are always saved.
- **The face grips the ball** (amended 2026-10-27, after the lead, a real
  player, hit 80% into the net with no assist). The contact gave the ball
  only the face's push along its normal. The face sliding across the ball
  (the low-to-high lift of every dink and drive) made spin but no lift:
  a lifted swing left the ball rising at 0.1 m/s, the same as a flat
  push. Now the face takes half the slide between them out
  (`PADDLE_GRIP`, a hollow ball rolling without slip would lose 60%), so
  lifting the paddle lifts the ball (`test_a_low_to_high_swing_lifts_the_ball`).
  The bot plans for it. The golden traces were regenerated for it.
- **Restitution falls with the impact, and the sweet spot is gentler**
  (amended 2026-10-27, from the lead's logged session: 44 swings at
  assist OFF, read off the headset with `game/tools/swings.sh`). Their
  kitchen-line dinks were consistent and correct: the face 25 to 37°
  open, a 35 to 44° launch. But they came off at 3.9 to 5.6 m/s, about
  15% short of the 5.5 to 6.5 m/s a dink needs from there, and 19 of 24
  went into the net or short. Their firmer strokes came off about 15% too
  hot. Now restitution is 0.66 for a closing speed up to 4 m/s, easing to
  0.34 at 9 m/s (`K.paddle_e`): lively for touch, deader for a hard hit,
  as real balls are. A rim hit loses 20%, not 40%, since you can't feel
  the sweet spot in VR. `test_the_leads_strokes_land` replays their
  typical strokes: into the net before the change, into their kitchen
  after. The golden traces were regenerated.
- **The swing curve** (amended 2026-10-27, second logged session, 57
  swings). With the restitution change, gentle dinks landing in their
  kitchen went from 3 of 24 to 15 of 32, but half still found the net,
  just short of the speed they needed. The firm strokes still flew. The
  lead's touch strokes were 2.6 to 3.1 m/s at the face; anything with
  intent jumped to 5 to 7.7 m/s. That's the usual VR effect: a controller
  has no weight, so touch comes out underhit and power overhit. So the
  face's speed counts for the hit through a curve: x1.22 up to 2.5 m/s,
  x1.0 at 4.5 m/s, x0.75 from 8 m/s (`K.swing_gain`, still rising
  overall). Where the face touched the ball is unchanged. Replaying their
  52 logged kitchen-line strokes (a float replay of the model matched
  the logged speeds within about 5%):
  - kitchen dinks would go from 12 of 32 to 26 of 32;
  - the firm strokes' median depth from 3.7 m to 3.0 m;
  - deep or long from 5 to 1.

  The bot swings the speed whose curve gives what it wants
  (`K.swing_for`). The golden traces were regenerated.
- **The swing curve levels off for an average swing** (amended 2026-10-27,
  third session, 66 strokes; "the net play feels very close to done; the
  normal-speed ball is still flying"). Gentle dinks landed in their
  kitchen 36 of 46 times, as the replay predicted. But the lead's
  average strokes (5 to 6.5 m/s at the face) came off at 8 to 9 m/s on a
  30°+ arc and landed 2.3 to 4.3 m deep. The curve is now defined as an
  effective speed, as straight segments that only rise
  (`K.SWING_CURVE`, `K.swing_eff`):

  | Your swing (m/s) | Counts as (m/s) | What it does |
  |---|---|---|
  | 2.5 | 3.05 | touch is boosted |
  | 4.2 | 4.2 | unchanged |
  | 6.5 | 4.6 | an average swing levels off |
  | 9 | 5.8 | rising again |
  | beyond 9 | +0.62 per m/s | a put-away still drives |

  A first try that interpolated the multiplier dipped (a faster swing
  hit softer), and the test caught it. Replaying sessions 2 and 3: the
  average strokes land at about 2.4 m (their kitchen line) instead of
  3.1 m, 11 of 15 in or at their kitchen, and the gentle dinks are
  unchanged. Bounce-back can't do this, because dinks and average
  strokes meet the ball at overlapping closing speeds. Steepening it cut
  the gentle dinks from 38 to 17 to 24 of 47. Logging skips the lobby's
  demo bot now. The golden traces were regenerated.
- **Flat mode and DEMO** drive the same input from `Bot`, which plans a
  swing through the ball on the sim's own prediction. In flat mode you
  move and aim and the bot swings; in DEMO it does all of it.

## Consequences

- Tests can play whole matches with nothing but `Sim.step([bot.input()])`.
- Spin is left out of the first contact model. Its ADR comes with the
  feature (roadmap phase 3).
- Body reach isn't enforced in VR: the paddle is wherever your hand is.
  Locomotion is the view's job (thumbstick, comfort options).
