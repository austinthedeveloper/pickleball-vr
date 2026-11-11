# ADR-031: ZEN, a long rally goes deeper: HUSH and DRIFT

**Status:** Accepted (2026-11-11). Built: VR-162, a prototype for the
headset.

## Context

The lead wants the game to "feel all cerebral": the FOCUS darkening
(ADR-013) as the start of a meditation state, where "things started
changing" as a dink rally goes on. ADR-013 already named the aim (a "zen
state") and left the ideas for later: the crowd hushing, a low tone,
colour, the court glowing. Five stages were sketched (DIM, HUSH, DRIFT,
SYNC, STILL), and the lead picked the first two after DIM to prototype.

## Decision

**Display and sound only** (`view/zen.gd`, `Zen`). The sim, its golden
traces and the coach's numbers are untouched. It grows from FOCUS's own
count (`Focus.shots_of`: a match's shots, a practice streak doubled), so
it starts only after FOCUS is fully dark (26 shots, 13 in a row).

- **HUSH** from 30 shots (15 in a row), full by 40 (20 in a row):
  - the ambience and the crowd run through their own bus (`ZenWorld`):
    a low-pass filter closes from 20 kHz to 350 Hz and the level drops
    to 15%;
  - a low drone comes in (an 8 s seamless loop, A1 with its octave and
    fifth and a slow beat);
  - the hits' and bounces' own sound drops by up to 12 dB, and each hit
    rings a soft bowl tone on a major pentatonic scale. The melody steps
    1 or 2 notes per hit (the view's own generator, never the sim's).
    Your notes are an octave above the other side's, so a rally sounds
    like two voices answering each other;
  - the announcer stops counting the rally aloud.
- **DRIFT** from 40 shots (20 in a row), full by 60 (30 in a row):
  - the venue fades into a deep blue void. This is the environment's
    depth fog, from 13 m (past the court and the players) to solid at
    30 m, and the sky goes with it. The fog is on from the start, pushed
    out to 1000 m, so DRIFT never compiles a shader mid-rally (ADR-009);
  - 260 motes of light hang in a ring 6 to 18 m out, rising at a few
    cm/s, all alike (nothing that reads as the floor moving);
  - each bounce sends a ring of light over the court (six reused rings,
    2.6 m out over 2.2 s);
  - the court's paint dims 40%, and its lines glow pale cyan;
  - the ball's trail shows at any speed, brighter and paler.
- **The exhale:** when a rally that reached 30% HUSH ends, a low bell
  rings once, and everything eases back over about 3 s (in: about 2 s).
- **Never in the lobby's demo or when watching.** In passthrough there's
  no fog (the room stays); the rest works.
- **Comfort:** nothing moves the horizon or the floor, nothing strobes,
  the court stays solid and lit.
- **Tunable** on TUNING > ZEN (debug builds, ADR-020): where each stage
  starts and fills, the drone and note levels, the hits' drop.
- The sounds are synthesized by `tools/make_zen.py` (ours, remakeable).

## Consequences

- `test_zen.gd` covers the thresholds, the sound and the world going and
  coming back, the bell (only after a deep rally), the rings only under
  DRIFT, and the lobby. `screenshot.gd zen=0..1` holds the stages for a
  picture.
- Not heard or felt in the headset yet. Whether the melody soothes or
  grates, and whether the void is calming or eerie, needs the lead.
- The fog runs in every venue now, out of sight. It should cost next to
  nothing on the Compatibility renderer; a PERF check on the Quest will
  confirm it.
- Next, if these land: SYNC (the world on the rally's rhythm, the partner
  in light), STILL (a mandala growing from the court), deepening on calm
  play (a steady head, unhurried swings), a MEDITATE practice mode, an
  INTENSITY setting and a ZEN off switch.
