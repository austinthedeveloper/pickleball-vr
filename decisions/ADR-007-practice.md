# ADR-007: The ball machine and HOW TO PLAY

**Status:** Accepted (2026-10-27)

## Context

Phase 5 begins with practice. The port kit had a BALL MACHINE (port
ADR-028: SHOT, TARGET, RATE, RETURN TO and a streak) and HOW TO PLAY
(PORT-30: short lessons, each with one goal). A first-time VR player needs
both more than a 2D player did: swinging a real paddle at a moving ball
takes reps before a match is any fun.

## Decision

- **`Drill`** lives in the sim's state and runs from `Sim.step`
  (`MatchConfig.drill`). It's pure and seeded like everything else. A
  machine on the far baseline feeds DRIVE, DINK, LOB or MIX, aimed AT YOU,
  to your FOREHAND or BACKHAND, the KITCHEN, DEEP or at RANDOM, at a SLOW,
  NORMAL or FAST rate. A return counts when it lands in court, in the
  RETURN TO zone (ANY, KITCHEN, DEEP, LEFT, RIGHT). Good returns build a
  streak. Your best is saved.
- **No match rules in a drill.** There's no score, no serve and no CPU.
  Your shot assist still applies. Each result is called (GOOD!, NET,
  OUT, MISSED THE ZONE, ...).
- **Lessons are data** (`data/lessons.json`): each is a drill with rules
  (`NO_VOLLEY`, `VOLLEY`, `KITCHEN`, `TOPSPIN`), a goal (good returns),
  a spot to stand on, and three lines of instruction standing over the
  far court. There are seven, from the port kit's Pickleball 101: FIRST
  HITS, THE SERVE (no machine: you serve into the box), LET IT BOUNCE,
  THE DINK, THE KITCHEN, GO DEEP and TOPSPIN. A finished lesson is saved
  and marked DONE, and the end menu offers the next one.
- **`NO_VOLLEY` reuses the two-bounce rule's machinery**
  (`required_bounce`). The planner and the bot already let a ball bounce
  when a rule says so, so the bot passes that lesson unchanged. A test
  checks the bot passes every lesson, so a lesson that can't be passed
  fails the build.
- **Menus:** the lobby now has pages: MAIN (PLAY A MATCH, BALL MACHINE,
  HOW TO PLAY), MATCH SETUP, BALL MACHINE and HOW TO PLAY. The lobby's
  demo matches the page. A new page ignores pointing for 0.3 s, so the
  click that opened it doesn't press a row (port kit playbook rule 9).
- **Pause:** the menu button (Esc in flat mode) pauses a match, drill or
  lesson, offering RESUME, RESTART or MENU. The sim isn't stepped while
  paused.

## Consequences

- Match play and its golden traces are unchanged: drills don't touch the
  match path.
- In a drill, the bot stays within 1.5 m of its spot.
