# CLAUDE.md

Pickleball '94 VR: first-person pickleball for Meta Quest (Godot 4.7,
OpenXR), built from what the port kit (`../pickleball-port-kit`) learned.
Branch per change with the `feature/cld-` prefix. Never commit to `main`
(the human reviews and merges).

## Commands

```sh
game/tools/test.sh                                   # all tests, headless (must pass)
godot --path game                                    # play (flat mode without a headset)
godot --path game -- demo                            # DEMO: bot vs CPU
godot --headless --path game -s res://tests/golden.gd   # regenerate golden traces (play changes only)
godot --path game --resolution 1280x720 -s res://tools/screenshot.gd -- <demo|play> <frames> <out.png>
godot --headless --path game -s res://tools/rally_stats.gd -- <matches> <difficulty>
```

`design/ROADMAP.md` is the milestone sheet: keep it current with each
branch. `design/KNOWN_ISSUES.md` lists the defects, and
`decisions/README.md` the ADRs (next: ADR-004). `design/QUEST_SETUP.md`
covers the headset build.

**The canon bible** is `../pickleball/docs/PICKLEBALL_94_BIBLE.md`. The VR
game is one of its artifacts and may not contradict it. Port kit
decisions are cited as "port ADR-n", the SNES repo's as "SNES ADR-n".

## Rules of the code (game/)

- **The sim is pure and exact** (ADR-002). `game/sim/` uses ints only
  (micrometres, 120 Hz ticks, Q14 unit vectors), no Nodes, no clock, and
  no randomness except the seeded generator in its state. Square roots go
  through `Fx.isqrt`. GDScript `/` truncates and `>>` floors.
- **A human's input is a `SimTypes.HumanInput`** (ADR-003): head on the
  ground, paddle face centre and normal, free hand, toss. Nothing else
  crosses into the sim. The XR rig interpolates poses to ticks; flat mode
  and DEMO get theirs from `Bot`.
- **Presentation never writes to the sim**
  (`test_view_never_writes_to_the_sim`). A change to a running match is a
  command: `MatchView.command` → `Sim.step(human, commands)`.
- **Tests play through `step()`** with the bot, as the game does.
- **Every OpenXR name lives in `view/xr_rig.gd`.**
- **Typed GDScript.** `:=` can't infer from Array elements: annotate
  (`var x: int = arr[i]`). `pass` and `call` are reserved.
- **Behaviour changes need an ADR**, and golden traces change only on
  purpose, with the reason in the commit.

## Before calling it done

1. `game/tools/test.sh` passes.
2. Look at a screenshot of anything visual (`tools/screenshot.gd`).
3. Update `design/KNOWN_ISSUES.md`, the ADRs and the roadmap.
