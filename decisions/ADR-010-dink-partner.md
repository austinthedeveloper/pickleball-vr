# ADR-010: DINK PARTNER and floor targets

**Status:** Accepted (2026-10-27)

## Context

The lead spends most of their time in practice. For dinking, they asked
for two things. The first, fast balls at the kitchen line, is the ball
machine's volley feed (ADR-007, amended). The second is a partner on the
other side, not a machine: an AI that only wants to get the ball back,
dinking it near you, never hitting away and never going for a winner. As a
bonus, they asked for floor targets to aim at.

## Decision

- **DINK PARTNER** (MAIN > DINK PARTNER) is a `Drill` with `partner` on.
  - A CPU stands at their kitchen line (slot 2). Between shots it squares
    up to you along that line. When your ball lands in court on its side,
    it plans the ball's path (`Intercept`), moves to the ball, lets it
    bounce and dinks it back.
  - Every shot lands about a metre in front of you and within about
    45 cm of your line, in your kitchen, with a little backspin. It never
    aims away and never drives.
- **A rally, not a feed loop.** A ball that lands in court keeps the
  rally going: one in their kitchen counts as a good dink, while one that
  lands deeper is MISSED THE ZONE (the streak resets, but the partner
  still plays it). A ball out or in the net ends the rally, and the
  partner starts a fresh one. The scoreboard shows the rally and the best
  rally (saved). The announcer calls rallies of 10, 15, 20 and 30.
- **No volleys from your kitchen**, as in a match (the KITCHEN rule).
- **DIFFICULTY is how low the dinks skim the tape:** EASY clears it by
  60 cm (peaking about 1.9 m), MEDIUM 30 cm (1.5 m), HARD 12 cm (1.3 m).
  Pace alone didn't change anything: a dink must loft over the net, so the
  solver chose the same arc whatever pace was asked for. `Aim.shot` takes
  the clearance now.
- **Floor targets** (TARGETS on DINK PARTNER, on by default, and on the
  BALL MACHINE): a glowing circle 45 cm in radius on their side, inside
  the return zone (their kitchen for the partner). Land a ball in it for
  TARGET!, then it moves at least a metre. Hits are counted on the
  scoreboard. The bot aims at the target when there is one, so the
  demo and the tests use it.

## Consequences

- The partner is pure sim like everything else: seeded, deterministic,
  in the snapshot. Matches are untouched, so the golden traces are too.
- Later candidates: the partner's resets and speed-ups (a FIRM level that
  sometimes attacks a high dink), a target pattern (corners in turn), and
  a partner for the kitchen-line hands battle.
