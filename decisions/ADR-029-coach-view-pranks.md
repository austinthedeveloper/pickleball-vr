# ADR-029: PRANKS, and the coach's voice, from a watching computer

**Status:** Accepted (2026-10-30). Built: VR-82.

## Context

COACH VIEW (ADR-028) gave a coach on a Mac the phone's coaching
controls, but not its PRANKS tab (ADR-025). The lead, after trying it:
"Having a voice or way to communicate goes a long way." The phone's
cues are a fixed list; its HOLD TO TALK is the only way to say anything
else.

The headset already takes every prank as the phone sends it,
`{"type": "prank", "what", "id"}`, and a voice as 16-bit mono PCM at
8 to 24 kHz, at most 8 seconds (CoachDesk's checks, cool-downs and
MERCY). A watching game's RemoteCoach passes any message on to the
headset through the relay.

## Decision

**The coach's panel gets the phone's two tabs, COACH and PRANKS.** PRANKS
has what the phone's has and sends the same messages:

- TALK TO THEM, in four voices;
- the sounds and the announcer's calls;
- the partner's antics (shown when there's a partner) and confetti;
- the silly ball, the silly paddle and the weather, with the ones on now
  lit from the headset's state.

THEIR FACE is left out: it needs the phone's photo. MERCY and the
headset's PRANKS switch hold the Mac's pranks off as they do the phone's,
and the page says so. The headset's row is now PRANKS FROM THE COACH,
since it covers both.

**HOLD TO TALK reads the computer's microphone** through
`AudioServer.set_input_device_active` and `get_input_frames` (Godot 4.6
on). Holding the button or the T key records; letting go sends. The clip
is made in `view/voice_rec.gd` as the phone page makes it:

- the quiet ends trimmed;
- at 16 kHz;
- CHIPMUNK or MONSTER by speed, ROBOT ring-modulated, MONSTER
  saturated;
- normalised to 90%;
- at most the headset's 8 seconds.

Nothing heard sends nothing.

**The microphone is for computers only.** `audio/driver/enable_input` is
on for the `pc` feature tag alone, so the Quest build never opens a
microphone or asks for RECORD_AUDIO. The macOS export asks for the
microphone entitlement, with a reason shown by macOS.

**The relay link's outbound buffer is 512 KiB.** An 8-second clip is
about 340 KB of base64 in one message. Godot's default buffer is 64 KiB,
too small for it to go. The relay takes up to 1 MiB a message.

## Consequences

- A coach watching from a Mac can talk to the player and prank them. A
  full 8-second clip reached a player 0.4 s after it was sent through the
  live relay.
- Run from a terminal (`godot --path game`), macOS asks once to let the
  terminal use the microphone. Without that, recordings are silent and
  the page says it couldn't hear you.
- The pranks are the headset's own. The coach's screen draws the
  player's drill from the sim, so the coach doesn't see the duck or the
  snow. The lit buttons say what's on.
