# ADR-012: How the practice partners look and move

**Status:** Accepted (2026-10-27)

## Context

The lead spends most of their time practising with the ball machine and
the dink partner, so those are what they look at. They asked for basic
styling with good animation, with no need to match the port kit (though
borrowing is welcome). The first versions were placeholders: a capsule
person whose paddle slid toward the ball, and a box machine.

## Decision

All display only (`game/view/`); the sim, its tests and the golden traces
are untouched.

- **The person** (`view/avatar.gd`) is built from simple shapes on a rig
  of joints, posed every frame.
  - Arms and legs are two-bone IK chains (shoulder-elbow-hand,
    hip-knee-foot) solved toward targets, so elbows and knees bend
    naturally.
  - Feet stay planted, and one at a time steps when the body has moved
    off it, so moving across the court reads as a shuffle.
  - A split step (a small hop) as the other side hits. A ready crouch while
    the ball is coming. A forward lean, and the torso coiling into the
    backswing.
  - **The swing is timed to the sim's contact.** The partner's planned
    tick, or a CPU's, gives the contact point and time from a copy of the
    ball flown ahead: a backswing, through the contact, a follow-through,
    then back to ready. When the sim says the hit happened, the swing
    syncs to it. Dinks get a short, low swing; drives a full one.
  - The head watches the ball in play and looks at you between points.
    Its tilt is limited so the cap never hides the face.
  - A conventional face: eyes, brows, nose, mouth, ears, hair, and a cap
    with a visor. Skin and hair vary by player; the shirts are the ladder
    teams' colours.
- **The feet carry the body** (amended after the first look: "dragged
  around by his torso, the legs along for the ride"). The hips used to
  glide with the sim while the feet stepped after them. Running sideways
  at 3.5 m/s, the feet trailed the body by about 1 m in 5 steps. Now:
  - each step lands where the body will be (led by its velocity);
  - steps quicken with speed and overlap when running;
  - sideways, the lead foot goes first;
  - the hips ride between the feet, leaning only a little ahead, and dip
    as a foot swings through;
  - the free arm swings with the stride.

  At the same run, the feet lag 0.35 m and take 9 steps
  (`test_avatar.gd`).
- **The ball machine** (`view/machine.gd`):
  - A wheeled base with a handle and an accent band.
  - A clear hopper whose balls empty one per feed (and refill).
  - A launch head on a post at the sim's release height. It turns and
    tilts along each feed's line, with two throwing wheels spinning at the
    SPEED setting.
  - Just before a feed, a ball rolls from the hopper into the head; on the
    feed the head kicks back.
  - A light on top blinks for the last second before a feed, and turns
    red when a lesson is done.
- **The paddle** (`view/paddle_mesh.gd`) is a rounded face with an edge
  guard, a stripe, a wrapped grip and an end cap. The sim's contact disc
  is unchanged.
- **The ball:** a pickleball with rings of holes, painted into a small
  texture at load (`view/look.gd`), with a slight glow. It turns with its
  spin. When it's moving faster than 7 m/s, a short fading trail helps
  you track it.
- **Cost:** small parts don't cast shadows. Everything is simple meshes,
  and the hopper's balls are one MultiMesh.

## Consequences

- `tools/screenshot.gd` can pin the camera (`cam=`, `look=`) for
  close-ups, which go into `shots/`.
- Later: real textures (court, grass, the shirts' patterns), baked
  lighting, and a proper skinned character if the shapes stop being
  enough.
