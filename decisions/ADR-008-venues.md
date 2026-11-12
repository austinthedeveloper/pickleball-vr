# ADR-008: Venues, rebuilt in 3D

**Status:** Accepted (2026-10-27)

## Context

The port kit has eighteen venues (port ADR-024/046/088): painted 2D
backdrops with a court palette and an ambience each, and every ladder
team has a home. Painted backdrops don't work around you in VR. A venue
has to be a place.

## Decision

- **Five venues first, built in code** (`view/world.gd`, `meta/venues.gd`).
  - **PARK:** trees, chain-link fences.
  - **LAKESIDE:** a lake past the far fence, a dock, hills across it.
  - **SUNSET:** a low warm sun behind the far baseline, palms, red mesas.
  - **GYM:** an indoor hall with lights in the roof and wall padding.
  - **SPACE:** a starfield, a ringed planet, moon rocks, glowing cyan
    rails.
- **Court colours are the port kit's** (its `venues.json` grounds and
  `court_colors.json` presets), so the 2D and VR courts match. Each venue
  plays the port kit's ambience for it.
- **VENUE on MATCH SETUP:** HOME (the opponent's home court, as in the
  port kit's ladder) or one of the five. Ladder homes not built yet stand
  in with the nearest built one: DINOSAUR plays in the GYM (the GYM
  BROS) and UNDERSEA at LAKESIDE (the SURF CREW). A team's home now comes
  over in `data/opponents.json`.
- **Display only:** `MatchConfig.venue` is for the view. The sim never
  reads it, so the golden traces are untouched.

## Consequences

- Each new venue is a function in `World` plus a row in `VENUES` and
  `Venues.NAMES`. `test_venues` builds every one and checks its ambience.
- Next candidates: DINOSAUR and UNDERSEA (so the stand-ins can go), then
  the painted ones (WESTERN, ROOFTOP, ...), and TIME (DUSK, NIGHT) from
  port ADR-045.

## Amendment (2026-11-11): DINOSAUR and UNDERSEA (VR-97, VR-98)

The canon's six venues are all here now (bible 5.6), and every ladder
home is a real venue, so the stand-ins are gone (`Venues.STAND_INS` is
empty). The GYM stays as a seventh. Indexes 5 and 6 are new, so saved
VENUE settings keep their meaning.

- **DINOSAUR** (the Gym Bros' home): a jungle clearing under a hazy sky.
  It has palms, a ring of ferns and bushes in one draw, a volcano on the
  horizon with a glowing crater and smoke, and a long-necked dinosaur
  standing among the trees past the fence. The court is the port kit's
  (GREEN, ORANGE kitchen, GRASS round it).
- **UNDERSEA** (the Surf Crew's home): a sandy seabed in blue-green water.
  - **The water** is the environment's depth fog, from 16 m to solid at
    70 m, and ZEN's DRIFT takes over from it (`World._fog_begin`).
  - **Kelp** sways in a ring 11 to 26 m out, more at the tip, slowly. It
    is one draw with a vertex shader, and nothing near you moves.
  - **Coral and rocks** are one draw. **Bubbles** rise from four vents,
    and **light** ripples over the court from a cheap animated cell shader.
  - Glass fences. The court is the port kit's (AQUA, NAVY kitchen, SAND
    round it).
- The ambience is the port kit's own `ambience_dinosaur.ogg` and
  `ambience_undersea.ogg`, as for the other five.
- **FOCUS:** scenery shaders take a `dim` uniform (`World._shaders`), so
  the kelp and the light dim with the rest.

## Amendment (2026-11-12): critters between points (VR-101)

Now and then a critter crosses the sky (bible 5.6): a gull at LAKESIDE, a
pterosaur at DINOSAUR (both by day and dusk only), a satellite in SPACE,
and a fish UNDERSEA, swimming past the far fence (`view/critters.gd`).

- **When:** one sets off only between points: in a match off the live
  ball, in a drill while waiting or holding the next feed. One under way
  fades out in 0.6 s when a rally starts. Every 20 to 45 s, on the view's
  own generator.
- **Where:** far off and slow (9 to 22 s across, 24 m or more away; the
  fish 12 to 15 m, behind the far fence), and scaled up so it still
  reads. Nothing near you moves.
- Never in the lobby's demo, when watching, or in passthrough.
  `screenshot.gd critter` sends one across halfway. Display only.
