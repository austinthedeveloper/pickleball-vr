# Changelog

What's new in each release of Pickleball '94 VR, for players. The format
follows [Keep a Changelog](https://keepachangelog.com); versions follow
[semver](https://semver.org) (design/RELEASING.md).

## [Unreleased]

### Added
- **Every partner feed has a lead-in:** the partner holds the next ball
  up, drops it and hits it as it falls, so you see where it's coming
  from and when.
- **Menu arrows both work:** clicking the < on a setting steps it back,
  the > steps it on.
- **RESETS:** a new PRACTICE PARTNER drill. You stand mid-court and the
  partner drives at you, hard and low. Block it soft into their kitchen,
  under the red pop-up line over the net. DIFFICULTY sets the pace and
  how low the line is.
- **PADDLE** (on MAIN), with profiles for paddle accessories. DEFAULT is
  the paddle you had. PROFILE 1-3 set the ANGLE (-30 to 90), TWIST and
  REACH (how far out the face sits) to fit an accessory, and the paddle
  in your hand moves as you change them.
- **Blocks keep their pace:** stick your paddle out against a hard-hit
  ball and it goes back with real speed, not a dead drop into the net.
- **HANDS:** a new PRACTICE PARTNER drill (DRILL: HANDS). You and the
  partner stand at your kitchen lines and volley hard at each other; it
  takes every ball out of the air and sends it back at you. DIFFICULTY
  is the pace.

### Changed
- DINK PARTNER is now PRACTICE PARTNER, with DINKS and HANDS drills.
- PADDLE ANGLE moved from MATCH SETUP to the PADDLE page, so it's
  reachable from practice too.
- **HANDS starts each rally with a soft feed** straight at you, then
  speeds up quickly to the DIFFICULTY's pace, which is a little harder
  than before.
- **A bigger, unhurried swing** no longer sends a dink long: the middle
  of the swing range is a little softer. Gentle touch and full drives
  are unchanged.
- **The dink zone** now runs 2.5 ft past the kitchen line.
- **FOCUS is much stronger:** it starts at 5 in a row and the world is
  nearly black around the court by 13.

## [0.2.0] - 2026-10-27

The practice update: a dinking partner, a paddle tuned on real strokes,
and a world that falls away in a long rally.

### Added
- **DINK PARTNER:** a CPU at their kitchen line who only wants the rally
  to go on. Every ball comes back as a dink to your forehand or backhand.
  - **DIFFICULTY** sets how low it skims the net.
  - **PARTNER** puts it straight across or cross court.
  - **SPREAD** sets how far it makes you reach.
  - **Floor targets** to aim at.
  - The board counts dinks in a row. A dink landing up to a foot past
    their kitchen line counts.
- **FOCUS:** string together a long rally and everything outside the court
  darkens, step by step, a spotlight on the rally. In practice it begins
  at your 8th good shot in a row.
- **The ball machine:**
  - At your kitchen line, drives come at you through the air for reflex
    practice.
  - New **SPEED** (up to about 17 m/s), **MACHINE AT** (the baseline or
    their kitchen line) and **RAPID** rate settings.
  - Real dinks from their kitchen.
  - Floor targets.
- **A new look:** the partner and the CPU players are people now. They
  split-step, shuffle, watch the ball and swing in time with the hit. The
  ball machine has a hopper that empties, a head that aims along each
  feed and a countdown light. The paddle and the ball (with holes) are
  remade, and fast balls leave a short trail.

### Changed
- **The paddle feels like a paddle.** It was tuned on 160+ logged strokes
  from a real player:
  - lifting through the ball lifts it;
  - touch shots are livelier;
  - an average swing gives a firm, controlled ball instead of flying long;
  - the sweet spot is gentler.
- **SHOT ASSIST** helps with length more than aim, so you keep your
  direction.
- **The partner** reads your shot and moves before it bounces, and its
  footwork carries its body.

### Fixed
- Dinks from the machine were called OUT before your return came down.
- Drives at the kitchen line came as slow lobs.
- In the headset, the lobby's demo took your controllers, reset you to a
  corner each point and hid the menu.
- Changing an option no longer shifts your view. Holding the Meta button
  recenters you facing the court.
- The ball in your free hand sits in your fingers and leaves from there.

## [0.1.0] - 2026-10-27

The first release: first-person pickleball on the Meta Quest, with a
practice mode built for the kitchen line.

### Added
- **Singles and doubles** against the remaster's eight ladder teams, from
  HENDERSON to the CHAMPS, each with its own style. Rally scoring to 5
  (up to 15, win by 2 optional), the two-bounce rule, and no volleys from
  the kitchen.
- **Your paddle is the paddle:** swing it, angle it, brush the ball for
  topspin or slice. A shot assist (OFF, LOW, MID, FULL) helps with
  length; you keep the aim. PADDLE HAND and PADDLE ANGLE fit it to you.
- **DINK PARTNER:** a CPU at their kitchen line who only wants the rally
  to go on. Every ball comes back as a dink near you. EASY, MEDIUM or HARD
  (how low it skims the net), across or cross court, with floor targets
  to aim at. The board counts dinks in a row.
- **BALL MACHINE:** drives, dinks, lobs or a mix, at four speeds, from the
  baseline or their kitchen line. At your kitchen line, drives come at
  you through the air for reflex practice. There are return zones,
  targets and a best streak.
- **HOW TO PLAY:** seven short lessons, from your first hits to topspin.
- **Five venues:** PARK, LAKESIDE, SUNSET, GYM and SPACE, each with the
  remaster's court colours and sounds. HOME plays at your opponent's
  court.
- **The remaster's sounds:** shot-by-shot hits, the announcer calling the
  score and the faults, and a crowd that stands for long rallies.
- **Flat mode** for playing on a Mac or PC without a headset.

### Known issues
- Builds are signed with a development key: install by sideloading
  (developer mode).
- The art is placeholder: simple shapes, no textures yet.
