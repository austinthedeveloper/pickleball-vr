## A CPU player (ADR-012): a rigged body (ADR-018, `Body`) posed every
## frame from joints worked out here. Display only: it reads the sim and never
## writes to it.
##
## - Legs and arms are two-bone IK chains (hip-knee-foot, shoulder-elbow-
##   hand) solved toward targets, so knees and elbows bend naturally.
## - Feet stay planted and step when the body has moved off them, one at a
##   time, so moving across the court reads as a shuffle.
## - The paddle hand plays a swing timed to the sim's contact: a
##   backswing, through the contact point, a follow-through; then back to
##   ready. It syncs to the actual hit when that happens.
## - A split step (a small hop) as the other side strikes; the head
##   watches the ball; the torso coils into the backswing.
class_name Avatar
extends Node3D

const SKINS := [Color(0.84, 0.6, 0.46), Color(0.7, 0.48, 0.34), Color(0.48, 0.31, 0.21)]
const HAIRS := [Color(0.24, 0.15, 0.09), Color(0.1, 0.08, 0.07), Color(0.62, 0.42, 0.2)]
const MEN_HAIR := ["parted", "buzzed"]
const WOMEN_HAIR := ["long", "buns", "buzzed_f"]

# The rig, metres (bone lengths come from the Body).
const PELVIS_DROP := 0.022           ## the pelvis bone under the hip joints
const PALM := 0.07                   ## wrist to the paddle's grip
const CAP_R := 0.108
const CAP_AT := Vector3(0, 0.135, 0.005) ## the crown's centre, from the head bone
const STANCE := 0.2                  ## half the feet's spread
const STEP_AT := 0.24                ## a foot this far off its spot steps
const STEP_TIME := 0.16
const STEP_LIFT := 0.07
const READY_HIPS := 0.88             ## knees bent: ready
const TALL_HIPS := 0.94
const BACKSWING := 0.42              ## seconds before contact the backswing starts
const FORWARD := 0.12                ## ...and the forward swing
const FOLLOW := 0.3
const RECOVER := 0.35
const MASK_AT := Vector3(0, 0.075, 0.13)   ## a prank's face photo, from the head bone

var slot := 2
var shirt := Color(0.95, 0.55, 0.12)
var shorts := Color(0.15, 0.18, 0.3)
var skin := SKINS[0]
var hair := HAIRS[0]
var cap := true
var female := false
var style := "parted"                ## Body.HAIR_STYLES
var beard := false
var model := ""                      ## Body.MODELS: another person in their own clothes (no cap)
var paddle: PaddleMesh
var figure: Body

var _root := Vector3.ZERO            ## feet's centre, smoothed
var _face := Vector3.FORWARD         ## facing, horizontal
var _feet: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _step_from: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _step_to: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _step_t: Array[float] = [-1.0, -1.0]
var _hand := Vector3.ZERO            ## paddle hand, smoothed
var _look := Vector3.ZERO            ## the head's direction, smoothed
var _vel := Vector3.ZERO             ## the body's velocity, smoothed
var _gait := 0.0                     ## the stride's phase (arm swing)
var _off := Vector3.ZERO
var _hop := 0.0
var _coil := 0.0
var _placed := false
# The swing: contact point and time (seconds from now), and the shot's way out.
var _swing := false
var _contact := Vector3.ZERO
var _until := 0.0
var _since := -1.0                   ## seconds since the hit, or -1
var _out := Vector3.FORWARD
var _soft := false
var _backhand := false
var _plan_seen := -2
var _last_hitter := -9
var _last_swing := -1
# A prank's antic (ADR-025): what, for how long, how far in. A swing comes
# first: the antic waits while the ball is theirs to hit.
var _antic := ""
var _antic_len := 0.0
var _antic_t := 0.0
var _mask: MeshInstance3D


func _ready() -> void:
	figure = Body.new()
	figure.female = female
	figure.dark = skin == SKINS[2]
	figure.tint = Color(0.86, 0.78, 0.72) if skin == SKINS[1] else Color.WHITE
	figure.shirt = shirt
	figure.shorts = shorts
	figure.hair = hair
	figure.style = style if not cap else ("buzzed_f" if female else "buzzed")
	figure.beard = beard
	figure.model = model
	add_child(figure)
	if cap and model == "":
		_add_cap()
	paddle = PaddleMesh.new()
	paddle.color = Color(0.85, 0.15, 0.2) if slot < 2 else Color(0.2, 0.3, 0.85)   # your side's red
	paddle.top_level = true          # posed in world space
	add_child(paddle)


