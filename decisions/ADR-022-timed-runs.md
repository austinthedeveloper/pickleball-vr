# ADR-022: Timed runs and records

**Status:** Accepted (2026-10-28)

## Context

"I'd also like some sort of time attack/board so scores actually matter
and I can see improvement. We still need the original where it's
unlimited hitting. Maybe it's another option under the mode."

## Decision

**MODE.** PRACTICE PARTNER and BALL MACHINE get a MODE row: FREE PLAY
(the original, which runs forever), 1 MIN, 2 MIN or 3 MIN. It is saved
per page. The lobby's demo always plays free.

**The clock is the sim's.** `Drill.time_limit` is in ticks, and
`ends_at` is the first feed plus the limit. On that tick:
- the drill goes DONE, and nothing after it counts;
- a ball already in the air plays out;
- the drill emits `EVENT_TIME_UP` with the score, good balls and the
  best streak.

The clock is deterministic like the rest of the sim.

**The score** is one point per good ball plus any dartboard points
(ADR-019). Precision pays on the target drills, and every drill scores
the same way.

**The scoreboard** shows the score and the time left. The score turns
red for the last 10 seconds. Time up brings applause, "TIME! SCORE n",
and a screen with:
- NEW BEST!, or the best score and where this run placed;
- good balls and the longest streak;
- the last few runs;
- AGAIN or MENU.

**Records.** Every timed run is kept in Settings, the last 100 per run
name. A run name is the drill, its level, TARGETS if on, and the time,
for example "CALL THE SPOT HARD 1 MIN". The saved key `records` has a
harmless default, so it needs no new save version. The RECORDS row on
each practice page lists, for the drill set there, each time's three
best scores and its last five, oldest first, so improvement shows. The
swing log's mode name carries the time too.

## Consequences

- A run name ignores the settings that matter less (SPREAD, the
  machine's RATE and target). If those turn out to matter, the name can
  grow and old runs would sit under the old names.
- Matches are unchanged.
