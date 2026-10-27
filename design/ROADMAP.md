# VR roadmap

The milestone sheet for the VR game. Branches chain, each cut from the
previous one's tip, with the `feature/cld-` prefix. Nothing goes to `main`
except the bootstrap commit: you review and merge. When a branch's work
is in, its row's status flips in the same commit.

**Status:** **Done** means automated checks cover it fully or you've played
and approved it. **Ready to test** means it works and is verified, but it
needs a human in the headset (the row says what to try). **Planned / In
progress / Blocked** mean what they say.

**Every branch, before it's marked:** `game/tools/test.sh` passes; the
golden traces are unchanged unless the branch means to change play (the
commit says why, and an ADR covers it); there are screenshots of anything
visual; `design/KNOWN_ISSUES.md` and the ADRs are up to date.

## Phases

1. **Singles.** One human against one CPU, first person, flat mode and Quest.
2. **Doubles.** A CPU partner, four on court, doubles serving.
3. **Feel.** Spin, paddle tuning, the port kit's CPU personalities and
   ladder, sound and crowd.
4. **In-headset menus.** MATCH SETUP, options and the save, all inside VR.
5. **Modes.** Ball machine and HOW TO PLAY, tournament, venues, career,
   records.
6. **Online.** The port kit's rollback (port ADR-102/103) on the 120 Hz sim.

## Index

| Task | What | Branch | Status |
|---|---|---|---|
| VR-01 | The 3D sim: ball, net, bounce, aim, rules (ADR-002) | `feature/cld-vr-singles` | Done |
| VR-02 | Paddle contact and the shot assist (ADR-003) | `feature/cld-vr-singles` | Ready to test |
| VR-03 | The CPU and the bot | `feature/cld-vr-singles` | Ready to test |
| VR-04 | The park, the match view, flat mode | `feature/cld-vr-singles` | Ready to test |
| VR-05 | The XR rig: paddle hand, serve hand, sticks, haptics | `feature/cld-vr-singles` | Blocked (needs the Quest set up) |
| VR-06 | Quest build: export preset, OpenXR vendors plugin | | Blocked (needs the Quest set up) |
| VR-07 | Doubles | | Planned |

## Phase 1: singles

**VR-02, ready to test (flat mode now; the headset after VR-06).** In
flat mode: `godot --path game`, Space to serve, move with WASD, aim with
the mouse, Shift for a soft shot. Do the shots go where the ring is? Is
rally pace right?

**VR-03, ready to test.** `godot --path game -- demo`: does the CPU move
and choose shots like a rec player? Rally stats:
`godot --headless --path game -s res://tools/rally_stats.gd -- 6 1`
(about 10 to 15 shots a rally, points split).

**VR-05 / VR-06, blocked on you.** See `design/QUEST_SETUP.md`. Once the
JDK and SDK are in and the Quest is in developer mode, the remaining work
is the export preset, the vendors plugin and the first on-device check:
pose names, the paddle's angle in the hand, frame rate.

## For you

1. **Quest setup** (QUEST_SETUP.md, steps 1 to 3): it unblocks VR-05/06.
2. **A GitHub repository** for this project, if you want one (it's local
   only for now). Pick its name and visibility, and I'll add the remote
   and CI.
3. **The paddle's angle in the hand.** The grip pose holds the paddle
   along the controller. VR games often tilt it 30 to 45 degrees. Decide
   on the device.
