# Known issues

1. **Matches in the headset are less played than practice.** Since the
   first session (2026-10-27) nearly all play has been practice and
   coaching. The serve, the sticks and doubles in the headset want a
   session of their own.
2. **Spin is simple** (ADR-006). The paddle makes spin from its brush,
   but friction never bends the shot's line (no sidespin "hook" off a
   slanted face). The spin axis comes straight from the brush, with no
   gyroscopic effects.
3. **The serve isn't checked for form.** Underhand, below the waist and
   behind the baseline are not enforced. The bot's toss is struck at
   about 1.25 m.
4. **Flat-mode swing is automatic.** The bot hits whatever comes within
   reach of where you stand. It is a stand-in, not the VR game.
5. **Net cords.** A ball that touches the tape always drops back on the
   hitter's side (a NET! fault). Real tape-rollers that go over aren't
   modelled.
6. **The golden traces use Godot's `hash()`** of the snapshot. If a Godot
   upgrade changes `hash()`, regenerate them, with the reason in the
   commit.
7. **The announcer and the crowd are untested by ear.** The clips come
   from the port kit and are all present (`test_audio`). The volumes and
   the call timing need a listen in the headset.
8. **HOLD TO TALK needs HTTPS** (ADR-025). The headset serves plain HTTP,
   so a phone's browser won't open the microphone; the PRANKS tab opens
   the phone's recorder instead. An iPhone offers only the camera: after
   recording, tap SEND IT and the page plays the video silently to catch
   its sound. The prank sounds are synthesized and
   unheard in the headset yet.
9. **The CPUs' paddle can leave their hand** for a moment in some
   wind-ups (seen in screenshots, 2026-10-28, with the classic body and
   the new one alike). The hand's target is then out of the arm's reach,
   so the paddle is drawn where the hand was meant to be. It's display
   only.