## A cap with a visor, on the head bone (the partner's look).
func _add_cap() -> void:
	var on := BoneAttachment3D.new()
	on.bone_name = figure.bone_name("Head")
	figure.skel.add_child(on)
	var cap_m := _mat(shirt.darkened(0.25), 0.7)
	var crown := SphereMesh.new()
	crown.radius = CAP_R
	crown.height = CAP_R
	crown.is_hemisphere = true
	crown.height = CAP_R * 0.9
	var visor := [_box(Vector3(0.18, 0.012, 0.1)), CAP_AT + Vector3(0, 0.0, 0.13), Vector3(-0.12, 0, 0)]
	for part in [[crown, CAP_AT, Vector3.ZERO], visor]:
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		mi.material_override = cap_m
		mi.position = part[1]
		mi.rotation = part[2]
		on.add_child(mi)


static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := World.material(c)
	m.roughness = rough
	return m


static func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


# --- Pranks (ADR-025) ------------------------------------------------------------

## Do an antic for `seconds` (Pranks.ANTICS, or "talk"); "" stops.
func antic(kind: String, seconds: float) -> void:
	_antic = kind
	_antic_len = seconds
	_antic_t = 0.0


func antic_on() -> String:
	return _antic


## A photo over the face, like a cut-out mask on a stick; null takes it off.
func set_mask(tex: Texture2D) -> void:
	if _mask:
		_mask.get_parent().free()
		_mask = null
	if tex == null or figure == null:
		return
	var on := BoneAttachment3D.new()
	on.bone_name = figure.bone_name("Head")
	figure.skel.add_child(on)
	_mask = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.27, 0.27)
	_mask.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mask.material_override = m
	_mask.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mask.transform = figure.head_mount(MASK_AT) if model != "" else Transform3D(Basis(), MASK_AT)
	on.add_child(_mask)


## The antic's pose this frame: {} for none, else any of "pelvis" (an
## offset), "hand", "off" (the hands) and "pole" (elbows, for both arms).
func _antic_pose(delta: float, pelvis: Vector3, face: Vector3, right: Vector3) -> Dictionary:
	if _antic == "":
		return {}
	_antic_t += delta
	if _antic_t >= _antic_len:
		_antic = ""
		return {}
	if _swing and (_since >= 0.0 and _since < FOLLOW or _since < 0.0 and _until < BACKSWING):
		return {}                        # the ball first: the swing, then back to it
	var t := _antic_t
	var up := Vector3.UP
	match _antic:
		"dance":
			# Disco: the paddle hand points up and across, then down; the
			# hips sway to the beat; the other hand on the hip.
			var beat := sin(TAU * 1.0 * t)
			var sway := right * 0.07 * sin(TAU * 1.0 * t) + up * 0.035 * absf(sin(TAU * 2.0 * t))
			var hi := pelvis + right * 0.4 + up * 1.05 + face * 0.15
			var lo := pelvis - right * 0.12 + up * 0.15 + face * 0.32
			return {"pelvis": sway, "hand": hi if beat > 0.0 else lo,
				"off": pelvis - right * 0.24 + up * 0.08 + face * 0.02}
		"flex":
			var pump := 0.03 * sin(TAU * 2.0 * t)
			return {"hand": pelvis + right * 0.3 + up * (0.78 + pump) + face * 0.05,
				"off": pelvis - right * 0.3 + up * (0.78 + pump) + face * 0.05, "pole": Vector3.DOWN * 0.3, "wide": true}
		"wave":
			return {"off": pelvis - right * (0.3 + 0.13 * sin(TAU * 2.2 * t)) + up * 1.1 + face * 0.12}
		"jump":
			return {"pelvis": up * 0.07 * absf(sin(TAU * 1.5 * t)), "hand": pelvis + right * 0.22 + up * 1.2 + face * 0.08,
				"off": pelvis - right * 0.22 + up * 1.2 + face * 0.08}
		"talk":
			return {"off": pelvis - right * 0.18 + face * 0.38 + up * (0.4 + 0.06 * sin(TAU * 2.5 * t)),
				"nod": 0.12 * sin(TAU * 3.0 * t)}
	return {}


