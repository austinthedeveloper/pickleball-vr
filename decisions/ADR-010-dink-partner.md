# ADR-010: DINK PARTNER and floor targets

**Status:** Accepted (2026-10-27)

## Context

The lead spends most of their time in practice. For dinking, they asked
for two things. The first, fast balls at the kitchen line, is the ball
machine's volley feed (ADR-007, amended). The second is a partner on the
other side, not a machine: an AI that only wants to get the ball back,
dinking it near you, never hitting away and never going for a winner. As a
bonus, they asked for floor targets to aim at.

## Decision

- **DINK PARTNER** (MAIN > DINK PARTNER) is a `Drill` with `partner` on.
  - A CPU stands at their kitchen line (slot 2). Between shots it squares
    up to you along that line. When your ball lands in court on its side,
    it plans the ball's path (`Intercept`), moves to the ball, lets it
    bounce and dinks it back.
  - Every shot lands about a metre in front of you and within about
    45 cm of your line, in your kitchen, with a little backspin. It never
    aims away and never drives.
- **A rally, not a feed loop.** A ball that lands in court keeps the
  rally going: one in their kitchen counts as a good dink, while one that
  lands deeper is MISSED THE ZONE (the streak resets, but the partner
  still plays it). A ball out or in the net ends the rally, and the
  partner starts a fresh one. The scoreboard shows the rally and the best
  rally (saved). The announcer calls rallies of 10, 15, 20 and 30.
- **No volleys from your kitchen**, as in a match (the KITCHEN rule).
- **DIFFICULTY is how low the dinks skim the tape:** EASY clears it by
  60 cm (peaking about 1.9 m), MEDIUM 30 cm (1.5 m), HARD 12 cm (1.3 m).
  Pace alone didn't change anything: a dink must loft over the net, so the
  solver chose the same arc whatever pace was asked for. `Aim.shot` takes
  the clearance now.
- **Floor targets** (TARGETS on DINK PARTNER, on by default, and on the
  BALL MACHINE): a glowing circle 45 cm in radius on their side, inside
  the return zone (their kitchen for the partner). Land a ball in it for
  TARGET!, then it moves at least a metre. Hits are counted on the
  scoreboard. The bot aims at the target when there is one, so the
  demo and the tests use it.

## Amended 2026-10-27: after the first session with the partner

- **The counter is dinks in a row,** in their kitchen. A ball outside it
  starts the count again; the rally goes on. It used to show the rally
  (any ball in court), which kept counting through misses.
- **The announcer says the board's number.** The port kit's rally clips
  count shots by both players ("Ten shots!"). Now it calls the clips that
  say the number (rally_10_1, rally_15_1, rally_20_1, rally_25,
  rally_30_1) when the streak reaches it, so the call and the board
  agree.
- **PARTNER: ACROSS or CROSS COURT.** Cross court puts you in your right
  court and the partner diagonally across (their right). Its targets sit
  in its half of the kitchen. Its dinks still come to you.
- **Changing an option no longer moves you** (MatchView, ADR-001's rig).
  The lobby rebuilds its demo, and with it the rig. The new rig takes the
  old play space as it was and only moves you when the view stands you
  somewhere new.
- **The Quest's recenter** (hold the Meta button) now faces you down the
  court again where you stand (OpenXR's `pose_recentered`). Before, the
  game ignored it.

## Amended again 2026-10-27: reach and reaction

- **Dinks reach you cross court.** The partner aimed each dink to bounce
  at your x, but a diagonal ball keeps drifting sideways after the
  bounce: fresh cross-court dinks passed 1.0 to 1.6 m to your side, out
  of reach. Now it bounces on the line from the partner to you, so it
  carries on to you, with the scatter down to 30 cm. Every fresh dink
  passes within 30 cm (`test_dinks_reach_you_cross_court_too`).
- **It reads your shot.** The partner used to plan only once your ball
  bounced. Now, 0.18 s after you hit it (a person's reaction), it plans
  to meet the ball after the bounce and moves, then refines the plan on
  the bounce. It's usually 1 to 2.5 m on its way before your ball lands
  (`test_the_partner_moves_before_your_ball_bounces`). The person's
  swing follows that early plan too.

## Amended a third time: SPREAD

The 30 cm scatter felt like every ball came dead centre. Now each dink
goes to your forehand or backhand by a reach that SPREAD sets: TIGHT
10 to 35 cm, NORMAL 25 to 75 cm, WIDE 50 cm to 1.2 m. About one in seven
comes straight at you. It still aims along the line to you, so the reach
holds cross court.

## Amended: the dink zone runs a foot past the kitchen line

"It's ok for the ball to land past the kitchen line, as long as it's near
it." RETURN TO KITCHEN and DINK PARTNER's count now take a ball up to
30 cm past the line (`Drill.DINK_ZONE`). The highlight on the court and
the partner's targets follow it.

## Consequences

- The partner is pure sim like everything else: seeded, deterministic,
  in the snapshot. Matches are untouched, so the golden traces are too.
- Later candidates: the partner's resets and speed-ups (a FIRM level that
  sometimes attacks a high dink), a target pattern (corners in turn), and
  a partner for the kitchen-line hands battle.
