## The coach's side of the game (ADR-023, design/COACHING.md): the Coach
## server, and what a coach can ask of the game. Main owns the views and
## the menus; this turns a coach's messages into what main and the view
## already do, and keeps the coaching state (the session being saved, a
## challenge, a workout, the court marks).
class_name CoachDesk
extends Node

const EVERY := 0.25                  ## seconds between state messages
const NEXT_STEP := 5.0               ## a workout's pause between drills, seconds
const CUES := ["PADDLE UP", "SOFT HANDS", "RESET", "BEND YOUR KNEES", "WATCH THE BALL", "NICE!"]
const CHALLENGES := {"streak": "%d / %d IN A ROW", "board": "%d / %d IN A ROW ON THE BOARD",
	"good": "%d / %d GOOD", "score": "SCORE %d / %d"}
## The TUNING groups a drill's sliders come from (C-11).
const SLIDERS := {Drill.KIND_DINKS: ["DINKS"], Drill.KIND_HANDS: ["HANDS"], Drill.KIND_RESETS: ["RESETS"],
	Drill.KIND_SPOTS: ["DINKS", "TARGETS"], Drill.KIND_LANES: ["DINKS"], Drill.KIND_VOLLEYS: ["VOLLEYS", "TARGETS"],
	Drill.KIND_ATTACK: ["ATTACK", "DINKS"]}
const LEVEL_IDS := ["_easy", "_medium", "_hard"]

var main: Node                       ## scenes/main.gd: settings, view, _start, _on_pause, _on_pressed
var coach: Coach
var session: Sessions
var challenge := {}                  ## {kind, n, progress, done}
var workout := {}                    ## {name, steps, step}
var marks: Array = []                ## [shape, a: Vector2, b: Vector2], put back on every new view
var live: Array = []                 ## this session's shots, for the tablet (C-22)
const LIVE_KEEP := 400
var machine_on := false              ## the coach started the ball machine: their settings feed it (C-21)
var _t := 0.0


func _init(owner_main: Node) -> void:
	main = owner_main


func set_on(on: bool) -> void:
	if on and coach == null:
		coach = Coach.new()
		add_child(coach)
		coach.command.connect(handle)
	elif not on and coach != null:
		coach.queue_free()
		coach = null


func _process(delta: float) -> void:
	if coach == null or coach.coaches() == 0:
		return
	_t += delta
	if _t >= EVERY:
		_t = 0.0
		coach.broadcast(state())


func _send(msg: Dictionary) -> void:
	if coach:
		coach.broadcast(msg)


func _view() -> MatchView:
	return main.view


func _playing() -> bool:
	return main._playing()


# --- From the game -------------------------------------------------------------------

## A new view (a drill, the lobby): the coach's marks go back down.
func on_new_view(v: MatchView) -> void:
	for m in marks:
		v.add_mark(m[0], m[1], m[2])
	if machine_on and v.sim.drill and not v.sim.drill.partner and not v.spectate:
		v.command(machine_command(main.settings.coach_machine))


## The sim's command for the coach's machine settings (page units to um,
## um per tick, ticks).
static func machine_command(m: Dictionary) -> Array:
	return [K.CMD_MACHINE, roundi(float(m["x"]) * K.M), roundi(float(m["z"]) * K.M), roundi(float(m["bx"]) * K.M),
		roundi(float(m["bz"]) * K.M), roundi(float(m["speed"]) * K.M / K.TICK_HZ),
		roundi(float(m["spin"]) * Drill.FEED_SPIN_MAX / 100.0), roundi(float(m["clear"]) * K.M),
		roundi(float(m["every"]) * K.TICK_HZ)]


## Your shot ended: saved, counted toward a challenge, sent to the coach.
func on_shot(info: Dictionary) -> void:
	var s: Settings = main.settings
	if session == null or session.player != s.player:
		session = Sessions.start(s.player)
	session.add_shot(info)
	live.append(info)
	if live.size() > LIVE_KEEP:
		live.pop_front()
	_challenge_shot(info)
	_send(info)


