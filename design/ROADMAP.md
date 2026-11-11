# VR roadmap

The milestone sheet for the VR game: the phases, the releases, every
task's status, what's next and what's waiting on you. What to try for
each task, as it landed, is in `design/HISTORY.md`.

Branches chain, each cut from the previous one's tip, with the
`feature/cld-` prefix. They go into `main` when you say "merge", and a
release when you say "release". When a branch's work is in, its row's
status flips in the same commit.

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
5. **Modes and practice.** Ball machine, PRACTICE PARTNER's kitchen
   drills, HOW TO PLAY, venues, timed runs and records; then tournament
   and career.
6. **Coaching.** The coach companion on a phone, the tablet in the
   headset, the coach's ball machine, PRANKS (`design/COACHING.md`).
7. **Sharing and online.** Friends on Meta's ALPHA channel
   (`design/TEST_CHANNEL.md`); remote coaching and online play through
   the relay shared with the port kit (its `design/RELAY.md`); the port
   kit's rollback (port ADR-102/103) on the 120 Hz sim.

## Releases

- **v0.9.0** (2026-11-05): BRICK BREAK, breakout on the court (five
  levels, three balls, a best score); Mac and Windows downloads beside
  the APK.
- **v0.8.0** (2026-10-30): PRANKS and HOLD TO TALK on a watching
  computer's coach panel; a quick click presses a menu row.
- **v0.7.0** (2026-10-29): COACH VIEW: WATCH A PLAYER in 3D, the coach's
  controls on their screen, instant replay.
- **v0.6.0** (2026-10-29): PLAY A FRIEND, dinking online with a friend
  through the relay (FRIENDLY DINK, rollback, the friend on court).
- **v0.5.0** (2026-10-29): COACH FROM ANYWHERE through the relay (the
  room is the key), PARTNER LOOK (Rocketbox), a real net, the court's
  surroundings, a seated crowd, a proper paddle.
- **v0.4.1** (2026-10-28): PRANKS voice messages from an iPhone (SEND IT).
- **v0.4.0** (2026-10-28): the pranks update. The coach page's PRANKS
  tab: a soundboard, silly balls and paddles, weather, the partner's
  antics, a voice in your headset, a selfie on the partner; MERCY.
- **v0.3.0** (2026-10-28): the coaching update. The coach companion and
  its tablet in the headset, the coach's ball machine, rigged bodies,
  dartboard targets, passthrough, timed runs, TUNING, paddle profiles.
- **v0.2.0** (2026-10-27): the practice update. DINK PARTNER, the ball
  machine's volley feeds, the new look, the paddle tuned on logged
  strokes, FOCUS.
- **v0.1.0** (2026-10-27): the first release. Singles and doubles against
  the ladder, DINK PARTNER, the BALL MACHINE, HOW TO PLAY, five venues.

## The year ahead (2026-11 to 2027-11)

Eight milestones, about six weeks each, from v0.10 to the store's v1.0. Each
task is a GitHub issue (story, acceptance criteria) in its milestone; the
issue number is in the index's Branch column until a branch is cut.
Labels: `area:*`, `headset` (needs you), `needs-adr`, `golden`, `canon`, `blocked`.

