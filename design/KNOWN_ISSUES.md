# Known issues

1. **The XR rig, first session on a Quest 3 (2026-10-27).** The paddle in
   the hand felt right. Three bugs were found and fixed. The lobby's demo
   took your controllers, so you played it from the spectator corner and
   were reset there each point. Its panel was placed before tracking
   started, so you never saw MATCH SETUP. The held ball sat above the
   fist and jumped when let go. The sticks, the serve and the menus still
   need a check.
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
   the phone's recorder instead. An iPhone may offer only the camera (a
   short video's sound works). The prank sounds are synthesized and
   unheard in the headset yet.
