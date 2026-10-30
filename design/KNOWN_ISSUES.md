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
9. ~~The CPUs' paddle could leave their hand~~ in some wind-ups. Fixed
   (VR-71): the hand stops at the arm's reach, and
   `test_the_paddle_never_leaves_the_hand` watches a whole rally.
10. **Online, a guessed sound can't be taken back** (ADR-027). When the
    prediction guessed your friend's paddle met the ball and it really
    didn't, you hear a hit that didn't happen; the ball then eases to
    where it really is. Rare: a guess carries their swing on for only
    8 ticks.
11. **Online, a third player waits forever** (ADR-027). The relay lets a
    `pb94-vr` room take 3 guests, but the host talks only to the first.
    The fix is the relay's `GAMES` entry (1 guest) or a refusal from the
    host.
12. **Flat mode's help line says SHIFT SOFT** in FRIENDLY DINK, where soft
    is the default and Shift drives (ADR-027).
