# ADR-013: FOCUS: a long rally dims the world

**Status:** Accepted (2026-10-27)

## Context

The lead asked for the port kit's focus effect (port ADR-068, rally heat):
in a long rally everything outside the court darkens. The longer-term
aim is a "zen state": hitting so many balls in a row that everything
changes. VR practice counts only the player's shots, so they asked for
the port kit's numbers, halved.

## Decision

Display only; the sim and its golden traces are untouched.

- **The numbers** (`view/focus.gd`) are the port kit's, counted in shots by
  both sides:
  - the first step at 15 shots;
  - one more every 5;
  - each step 13% darker;
  - capped at 62%, never black.

  A match counts its rally (`sim.shots`). Practice counts your streak
  (dinks in a row for DINK PARTNER, the BALL MACHINE's streak) doubled,
  which is the port kit's numbers halved: focus begins at your 8th good
  shot in a row and reaches the cap at about 18. It eases in over about
  half a second and out a little slower. Never in the lobby's demo.
- **What dims** (`World.set_focus`, `Crowd.set_focus`): the sky, the ground
  and the court's surround, the fences, trees and venue scenery, the
  stands and the crowd. **What stays bright**: the court, its lines, the
  net, the players, the ball, the machine, your paddle and the
  scoreboard: a spotlight on the rally.
- **Ambient light comes from a fixed colour,** the sky's own averaged,
  not from the sky. Otherwise darkening the sky dimmed everything it lit:
  your paddle went near black in the first test render.

## Amendment (2026-10-27): deeper and sooner

In the headset the lead didn't notice it ("if the darken has been in
place for a bit, i didn't notice. increase it"). A 13% step is too soft
in a headset that adapts to the light, and 62% still left the trees and
sky plainly visible. Now: the first step at 10 shots (5 in a row in
practice), one more every 4 (every 2 in a row), 18% each, down to 88%:
nearly black around a lit court by 13 in a row. The easing is unchanged.

## Consequences

- `test_focus.gd` covers the thresholds, practice's doubling, the world
  dimming while the court doesn't, the easing out, and the lobby.
- The zen state grows from `Focus.amount`: sound (the crowd hushing, a
  low tone), colour, the court glowing, the partner's dinks slowing.
  Ideas for the lead to pick from.
