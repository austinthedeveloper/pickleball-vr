# ADR-005: MATCH SETUP in the world, and the port kit's ladder

**Status:** Accepted (2026-10-27)

## Context

The headset has no command line, so a Quest player needs a way to choose
singles or doubles, the opponent and the assist. The port kit's eight
ladder teams (port ADR-023/048) are the game's cast. Their AI knobs are
in SNES units, so they can't drive the 3D sim as they are.

## Decision

- **The lobby:** the game opens behind the near baseline (outside the
  fence), watching a demo of the chosen match: the bot in your place
  against the chosen team. A MATCH SETUP panel stands beside you. It has
  MODE, VS (the eight teams), DIFFICULTY, SHOT ASSIST, POINTS, WIN BY 2,
  PADDLE HAND, and PLAY (plus QUIT in flat mode). Changing the mode, the
  team or the hand rebuilds the demo to match.
- **`Menu3D`:** rows by id, driven by move/change/press (sticks, keys) or
  by pointing (the free hand's laser, the mouse) and clicking (a trigger,
  the mouse button). Tests select rows by id.
- **At the match's end:** REMATCH (a `CMD_NEW_MATCH` command) or MATCH
  SETUP (back to the lobby).
- **Settings** live in `Settings` (`user://settings.cfg`, version 1), not
  on screens. Tests use their own file.
- **The ladder:** `tools/import_opponents.py` re-cuts each player's SNES
  knobs into a `CpuStyle` and writes `data/opponents.json`. Speed maps
  from the SNES speed, net rush from `net`, dinks from `dink_period`,
  lobs from `lob_distance`, and aim from AWAY / BODY / MIX. Error,
  reaction and pace tighten with each rung. The names, intros, quips and
  shirt colours come over as they are. Each CPU slot can have its own
  style (`MatchConfig.styles`).
- **Display-only flavour:** the team's intro is called at the start, and
  sometimes a quip when they lose a point. Which quip is the view's own
  roll, never the sim's.

## Consequences

- The default style and its golden traces are unchanged. A ladder team
  plays through `styles`, so the default (no team) is still the reference.
- The QUIT row exists in flat mode only. On the Quest, the system button
  leaves.
