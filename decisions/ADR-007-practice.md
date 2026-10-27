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

## Amended 2026-10-27: after the first practice in the headset

The lead's verdict: practice is where they'll spend most of their time.
They want fast balls at the kitchen line for reflexes. Two things were
broken:

- **Drives at the kitchen line came as lobs.** Every feed aimed to bounce
  2.2 m in front of you. From the kitchen line that spot is just over the
  net, which a machine on the far baseline can only reach with a 4.6 m
  lob (3.7 m/s when it got to you).
- **Dinks were all called OUT.** A "dink" from the far baseline was a
  5.7 m lob taking 3.1 s, and the machine gave up 3.5 s after the feed, so
  any return still in the air was called OUT.

Changes:

- **Volley feeds:** within 1.6 m behind the kitchen line (or under a
  VOLLEY rule), a drive aimed at you, your forehand or your backhand comes
  through the air to about 1.0 m high where you stand
  (`Aim.through`, lifted 10 cm at a time until it clears the tape).
- **SPEED:** SLOW, MEDIUM, FAST or BLAZING, drives at 8 to 17 m/s, with
  dinks and lobs scaled to it.
- **MACHINE AT:** AUTO, BASELINE or KITCHEN. AUTO feeds dinks from the far
  kitchen line and everything else from the baseline. KITCHEN with
  BLAZING gives you 0.30 s to react, the hands battle.
- **Dinks land in your kitchen,** about a metre in front of you, with an
  apex of 1.2 to 1.5 m.
- **RATE** gains RAPID (a feed about every 1.1 s).
- **The give-up timer** runs from your hit (4 s), not the feed. A feed
  nobody hits gives up after 5 s.
- **The assist's rescue for a soft shot into the net** is a drop into
  their kitchen, not a ball to mid-court, so a dink stays a dink. This
  changes matches too, rarely; the golden traces were regenerated (only
  the doubles trace moved).

## Consequences

- Match play and its golden traces are unchanged: drills don't touch the
  match path.
- In a drill, the bot stays within 1.5 m of its spot.
