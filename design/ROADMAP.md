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
| VR-17 | More venues: DINOSAUR, UNDERSEA, TIME of day | | Planned |
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

## Next

- **VR-65:** friends on Meta's ALPHA channel. It waits on your Meta
  developer account (`design/TEST_CHANNEL.md`).
- **THIRD SHOT DROPS:** the one kitchen drill not built yet
  (`design/KITCHEN_DRILLS.md`).
- **VR-17:** more venues (DINOSAUR, UNDERSEA, TIME of day).
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