# --- Posing helpers ------------------------------------------------------------

## Two-bone IK: the middle joint for a chain root -> target with bone
## lengths a, b, bending toward `pole` (a direction). Returns [middle, end].
static func two_bone(root: Vector3, target: Vector3, a: float, b: float, pole: Vector3) -> Array[Vector3]:
	var d := target - root
	var dist := clampf(d.length(), 0.02, a + b - 0.002)
	var dir := d.normalized() if d.length() > 0.0001 else Vector3.DOWN
	var cos_r := clampf((a * a + dist * dist - b * b) / (2.0 * a * dist), -1.0, 1.0)
	var ang := acos(cos_r)
	var bend := pole - dir * pole.dot(dir)
	bend = bend.normalized() if bend.length() > 0.0001 else dir.cross(Vector3.RIGHT).normalized()
	var mid := root + dir * (cos(ang) * a) + bend * (sin(ang) * a)
	return [mid, root + dir * dist]


# --- Reading the sim -------------------------------------------------------------

## The tick the sim means this player to hit at, or -1.
func _plan_tick(sim: Sim) -> int:
	if sim.drill and sim.drill.partner and slot == 2:
		var st := sim.drill.stage
		return sim.drill.partner_plan if st == Drill.PARTNER or st == Drill.RETURN or st == Drill.SETUP else -1
	var p := sim.players[slot]
	return p.plan_tick if p.cpu else -1


func _incoming(sim: Sim) -> bool:
	if sim.drill:
		var st := sim.drill.stage
		return sim.drill.partner and slot == 2 and (st == Drill.PARTNER or st == Drill.RETURN or st == Drill.SETUP)
	return sim.phase == K.PHASE_LIVE and sim.last_hitter >= 0 and sim.last_hitter >> 1 != slot >> 1


## Where the ball will be `ticks` from now (a copy flown on; display only).
static func _ahead(sim: Sim, ticks: int) -> Vector3:
	var b := sim.ball.copy()
	for i in clampi(ticks, 0, 400):
		b.step()
	return World.m(b.x, b.y, b.z)


## No plan from the sim (the lobby's bot as you): the first point on the
## ball's path within reach of where this player stands.
func _reach_point(sim: Sim, body: Vector3) -> Array:
	var b := sim.ball.copy()
	for i in range(1, 160):
		b.step()
		var at := World.m(b.x, b.y, b.z)
		if Vector2(at.x - body.x, at.z - body.z).length() < 0.85 and at.y > 0.2 and at.y < 1.7:
			return [i, at]
	return []


# --- The frame ---------------------------------------------------------------------

