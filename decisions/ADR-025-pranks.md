# ADR-025: Pranks from the coach's phone

**Status:** Accepted (2026-10-28)

## Context

"I think it'd be fun to hand this to my kid and he does funny things to
me." From the ideas brainstormed, the lead picked the pranks and the easy
wins: a soundboard, silly balls and paddles, weather, the partner's
antics, a walkie-talkie and a selfie on the partner.

## Decision

**A PRANKS tab on the coach page** (`coach/index.html`), beside COACH.
It has big buttons for small hands, and the headset keeps the lists, so
the page only draws them. Everything goes through the desk as one message
type, `{"type": "prank", "what", "id", ...}` (`CoachDesk._prank`), and
`view/pranks.gd` (`Pranks`, a child of every MatchView) does it.

- **Sounds:** AIRHORN, BOO, CHEER, BA-DUM-TSS, SAD TROMBONE, BOING,
  WHOOPEE and SLIDE WHISTLE, in your ears. They're synthesized by
  `tools/make_pranks.py` (no samples to license), like the target ding.
  The announcer also calls OUT!, NET!, KITCHEN!, ACE! or WINNER! wherever
  the ball really landed.
- **Silly balls:** a rubber duck that squeaks when hit, a watermelon
  that splats on the bounce, a pea, a beach ball that boings, and their
  face (a photo always facing you). The ball in your free hand changes
  too.
- **Silly paddles:** a frying pan that clangs on your hits, a baguette,
  a fly swatter and a foam #1 hand (`PaddleMesh.set_skin`).
- **Weather:** snow or bubbles, until cleared. A CONFETTI button bursts
  over the net.
- **Antics:** the partner (in a match, the other side) can DANCE, FLEX,
  WAVE or JUMP FOR JOY (`Avatar.antic`). An antic waits for the swing:
  from the backswing to the follow-through the ball comes first, and then
  the antic goes on.
- **Their voice:** HOLD TO TALK, with NORMAL, ROBOT, CHIPMUNK or MONSTER.
  The phone decodes the recording itself (the headset can't decode a
  phone's formats), mixes it to mono, gives it the voice, trims it and
  resamples it to 16 kHz. It sends 16-bit PCM in base64, 8 s at most.
  The clip comes from the partner's head, and the partner nods and
  gestures along.
- **Their face:** TAKE A SELFIE (the phone's camera). It's cropped
  square, 256 px JPEG on the phone, then cut round with a white rim on
  the headset. It goes on the partner's face like a cut-out mask, on the
  bullseye, and as the THEIR FACE ball.

The looks (ball, paddle, weather, face) are the desk's, like the coach's
marks: they go back on every new view until changed or cleared.

**Limits, so it stays fun:**
- **Cooldowns per kind** (`COOL_MS`): a sound every 1.2 s, a call 1.5 s,
  an antic 2.5 s, confetti 3 s, a voice clip when the last one is done.
  The page greys a group while it waits.
- **MERCY** on the pause menu (while COACH MODE and PRANKS are on) takes
  every prank off and holds them off for a minute. The phone shows the
  countdown.
- **COACH > PRANKS FROM THE PHONE** turns the tab off on the headset
  (saved; on by default).
- **Nothing that disorients:** no shaking, flipping, darkening or moving
  the world, and no ball from behind. In a headset those make people
  lunge or feel sick.

**Display only.** The sim never sees a prank: the ball and paddle you
see change, the ones it plays with don't. `test_pranks` runs a drill
with all of them on against a bare sim and compares snapshots.

**Messages are bigger.** The socket takes up to 1 MB per message
(`Coach.INBOUND`; Godot's default is 64 KB). JSON goes out unsorted, so
the page shows the buttons in the headset's order.

## Consequences

- The phone's microphone needs a secure page (HTTPS or localhost). The
  headset serves plain HTTP on the Wi-Fi, so a phone gets RECORD A
  MESSAGE instead. That opens the phone's own recorder (`<input
  capture>`, which takes audio or a video's sound). Android's browsers
  open a recorder. An iPhone only offers the camera, and Safari can't
  decode a video's sound directly (decodeAudioData fails on its .mov).
  So when decoding fails, the page shows SEND IT: the tap plays the clip
  silently through the audio graph (a media element source) and catches
  its sound as it plays. That takes as long as the clip, and the tap is
  what lets Safari play it (amended 2026-10-28, after the lead's iPhone
  failed). HTTPS (a self-signed certificate in Godot) would
  give HOLD TO TALK everywhere, but means a certificate warning to tap
  through: later, if it's missed.
- The sounds are synthesized and want a listen in the headset; they're
  easy to change in `make_pranks.py`.
