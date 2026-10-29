# ADR-018: Rigged bodies for the partner and the CPU players

**Status:** Accepted (2026-10-28)

## Context

The partner and the CPU players (ADR-012) were built from about thirty
capsules, spheres and boxes, placed each frame from joints the Avatar
works out: two-bone IK for the legs and arms, planted feet, a timed
swing. The lead asked how to make the partner "not just shapes". The
outline was what read as shapes: capsules meeting at the elbows and
knees. Textures on the same primitives wouldn't change that. The lead
picked a rigged CC0 model.

## Decision

**The model.** Quaternius' *Universal Base Characters* (free Standard
pack, CC0; `game/assets/people/LICENSE.txt`): a male and a female base
body, about 7k vertices each, with a 65-bone humanoid skeleton (the
Unreal Engine mannequin's bone names), and six hairstyles skinned to the
head. The glTFs are stripped of their embedded textures, and the
textures are scaled to 1024 px. The pack's hair normal maps aren't used.

**Posed from the same joints.** `Body` (`view/body.gd`) wraps the
skeleton. The Avatar keeps all its footwork, swing timing and IK. Where
it used to place shapes, it now says per bone:
- `orient`: the T-pose turned to a forward and up. Used for the pelvis,
  spine, neck, head and feet.
- `aim`: swing the bone to point at a spot, keeping its twist. Used for
  the thighs, calves, upper arms and forearms, toward the IK's knees,
  ankles, elbows and hands.
- nothing: the bone stays at rest under its parent.

The IK uses the model's own bone lengths. The hips and shoulders are
read from the posed skeleton (`at`), so the limbs start where the mesh
has them. The paddle hand reaches its grip a palm (7 cm) past the wrist,
the hand turns so the palm sits behind the paddle face, and the fingers
curl round the handle. While holding the next feed (ADR-016), the free
hand turns palm up under the ball.

**Clothes: cloth shells.** The base bodies are in underwear. The first
cut painted the clothes on in the skin shader; in the headset the lead
found the shirt "looks painted on" (2026-10-28). Now the shirt and shorts
are their own meshes (`view/cloth.gd`), made from the body mesh itself
when a model first loads:
1. Copy the part of the skin a garment covers, with its skin weights.
   Seams are welded first.
2. Smooth it until the muscles are gone. Taubin smoothing is used
   because it doesn't shrink the mesh.
3. Cut the edges straight: a level hem, sleeves and legs square to the
   limb, and a collar smoothed along itself.
4. Push it out from the skin: snug at the shoulders and waistband,
   looser toward the hems.

The shells are skinned to the same skeleton, so they move with the body.
Under them, the skin shader still paints the cloth colour a little
inside the shell's edges, so nothing pokes through. Socks are painted.
Shoes are meshes on the foot bones. The partner's cap and visor sit on
the head bone. A cap goes with short hair, so the hair doesn't poke
through.

**Looks.** Skin tones come from the light and dark textures, and the
middle tone is the light one tinted. The hair colour comes from the
existing palette. The partner is male. In matches, the ladder's players
named in `Opponents.WOMEN` get the female body, and shorts come from the
team data. Hairstyles and beards vary by slot.

**Culling.** A skinned mesh's bounds are its T-pose at the origin, so a
player across the court was culled. The body meshes use a box the size
of the whole court.

Display only: the sim is untouched. `test_view_never_writes_to_the_sim`
and the golden traces are unchanged. `test_avatar` checks that the
skeleton lands on the joints: the paddle hand at its grip, the feet on
their spots and on the floor, for both bodies.

## Consequences

- Each player is one skinned mesh of about 7–8k vertices. A doubles
  match has four, which is well within the Quest 3's budget. The assets
  add about 9 MB.
- The free pack has two bodies. The paid Source pack (8 bodies, more
  hair) would drop in the same way if more variety is wanted.
- The shells are made at load: about 50 ms per model the first time.
  They're rigid with the body (no cloth simulation), so a shirt can't
  swing or flutter.

## Amendment (2026-10-28): other rigs, and a Rocketbox partner on trial

The lead wanted better-looking players, free first. Microsoft Rocketbox
(115 rigged people for VR research, MIT) was tried: Male_Adult_01, in a
striped polo, cargo shorts and sneakers. It has 7,440 triangles and
1024 px textures, downscaled from 2048 for the Quest
(`assets/people/rocketbox/`, with its licence).

The Body now poses any rig, not only the base body's:
- **Bone names:** `Body.RIGS` maps our names to the rig's (the 3ds Max
  "Bip01" names here). The Avatar asks for bones by our names
  (`bone_name`, `head_mount` for things worn on the head).
- **Limbs** aim along their own axis to their child (`_along`), not
  along +Y.
- **Hands** are turned to the base body's: each rig's hand frame (where
  the middle, index and pinky knuckles sit) is matched to the base
  body's (`HAND_L`), so a rig in an A-pose holds the paddle the same way.
- **Fingers** curl about the knuckles' line, toward the palm (`_hinge`).
- **The base body is untouched:** all of the above apply only to other
  rigs.

Such a person wears their own clothes, hair and shoes, so no shirt shells,
team colours or cap.

PRACTICE PARTNER > PARTNER LOOK picks the partner, saved in the
settings:
- CLASSIC;
- NEW MAN (Male_Adult_01);
- NEW WOMAN (Female_Adult_12: a hoodie, shorts and sneakers, the most
  court-ready of the women). The CPU players stay classic until the lead decides.
`test_avatar.test_another_rig_follows_the_joints` checks, for each of them:
- the grip and the feet land where the Avatar wants them;
- the fingers close;
- the view with the new partner still never writes to the sim.