## A timed run's clock ran out: saved; a score challenge judged; a workout
## on to its next drill.
func on_time_up(score: int, good: int, best: int) -> void:
	if session:
		session.add_run(Settings.run_name(_view().sim.drill), score, good, best)
	if workout.is_empty():
		return
	workout["step"] = int(workout["step"]) + 1
	var steps: Array = workout["steps"]
	if int(workout["step"]) >= steps.size():
		_view().cue("WORKOUT DONE!")
		workout = {}
		return
	var next: Dictionary = steps[workout["step"]]
	_view().cue("NEXT: %s IN %d" % [Drill.KIND_NAMES[int(next["drill"])], int(NEXT_STEP)])
	var at: int = workout["step"]
	get_tree().create_timer(NEXT_STEP).timeout.connect(func() -> void:
		if not workout.is_empty() and int(workout["step"]) == at:
			_run_step())


# --- What the numbers say (C-15, for the tablet; the phone's page has its own) -----

const READY_M := 0.8


static func _mean(a: Array, key: String) -> float:
	var t := 0.0
	for s in a:
		t += float(s[key])
	return t / a.size() if not a.is_empty() else 0.0


static func _good_pct(a: Array) -> int:
	return roundi(100.0 * a.filter(func(s: Dictionary) -> bool: return s.get("good", false)).size() / a.size()) if not a.is_empty() else 0


## Plain findings from the shots: net clearance, the weaker side, low
## contact, the ready paddle, standing back.
static func insights(shots: Array) -> Array[String]:
	var out: Array[String] = []
	var hit := shots.filter(func(s: Dictionary) -> bool: return s.has("speed"))
	if hit.size() < 8:
		out.append("A FEW MORE SHOTS FIRST: INSIGHTS NEED 8.")
		return out
	var cl := hit.filter(func(s: Dictionary) -> bool: return s.has("clear") and float(s["clear"]) >= 0.0)
	var nets := hit.filter(func(s: Dictionary) -> bool: return String(s.get("result", "")).contains("NET")).size()
	if cl.size() >= 6:
		var a := _mean(cl, "clear")
		if a > 0.45:
			out.append("BALLS CROSS %d CM OVER THE NET: BRING THEM DOWN." % roundi(a * 100))
		elif a < 0.15 and nets >= 3:
			out.append("SKIMMING THE TAPE (%d CM), %d IN THE NET: A TOUCH MORE LIFT." % [roundi(a * 100), nets])
		else:
			out.append("NET CLEARANCE %d CM: RIGHT FOR A DINK." % roundi(a * 100))
	var fh := hit.filter(func(s: Dictionary) -> bool: return s.get("side", "") == "FH")
	var bh := hit.filter(func(s: Dictionary) -> bool: return s.get("side", "") == "BH")
	if fh.size() >= 5 and bh.size() >= 5:
		var f := _good_pct(fh)
		var b := _good_pct(bh)
		if absi(f - b) >= 15:
			out.append("%s IS THE WEAKER SIDE: %d%% GOOD AGAINST %d%%." % ["BACKHAND" if f > b else "FOREHAND", mini(f, b), maxi(f, b)])
	var good := hit.filter(func(s: Dictionary) -> bool: return s.get("good", false))
	var miss := hit.filter(func(s: Dictionary) -> bool: return not s.get("good", false) and not String(s.get("result", "")).contains("NET"))
	if good.size() >= 5 and miss.size() >= 5:
		var hg := _mean(good, "height")
		var hm := _mean(miss, "height")
		if hg - hm > 0.08:
			out.append("MISSES COME OFF LOWER CONTACT (%.2f M AGAINST %.2f): GET LOWER." % [hm, hg])
	var rd := hit.filter(func(s: Dictionary) -> bool: return s.has("ready"))
	if rd.size() >= 8:
		var up := rd.filter(func(s: Dictionary) -> bool: return float(s["ready"]) >= READY_M).size()
		out.append("PADDLE UP AS THEY HIT: %d%% OF THE TIME." % roundi(100.0 * up / rd.size()))
	var bl := hit.filter(func(s: Dictionary) -> bool: return s.has("behind"))
	if bl.size() >= 6 and _mean(bl, "behind") > 0.4:
		out.append("STANDING %d CM BEHIND THE KITCHEN LINE: MOVE UP." % roundi(_mean(bl, "behind") * 100))
	if out.is_empty():
		out.append("NOTHING STANDS OUT YET: KEEP GOING.")
	return out


