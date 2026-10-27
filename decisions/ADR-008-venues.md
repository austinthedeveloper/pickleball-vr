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
