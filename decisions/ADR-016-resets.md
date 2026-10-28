# ADR-016: RESETS, blocking speed-ups into the kitchen

**Status:** Accepted (2026-10-27)

## Context

Filling the kitchen gap is why this app exists: the other VR pickleball
games have one dinking mode with moving targets, or nothing.
design/KITCHEN_DRILLS.md proposed six partner drills where you place the
ball, and the lead picked RESETS: you in the transition zone, the partner
driving at you, and you block it soft into their kitchen.

## Decision

- **PRACTICE PARTNER > DRILL** is DINKS, HANDS or RESETS. Settings keep it
  as `partner_drill` (saved as `partner/drill`). An older save's
  `partner/hands` flag still loads as HANDS.
- **You start mid-court**, 3.9 m from the net (`RESET_SPOT_Z`), about
  1.8 m behind your kitchen line. The partner is at their kitchen line.
- **The partner drives at you** from waist height, low: through a point
  35-75 cm up where you stand, with topspin, to your forehand, backhand
  or body as SPREAD has it (30% at your body). DIFFICULTY sets the pace:
  EASY 9 m/s, MEDIUM 11, HARD 13. Take it in the air or off the bounce.
- **A good reset** lands in their dink zone (the kitchen and 75 cm past
  it, ADR-010) and adds to RESETS IN A ROW. Deeper is MISSED THE ZONE;
  out and net as usual.
- **POP-UP!** If your reset crosses the net higher than the pop-up line,
  it ends the streak there: they'd put it away. The line is 60, 45 or
  30 cm over the net by DIFFICULTY and is drawn as a red band across the
  posts.
- **A feed loop, not a rally.** The partner doesn't play your reset; it
  drives a fresh ball at you after each one. That gives the most reps;
  a real point's follow-up (they dink your good reset back) can come
  later.
- Floor TARGETS work as in DINKS.
- The demo CPU resets firmer and flatter (7 m/s, deep in their kitchen),
  since a slow ball from mid-court loops over the line.

## Amended: a lead-in you can read

"Still having the issue of having no clue where the ball is coming from.
It's great that the ball is fast ... But the ball just appears and fires
right away." The partner's feed was placed and struck in the same tick,
and its swing only started at contact. Now every fresh partner feed
(DINKS, HANDS and RESETS) has a lead-in, a new drill stage, SETUP:
- the ball appears held up at chest height in front of the partner's
  free hand, for 0.35 s;
- it's dropped, with a little lift, and struck as it falls past the
  height of the shot (0.8 m for HANDS and RESETS, 0.5 m for DINKS);
- the partner's avatar winds up toward that strike, squared to you, and
  its free hand holds the ball until the drop.

That's about 0.85 s from seeing the ball to the strike, a rhythm to time
the split step on. The drive itself is just as fast. It's all in the sim
(`Drill._setup`), so the avatar plans its swing on the same flight.

## Consequences

- `test_partner.gd`: drives come hard from the partner and it never plays
  your reset; a pop-up is called and ends the streak; every level is
  playable by the CPU and HARD's lower line catches more pop-ups; the
  menu, the pop-up line, and an older save.
- The demo CPU pops up a lot of HARD's 13 m/s drives: its swing plan
  meets a fast, dipping ball less exactly than its aim. Real blocks use
  the block restitution (ADR-003 amended).
- Golden traces are unchanged: matches don't use the drill.
