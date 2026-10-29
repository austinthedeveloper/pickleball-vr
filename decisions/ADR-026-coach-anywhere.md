# ADR-026: COACH FROM ANYWHERE, through the relay

**Status:** Accepted (2026-10-29)

## Context

The coach page (ADR-023) works only on the headset's Wi-Fi: the phone
dials the headset's address. A coach at home can't watch, and the page is
plain HTTP, so a phone's microphone is off (HOLD TO TALK falls back to
RECORD A MESSAGE, and on an iPhone to SEND IT; ADR-025).

The relay shared with the port kit is live (the port kit's
`design/RELAY.md`; repo `../pickleball-relay`, on Azure Container Apps in
East US). It pairs connections in rooms by a four-letter code and passes
their messages on.

## Decision

**COACH > COACH FROM ANYWHERE** (saved, off by default; shown while COACH
MODE is on). When on, the Coach node keeps serving the Wi-Fi as before
and also:

- **opens a `pb94-vr-coach` room** on the relay (`Coach.RELAY`) as its
  host, and shows ANYWHERE   ROOM BXKM on the COACH page. The line
  updates in place as the room opens or closes (`Coach.room_changed`);
- **sends the relay its own page** (`{"op":"page"}`), which the relay
  serves at `/c/BXKM`. The page always matches the game's version, and
  there's nothing to deploy for it;
- **treats the relay's guests as coaches,** with the same JSON inside
  binary frames (one byte of guest number on the headset's side). They
  must send the four-digit code first, as on the Wi-Fi
  (`Coach._receive` serves both);
- **keeps the room open** with a word to the relay every minute, and
  dials again after a drop (2, 5, 10, then every 30 s). A new connection
  is a new room.

**The coach's side:** open the relay's address, type the room, then the
code. The relay's front page asks for the room and opens `/c/ROOM`.
Served from there, the page sees `/c/` in its address and talks through
the room instead of to the headset's port. If the room closes, it says
so and goes back to the start.

**HTTPS is the bonus.** The relay's page is secure, so HOLD TO TALK uses
the phone's microphone, iPhones included.

## Consequences

- **The headset needs the internet,** not just the Wi-Fi. With none, the
  COACH page says ANYWHERE   CONNECTING... and keeps trying.
- **A headset that sleeps** drops its room, and a new one opens on wake.
  The coach types the new room.
- **Delay:** everything goes through East US. From the lead's Mac, a
  message to the headset and back took 89 ms, plenty for coaching.
- **The relay's address is long.** A coach bookmarks it once. A short
  domain (about $12 a year) would make it easy to say aloud; that's the
  lead's call.
- **Privacy:** the relay stores nothing and logs counts, not messages.
  The page, the coach's commands, voice clips and selfies pass through
  it in memory only. A room's page is public while the room is open
  (anyone with the room can load it), but it does nothing without the
  four-digit code.
- **Tests:** `test_coach` runs the Coach against a stand-in relay (the
  room, the page, a coach's code and commands, the state out, a drop and
  the redial) and checks the COACH page's rows. The relay has its own
  tests. Checked live on 2026-10-29: the desktop game through the real
  relay, and the page in a browser (room, code, the lobby's state, HOLD
  TO TALK available, the closed-room message).
