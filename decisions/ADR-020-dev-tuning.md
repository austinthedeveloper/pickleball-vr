# ADR-020: Developer tuning pages, synced back as the defaults

**Status:** Accepted (2026-10-28)

## Context

The lead tunes the drills by feel in the headset, and until now every
change went through a rebuild and an install. They asked for a
developer panel: "you set the values, I play a bit and tweak, then you
sync the settings as the default when I ask you to".

## Decision

**Tunables are static vars.** The numbers worth trying stay where they
were, in the sim, but as `static var NAME := literal` instead of `const`.
Each is a plain int, or a list of ints with one element per difficulty.
`Tune.ALL` (`meta/tune.gd`) lists them in eight groups:
- **TARGETS:** spot radii, floor target radius, ring edges.
- **KITCHEN:** the lean allowance, the dink zone's reach past the line.
- **DINKS:** partner pace, the lead-in hold, partner speed.
- **HANDS:** the feed and the pace.
- **RESETS:** the pace and the pop-up line.
- **VOLLEYS:** the floater pace.
- **ATTACK:** the share of high balls.
- **PADDLE:** how much pace a block keeps.

Each entry has a unit, a step and a range.

**The pages.** In debug builds, PAUSED and the main lobby page have a
TUNING row. It opens the groups, then a page of `< value >` rows for a
group, plus RESET for the group (or for all), RESUME and BACK. A change
applies at once: the sim reads the var on its next use, and a board
resizes live. A value that differs from the source's is marked `*`.
Ring edges and anything a feed already in flight has read take effect at
RESTART.

**Saved, with where it lives.** Every change writes `user://tuning.cfg`
with three things per changed value:
- the value;
- `file:NAME:index`;
- the source's value at build time.

On launch, a debug build applies the file.

**Synced on request.**
- `game/tools/tune.sh show` pulls the file off the headset and shows each
  change against the source.
- `tune.sh sync` writes the values into the `static var` literals with
  `tools/tune_sync.py`. Comments that spell values out are fixed by hand
  in the same commit.
- `tune.sh clear` drops the headset's overrides.

**Never in tests or release builds.** `Settings.dev` is
`OS.is_debug_build()`. The test runner switches it off, so the sim runs
on the source's values. `test_tune` sets its own path and resets after
itself.

## Consequences

- The sim's tunables are mutable global state. They change only by hand
  on a debug build, and a change counts as a deliberate experiment.
  Determinism within a run is untouched.
- A new tunable is one line in `Tune.ALL`, plus `const` → `static var`.
  `test_tune` checks that every entry can be synced.

## Amendment (2026-10-28): hit vibration

The lead found the hit vibration "a bit too low". It's stronger now:
- 50% at rest, up from 35%;
- plus 40% per 10 m/s of ball speed, up from 33%;
- a 50 ms pulse on a clean hit, up from 40 ms.

All three are tunables on the PADDLE page (they live in
`view/match_view.gd`): Tune reaches any script's static vars, not only
the sim's.

Raised again (2026-10-28, "a bit" more): 60% at rest, plus 45% per 10 m/s.
