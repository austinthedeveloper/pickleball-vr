# ADR-002: A new 3D sim, pure and exact, with the port kit's rules

**Status:** Accepted (2026-10-27)

## Context

The port kit's sim is a frame-exact port of the SNES C (port ADR-059). Its
world is the ROM's: ground pixels in 12.4 fixed point, a ball with a
height, and shots chosen by buttons. A swing is an intent (HIT, DRIVE,
SOFT, SLICE), not a paddle. In VR the player holds the paddle, so the
paddle's own position and angle have to decide the shot. The SNES sim
can't take that input, and squeezing it in would break the conformance
traces the port kit lives by.

What the port kit taught, and what must carry over:

- **Pure and exact.** No Nodes, no clock, ints only, so tests, golden
  traces, replays and rollback netcode all work (port ADR-102/103).
- **Presentation never writes to the sim.**
- **The CPU schedule is the shipped schedule.** Tests use `step()`.
- **The rules**: rally scoring to 5 (the ROM's default), the two-bounce
  rule, no volleys from your own kitchen (port ADR-055), the faults and
  their names (NET!, OUT!, KITCHEN!, VOLLEY!, FAULT!, 2 BOUNCES).

## Decision

A new sim in `game/sim/`, written for 3D:

- **Units:** micrometres in Godot's axes (y up, net on z = 0, team 0 on
  z > 0), 120 ticks a second, velocity in um/tick, unit vectors in Q14.
  Ints throughout; the one square root goes through `Fx.isqrt`, which is
  exact.
- **Real dimensions:** a 20 x 44 ft court, a 7 ft kitchen, a net 34 in at
  the centre and 36 in at the posts, a 74 mm ball with gravity, air drag,
  and a bounce tuned to the rulebook's drop test.
- **Variety from a seeded generator** held in the sim's state. The SNES
  sim drew on frame counts instead; the seed makes "the same match again"
  explicit.
- **Rules in the port kit's shape.** `resolve_point`, `_rules_hit` and
  `_rules_bounce` follow `rules_process_player_hit` and
  `rules_process_ball_events`, so a rules change can be checked against
  both.
- Singles uses slots 0 and 2, so doubles drops into the same layout
  (team = slot >> 1, as in the port kit).

## Consequences

- The sim gives up frame-exactness with the ROM. In return it keeps
  determinism, which the tests (`test_match.test_deterministic`) and,
  later, the golden traces and online play depend on.
- Tuning lives in `sim/k.gd`. The port kit's CPU styles are re-cut
  (`SimTypes.CpuStyle`), since speed, reach and aim error are now metres.
