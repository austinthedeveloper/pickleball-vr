# ADR-034: SOUND: levels for the ambience, the crowd and the announcer; the night's crickets

**Status:** Accepted (2026-11-12). Built: VR-100.

## Context

Each venue already plays its port kit ambience (ADR-008). VR-100 asked
for one per venue and time, crickets at night, and an AMBIENCE volume.
Nothing in the game set how loud anything was: known issue 7 says the
crowd and the announcer are untested by ear. A level a player can turn
down is the safer default until someone has listened.

## Decision

- **A SOUND page** off MAIN, with three rows: AMBIENCE, CROWD and
  ANNOUNCER, each OFF / LOW / MID / FULL (0, 30, 60, 100%). They're saved
  in `Settings`, applied at startup and at once on a change.
- **Each is its own audio bus** (`meta/sound.gd`, `Sound`). The ambience
  and the crowd send through ZEN's bus, so HUSH still muffles them
  (ADR-031). The announcer goes straight to Master. OFF mutes the bus.
- **Night:** outdoors at NIGHT (PARK, LAKESIDE, SUNSET, DINOSAUR), the
  ambience is crickets over a soft breeze. `ambience_night.wav` is a
  12 s loop, synthesized by `tools/make_night.py`. The GYM, SPACE and
  UNDERSEA keep their own. DUSK keeps the venue's day ambience.
- Sound only: the sim never hears of it.

## Consequences

- `test_audio` checks every venue at every time has an ambience, the
  levels on the buses, the routing through ZEN, the view's players on
  their buses, and the SOUND page.
- The crickets are unheard in the headset, like the rest (known issue 7).
