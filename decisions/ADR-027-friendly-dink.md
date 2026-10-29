# ADR-027: FRIENDLY DINK, and dinking online with a friend

**Status:** Accepted (2026-10-29). The sim's part is built (VR-74); the
netcode, the friend on court and the menu are planned (VR-75..78).

## Context

The lead wants to dink with a friend in another house: one on one, no
CPU. The relay shared with the port kit (ADR-026) already pairs two
connections in a room and keeps a game for it (`pb94-vr`). The port kit
plays online through it (port ADR-105) with a lockstep-or-rollback
session over a deterministic sim; the VR sim is deterministic too
(ADR-002) and already takes a human in each singles slot (`humans = 2`).

What's missing is a way to play that's just dinking: a match would make
two friends serve from the baseline and keep score.

## Decision

**FRIENDLY DINK is a match variant in the sim** (`MatchConfig.friendly`),
not a drill: drills are built around one human and a machine or CPU
partner on slot 2.

- **Singles, two humans**, standing behind their kitchen lines
  (`Sim.FRIENDLY_BACK`, 40 cm).
- **The start is a dink off a drop.** The starter drops the ball from
  their hand, as on a drop serve, and hits it before or after the
  bounce. There's no service box and no two-bounce rule.
- **The usual faults end a rally**: the net, out, two bounces, and a volley
  from the kitchen. The kitchen is judged from the head with practice's lean
  (ADR-019): leaning over the line is fine.
- **No score.** A rally's count is its returns (the hits after the start).
  `EVENT_RALLY` reports it, the best so far and who missed; `best_rally`
  is sim state, in the snapshot. The match never ends.
- **Whoever missed starts the next rally**; they're the one fetching the ball.
- A CPU on the other side would still serve as in a match: FRIENDLY DINK
  is for two humans (and the tests' Bots, which dink into the kitchen from
  the kitchen line when `friendly` is on).

**Online, as planned** (each its own task):

1. **VR-75, the netcode:** the port kit's `net/` (NetLink, RelayLink,
   OnlineSession, Rollback) carried over. Each message is a tick's
   `HumanInput.to_array()` (head, paddle, normal, hand, toss), several
   ticks to a frame. The relay game is `pb94-vr`. Rollback needs the
   sim's state saved and restored, not just its snapshot.
2. **VR-76, the friend on court:** their body, head and paddle from their
   inputs; the ball after their hit eased into place, not snapped.
3. **VR-77, PLAY A FRIEND:** HOST shows the room, and JOIN takes four
   letters from a picker of the relay's alphabet.
4. **VR-78, a playtest:** the Quest against the Mac's flat mode, then two
   houses.

Voice isn't part of it: a phone call or Discord at first.

## Consequences

- Two friends can dink in the sim today; there's no screen or online play yet.
- Your own hits will be instant (rollback predicts the friend); the
  friend's will reach you a round trip late, 50 to 100 ms on the relay,
  which the view must hide. Only a playtest can say if it's good enough.
- Golden traces are unchanged: every rule change checks `config.friendly`,
  and the snapshot only grows when it's on.
- Tests: `test_friendly` (two Bots dink for three minutes, with rallies
  counted and no score; the start; who starts next; the kitchen with the
  lean; determinism). Ten minutes of two Bots: 53 rallies, an average of 7
  returns, a best of 63, and every bounce in the dink zone.