## Forehand against backhand, good %, one line.
static func split_line(shots: Array) -> String:
	var fh := shots.filter(func(s: Dictionary) -> bool: return s.get("side", "") == "FH")
	var bh := shots.filter(func(s: Dictionary) -> bool: return s.get("side", "") == "BH")
	if fh.is_empty() and bh.is_empty():
		return ""
	return "FOREHAND %d%% OF %d   BACKHAND %d%% OF %d" % [_good_pct(fh), fh.size(), _good_pct(bh), bh.size()]


# --- Challenges (C-12) ---------------------------------------------------------------

func _challenge_shot(info: Dictionary) -> void:
	if challenge.is_empty() or challenge.get("done", false):
		return
	var n: int = challenge["n"]
	var p: int = challenge["progress"]
	match String(challenge["kind"]):
		"streak": p = p + 1 if info.get("good", false) else 0
		"board": p = p + 1 if int(info.get("ring", 0)) > 0 else 0
		"good": p += 1 if info.get("good", false) else 0
		"score": p = _view().sim.drill.score() if _view().sim.drill else p
	challenge["progress"] = p
	if p >= n:
		challenge["done"] = true
		_view().cue("CHALLENGE DONE!")
		_view()._play("4_applause", Vector3(0, 2, 0))
	_show_challenge()


func _show_challenge() -> void:
	var v := _view()
	if v == null:
		return
	if challenge.is_empty():
		v.show_challenge("")
	elif challenge.get("done", false):
		v.show_challenge("CHALLENGE DONE!")
	else:
		v.show_challenge("CHALLENGE: " + CHALLENGES[challenge["kind"]] % [challenge["progress"], challenge["n"]])


# --- Workouts (C-13) -----------------------------------------------------------------

## A workout's step: its drill set up, then started.
func _run_step() -> void:
	var st: Dictionary = workout["steps"][workout["step"]]
	var s: Settings = main.settings
	s.partner_drill = clampi(int(st["drill"]), 0, Drill.KIND_NAMES.size() - 1)
	s.partner_level = clampi(int(st["level"]), 0, 2)
	s.partner_time = clampi(int(st["time"]), 1, Drill.TIMES.size() - 1)   # every step is timed
	s.partner_targets = bool(st.get("targets", s.partner_targets))
	s.save()
	main._start.call_deferred(s.partner_config(), false)


static func _clean_steps(raw: Variant) -> Array:
	var out: Array = []
	if raw is Array:
		for st in raw:
			if st is Dictionary and out.size() < 12:
				out.append({"drill": clampi(int(st.get("drill", 0)), 0, Drill.KIND_NAMES.size() - 1),
					"level": clampi(int(st.get("level", 1)), 0, 2),
					"time": clampi(int(st.get("time", 1)), 1, Drill.TIMES.size() - 1),
					"targets": bool(st.get("targets", true))})
	return out


static func _clean_name(raw: Variant, fallback: String) -> String:
	var t := String(raw).to_upper().strip_edges().left(20)
	var keep := ""
	for ch in t:
		if ch.is_valid_identifier() or ch in " -'!?.,0123456789":
			keep += ch
	return keep if keep != "" else fallback


# --- A coach's messages --------------------------------------------------------------