func show_from(sim: Sim, delta: float) -> void:
	var p := sim.players[slot]
	var side := K.side_sign(p.team)
	var body := World.m(p.x, 0, p.z)
	var ball := World.m(sim.ball.x, sim.ball.y, sim.ball.z)
	if not _placed:
		_placed = true
		_root = body
		_face = Vector3(0, 0, -side)
		var r0 := _face.cross(Vector3.UP)
		for i in 2:
			_feet[i] = body + r0 * (STANCE if i == 1 else -STANCE)
		_hand = body + Vector3(0, 1.0, -side * 0.3)
		_off = _hand
	# Where the sim has the player, and how fast they're going there: the
	# feet go after it, and the hips ride between the feet (they used to
	# glide with the sim, dragging the legs along).
	if delta > 0.0:
		_vel = _vel.lerp((body - _root) / delta, clampf(delta * 10.0, 0.0, 1.0))
	_root = body
	_track_swing(sim, body, ball, delta)
	# Facing: the ball while it's coming, else the other side.
	var want := Vector3(0, 0, -side)
	if _incoming(sim) or _swing:
		var to_ball := Vector3(ball.x - _root.x, 0, ball.z - _root.z)
		if to_ball.length() > 0.3 and to_ball.dot(want) > 0.0:
			want = to_ball.normalized().lerp(want, 0.4).normalized()
	_face = _face.slerp(want, clampf(delta * 6.0, 0.0, 1.0)).normalized()
	var right := _face.cross(Vector3.UP).normalized()
	# The split step: a hop as the other side hits.
	if sim.last_hitter != _last_hitter:
		if sim.last_hitter >= 0 and sim.last_hitter >> 1 != p.team:
			_hop = 1.0
		_last_hitter = sim.last_hitter
	_hop = maxf(_hop - delta * 6.0, 0.0)
	var ready := _incoming(sim) or _swing
	var speed := Vector2(_vel.x, _vel.z).length()
	_feet_step(right, delta, speed)
	# The hips: between the feet, leaning a little toward where they're going,
	# dipping as a foot swings through (a stride's bob).
	var feet_mid := (_feet[0] + _feet[1]) / 2
	var ahead := Vector3(_root.x - feet_mid.x, 0, _root.z - feet_mid.z).limit_length(0.18)
	var bob := 0.0
	for i in 2:
		if _step_t[i] >= 0.0:
			bob = maxf(bob, sin(_step_t[i] * PI))
	var hips_h: float = (READY_HIPS if ready or speed > 1.0 else TALL_HIPS) + 0.06 * sin(_hop * PI) \
		- (0.04 if _swing and _until < 0.2 else 0.0) - 0.03 * bob
	var pelvis := Vector3(feet_mid.x, hips_h, feet_mid.z) + ahead + _face * 0.03
	var fun := _antic_pose(delta, pelvis, _face, _face.cross(Vector3.UP).normalized())
	if fun.has("pelvis"):
		pelvis += fun["pelvis"]
	_gait += speed * delta * 4.0
	# Torso: leans in when ready, coils into the backswing.
	var coil_want := 0.0
	if _swing and _since < 0.0:
		coil_want = (-0.5 if not _backhand else 0.5) * clampf(1.0 - _until / BACKSWING, 0.0, 1.0)
	elif _swing:
		coil_want = (0.35 if not _backhand else -0.35) * clampf(1.0 - _since / FOLLOW, 0.0, 1.0)
	_coil = lerpf(_coil, coil_want, clampf(delta * 10.0, 0.0, 1.0))
	var t_face := _face.rotated(Vector3.UP, _coil)
	var t_right := t_face.cross(Vector3.UP).normalized()
	var lean := 0.18 if ready else 0.08
	var spine := (Vector3.UP + t_face * lean + (_vel * Vector3(1, 0, 1) * 0.05).limit_length(0.2)).normalized()
	# The body: hips, a spine that bends and coils, the neck.
	figure.begin()
	figure.orient("pelvis", _face, Vector3.UP, pelvis - Vector3(0, PELVIS_DROP, 0))
	var mid_face := _face.slerp(t_face, 0.5)
	figure.orient("spine_01", mid_face, Vector3.UP.lerp(spine, 0.5).normalized())
	figure.orient("spine_02", t_face, spine)
	figure.orient("spine_03", t_face, spine)
	figure.orient("neck_01", t_face, spine)
	# Legs: hips to planted feet, knees forward.
	for i in 2:
		var s := "_l" if i == 0 else "_r"
		var hip := figure.at("thigh" + s)
		var ankle := _feet[i] + Vector3(0, figure.ankle_h + _lift(i), 0)
		var leg := two_bone(hip, ankle, figure.thigh_len, figure.shin_len, _face + right * (0.25 if i == 1 else -0.25))
		figure.aim("thigh" + s, leg[0])
		figure.aim("calf" + s, leg[1])
		var toe := _face.rotated(Vector3.UP, 0.25 if i == 0 else -0.25)
		figure.orient("foot" + s, toe, Vector3.UP)
	# Arms: the paddle hand on its swing; the other out for balance.
	var hand_want: Vector3 = fun.get("hand", _paddle_target(pelvis, t_face, t_right, ball))
	var rate := 22.0 if _swing else 9.0
	_hand = _hand.lerp(hand_want, clampf(delta * rate, 0.0, 1.0))
	var off_want := pelvis + t_face * (0.32 + 0.12 * sin(_gait) * clampf(speed / 2.5, 0.0, 1.0)) \
		- t_right * 0.26 + Vector3(0, 0.32 if ready else 0.12, 0)
	var holding := sim.drill != null and slot == 2 and sim.drill.stage == Drill.SETUP and sim.tick < sim.drill.toss_at + 6
	if holding:
		off_want = ball + Vector3(0, -0.07, 0)    # holding the next ball up, then letting it go
	elif fun.has("off"):
		off_want = fun["off"]
	_off = _off.lerp(off_want, clampf(delta * 8.0, 0.0, 1.0))
	var elbow_pole: Vector3 = fun.get("pole", Vector3.DOWN * 0.7 - t_face * 0.3)
	var out_w := 1.2 if fun.has("wide") else 0.4   # flexing: elbows out
	var hands := [_off, _hand]
	var wrist := Vector3.ZERO
	for i in 2:
		var s := "_l" if i == 0 else "_r"
		var sh := figure.at("upperarm" + s)
		# The paddle hand reaches its grip, a palm past the wrist.
		var fore := figure.fore_len + (PALM if i == 1 else 0.0)
		var arm := two_bone(sh, hands[i], figure.upper_len, fore, elbow_pole + t_right * (out_w if i == 1 else -out_w))
		figure.aim("upperarm" + s, arm[0])
		figure.aim("lowerarm" + s, arm[1])
		if i == 1:
			wrist = arm[0] + (arm[1] - arm[0]).normalized() * figure.fore_len
	# The paddle: out of the hand along the forearm, tipped up, face to the shot.
	var along := (_hand - wrist).normalized()
	along = (along + Vector3.UP * 0.6 + t_face * 0.2).normalized()
	var face_n := _out if _swing else t_face
	if _backhand:
		face_n = face_n.rotated(Vector3.UP, 0.4)
	paddle.pose_grip(_hand, along, face_n)
	# The hand round the handle: thumb up it, palm behind the face.
	figure.orient("hand_r", along, -face_n)
	figure.curl(1, 1.0)
	if holding:
		figure.orient("hand_l", t_face, Vector3.DOWN)      # palm up under the ball
		figure.curl(0, 0.35)
	else:
		figure.curl(0, 0.25)
	# The head: on the neck, watching the ball in play (between points, the
	# other side), never tipped down so far the cap hides the face.
	var head_at := figure.at("Head") + spine * 0.1
	var look := (ball - head_at) if ready else _face
	if look.length() < 0.1 or look.dot(_face) < -0.2:
		look = _face
	look = look.normalized().lerp(_face, 0.25)
	var flat_len := Vector2(look.x, look.z).length()
	look.y = clampf(look.y, -0.5 * flat_len, 0.6 * flat_len)
	_look = _look.slerp(look.normalized(), clampf(delta * 10.0, 0.0, 1.0)) if _look != Vector3.ZERO else look.normalized()
	var head_dir := _look
	if fun.has("nod"):
		head_dir = (_look + Vector3.UP * float(fun["nod"])).normalized()
	figure.orient("Head", head_dir, Vector3.UP)
	figure.apply()


