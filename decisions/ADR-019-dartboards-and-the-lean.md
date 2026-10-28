# ADR-019: Dartboard targets, and a lean allowance at the kitchen line

**Status:** Accepted (2026-10-28)

## Context

The lead played every drill in one session. The swing log (ADR-017),
mode by mode:

| Mode | Good | Best streak | Most common miss |
|---|---|---|---|
| LINE AND CROSS | 95% | 40 | (none to speak of) |
| ATTACK OR DINK | 51% | — | — |
| VOLLEY DINKS | 8% | — | MISSED THE SPOT, 16 of 25 |
| CALL THE SPOT | 3% | — | MISSED THE SPOT, 19 of 31 |

"Anything with a target: make it more like a dartboard. Bigger with a
few rings, bullseye being the most points. It's hard to hit them
exactly."

The kitchen fault was judged from the headset. A player standing on the
line and leaning over it, which is legal and common, put their head
inside: "give a bigger buffer on the line or just remove it in practice".

## Decision

**Dartboards.** Every target is a board with three rings: an outer ring,
an inner ring and a bullseye.
- The rings end at 100%, 66% and 33% of the board's radius. They score
  1, 2 and 3 points (`Drill.ring`).
- Landing anywhere on the board counts. CALL THE SPOT and VOLLEY DINKS
  call it GOOD and add the ring's points. Off the board is still MISSED
  THE SPOT.
- The boards are bigger. The spots are 1.0, 0.85 and 0.7 m in radius
  (EASY to HARD), up from 0.6, 0.45 and 0.35 m. The floor targets in
  DINKS and on the machine are 0.8 m, up from 0.45 m.
- The scoreboard shows POINTS. A landing on a board flashes +1, +2 or
  BULLSEYE! +3.
- The swing log's RESULT lines say the ring and how far from the centre
  the ball landed, so the next session shows how close the misses are.

**The lean.** In practice (`Drill.in_kitchen`), you're in the kitchen
only when your head is more than 45 cm past the line. That's a lean
over a planted foot, not a step in. Matches keep the rule as the sim
has it.

## Consequences

- A test pins the rings and points, the boards shrinking with
  difficulty, and the lean: 30 cm over is fine, 60 cm in is a fault.
- The bot's success rates in the kitchen drills only go up (bigger
  boards). The golden traces are unchanged: they don't play spot drills.
- Matches still judge the kitchen from the head. If that bothers the
  lead in a match, the same lean could apply to the human player there.

## Amendment (2026-10-28): the target follows you

In DINKS, the lead switched sides and the target stayed where it was. It
only moved after a hit. A partner drill's floor target now sits in the
partner's half of their kitchen: straight across from you, or the
diagonal on CROSS COURT. If you cross to the other side, more than
40 cm past the middle, it moves to the new half before the next feed.