func handle(msg: Dictionary) -> void:
	var s: Settings = main.settings
	var v := _view()
	match String(msg.get("type", "")):
		"set":
			var n := int(msg.get("value", 0))
			match String(msg.get("key", "")):
				"drill": s.partner_drill = clampi(n, 0, Drill.KIND_NAMES.size() - 1)
				"level": s.partner_level = clampi(n, 0, 2)
				"time": s.partner_time = clampi(n, 0, Drill.TIMES.size() - 1)
				"targets": s.partner_targets = n != 0
				"side": s.partner_cross = n != 0
				"spread": s.partner_spread = clampi(n, 0, Drill.SPREADS.size() - 1)
				_: return
			s.save()
			if not _playing():
				main.lobby.call_deferred("partner")   # the headset shows what the coach set
		"start":
			workout = {}
			machine_on = false
			if _playing():
				main._keep_best()
			main._start.call_deferred(s.partner_config(), false)
		"pause":
			if _playing() and not v.paused:
				main._on_pause()
		"resume":
			if _playing() and v.paused:
				main._on_pressed("resume")
		"restart":
			if _playing():
				main._on_pressed("again")
		"menu":
			workout = {}
			machine_on = false
			if _playing():
				main._on_pressed("lobby")
		"cue":
			if v:
				v.cue(_clean_name(msg.get("text", ""), "LOOK HERE").left(24))
		"target":
			if _playing():
				v.command([K.CMD_PIN_TARGET, roundi(float(msg.get("x", 0)) * K.M), roundi(float(msg.get("z", -1)) * K.M), 1])
		"target_free":
			if _playing():
				v.command([K.CMD_PIN_TARGET, 0, 0, 0])
		"feed":
			if _playing():
				v.command([K.CMD_FEED_TO, roundi(float(msg.get("x", 0)) * K.M), roundi(float(msg.get("z", 2)) * K.M)])
		"mark":
			var a := Vector2(float(msg.get("ax", 0)), float(msg.get("az", 0)))
			var b := Vector2(float(msg.get("bx", 0)), float(msg.get("bz", 0)))
			var shape := "zone" if String(msg.get("shape", "")) == "zone" else "line"
			marks.append([shape, a, b])
			if marks.size() > MatchView.MAX_MARKS:
				marks.pop_front()
			if v:
				v.add_mark(shape, a, b)
		"clear_marks":
			marks = []
			if v:
				v.clear_marks()
		"tune":
			var id := String(msg.get("id", ""))
			if not Tune.entry(id).is_empty():
				Tune.set_value(id, int(msg.get("value", Tune.value(id))))   # live, this session (C-11)
		"machine_start":
			workout = {}
			machine_on = true
			if _playing():
				main._keep_best()
			main._start.call_deferred(s.machine_config(), false)
		"machine_set":
			for k in s.coach_machine:
				if msg.has(k):
					s.coach_machine[k] = float(msg[k])
			s.save()
			if machine_on and _playing() and v.sim.drill and not v.sim.drill.partner:
				v.command(machine_command(s.coach_machine))
		"tune_reset":
			Tune.reset()
		"challenge":
			var kind := String(msg.get("kind", ""))
			if CHALLENGES.has(kind):
				challenge = {"kind": kind, "n": clampi(int(msg.get("n", 5)), 1, 999), "progress": 0, "done": false}
				if kind == "score" and v and v.sim.drill:
					challenge["progress"] = v.sim.drill.score()
			_show_challenge()
		"challenge_clear":
			challenge = {}
			_show_challenge()
		"workout_save":
			var steps := _clean_steps(msg.get("steps", []))
			var name := _clean_name(msg.get("name", ""), "WORKOUT %d" % (s.workouts.size() + 1))
			if not steps.is_empty():
				s.workouts = s.workouts.filter(func(w: Dictionary) -> bool: return w["name"] != name)
				s.workouts.append({"name": name, "steps": steps})
				s.save()
		"workout_delete":
			var name := String(msg.get("name", ""))
			s.workouts = s.workouts.filter(func(w: Dictionary) -> bool: return w["name"] != name)
			s.save()
		"workout_run":
			var steps := _clean_steps(msg.get("steps", []))
			if steps.is_empty():
				for w in s.workouts:
					if w["name"] == String(msg.get("name", "")):
						steps = w["steps"]
			if not steps.is_empty():
				machine_on = false
				workout = {"name": _clean_name(msg.get("name", ""), "WORKOUT"), "steps": steps, "step": 0}
				if _playing():
					main._keep_best()
				_run_step()
		"workout_stop":
			workout = {}
		"player":
			var name := _clean_name(msg.get("name", ""), s.player)
			if not s.players.has(name):
				s.players.append(name)
			s.player = name
			s.save()
			live = []
			session = null                   # the next shot starts their session
		"sessions":
			_send({"type": "sessions", "list": Sessions.list(s.player)})
		"session":
			_send({"type": "session", "data": Sessions.read(String(msg.get("id", "")))})
		_:
			return
	_send(state())