## Where the paddle hand goes: the swing if there is one, else ready.
func _paddle_target(pelvis: Vector3, face: Vector3, right: Vector3, ball: Vector3) -> Vector3:
	var ready := pelvis + face * 0.38 + right * 0.24 + Vector3(0, 0.3, 0)
	if not _swing:
		return ready
	var side := -1.0 if _backhand else 1.0
	var amp := 0.22 if _soft else 0.45
	var back := _contact - _out * amp + Vector3(0, -0.1 if _soft else -0.18, 0) + right * side * 0.12
	var through := _contact + _out * amp + Vector3(0, 0.12 if _soft else 0.38, 0) - right * side * (0.05 if _soft else 0.25)
	if _since >= 0.0:
		var f := clampf(_since / FOLLOW, 0.0, 1.0)
		if _since > FOLLOW:
			return through.lerp(ready, clampf((_since - FOLLOW) / RECOVER, 0.0, 1.0))
		return _contact.lerp(through, sin(f * PI / 2))
	if _until > BACKSWING:
		return ready
	if _until > FORWARD:
		return ready.lerp(back, clampf(1.0 - (_until - FORWARD) / (BACKSWING - FORWARD), 0.0, 1.0))
	return back.lerp(_contact, clampf(1.0 - _until / FORWARD, 0.0, 1.0))


