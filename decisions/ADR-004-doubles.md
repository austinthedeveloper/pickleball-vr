# ADR-004: Doubles: rally-scoring rotation, a CPU partner, lanes

**Status:** Accepted (2026-10-27)

## Context

Phase 2. The port kit's doubles (port ADR-018/036/038/043) has four
players in slots 0 to 3 (team = slot >> 1), a CPU partner, and lane
rules so partners don't both chase a ball. Rally scoring is the ROM's
default.

## Decision

- **Slots as in the port kit:** 0 is you, 1 is your CPU partner, 2 and 3
  are the far side. `MatchConfig.doubles`, and `-- doubles` on the
  command line until the menus come.
- **Rally-scoring rotation:** each player has a court (right or left). The
  serving side serves from the player in the right court on an even
  score, and the left on odd. When the serving side wins the rally, its
  two players switch courts. When it loses, the serve passes with nobody
  switching. The receiver is the player diagonally opposite, and only the
  receiver may take the serve.
- **Starting spots:** the server and partner stand back. The receiver
  stands back, and the receiver's partner waits at the kitchen line.
- **Whose ball:** after the serve, whichever partner is nearer the ball's
  line takes it (the right-court player on a tie). That's
  `Sim.covers(slot, x)`. The CPUs and the bot both obey it. You don't
  have to: if you take your partner's ball, it's yours.
- **CPU shots in doubles** go down the middle between the opponents. When
  both are at the kitchen, the dinks go crosscourt.
- **CPU teammates keep 90 cm apart** (port `separate_teammates`).

## Consequences

- The sim's snapshot now holds each player's court and let-go flag, and
  the receiver's slot. The golden traces were regenerated for that alone:
  singles play is unchanged, because `covers` is always true in singles.
- Side-out scoring (port ADR-063) and stacking are left for the menus.
