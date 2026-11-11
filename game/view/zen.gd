## ZEN (ADR-031): past FOCUS's darkness, a long rally goes deeper. Two
## stages grow from the same count FOCUS uses (a match's shots, a practice
## streak doubled):
##
## - HUSH: the world's sound (ambience, crowd) fades and muffles, a low
##   drone comes in, and each hit rings a soft note of a pentatonic scale:
##   yours an octave above the other side's, so the rally makes a melody.
## - DRIFT: the venue dissolves into a deep blue void (fog past the court),
##   motes of light hang in it, each bounce sends a ring of light over the
##   court, the lines glow, and the ball leaves a glowing trail.
##
## When a deep rally ends, a low bell, and the world comes back over a
## few seconds. Display and sound only: the sim never hears of it. Never
## in the lobby, and the court and the floor stay solid (comfort).
class_name Zen
extends Node3D

## Where each stage starts and how many shots it takes to fill, in the
## shots FOCUS counts (practice: twice the streak). Tunable (ZEN page).
static var HUSH_AT := 30             ## 15 in a row
static var HUSH_SPAN := 10           ## ...full at 20
static var DRIFT_AT := 40            ## 20 in a row
static var DRIFT_SPAN := 20          ## ...full at 30
static var DRONE_PCT := 35           ## the drone's level at full HUSH
static var TONE_PCT := 70            ## a hit's note at full HUSH
static var HIT_CUT_DB := 12          ## how far the hits' and bounces' own sound drops
const EASE_IN := 0.5                 ## per second: about 2 s in
const EASE_OUT := 0.35               ## ...about 3 s back, the exhale
const BELL_AFTER := 0.3              ## a rally this deep gets the bell when it ends
const CUTOFF_TOP := 20000.0          ## Hz: the world's sound unmuffled
const CUTOFF_LOW := 350.0            ## ...under full HUSH
const BUS := "ZenWorld"              ## the ambience and the crowd go through it
## The major pentatonic in semitones from A, over two octaves: any walk
## through it sounds calm.
const SCALE := [-12, -10, -8, -5, -3, 0, 2, 4, 7, 9]
const VOID := Color(0.035, 0.07, 0.17)   ## the void: deep night blue
const VOID_BEGIN := 13.0             ## m: fog starts past the court and its players
const VOID_END := 30.0               ## ...and is solid here
const RIPPLES := 6
const RIPPLE_R := 2.6                ## m: how far a bounce's ring spreads
const RIPPLE_S := 2.2                ## s: ...and how long it takes
const MOTES := 260

var hush := 0.0
var drift := 0.0
var world: World
var passthrough := false
var forced := -1.0                   ## screenshots: hold both stages here (0..1)
var _drone: AudioStreamPlayer
var _tone: AudioStreamPlayer3D
var _bell: AudioStreamPlayer
var _note := 5                       ## where the melody is in SCALE
var _rng := RandomNumberGenerator.new()   ## the melody's walk: display only
var _deep := false                   ## this rally went deep enough for the bell
var _ripples: Array[MeshInstance3D] = []
var _ripple_age: Array[float] = []
var _next_ripple := 0
var _motes: GPUParticles3D
var _mote_mat: StandardMaterial3D
var _lowpass: AudioEffectLowPassFilter
var _audible := DisplayServer.get_name() != "headless"
var bells := 0                       ## tests: how many exhales rang


## How deep each stage is at a rally of `shots` (FOCUS's count), 0..1.
static func hush_of(shots: int) -> float:
	return clampf(float(shots - HUSH_AT) / maxf(HUSH_SPAN, 1), 0.0, 1.0)


static func drift_of(shots: int) -> float:
	return clampf(float(shots - DRIFT_AT) / maxf(DRIFT_SPAN, 1), 0.0, 1.0)


## The world's sound runs through one bus whose filter HUSH closes.
static func bus() -> int:
	var i := AudioServer.get_bus_index(BUS)
	if i < 0:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, BUS)
		AudioServer.set_bus_send(i, "Master")
		AudioServer.add_bus_effect(i, AudioEffectLowPassFilter.new())
	return i


func _ready() -> void:
	_rng.seed = 94
	_lowpass = AudioServer.get_bus_effect(bus(), 0) as AudioEffectLowPassFilter
	_drone = AudioStreamPlayer.new()
	var d: AudioStreamWAV = load("res://assets/audio/zen_drone.wav")
	d.loop_mode = AudioStreamWAV.LOOP_FORWARD
	d.loop_begin = 0
	d.loop_end = int(d.get_length() * d.mix_rate)
	_drone.stream = d
	add_child(_drone)
	_tone = AudioStreamPlayer3D.new()
	_tone.stream = load("res://assets/audio/zen_tone.wav")
	_tone.max_polyphony = 4
	_tone.unit_size = 8.0
	add_child(_tone)
	_bell = AudioStreamPlayer.new()
	_bell.stream = load("res://assets/audio/zen_bell.wav")
	add_child(_bell)
	_build_ripples()
	_build_motes()
	_apply()


## Each frame, from the rally as FOCUS counts it.
func update(shots: int, delta: float) -> void:
	var want_h := hush_of(shots)
	var want_d := drift_of(shots)
	if forced >= 0.0:
		want_h = forced
		want_d = forced
	if want_h > 0.0:
		_deep = _deep or hush >= BELL_AFTER
	elif _deep:
		_deep = false
		bells += 1
		if _audible:
			_bell.play()                 # the exhale
	var was_h := hush
	var was_d := drift
	hush = move_toward(hush, want_h, (EASE_IN if want_h > hush else EASE_OUT) * delta)
	drift = move_toward(drift, want_d, (EASE_IN if want_d > drift else EASE_OUT) * delta)
	if forced >= 0.0:
		hush = forced
		drift = forced
	if hush != was_h or drift != was_d:
		_apply()
	_age_ripples(delta)