# --- What the coach sees -------------------------------------------------------------

func state() -> Dictionary:
	var s: Settings = main.settings
	var v := _view()
	var where := "lobby"
	if _playing():
		where = "paused" if v.paused else "playing"
	var st := {"type": "state", "where": where, "player": s.player, "players": s.players,
		"court": {"hw": K.COURT_HALF_WIDTH / 1e6, "hl": K.COURT_HALF_LENGTH / 1e6, "kd": K.KITCHEN_DEPTH / 1e6,
			"dink": Drill.DINK_ZONE / 1e6},
		"setup": {"drill": s.partner_drill, "drills": Drill.KIND_NAMES, "level": s.partner_level,
			"levels": Drill.PACE_NAMES, "time": s.partner_time, "times": Drill.TIME_NAMES,
			"targets": s.partner_targets, "side": s.partner_cross, "spread": s.partner_spread,
			"spreads": Drill.SPREAD_NAMES},
		"cues": CUES, "workouts": s.workouts,
		"marks": marks.map(func(m: Array) -> Dictionary: return {"shape": m[0], "ax": m[1].x, "az": m[1].y, "bx": m[2].x, "bz": m[2].y}),
		"challenge": challenge, "workout": {} if workout.is_empty() else
			{"name": workout["name"], "step": workout["step"], "of": (workout["steps"] as Array).size()},
		"tunes": _sliders(),
		"machine": s.coach_machine.merged({"on": machine_on and _playing()})}
	var d: Drill = v.sim.drill if v and v.sim and _playing() else null
	if d:
		st["run"] = {"name": Settings.run_name(d) if d.time_limit > 0 else d.mode_name(), "score": d.score(),
			"good": d.good, "streak": d.streak, "best": d.best, "points": d.points, "timed": d.time_limit > 0,
			"left": ceili(d.time_left(v.sim) / float(K.TICK_HZ)), "done": d.stage == Drill.DONE}
		if d.targets or d.spots:
			st["target"] = {"x": d.target_x / 1e6, "z": d.target_z / 1e6, "lit": d.spot_lit or d.targets,
				"r": (d.spot_radius() if d.spots else Drill.TARGET_RADIUS) / 1e6, "rings": Drill.RING_EDGES,
				"pinned": d.target_pinned}
		if d.feed_set:
			st["feed"] = {"x": d.feed_x / 1e6, "z": d.feed_z / 1e6}
	var cfg := s.partner_config()
	cfg.drill.time_limit = Drill.TIMES[s.partner_time] * K.TICK_HZ
	if cfg.drill.time_limit > 0:
		var name := Settings.run_name(cfg.drill)
		st["records"] = {"name": name, "best": s.best_runs(name, 3).map(func(r: Array) -> int: return r[0]),
			"recent": s.recent_scores(name, 8)}
	return st


## The drill's sliders (C-11): its TUNING groups, at the level set, with
## the source's value to go back to.
func _sliders() -> Array:
	var s: Settings = main.settings
	var groups: Array = SLIDERS.get(s.partner_drill, ["DINKS"])
	if s.partner_targets and not groups.has("TARGETS"):
		groups = groups + ["TARGETS"]
	var out: Array = []
	for g in groups:
		for e in Tune.in_group(g):
			var id: String = e[0]
			var levelled := LEVEL_IDS.any(func(l: String) -> bool: return id.ends_with(l))
			if levelled and not id.ends_with(LEVEL_IDS[s.partner_level]):
				continue
			if id in ["inner", "bull", "hold"]:
				continue                     # not for a live slider
			out.append({"id": id, "label": e[2], "value": Tune.value(id), "min": e[8], "max": e[9], "step": e[7],
				"text": Tune.text(id, Tune.value(id)), "default": Tune.default_of(id)})
	return out