## Plan, time and sync the swing from the sim.
func _track_swing(sim: Sim, body: Vector3, ball: Vector3, delta: float) -> void:
	var p := sim.players[slot]
	var hit := p.swing_tick != _last_swing and p.swing_tick >= 0
	if sim.last_hitter == slot and _since < 0.0 and _swing:
		hit = true
	if hit:
		_last_swing = p.swing_tick
		_swing = true
		_since = 0.0
		_contact = _hand.lerp(ball, 0.7)
		var v := Vector3(sim.ball.vx, sim.ball.vy, sim.ball.vz)
		_out = Vector3(v.x, 0, v.z).normalized() if Vector2(v.x, v.z).length() > 10 else _face
		_soft = sim.ball.speed() < 60000
		return
	if _since >= 0.0:
		_since += delta
		if _since > FOLLOW + RECOVER:
			_swing = false
			_since = -1.0
			_plan_seen = -2
		return
	if not _incoming(sim):
		_swing = false
		return
	var plan := _plan_tick(sim)
	if plan != _plan_seen:
		_plan_seen = plan
		if plan >= sim.tick:
			_contact = _ahead(sim, plan - sim.tick)
			_until = (plan - sim.tick) / float(K.TICK_HZ)
		else:
			var r := _reach_point(sim, body)
			if r.is_empty():
				return
			_contact = r[1]
			_until = r[0] / float(K.TICK_HZ)
		_swing = true
		var right := _face.cross(Vector3.UP)
		_backhand = (_contact - body).dot(right) < -0.1
		_out = Vector3(0, 0, K.side_sign(1 - p.team))
		if sim.drill != null and sim.drill.stage == Drill.SETUP:
			# The feed: square to you, so the wind-up shows where it's going.
			var you := World.m(sim.players[0].x, 0, sim.players[0].z)
			_out = Vector3(you.x - _contact.x, 0, you.z - _contact.z).normalized()
		_soft = sim.drill != null and sim.drill.partner and not sim.drill.hands and not sim.drill.resets
	else:
		_until = maxf(_until - delta, 0.0)


# --- Footwork ---------------------------------------------------------------------

func _feet_step(right: Vector3, delta: float, speed: float) -> void:
	# Quicker steps the faster it's going; a step may start before the
	# other lands (running), and lands where the body will be.
	var step_time := clampf(STEP_TIME + 0.06 - speed * 0.035, 0.1, STEP_TIME + 0.06)
	var reach := 0.13 if speed > 0.6 else STEP_AT
	for i in 2:
		if _step_t[i] >= 0.0:
			_step_t[i] += delta / step_time
			if _step_t[i] >= 1.0:
				_step_t[i] = -1.0
				_feet[i] = _step_to[i]
			else:
				var f := _step_t[i]
				_feet[i] = _step_from[i].lerp(_step_to[i], f * f * (3.0 - 2.0 * f))
	var lead := Vector3(_vel.x, 0, _vel.z) * step_time * 1.2
	var best := -1
	var best_d := reach
	for i in 2:
		if _step_t[i] >= 0.0:
			continue
		var other := 1 - i
		if _step_t[other] >= 0.0 and _step_t[other] < 0.55:
			continue                     # one foot at a time, overlapping when running
		var spot := _root + right * (STANCE if i == 1 else -STANCE) + lead
		var d := Vector2(_feet[i].x - spot.x, _feet[i].z - spot.z).length()
		# Sideways, the foot on the side it's going leads (a shuffle, no crossing).
		var leads := speed > 0.6 and (right * (1.0 if i == 1 else -1.0)).dot(_vel) > 0.0
		if d > best_d or (leads and d > reach * 0.7 and best < 0):
			best = i
			best_d = d
	if best >= 0:
		var spot2 := _root + right * (STANCE if best == 1 else -STANCE) + lead
		_step_from[best] = _feet[best]
		_step_to[best] = Vector3(spot2.x, 0, spot2.z)
		_step_t[best] = 0.0


func _lift(i: int) -> float:
	return sin(_step_t[i] * PI) * STEP_LIFT if _step_t[i] >= 0.0 else 0.0
