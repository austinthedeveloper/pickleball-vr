# ADR-033: TIME OF DAY, and the court under lights at night

**Status:** Accepted (2026-11-11). Built: VR-99.

## Context

The canon has three times of day, and at night the court plays under
lights (bible 5.6; port ADR-045). ADR-008 left TIME for later. In VR a
night has to stay playable: the ball and your paddle must stay easy to
see. The Quest can't afford real-time lights per lamp (ADR-009).

## Decision

**TIME: DAY, DUSK, NIGHT**, a row on MATCH SETUP, PRACTICE PARTNER and
the BALL MACHINE (`Settings.time_of_day`, saved). It travels in
`MatchConfig.time`, for the view only, like the venue: the sim never
reads it, so golden traces are unchanged. `World.time` builds it.

- **Where it applies:** outdoors (PARK, LAKESIDE, SUNSET, DINOSAUR) and
  UNDERSEA. The GYM and SPACE are as they are (`World.timed()`).
- **DUSK:** the sky warms toward violet and orange, the sun drops low
  and orange, and the ambient light follows the sky. SUNSET is dusk
  already and keeps its own sky.
- **NIGHT:**
  - **The sky** is near black with stars (one draw).
  - **The floodlights:** the one sun turns into them, white, high over
    the court from the poles. Four poles past the court's corners carry
    glowing lamps. No extra lights, so no extra cost per pixel.
  - **The ambient light** is a cool, low fill, so your paddle's face and
    the players stay readable.
- **The surroundings** fall into the dusk (72%) or the dark (30%). Their
  dimmed colours become FOCUS's starting point, and scenery shaders
  take the same factor.
- **UNDERSEA:** the water and its fog darken (65%, 45%), and at night the
  floodlights light the court.
- **The ball** is optic yellow against a night horizon at least the port
  kit's 2:1 (`min_ball_contrast`), checked by `test_night_plays_under_lights`.
- `screenshot.gd tod=DAY|DUSK|NIGHT`.

## Consequences

- `test_venues` covers night (sky, light, lamps, dark surroundings, the
  ball's contrast), dusk, the GYM and SPACE untouched, UNDERSEA's water,
  the setting reaching the view and the TIME rows.
- Not seen in the headset: how bright the floodlights feel, and whether
  your paddle face reads at night, are first guesses from the Mac (known
  issue 17).
- The crowd isn't dimmed at night: it sits beside the court, under the
  lights.

## Amendment (2026-11-12): bounce marks and close calls (VR-106)

Each bounce leaves a pale scuff on the court (`view/bounce_marks.gd`).
- **The scuff** is 18 cm across and unshaded, so it reads the same by day,
  at dusk and under the lights. It fades over 2.6 s; four are kept at once.
- **Close calls:** a ball that lands within 10 cm of a sideline's or
  baseline's outside edge, in or out, glows gold and pulses at its mark
  for 1.4 s. You can see how close it was.
- `screenshot.gd marks` lays three down, one a close call. Display only:
  the sim's own bounce is drawn, never written back.
