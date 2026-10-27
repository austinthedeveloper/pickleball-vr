# Known issues

1. **The XR rig is untested on a headset.** Its action names (`trigger`,
   `primary`, `ax_button`, `haptic`) match `game/openxr_action_map.tres`.
   The pose name (`grip`), the stick directions and the paddle's angle in
   the hand are unchecked on the Quest (VR-05).
2. **No spin.** The contact model is a restitution bounce off the face
   (ADR-003). Slices and topspin come in phase 3.
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
