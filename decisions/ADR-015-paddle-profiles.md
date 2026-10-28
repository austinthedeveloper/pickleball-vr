# ADR-015: Paddle profiles for paddle accessories

**Status:** Accepted (2026-10-27)

## Context

There are VR accessories that act like a paddle: a handle or a paddle
shell the Quest controller clips into. Each holds the controller at its
own angle, and often further from the face than a bare controller in the
hand. The lead asked for the paddle angle to be adjustable and for
profiles: "Default profile is what you have. The others would be
overrides." Until now PADDLE ANGLE was a MATCH SETUP row, with 0, 15, 30
or 45 degrees, so it couldn't be set from practice at all.

## Decision

- **MAIN > PADDLE** is a page of its own: PROFILE, PADDLE HAND, ANGLE,
  and for a custom profile TWIST, REACH and RESET TO DEFAULT. PADDLE ANGLE
  left MATCH SETUP.
- **DEFAULT** is the paddle as it was: ANGLE is the old PADDLE ANGLE
  (0-45), no twist, no reach. Old saves load into it unchanged.
- **PROFILE 1-3** override it. Each has:
  - ANGLE, -30 to 90 degrees in steps of 5: the face tipped about its
    normal's axis, as before, so the face stays square.
  - TWIST, -45 to 45 degrees: the face turned about the handle, for a
    shell that holds the controller rotated.
  - REACH, 0 to 40 cm in steps of 2: the paddle slid out along its
    handle, for an accessory that puts the controller at the butt of a
    longer grip.
  - RESET TO DEFAULT copies DEFAULT's angle and clears the rest.
- One function places the paddle: `XrRig.grip(tilt, twist, reach)`. The
  sim still reads the face's centre and normal from the paddle mesh, so a
  profile changes the contact exactly as it changes what you see.
- **Live:** each change rebuilds the lobby, so the paddle in your hand
  moves as you step the value.
- Saved under `[paddle]` (`profile`, `profiles`): new keys with harmless
  defaults, so the save stays version 1.

## Consequences

- `test_profiles.gd`: DEFAULT's grip is the old one, a profile overrides
  it, the save keeps all three, an old save loads, REACH and TWIST move
  the face as they say, and the page flow.
- A profile per accessory needs a name later (typed names need a
  keyboard). The lead can say what their accessories need first.