| Milestone | Due | Tasks | What |
|---|---|---|---|
| [M1 · v0.10 Close the loop](https://github.com/austinthedeveloper/pickleball-vr/milestone/1) | 2026-12-18 | VR-85..VR-96 | Pay down the playtest debt: BRICK BREAK tuned, the last kitchen drill, the open known issues, release builds on Meta's ALPHA channel. |
| [M2 · v0.11 Venues and lights](https://github.com/austinthedeveloper/pickleball-vr/milestone/2) | 2027-02-05 | VR-97..VR-106 | The canon's six venues, DAY / DUSK / NIGHT under lights, each venue's sounds and critters, court colours. |
| [M3 · v0.12 Career](https://github.com/austinthedeveloper/pickleball-vr/milestone/3) | 2027-03-19 | VR-107..VR-116 | Career save slots, your own look, the four paddles and thirteen hats, unlocks, the Hat Museum, lifetime records. |
| [M4 · v0.13 STORY: Save the park](https://github.com/austinthedeveloper/pickleball-vr/milestone/4) | 2027-05-07 | VR-117..VR-125 | The canon's story mode in VR: Pepper, the petition, eight chapters, Grimsby only ever in text. |
| [M5 · v0.14 OPEN PLAY, tournaments, modifiers](https://github.com/austinthedeveloper/pickleball-vr/milestone/5) | 2027-06-25 | VR-126..VR-134 | The park with three courts and a paddle rack, park points, the clubhouse, a tournament bracket, the eight modifiers. |
| [M6 · v0.15 Feel and rules](https://github.com/austinthedeveloper/pickleball-vr/milestone/6) | 2027-08-13 | VR-135..VR-143 | The physics and rules still simple: sidespin, net-cord rollovers, serve form, the smash, the momentum rule, side-out scoring. |
| [M7 · v0.16 Online 2](https://github.com/austinthedeveloper/pickleball-vr/milestone/7) | 2027-09-24 | VR-144..VR-152 | From friendly dinking to real online matches: singles, doubles, voice, invites, spectators, a hardened relay. |
| [M8 · v1.0 Store launch](https://github.com/austinthedeveloper/pickleball-vr/milestone/8) | 2027-11-05 | VR-153..VR-161 | Comfort, accessibility, onboarding, Quest 2 / 3S, Meta's VRC checks, the store page, BETA, then 1.0. |

## Index

| Task | What | Branch | Status |
|---|---|---|---|
| VR-01 | The 3D sim: ball, net, bounce, aim, rules (ADR-002) | `feature/cld-vr-singles` | Done |
| VR-02 | Paddle contact and the shot assist (ADR-003) | `feature/cld-vr-singles` | Ready to test |
| VR-03 | The CPU and the bot | `feature/cld-vr-singles` | Ready to test |
| VR-04 | The park, the match view, flat mode | `feature/cld-vr-singles` | Ready to test |
| VR-05 | The XR rig: paddle hand, serve hand, sticks, haptics | `feature/cld-vr-singles` | Ready to test (on the Quest 3) |
| VR-06 | Quest build: export preset, `quest_build.sh`, OpenXR Vendors 5.1.0 | `feature/cld-vr-quest-device` | Ready to test (builds and installs on the Quest 3) |
| VR-07 | Doubles (ADR-004) | `feature/cld-vr-doubles` | Ready to test |
| VR-08 | The ladder's eight teams as CPUs (ADR-005) | `feature/cld-vr-setup` | Ready to test |
| VR-09 | The lobby and MATCH SETUP in the world (ADR-005) | `feature/cld-vr-setup` | Ready to test |
| VR-10 | Spin and the sweet spot (ADR-006) | `feature/cld-vr-feel` | Ready to test |
| VR-11 | Hit sounds, haptics, PADDLE ANGLE (ADR-006) | `feature/cld-vr-feel` | Ready to test |
| VR-12 | The crowd and the announcer (ADR-006) | `feature/cld-vr-feel` | Ready to test |
| VR-13 | The ball machine (ADR-007) | `feature/cld-vr-practice` | Ready to test |
| VR-14 | HOW TO PLAY: seven lessons (ADR-007) | `feature/cld-vr-practice` | Ready to test |
| VR-15 | Menu pages and pause (ADR-007) | `feature/cld-vr-practice` | Ready to test |
| VR-16 | Venues: PARK, LAKESIDE, SUNSET, GYM, SPACE (ADR-008) | `feature/cld-vr-practice` | Ready to test |
| VR-17 | More venues: DINOSAUR, UNDERSEA, TIME of day | | Planned: split into VR-97..99 (M2) |
| VR-18 | Quest performance: CPU spikes fixed, PERF timing (ADR-009) | `feature/cld-vr-quest-device` | Done (measured on the Quest 3) |
| VR-19 | Ball machine 2: volley feeds, SPEED, MACHINE AT, real dinks (ADR-007) | `feature/cld-vr-machine-2` | Done (played) |
| VR-20 | DINK PARTNER: a cooperative dinking CPU (ADR-010) | `feature/cld-vr-dink-partner` | Done (played) |
| VR-21 | Floor targets, partner and machine (ADR-010) | `feature/cld-vr-dink-partner` | Done (played) |
| VR-22 | Releases: version.py, release.py, CHANGELOG (ADR-011) | `main` | Done |
| VR-23 | CI: tests on every push and pull request (ADR-011) | `feature/cld-vr-ci` | Done (green on GitHub) |
| VR-24 | Style: the person, the machine, the paddle, the ball (ADR-012) | `feature/cld-vr-style` | Done (played; 72 fps, 9.5 ms GPU) |
| VR-25 | Paddle tuned on logged swings: grip, restitution, swing curve (ADR-003) | `feature/cld-vr-partner-2` | Done (played: "so much better, feeling really good") |
| VR-26 | FOCUS: long rallies dim the world (ADR-013) | `feature/cld-vr-focus` | Ready to test |
| VR-27 | The dink zone: a foot past the kitchen line (ADR-010) | `feature/cld-vr-focus` | Ready to test |
| VR-28 | HANDS: the partner volleys hard at you (ADR-014) | `feature/cld-vr-hands` | Done (played: "feel good") |
| VR-29 | FOCUS deeper and sooner: 5 in a row, nearly black by 13 (ADR-013) | `feature/cld-vr-focus-2` | Done (played: "feel good") |
| VR-30 | Blocks keep a fast ball's pace (ADR-003) | `feature/cld-vr-blocks` | Ready to test |
| VR-31 | HANDS: a soft feed, then faster (ADR-014) | `feature/cld-vr-blocks` | Played: "the soft start is good" |
| VR-32 | The dink zone 2.5 ft past the kitchen line (ADR-010) | `feature/cld-vr-blocks` | Ready to test |
| VR-33 | A bigger, unhurried swing lands shorter (swing curve, ADR-003) | `feature/cld-vr-blocks` | Ready to test |
| VR-34 | HANDS: more power after the feed (ADR-014) | `feature/cld-vr-blocks` | Ready to test |
| VR-35 | PADDLE page: profiles for paddle accessories (ADR-015) | `feature/cld-vr-paddle-profiles` | Ready to test |
| VR-36 | Kitchen drills: proposals (design/KITCHEN_DRILLS.md) | `feature/cld-vr-paddle-profiles` | Done (the lead picked RESETS) |
| VR-37 | RESETS: block speed-ups into the kitchen (ADR-016) | `feature/cld-vr-resets` | Played: "the right idea" |
| VR-38 | Partner feeds have a lead-in: hold, drop, strike (ADR-016) | `feature/cld-vr-resets` | Ready to test |
| VR-39 | Menus: click < to step back, > to step on | `feature/cld-vr-resets` | Ready to test |
| VR-40 | CALL THE SPOT, LINE AND CROSS, VOLLEY DINKS, ATTACK OR DINK (ADR-017) | `feature/cld-vr-drills` | Ready to test |
| VR-41 | The swing log by mode, and swings_report.py (ADR-017) | `feature/cld-vr-drills` | Ready to test |
| VR-42 | Rigged bodies for the partner and CPU players (ADR-018) | `feature/cld-vr-body` | Done (replaced by VR-43) |
| VR-43 | Cloth shells: a real shirt and shorts (ADR-018) | `feature/cld-vr-body` | Played: "looks better" |
| VR-44 | Dartboard targets: rings and points (ADR-019) | `feature/cld-vr-dartboard` | Played: "look good" |
| VR-45 | Practice: leaning over the kitchen line isn't a fault (ADR-019) | `feature/cld-vr-dartboard` | Ready to test |
| VR-46 | TUNING pages (debug builds) and tune.sh sync (ADR-020) | `feature/cld-vr-tuning` | Ready to test |
| VR-47 | Paddle profiles: TURN, a full TWIST, ANGLE +-90 (ADR-015) | `feature/cld-vr-tuning` | Played: "good" |
| VR-48 | DINKS: the target follows you across (ADR-019) | `feature/cld-vr-tuning` | Ready to test |
| VR-49 | Passthrough: the court in your room (ADR-021) | `feature/cld-vr-timed` | Played: "worked perfect" |
| VR-50 | Timed runs (MODE) and RECORDS (ADR-022) | `feature/cld-vr-timed` | Ready to test |
| VR-51 | Stronger hit vibration (tunable); a ding on target hits | `feature/cld-vr-timed` | Played: raised again in VR-54 |
| VR-52 | Floor targets move after a miss too (ADR-019) | `feature/cld-vr-timed` | Ready to test |
| VR-53 | Coach companion: a web page from the headset (ADR-023) | `feature/cld-vr-coach` | Played: "worked so well" |
| VR-54 | Coach START NEW mid-run; stronger vibration; blocks keep 72% (ADR-003, 023) | `feature/cld-vr-coach` | Ready to test |
| VR-55 | The coaching suite: C-3..C-18 (ADR-024, design/COACHING.md) | `feature/cld-vr-coaching` | Ready to test |
| VR-56 | The coach's ball machine: place, bounce, speed, spin, height (C-21, ADR-024) | `feature/cld-vr-coach-machine` | Played: "placed exactly where I wanted" |
| VR-57 | The coach tablet beside PAUSED (C-22, ADR-024) | `feature/cld-vr-tablet` | Played: "a lot better" (the carry-over fixed in VR-62) |
| VR-58 | REACH -30..+20 cm, 1 cm steps (ADR-015) | `feature/cld-vr-reach` | Played: profiles set with it |
| VR-59 | Full swings hit full: the swing curve's top (ADR-003) | `feature/cld-vr-drives` | Played: "a lot better" |
| VR-60 | The tablet shows the drill's own controls (ADR-024) | `feature/cld-vr-drives` | Played (the carry-over fixed in VR-62) |
| VR-61 | Drift: tracking in the swing log, PADDLE > CHECK (ADR-015) | `feature/cld-vr-drives` | Ready to test |
| VR-62 | Tablet: a clean court per drill; taps show and say what they did (ADR-024) | `feature/cld-vr-tablet-2` | Ready to test |
| VR-63 | PRANKS: soundboard, silly balls and paddles, weather, antics, voice, selfie; MERCY (ADR-025, C-23) | `feature/cld-vr-pranks` | Played: "no notes" |
| VR-64 | PRANKS voice from an iPhone: a video's sound, caught by playing it (ADR-025) | `feature/cld-vr-iphone-voice` | Played: works, normal and monster |
| VR-65 | Friends on Meta's ALPHA channel: release key, release builds, upload (design/TEST_CHANNEL.md) | — | Planned: waiting on the lead's Meta account |
| VR-66 | COACH FROM ANYWHERE: a room on the shared relay, the page served there (ADR-026, C-20) | `feature/cld-vr-relay-live` | Ready to test: checked live from the Mac |
| VR-67 | Cleanup: the roadmap split (HISTORY.md), README, CLAUDE.md, known issues, merged branches | `feature/cld-vr-cleanup` | Done |
| VR-68 | A real net: square mesh, tape, strap, bindings, metal posts (ADR-012) | `feature/cld-vr-court-assets` | Ready to test |
| VR-69 | A textured paddle: carbon twill, the colour panel, "94", a wound grip (ADR-012) | `feature/cld-vr-court-assets` | Ready to test |
| VR-70 | Any rig in the Body; Rocketbox partners on trial: PARTNER LOOK NEW MAN, NEW WOMAN (ADR-018) | `feature/cld-vr-court-assets` | Ready to test: compare CLASSIC and the two NEW |
| VR-71 | The CPUs' paddle stays in the hand (known issue 9) | `feature/cld-vr-court-assets` | Done (test) |
| VR-72 | Court grain, grass, chain-link fence and windscreens, clumped trees in two draws (ADR-012) | `feature/cld-vr-court-assets` | Ready to test |
| VR-73 | The crowd as people: seated, dressed, arms up to cheer, two draws (ADR-012) | `feature/cld-vr-court-assets` | Ready to test |
| VR-74 | FRIENDLY DINK in the sim: two humans from the kitchen lines, rallies counted, no score (ADR-027) | `feature/cld-vr-friend-dink` | Done (tests); nothing to play yet |
| VR-75 | Online netcode: the port kit's net/ over the relay, the sim's state saved and restored for rollback (ADR-027) | `feature/cld-vr-friend-dink` | Done (tests; two Bots through the live relay); nothing to play yet |
| VR-76 | The friend on court: body, head and paddle from their inputs; their hits eased in (ADR-027) | `feature/cld-vr-friend-dink` | Done (tests, screenshots of both ends); nothing to play yet |
| VR-77 | PLAY A FRIEND: HOST shows the room, JOIN picks four letters (ADR-027) | `feature/cld-vr-friend-dink` | Played: Quest against the Mac, "it all worked" |
| VR-78 | Playtest: the Quest against the Mac's flat mode, then two houses (ADR-027) | — | Quest against the Mac played 2026-10-29: moving and the paddle worked; two houses next |
| VR-79 | COACH VIEW: WATCH A PLAYER replays the player's drill from their stream, four cameras (ADR-028) | `feature/cld-vr-coach-view` | Ready to test: watched through the live relay on the Mac |
| VR-80 | COACH VIEW: the coach's controls on their screen, as on the phone (ADR-028) | `feature/cld-vr-coach-view` | Ready to test: coached through the live relay on the Mac |
| VR-81 | COACH VIEW: instant replay, any angle, slow (ADR-028) | `feature/cld-vr-coach-view` | Ready to test: THE LAST SHOT on the Mac (screenshots) |
| VR-82 | COACH VIEW: PRANKS on the Mac's panel, HOLD TO TALK (or T) through its microphone (ADR-029) | `feature/cld-vr-mac-pranks` | Released in v0.8.0: a prank and an 8 s voice through the live relay |
| VR-83 | Releases: the Mac and Windows games beside the APK, built by release.py (design/RELEASING.md) | `feature/cld-vr-desktop-builds` | Ready to test: the Mac app boots; Windows unchecked on Windows |
| VR-84 | BRICK BREAK: breakout on the court, five levels, three balls (ADR-030) | `feature/cld-vr-brick-break` | Ready to test: the bot clears levels; a human in the headset next |
| VR-85 | BRICK BREAK tuned in the headset | [#2](https://github.com/austinthedeveloper/pickleball-vr/issues/2) | Planned (v0.10) |
| VR-86 | Coach and watch BRICK BREAK | [#3](https://github.com/austinthedeveloper/pickleball-vr/issues/3) | Planned (v0.10) |
| VR-87 | THIRD SHOT DROPS drill | [#4](https://github.com/austinthedeveloper/pickleball-vr/issues/4) | Planned (v0.10) |
| VR-88 | Online: a third player is refused | [#5](https://github.com/austinthedeveloper/pickleball-vr/issues/5) | Planned (v0.10) |
| VR-89 | Flat mode's FRIENDLY DINK help line says SHIFT DRIVE | [#6](https://github.com/austinthedeveloper/pickleball-vr/issues/6) | Planned (v0.10) |
| VR-90 | Release builds on Meta's ALPHA channel | [#7](https://github.com/austinthedeveloper/pickleball-vr/issues/7) | Planned (v0.10) |
| VR-91 | Playtest from two houses: PLAY A FRIEND and COACH VIEW | [#8](https://github.com/austinthedeveloper/pickleball-vr/issues/8) | Planned (v0.10) |
| VR-92 | A matches session in the headset | [#9](https://github.com/austinthedeveloper/pickleball-vr/issues/9) | Planned (v0.10) |
| VR-93 | Ready-to-test sweep | [#10](https://github.com/austinthedeveloper/pickleball-vr/issues/10) | Planned (v0.10) |
| VR-94 | Saved sessions keep their replays | [#11](https://github.com/austinthedeveloper/pickleball-vr/issues/11) | Planned (v0.10) |
| VR-95 | Coach sliders: SAVE AS DEFAULT | [#12](https://github.com/austinthedeveloper/pickleball-vr/issues/12) | Planned (v0.10) |
| VR-96 | The Windows game checked on Windows | [#13](https://github.com/austinthedeveloper/pickleball-vr/issues/13) | Planned (v0.10) |
| VR-97 | DINOSAUR venue | [#14](https://github.com/austinthedeveloper/pickleball-vr/issues/14) | Planned (v0.11) |
| VR-98 | UNDERSEA venue | [#15](https://github.com/austinthedeveloper/pickleball-vr/issues/15) | Planned (v0.11) |
| VR-99 | TIME OF DAY: DAY, DUSK, NIGHT | [#16](https://github.com/austinthedeveloper/pickleball-vr/issues/16) | Planned (v0.11) |
| VR-100 | Each venue's ambience | [#17](https://github.com/austinthedeveloper/pickleball-vr/issues/17) | Planned (v0.11) |
| VR-101 | Critters cross the sky | [#18](https://github.com/austinthedeveloper/pickleball-vr/issues/18) | Planned (v0.11) |
| VR-102 | COURT page: four court colours | [#19](https://github.com/austinthedeveloper/pickleball-vr/issues/19) | Planned (v0.11) |
| VR-103 | Passthrough: the court anchored to your room | [#20](https://github.com/austinthedeveloper/pickleball-vr/issues/20) | Planned (v0.11) |
| VR-104 | Venue performance budget | [#21](https://github.com/austinthedeveloper/pickleball-vr/issues/21) | Planned (v0.11) |
| VR-105 | Screenshots of every venue | [#22](https://github.com/austinthedeveloper/pickleball-vr/issues/22) | Planned (v0.11) |
| VR-106 | Close-up of a ball's bounce at night | [#23](https://github.com/austinthedeveloper/pickleball-vr/issues/23) | Planned (v0.11) |
| VR-107 | Career: three save slots and a name | [#24](https://github.com/austinthedeveloper/pickleball-vr/issues/24) | Planned (v0.12) |
| VR-108 | Your look, in a mirror | [#25](https://github.com/austinthedeveloper/pickleball-vr/issues/25) | Planned (v0.12) |
| VR-109 | The four paddles: Wood, Blue, Red, Gold | [#26](https://github.com/austinthedeveloper/pickleball-vr/issues/26) | Planned (v0.12) |
| VR-110 | Thirteen hats | [#27](https://github.com/austinthedeveloper/pickleball-vr/issues/27) | Planned (v0.12) |
| VR-111 | Unlocks and NEXT: | [#28](https://github.com/austinthedeveloper/pickleball-vr/issues/28) | Planned (v0.12) |
| VR-112 | The Hat Museum | [#29](https://github.com/austinthedeveloper/pickleball-vr/issues/29) | Planned (v0.12) |
| VR-113 | RECORDS board with initials | [#30](https://github.com/austinthedeveloper/pickleball-vr/issues/30) | Planned (v0.12) |
| VR-114 | The ladder kept per slot: CHAMPION! | [#31](https://github.com/austinthedeveloper/pickleball-vr/issues/31) | Planned (v0.12) |
| VR-115 | Save versions and migrations | [#32](https://github.com/austinthedeveloper/pickleball-vr/issues/32) | Planned (v0.12) |
| VR-116 | Career stats on the coach's phone | [#33](https://github.com/austinthedeveloper/pickleball-vr/issues/33) | Planned (v0.12) |
| VR-117 | STORY mode: chapters and progress | [#34](https://github.com/austinthedeveloper/pickleball-vr/issues/34) | Planned (v0.13) |
| VR-118 | Pepper, your partner | [#35](https://github.com/austinthedeveloper/pickleball-vr/issues/35) | Planned (v0.13) |
| VR-119 | Scenes before each match, and the petition | [#36](https://github.com/austinthedeveloper/pickleball-vr/issues/36) | Planned (v0.13) |
| VR-120 | Team intros, taunts and concessions | [#37](https://github.com/austinthedeveloper/pickleball-vr/issues/37) | Planned (v0.13) |
| VR-121 | The captain's partner in the stands | [#38](https://github.com/austinthedeveloper/pickleball-vr/issues/38) | Planned (v0.13) |
| VR-122 | Celebrations on court | [#39](https://github.com/austinthedeveloper/pickleball-vr/issues/39) | Planned (v0.13) |
| VR-123 | The ending | [#40](https://github.com/austinthedeveloper/pickleball-vr/issues/40) | Planned (v0.13) |
| VR-124 | Story balance | [#41](https://github.com/austinthedeveloper/pickleball-vr/issues/41) | Planned (v0.13) |
| VR-125 | Canon review of the VR story | [#42](https://github.com/austinthedeveloper/pickleball-vr/issues/42) | Planned (v0.13) |
| VR-126 | OPEN PLAY: a park with three courts | [#43](https://github.com/austinthedeveloper/pickleball-vr/issues/43) | Planned (v0.14) |
| VR-127 | The paddle rack and winners stay | [#44](https://github.com/austinthedeveloper/pickleball-vr/issues/44) | Planned (v0.14) |
| VR-128 | Park points | [#45](https://github.com/austinthedeveloper/pickleball-vr/issues/45) | Planned (v0.14) |
| VR-129 | Pick your partner at the rack | [#46](https://github.com/austinthedeveloper/pickleball-vr/issues/46) | Planned (v0.14) |
| VR-130 | The clubhouse | [#47](https://github.com/austinthedeveloper/pickleball-vr/issues/47) | Planned (v0.14) |
| VR-131 | TOURNAMENT: an eight-team bracket | [#48](https://github.com/austinthedeveloper/pickleball-vr/issues/48) | Planned (v0.14) |
| VR-132 | MODIFIERS: BIG, FAST, POPCORN, GHOST | [#49](https://github.com/austinthedeveloper/pickleball-vr/issues/49) | Planned (v0.14) |
| VR-133 | MODIFIERS: LAVA, ICE, GLOW, INVERSE | [#50](https://github.com/austinthedeveloper/pickleball-vr/issues/50) | Planned (v0.14) |
| VR-134 | KID difficulty | [#51](https://github.com/austinthedeveloper/pickleball-vr/issues/51) | Planned (v0.14) |
| VR-135 | Sidespin bends the shot | [#52](https://github.com/austinthedeveloper/pickleball-vr/issues/52) | Planned (v0.15) |
| VR-136 | Net cords that roll over | [#53](https://github.com/austinthedeveloper/pickleball-vr/issues/53) | Planned (v0.15) |
| VR-137 | The serve's form checked | [#54](https://github.com/austinthedeveloper/pickleball-vr/issues/54) | Planned (v0.15) |
| VR-138 | The overhead smash | [#55](https://github.com/austinthedeveloper/pickleball-vr/issues/55) | Planned (v0.15) |
| VR-139 | The momentum rule | [#56](https://github.com/austinthedeveloper/pickleball-vr/issues/56) | Planned (v0.15) |
| VR-140 | Side-out scoring | [#57](https://github.com/austinthedeveloper/pickleball-vr/issues/57) | Planned (v0.15) |
| VR-141 | Close-call replay | [#58](https://github.com/austinthedeveloper/pickleball-vr/issues/58) | Planned (v0.15) |
| VR-142 | Two-handed backhand | [#59](https://github.com/austinthedeveloper/pickleball-vr/issues/59) | Planned (v0.15) |
| VR-143 | Paddle tuning pass on a season of swings | [#60](https://github.com/austinthedeveloper/pickleball-vr/issues/60) | Planned (v0.15) |
| VR-144 | Online singles: a full match | [#61](https://github.com/austinthedeveloper/pickleball-vr/issues/61) | Planned (v0.16) |
| VR-145 | Online doubles | [#62](https://github.com/austinthedeveloper/pickleball-vr/issues/62) | Planned (v0.16) |
| VR-146 | Voice between friends | [#63](https://github.com/austinthedeveloper/pickleball-vr/issues/63) | Planned (v0.16) |
| VR-147 | Invites and presence on the Quest | [#64](https://github.com/austinthedeveloper/pickleball-vr/issues/64) | Planned (v0.16) |
| VR-148 | Rematch, name tags, quick emotes | [#65](https://github.com/austinthedeveloper/pickleball-vr/issues/65) | Planned (v0.16) |
| VR-149 | Network quality shown | [#66](https://github.com/austinthedeveloper/pickleball-vr/issues/66) | Planned (v0.16) |
| VR-150 | Spectate an online match | [#67](https://github.com/austinthedeveloper/pickleball-vr/issues/67) | Planned (v0.16) |
| VR-151 | Relay hardening | [#68](https://github.com/austinthedeveloper/pickleball-vr/issues/68) | Planned (v0.16) |
| VR-152 | Cross-play polish: Quest and desktop | [#69](https://github.com/austinthedeveloper/pickleball-vr/issues/69) | Planned (v0.16) |
| VR-153 | Comfort options | [#70](https://github.com/austinthedeveloper/pickleball-vr/issues/70) | Planned (v1.0) |
| VR-154 | Accessibility | [#71](https://github.com/austinthedeveloper/pickleball-vr/issues/71) | Planned (v1.0) |
| VR-155 | First run | [#72](https://github.com/austinthedeveloper/pickleball-vr/issues/72) | Planned (v1.0) |
| VR-156 | Quest 2 and 3S | [#73](https://github.com/austinthedeveloper/pickleball-vr/issues/73) | Planned (v1.0) |
| VR-157 | Meta's VRC checks | [#74](https://github.com/austinthedeveloper/pickleball-vr/issues/74) | Planned (v1.0) |
| VR-158 | Store page and trailer | [#75](https://github.com/austinthedeveloper/pickleball-vr/issues/75) | Planned (v1.0) |
| VR-159 | Crash and error reports | [#76](https://github.com/austinthedeveloper/pickleball-vr/issues/76) | Planned (v1.0) |
| VR-160 | BETA with a wider circle | [#77](https://github.com/austinthedeveloper/pickleball-vr/issues/77) | Planned (v1.0) |
| VR-161 | v1.0 | [#78](https://github.com/austinthedeveloper/pickleball-vr/issues/78) | Planned (v1.0) |

## Next

- **BRICK BREAK (VR-84):** your session in the headset. Tune the wall's
  return (pace, depth) and the assist on what you find.
- **VR-65:** friends on Meta's ALPHA channel. It waits on your Meta
  developer account (`design/TEST_CHANNEL.md`).
- **THIRD SHOT DROPS (VR-87):** the one kitchen drill not built yet
  (`design/KITCHEN_DRILLS.md`).
- **The rest of M1 (v0.10):** the open known issues (VR-86, 88, 89), saved
  replays (VR-94), SAVE AS DEFAULT (VR-95), Windows checked (VR-96).
- **VR-17:** more venues (DINOSAUR, UNDERSEA, TIME of day), now VR-97..99
  in M2.
- **Dinking online with a friend (ADR-027):** a playtest from two houses, with a friend in a headset or on a Mac.
- **COACH VIEW (ADR-028):** your playtest: the Quest player, the Mac coach (design/HISTORY.md).

## For you

- **Meta:** a developer account, the app, an upload token and the
  release key's password, for VR-65 (`design/TEST_CHANNEL.md`, "What you
  do").
- **COACH FROM ANYWHERE (VR-66):** try it with someone off your Wi-Fi.
  A short domain for the relay is your call (ADR-026).
- **A listen:** the PRANKS sounds and the announcer, in the headset.
  Say which sound is off.
- **Still open from earlier:**
  - FOCUS (VR-26), the dink zone (VR-27, VR-32), the bigger-swing
    softening (VR-33), HANDS' pace (VR-34);
  - the lead-in (VR-38), timed runs (VR-50) and the coaching suite
    (VR-55).

  They're marked Ready to test. Say a word on any you've formed a view
  of, and I'll mark it.
