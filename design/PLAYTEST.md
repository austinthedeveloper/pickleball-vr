# Playtest card

Everything the roadmap marks **Ready to test** (or waiting on a human),
in the order you'd meet it in the headset, a sitting at a time. Each
line is what to try and the question it answers. Tick what you tried
and say a word on it ("good", "too fast", "didn't notice"): each word
becomes a Done row, a TUNING change or an issue. The details for each
are in `design/HISTORY.md` under its VR number.

Build first: `game/tools/quest_build.sh` (a debug build, so TUNING is
there). Keep this card current: a row leaves it when it's marked Done.

## 1. Matches (about 20 minutes)

- [ ] **VR-09** Lobby and MATCH SETUP: do the menus in the world read well, and does pointing feel right?
- [ ] **VR-39** Menus: does clicking `<` and `>` step back and on as you expect?
- [ ] **VR-05** The rig: paddle hand, serve hand, stick movement, snap turn, hit buzz. Anything off?
- [ ] **VR-02** Paddle contact and SHOT ASSIST: do hits go where you meant at each ASSIST level?
- [ ] **VR-10** Spin and the sweet spot: does a brushed shot spin, and does a rim hit feel worse?
- [ ] **VR-11** Hit sounds, haptics, PADDLE ANGLE: does the paddle sit right in your hand?
- [ ] **VR-03, VR-08** The CPU and the ladder: is each team a bit harder than the last, and does each play like itself?
- [ ] **VR-07** Doubles: does your partner cover their half, and does doubles serving work?
- [ ] **VR-12** The crowd and the announcer: volumes and timing (known issue 7).
- [ ] **VR-15** Pause and the menu pages mid-match.
- [ ] **VR-16** Venues: PARK, LAKESIDE, SUNSET, GYM, SPACE. Any that's uncomfortable or slow?
- [ ] **VR-97, VR-98** DINOSAUR and UNDERSEA: does the kelp's sway feel fine? Does the court read against the sand?
- [ ] **VR-68, 69, 72, 73** The net, the paddle, the court and fence, the crowd: do they look right up close?
- [ ] **VR-70** PARTNER LOOK: CLASSIC against NEW MAN and NEW WOMAN. Which stays?

## 2. PRACTICE PARTNER (about 25 minutes)

- [ ] **VR-27, VR-32** DINKS: is the dink zone (2.5 ft past their kitchen line) the right size?
- [ ] **VR-38** The lead-in: can you read the held ball, the drop and the strike?
- [ ] **VR-26** FOCUS: does the world darken as a rally goes on?
- [ ] **VR-162** ZEN: past 15 in a row, HUSH (the melody, the drone); past 20, DRIFT (the void). Does it soothe or grate? Any hitch or discomfort?
- [ ] **VR-48, VR-52** Floor targets: does the target follow you across, and move after a miss?
- [ ] **VR-45** Leaning over the kitchen line: never a fault in practice?
- [ ] **VR-30, VR-33** Blocks keep a fast ball's pace; a big unhurried swing lands shorter. Right?
- [ ] **VR-34** HANDS: the power after the soft feed.
- [ ] **VR-37** RESETS: played once ("the right idea"). Is the pace right now?
- [ ] **VR-40** CALL THE SPOT, LINE AND CROSS, VOLLEY DINKS, ATTACK OR DINK: a few minutes each. Which needs tuning?
- [ ] **VR-87** THIRD SHOT DROPS: is the walk in and back too much for your room? Is the return's depth right?

## 3. The ball machine and lessons (about 10 minutes)

- [ ] **VR-13** BALL MACHINE: each shot and target. Anything odd?
- [ ] **VR-14** HOW TO PLAY: do all seven lessons make sense from inside them?
- [ ] **VR-50** A timed run (MODE 1 MIN) and RECORDS afterwards.

## 4. BRICK BREAK (about 10 minutes)

- [ ] **VR-84** All five levels: the wall's return (pace, depth), the glass, the assist toward the wall (known issue 14; also VR-85).

## 5. The paddle and tuning (about 10 minutes, debug build)

- [ ] **VR-35** PADDLE page: set a profile for your paddle accessory.
- [ ] **VR-61** PADDLE > CHECK: does it catch the tracking drifting?
- [ ] **VR-46** TUNING: change a value, then `game/tools/tune.sh sync` on the Mac.
- [ ] **VR-41** After any session: `game/tools/swings.sh > s.log` and `python3 game/tools/swings_report.py s.log`.

## 6. With a phone (about 15 minutes)

- [ ] **VR-55** The coaching suite: placement, the breakdown, insights, a cue, a challenge, a workout.
- [ ] **VR-54** START NEW mid-run from the phone.
- [ ] **VR-62** The tablet beside PAUSED: a clean court per drill; taps show and say what they did.
- [ ] **VR-95** SAVE AS DEFAULT: save a slider, restart the game. Is it still there? Then RESET.
- [ ] **VR-94** HISTORY: open yesterday's session and replay a shot.
- [ ] **VR-86** BRICK BREAK with the phone open: its numbers, and the drill cards hidden.
- [ ] **VR-66** COACH FROM ANYWHERE: someone off your Wi-Fi coaches you.

## 7. With a Mac watching (about 15 minutes)

- [ ] **VR-79** WATCH A PLAYER: the four cameras, a quarter second behind.
- [ ] **VR-80** The coach's panel on the Mac: start, pause, a cue, a tap on the court.
- [ ] **VR-81** Instant replay: THE LAST SHOT, slow, from any angle.
- [ ] **VR-86** Watch BRICK BREAK: the wall and its bricks as in the headset.

## 8. With a friend in another house

- [ ] **VR-78, VR-91** PLAY A FRIEND from two houses: does the friend's ball arrive smoothly, and does anything freeze?
- [ ] **VR-88** A third person joining your room is told it's full.

## Not in the headset

- [ ] **VR-83, VR-96** The Windows download, on a Windows PC.
- [ ] **VR-06** The Quest build: it builds and installs (it does: mark it?).
