# ADR-014: HANDS, the partner's fast-hands drill

**Status:** Accepted (2026-10-27)

## Context

After DINK PARTNER (ADR-010), the lead asked for a second partner drill:
"Hands", where both players stand across from each other at the kitchen
and keep the ball alive, hitting hard at each other. It trains the same
reflexes as the ball machine's volley feed (ADR-007), but with a rally:
your ball comes back at you, wherever you sent it.

## Decision

- **PRACTICE PARTNER** (MAIN; it was DINK PARTNER) has a **DRILL** row:
  DINKS (ADR-010, unchanged) or HANDS. It's saved (`partner/hands`).
- **The partner volleys everything.** In HANDS it never lets a ball
  bounce: once your ball is on its way and within reach (`K.REACH`,
  between 25 cm and 1.9 m up), it hits it back in the air
  (`Drill._partner_takes_it`). It reads your ball after 0.1 s instead of
  the dink partner's 0.18 s.
- **At you, hard.** Each volley is aimed through a point about 95 cm up
  (give or take 15 cm), at your body or up to SPREAD to either side, with
  topspin (`Aim.through`). DIFFICULTY is the pace: EASY 7.2 m/s, MEDIUM
  10.2 m/s, HARD 13.2 m/s.
- **What counts.** Any ball of yours the partner can volley is GOOD and
  adds to HANDS IN A ROW (the zone is anywhere in; no floor targets). A
  ball in the net or out ends the rally, as in DINKS. The partner's
  volleys often fly long if you leave them: that's the drill, so a ball
  you don't play is MISSED, and the CPU in the demo plays them too (it
  skips its "going out" check in HANDS).
- **Volleys up to chest height.** `Intercept.plan` takes the highest
  ball to plan for; HANDS uses 1.8 m instead of the usual comfort height.
- FOCUS (ADR-013) works the same: the streak is hands in a row.

## Consequences

- The demo CPU rallies at every level (36 in a row on HARD in the bot
  test); `test_partner.gd` checks the volleys never bounce, harder is
  faster, the partner stays up at the net, the menu and the save.
- The bot used to walk to (0, 0) when it had nothing to plan; it now goes
  home to its spot. Golden traces are unchanged.
