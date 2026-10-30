# ADR-027: FRIENDLY DINK, and dinking online with a friend

**Status:** Accepted (2026-10-29). The sim's part (VR-74), the netcode
(VR-75) and the friend on court (VR-76) are built; the menu and a
playtest are planned (VR-77, VR-78).

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

**The netcode as built (VR-75, `game/net/`):**

- `NetLink`, `LoopbackLink` and `RelayLink` are the port kit's; the relay
  game is `pb94-vr`, and the version is `application/config/version`.
- **Your input isn't delayed** (`Rollback.DELAY` 0): your paddle in the
  sim is where your hand is. The port delays its own input 1 or 2
  frames to cut corrections; in a headset that would put the paddle
  behind the hand.
- **A guess is wrong only when it changed what both share.** A friend's
  hands move every tick, so a guess of them is never exactly right, and
  comparing inputs (the port's way) would roll back every tick. Instead,
  `pred`'s shared state is hashed after each tick (`Sim.snapshot(slot)`:
  everything but that slot's head and paddle, and a held ball's place),
  and when `truth` steps the same tick on the real input and the hash
  differs, `pred` is reset and runs again. A swing that missed the ball
  costs nothing; one that hit it is a correction.
- **The guess carries the friend's head, paddle and hand on** at their
  last two ticks' speed (up to 8 ticks), with the face held and never
  a toss.
- Prediction runs at most 36 ticks (300 ms) past what's confirmed and
  waits beyond that. The time sync holds a tick for the side that's 2 or
  more ahead, once a second. A hash of `truth` is compared every 2 s.
- **Messages:** each tick's input is a PackedInt32Array (12 ints), and a
  frame's messages go out together as one "B".
- `Sim.save_state()` / `load_state()` copy every script variable of the
  sim, its ball, players and drill (the config is shared).

**On court, as built (VR-76):**

- **Each end.** MatchView takes the session (`setup(..., online)`), draws
  its prediction and plays slot `me`: 0 for the host, 2 for the guest.
  The rigs take an `end` (1 near, -1 far): the guest's XR rig faces +z
  and the flat camera turns round, its keys and aim with it. The
  scoreboard turns to the guest. Everything stays in the sim's
  coordinates; nothing is mirrored. FRIENDLY DINK doesn't move you
  between rallies.
- **The friend is an Avatar with `human` on:** their paddle drawn exactly
  where theirs is in the sim (the ball bounces off what you see), the
  hand on its grip, the free hand where theirs is, the feet under their
  head. No CPU swing is planned for them.
- **The ball eases after a correction:** the jump between where you saw
  it and where it really is fades (half gone in 60 ms; over 1.5 m it
  snaps: a new rally). The sim is untouched.
- **Each event plays once** (`MatchView._fresh`): an event of the same
  kind (and hitter) within 3 ticks of one already played is the same
  one, run again by a correction.
- FRIENDLY DINK's board shows this rally's returns and BEST; a rally's
  end says RALLY n (NEW BEST! from 5) and the crowd and announcer
  answer a long one.
- Flat mode in FRIENDLY DINK dinks where the mouse aims, soft unless
  Shift is held.
- The screenshot tool's `online` and `online_guest` show either end, the
  other a Bot on its own session.

## Consequences

- Two friends can dink online in the code; there's no screen yet.
- **Measured (VR-75):**
  - Two Bots through the live relay from the Mac: a room in 0.17 s,
    connected in 1.8 s, an 83 ms round trip, 60 s in sync (30 hashes),
    no stalls, 17 and 23 corrections, about 6 ticks predicted ahead.
  - On a loopback at 50 ms each way with jitter: 90 s, about one
    correction per friend's hit (35), and a best rally of 30.
  - A sim step is 10 us on the Mac, and a save and load 77 us, so a
    correction's re-run of 6 to 12 ticks is well under a millisecond
    there; the Quest is slower and is checked in VR-78.
- **For the view (VR-76):** a corrected tick's events play again, so
  sounds must be played once per hit (the port's EventLedger idea).
  The relay lets `pb94-vr` rooms take 3 guests; the host talks only to
  the first, so a third person would wait forever.
- Your own hits will be instant (rollback predicts the friend); the
  friend's will reach you a round trip late, 50 to 100 ms on the relay,
  which the view must hide. Only a playtest can say if it's good enough.
- Golden traces are unchanged: every rule change checks `config.friendly`,
  and the snapshot only grows when it's on.
- Tests: `test_online_view` covers two MatchViews dinking over a
  loopback (in sync, rallies, the friend's paddle where theirs is, the
  logged inputs replaying to the confirmed match), each end and its
  rig, the friend's body, an event playing once, the ball easing, and
  the friend leaving. `test_online` covers a saved state stepping as before (a match
  and a drill), the pose-free snapshot, the config, two sessions
  dinking with rollback on a jittery loopback, a slow line that waits,
  versions, a stand-in relay, and the real relay server when it's
  beside the game (skipped on CI). Also `test_friendly` (two Bots dink for three minutes, with rallies
  counted and no score; the start; who starts next; the kitchen with the
  lean; determinism). Ten minutes of two Bots: 53 rallies, an average of 7
  returns, a best of 63, and every bounce in the dink zone.
