# ADR-030: BRICK BREAK, breakout on the court

**Status:** Accepted (2026-11-01). Built: VR-84.

## Context

The lead asked for a breakout game: "boxes on the opposite side, ball
bouncing between us". The game has a paddle, a ball and a far court, so
the far court can be the wall. Breakout depends on the ball always
coming back, and on your angle deciding where it goes next. A real wall
does neither in a headset. A pickleball off a wall 4.5 m past the net
often dies short or comes back into the net, because drag and the
bounce take most of its pace.

## Decision

**BRICK BREAK is a mode of its own on MAIN.** Its page sets START AT LEVEL,
DIFFICULTY and SHOT ASSIST, and shows the BEST score. Like a drill, it
lives in the sim's state (`sim/breakout.gd`, `Breakout`) and runs from
`Sim.step`. A match's rules, serve and score don't run. It is pure and
exact (ADR-002): ints, the sim's seeded generator, and `step()`.

**The wall.**
- The wall stands at `Breakout.WALL_Z`, 2.4 m past their kitchen line
  (4.5 m from the net).
- It holds a 7 x 6 grid of bricks across the court's width, from 30 cm to
  2.1 m up.
- Glass stands either side of their half, from the net to the wall.
- A brick takes 1, 2 or 3 hits, or it is steel: it never breaks and is
  never needed to clear.
- The levels are strings in `Breakout.LEVELS`, five of them. After the
  fifth they come round again.

**Every ball that reaches the wall comes back to you.** It comes back off
a brick or off the wall behind the bricks, and it isn't a physical
bounce. The wall sends a fresh shot (`Aim.shot`) over the net to your
side:

- **across:** the ball's line over the ground carries on mirrored, as
  off a breakout paddle, and folds between the sidelines. The angle you
  hit at is the angle you get.
- **deep:** a ball that met the wall low lands short (3.3 m from the
  net), and one that met it high lands deep (5.5 m).
- **pace:** set by DIFFICULTY (6, 7.4, 9 m/s over the ground), plus a
  little each level up to the fifth.

The glass is physical: a ball off it keeps 0.9 of its speed across and
carries on to the wall. Bank shots work.

**A ball is lost** when:
- it bounces twice on your side or gets past you (MISSED);
- your ball goes into the net (NET);
- your ball dies on their side short of the wall (SHORT);
- your ball goes wide of the glass (OUT).

You have three balls. A new ball shows in the launcher's ring in the
middle of the wall, then comes to you as an easy feed. There's no
serve to make, and no kitchen or two-bounce rule. Volleys are fine.

**Scoring.** Each hit on a brick is 10. A broken brick adds 50, plus 10
for each row up. A cleared level adds 250 times its number.

**The assist pulls a shot to the wall.** The match's assist (ADR-003)
pulls a shot toward landing in their court; this one pulls it toward
meeting the wall in the bricks' band.
- **The line:** the line along the shot's direction over the ground is
  kept, out to three court widths. A shot aimed at the glass stays a
  bank shot.
- **The height:** it is pulled to where the raw shot would meet the
  wall, clamped into the band. A shot into the net is pulled to the
  middle of the band.
- **The pull:** the line is pulled `assist` and the pace and arc twice
  that, as in a match.

**The bot plays it.** It aims through the lowest brick left nearest the
ball's line (`Breakout.bot_target`), flat, with its usual scatter. In
flat mode the crosshair picks the spot on the wall: across is across,
and further away is higher. The sim's fields that the bot and
`Intercept` read keep their meaning:
- `phase`, LIVE while a ball is in play;
- `last_hitter`, the wall as slot 2;
- `bounce_count`, the bounces on your side;
- `shots`, which goes up each way.

So DEMO, flat mode and the tests play it unchanged.

## Consequences

- New events: EVENT_LAUNCH, EVENT_BRICK, EVENT_WALL, EVENT_LOST,
  EVENT_LEVEL and EVENT_GAME_OVER (`K`).
- `Sim.save_state` gains a fifth entry, the wall's state. A match's
  snapshot, and so the golden traces, are unchanged.
- The view's `BrickWall` draws the bricks in one MultiMesh draw (ADR-009)
  and a CPUParticles3D burst per break. The glass glows where a ball
  comes off it. The score, level and balls show over the wall and on the
  courtside board. There's no crowd and no CPU.
- The bot never drops a ball in practice: it clears four levels in five
  minutes. It is a demo, not a measure of how hard the game is for a
  person.
- COACH VIEW, the coach's phone and PLAY A FRIEND don't know BRICK BREAK.
  A coach's controls do nothing in it, and a watcher can't follow it
  (`Watch.config_save` doesn't carry it). This is in
  `design/KNOWN_ISSUES.md`.
- The return's depth and pace and the glass's give are first guesses.
  They want a session in the headset.
