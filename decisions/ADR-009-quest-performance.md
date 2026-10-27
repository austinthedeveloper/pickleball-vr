# ADR-009: Quest performance: one shadow map, foveation, a fast aim solver

**Status:** Accepted (2026-10-27)

## Context

On the Quest 3 (the first device session), the game held about 71 of 72
fps, with 1 to 9 frames a second late. Each frame took 10 to 11 ms of
GPU time out of a 13.9 ms budget, and the CPU averaged 15 to 20% busy.
The late frames came while the GPU had room, which pointed at bursts on
the CPU. On the Mac, the aim solver (`Aim.shot`) took 2.0 ms a shot, and
the worst sim tick 11.7 ms. The Quest's cores run GDScript several times
slower. Every CPU shot, every assisted human shot and every demo-bot plan
calls it.

## Decision

- **Rendering:** the sun casts a single orthogonal shadow map over the
  court instead of four splits (each split draws the scene again). Fixed
  foveated rendering is on, at level 3 and dynamic. Together they saved
  about 1 ms of GPU time a frame.
- **Exact speed-ups** (golden traces unchanged):
  - `Fx.isqrt` skips its fix-up loops below 2^50. There a double's
    correctly rounded square root can't round up across an integer, so
    `int(sqrt(n))` is already exact.
  - `Ball.fly` inlines its length, drag and Magnus maths, and skips
    Magnus for a ball with no spin.
  - The solver stops once every correction rounds to zero.
- **A faster solver** (golden traces regenerated). `Aim.solve` takes
  secant steps per axis: the slope comes from the last two passes, not
  from the no-drag guess. Its first guess comes from a fitted drag reach
  of 1 / (1 + 0.62 kD), and it stops within 2 mm. Shots land within the
  same tolerance (`test_aim`, `test_spin`), and rally stats are unchanged
  (3-3 in six matches).
- **Measured, not guessed:** debug builds log `PERF` lines every 2 s.
  They give the average and worst ms by section (input, bot, sim, draw,
  crowd), plus slow frames and ticks per frame. Release builds skip it.

## Consequences

| On the Mac | Before | After |
|---|---|---|
| `Aim.shot`, a drive | 2.0 ms | 0.25 ms |
| `Aim.shot`, a dink | 1.5 ms | 0.46 ms |
| Worst sim tick | 11.7 ms | 2.2 ms |
| Worst bot input | 14 ms | 2.2 ms |
| The test suite | 17 s | 8 s |

**On the Quest 3, in a match (2026-10-27, debug build):**

- **CPU:** a frame's work averages about 0.5 ms (crowd 0.2, sim 0.1,
  input and draw under 0.1 each). The worst frame in 2 s ranges from 0.7
  to 6.7 ms. No frame went over 11 ms.
- **Display:** 72/72 fps. Late frames went from 1 to 9 a second to 0
  most seconds, with an occasional 2 or 3.
- **What remains is the GPU:** 10.4 to 11.5 ms a frame of the 13.9 ms
  budget. The few late frames come at the top of that range, not from
  the CPU. The next savings are on the GPU side.