## Under HUSH, how much quieter the hits' and bounces' own sound is (dB).
func hit_cut() -> float:
	return -HIT_CUT_DB * hush


## The announcer keeps quiet about the count once HUSH is in.
func quiet() -> bool:
	return hush > 0.3


## A hit under HUSH rings a note: the melody steps through the scale, your
## notes an octave above the other side's.
func on_hit(at: Vector3, mine: bool) -> void:
	if hush <= 0.02:
		return
	var steps := [-2, -1, 1, 2]
	_note = clampi(_note + int(steps[_rng.randi() % steps.size()]), 0, SCALE.size() - 1)
	var semis: int = SCALE[_note] + (12 if mine else 0)
	_tone.global_position = at
	_tone.pitch_scale = pow(2.0, semis / 12.0)
	_tone.volume_db = linear_to_db(TONE_PCT / 100.0 * hush)
	if _audible:
		_tone.play()


## A bounce under DRIFT sends a ring of light over the court.
func on_bounce(at: Vector3) -> void:
	if drift <= 0.02:
		return
	ripple(at, 0.0)


func ripple(at: Vector3, age: float) -> void:
	var i := _next_ripple
	_next_ripple = (_next_ripple + 1) % RIPPLES
	_ripples[i].position = Vector3(at.x, 0.02, at.z)
	_ripple_age[i] = age
	_ripples[i].visible = true
	_age_ripples(0.0)


## The trail shows at any speed under DRIFT, brighter.
func trail_glow() -> float:
	return drift


func _apply() -> void:
	# HUSH: the world's sound muffles and fades; the drone comes in.
	var b := bus()
	AudioServer.set_bus_volume_db(b, linear_to_db(maxf(1.0 - 0.85 * hush, 0.001)))
	if _lowpass:
		_lowpass.cutoff_hz = CUTOFF_TOP * pow(CUTOFF_LOW / CUTOFF_TOP, hush)
	_drone.volume_db = linear_to_db(maxf(DRONE_PCT / 100.0 * hush, 0.0001))
	if hush > 0.0 and not _drone.playing and _audible:
		_drone.play()
	elif hush <= 0.0 and _drone.playing:
		_drone.stop()
	# DRIFT: the void past the court, the motes, the glowing lines.
	if world and not passthrough:
		world.set_drift(drift, VOID, VOID_BEGIN, VOID_END)
	elif world:
		world.set_drift(drift, VOID, VOID_BEGIN, VOID_END, false)
	_motes.visible = drift > 0.01
	_motes.emitting = drift > 0.01
	_mote_mat.albedo_color = Color(0.55, 0.85, 1.0, 0.75 * drift)


func drone_on() -> bool:
	return hush > 0.0


func _build_ripples() -> void:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform float t = 0.0;
uniform float strength = 1.0;
uniform vec3 tint = vec3(0.45, 0.85, 1.0);
void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float ring = smoothstep(0.08, 0.0, abs(r - t)) + 0.35 * smoothstep(0.16, 0.0, abs(r - t * 0.7));
	float a = ring * (1.0 - t) * strength * step(r, 1.0);
	ALBEDO = tint * a * 1.8;
	ALPHA = a;
}
"""
	for i in RIPPLES:
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(RIPPLE_R * 2, RIPPLE_R * 2)
		mi.mesh = pm
		var m := ShaderMaterial.new()
		m.shader = sh
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_ripples.append(mi)
		_ripple_age.append(RIPPLE_S)


func _age_ripples(delta: float) -> void:
	for i in RIPPLES:
		if not _ripples[i].visible:
			continue
		_ripple_age[i] += delta
		var t := _ripple_age[i] / RIPPLE_S
		if t >= 1.0:
			_ripples[i].visible = false
			continue
		var m := _ripples[i].material_override as ShaderMaterial
		m.set_shader_parameter("t", 1.0 - pow(1.0 - t, 2.0))   # fast, then slowing
		m.set_shader_parameter("strength", drift)


## Motes of light hanging in the void, rising very slowly: sparse, far
## from your eyes, all moving alike (no sense of the floor moving).
func _build_motes() -> void:
	_motes = GPUParticles3D.new()
	_motes.amount = MOTES
	_motes.lifetime = 10.0
	_motes.preprocess = 10.0
	_motes.visibility_aabb = AABB(Vector3(-22, -1, -22), Vector3(44, 10, 44))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 18.0
	pm.emission_ring_inner_radius = 6.0
	pm.emission_ring_height = 5.0
	pm.direction = Vector3.UP
	pm.spread = 15.0
	pm.initial_velocity_min = 0.03
	pm.initial_velocity_max = 0.08
	pm.gravity = Vector3.ZERO
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	_motes.process_material = pm
	_motes.position = Vector3(0, 2.6, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	_mote_mat = StandardMaterial3D.new()
	_mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mote_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mote_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mote_mat.vertex_color_use_as_albedo = true
	_mote_mat.disable_fog = true
	q.material = _mote_mat
	_motes.draw_pass_1 = q
	_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_motes.visible = false
	_motes.emitting = false
	add_child(_motes)
