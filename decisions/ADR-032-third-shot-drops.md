# ADR-032: THIRD SHOT DROPS, the transition drill

**Status:** Accepted (2026-11-11). Built: VR-87.

## Context

`design/KITCHEN_DRILLS.md` proposed six partner drills; five are built
(ADR-016, ADR-017). The last is THIRD SHOT DROPS: start at your
baseline, drop the partner's deep return into their kitchen, then follow
it in. It's the transition game RESETS (ADR-016) starts from the middle.

## Decision

A partner drill, `Drill.KIND_DROPS` (DRILL: THIRD SHOT DROPS), in the sim
like the others: ints, the seeded generator, `step()`.

- **You start at your baseline** (`DROP_SPOT_Z`, 30 cm inside it). The
  partner stands at their kitchen line, holds the ball up, drops it and
  strikes (the lead-in, ADR-016 amended).
- **The deep return** lands in from your baseline by DIFFICULTY's depth
  (2, 1.4, 0.9 m) at its pace (7.4, 8.6, 9.8 m/s), to your forehand,
  backhand or body as SPREAD has it.
- **The two-bounce rule:** the return must bounce. A volleyed return is
  LET IT BOUNCE.
- **The drop counts** when it lands in their dink zone (the kitchen and
  2.5 ft past it, ADR-010). The count is DROPS IN A ROW. Anything else
  ends it: net, out, MISSED THE ZONE.
- **Following it in:** after a good drop the partner chases it and dinks
  one ball back, about a metre in front of wherever you are. If you're
  within 90 cm of your kitchen line as they strike, **AT THE LINE +1**
  (the dartboard's ding; a timed run scores it). That ball counts for
  nothing either way, so the streak is drops only.
- **The next return waits** until you're back behind 1.5 m from your
  baseline, so a fresh ball never catches you walking.
- **TUNING > DROPS** (debug builds, ADR-020): each level's depth and
  pace. The coach's sliders for the drill are the same values (C-11).
- **The bot plays it** (`test_kitchen_drills`): it lets the return
  bounce, drops from the baseline with a soft lofted ball, and walks in
  to its line once the drop is away (`Drill.home_z`), then back.

## Consequences

- Matches and the other drills are unchanged: golden traces too.
  `Drill.home_z()` is the drill's spot everywhere else.
- VR players walk 4.6 m in and back each ball. Room-scale players will
  use the stick for some of it; whether that's tiring is for the headset.
- A drop high over the net isn't penalized yet (RESETS's pop-up line
  isn't used). It may want one at HARD.
