# ADR-006: Spin, the sweet spot, and how a point sounds

**Status:** Accepted (2026-10-27)

## Context

Phase 3, feel. In VR you can see and feel spin: a topspin drive dips and
kicks, and a cut dink floats and checks up. A swing that clips the rim
should feel dead. The first contact model (ADR-003) had none of this.
The port kit had shot-type hit sounds, an announcer (port ADR-076) and a
crowd.

## Decision

**In the sim (play changes; golden traces regenerated):**

- **Spin** is an angular velocity in urad/tick on the ball. In flight,
  Magnus is `a = k (w x v)` with k about 0.002 (less than a tennis ball's:
  the holes), and the spin decays to about 60% a second.
- **The bounce** applies friction to the slip at the contact patch (0.2
  of it). Topspin kicks on and backspin checks up. With no spin this is
  exactly the old 0.8 of the planar speed kept.
- **Off the paddle:** the face's brush across the ball (the paddle's
  velocity relative to the ball, along the face) becomes spin at 40%
  efficiency, plus a quarter of the spin the ball came in with. The brush
  doesn't change the shot's pace or line; only the normal impulse does.
- **The sweet spot:** restitution falls with the square of the distance
  from the face's centre, losing 40% at the rim. The sim reports
  `last_offset` for the view.
- **CPU shots carry spin by type:** drives and serves topspin, lobs a
  little, dinks and drops backspin. The aim solver flies the spin, so they
  still land where they're aimed. The bot brushes up on drives and under
  on dinks.
- **The solver aims a millimetre under bounce height.** Its corrections
  are integer divisions by the flight's ticks, so an error of under n um
  rounds to nothing and the bounce slipped a tick late (about 9 cm).

**In the view (display only):**

- **Hit sounds by shot:** smash, slice (backspin), soft, drive or the plain
  pop, from the port kit's variants. Bounces have three variants.
- **Haptics:** crisp and strong from the sweet spot, duller and longer
  off the rim.
- **PADDLE ANGLE** (0, 15, 30 or 45 degrees, in the headset's MATCH
  SETUP): the paddle tips forward in the hand, about the face's normal, so
  the face stays square.
- **The crowd:** bleachers on both sidelines, 108 people in two
  MultiMeshes. They sway, and they stand and jump after a point, harder
  for a long rally or a winner. Applause scales with the rally.
- **The announcer:** the port kit's clips (a subset), one line at a time.
  A lower line while it's talking is dropped; a higher one cuts in; score
  calls queue. It calls the match's start, faults, the score before each
  serve (server first, "all" when level), match point, aces, winners,
  rallies of 10/15/20/30, and the result. The lobby's demo is silent.

## Consequences

- The ball's spin is in the snapshot.
- Rally stats with spin: singles about 14 shots, 3-3 in six matches;
  doubles about 13.
