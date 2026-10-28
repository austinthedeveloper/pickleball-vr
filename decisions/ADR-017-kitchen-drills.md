# ADR-017: Four kitchen drills, and the swing log by mode

**Status:** Accepted (2026-10-27)

## Context

The kitchen gap is why this app exists (ADR-016). After RESETS the lead
asked to "knock out a few drills" from design/KITCHEN_DRILLS.md, and
asked whether a session of several modes could be analyzed mode by mode:
"can I play 5 different modes in one game, then you analyze them all".
The swing log (ADR-003) had every hit, but not the mode it was in.

## Decision

**One drill kind.** `Drill.kind` (KIND_*) replaces the HANDS and RESETS
flags; `hands`, `resets`, `spots`, `lanes` and `attack` read it.
PRACTICE PARTNER > DRILL lists all seven; the save keeps the index.

**CALL THE SPOT.** The partner dinks as in DINKS. For each of its shots
one of four spots is picked on their side: their left or right kitchen
corner, the middle, or at their feet, never the same twice running. It
shows as a green disc that pops on.
- Dink onto it for GOOD. In their dink zone but off it is MISSED THE
  SPOT, which resets the streak, and the rally goes on.
- DIFFICULTY: the spot lights as they hit (EASY), as the ball crosses the
  net (MEDIUM) or as it bounces on your side (HARD). It shrinks too:
  radius 60, 45 then 35 cm.

**LINE AND CROSS.** You stand in your right court with the partner
straight across. Only half their dink zone counts, and it's lit: LINE
(straight ahead), CROSS (the diagonal), or ALTERNATE. LANE is a row on
the page for this drill only. The other half is WRONG LANE.

**VOLLEY DINKS.** The partner floats a soft ball that passes your
kitchen line about waist high (85, 75 or 65 cm by DIFFICULTY; 4.3-5.8
m/s). Volley it, not from the kitchen, onto the spot lit as they hit. If
you let it bounce, that's VOLLEY IT; from the kitchen it's KITCHEN!.

**ATTACK OR DINK.** The partner dinks, but 30% of them come up high:
they land in your kitchen and sit up at your line.
- A high one sped up (7 m/s or more over the ground) and in is GOOD.
  Dinked, it's ATTACK THAT!
- A low one dinked into the zone is GOOD. Sped up, it's BE PATIENT.
- A speed-up ends the rally (the partner feeds a fresh one), while a
  dink plays on.
- DIFFICULTY is how little the high ones stand out: 1 m over the net
  against 30 cm on EASY, down to 55 against 12 on HARD.

**The swing log by mode.** Every SWING line now carries `mode=` (the
drill, level and lane, the machine's shot and speed, LESSON, SINGLES or
DOUBLES), and each drill result adds a RESULT line with the streak.
`game/tools/swings_report.py` sums a session up by mode: hits and where
they went, the paddle and ball speeds, the results, the hit rate and the
best streak. Lines from before have "(no mode)".

**The demo CPU** aims at the spot or lane. In ATTACK OR DINK it waits for
a high ball to sit up (70 cm or more, `Intercept.plan`'s new `low`) and
drives it at their feet. Its movement uses the same heights as its swing.

## Consequences

- `test_kitchen_drills.gd`: each drill playable on EASY and HARD,
  deterministic; the spot's timing per level and never repeating;
  judging (spot, lane, attack and patience); lanes that stay or
  alternate; volleys required, with floaters waist high at your line;
  high balls clearly higher on EASY; the LANE row and the log's names.
- Golden traces unchanged: matches don't use drills.
- design/KITCHEN_DRILLS.md is now built but for THIRD SHOT DROPS.
