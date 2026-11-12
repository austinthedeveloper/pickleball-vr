## Critters (VR-101, canon bible 5.6): now and then, between points, one
## crosses the sky: a gull at LAKESIDE, a pterosaur at DINOSAUR, a satellite
## in SPACE, a fish UNDERSEA. Never during a rally: one under way fades out
## as the ball goes live (FOCUS's rule, ADR-013). Far off and slow, so
## nothing near you moves. Display only: the view's own generator, never
## the sim's; the sim never hears of it.
class_name Critters
extends Node3D

const GULL := "gull"
const PTEROSAUR := "pterosaur"
const SATELLITE := "satellite"
const FISH := "fish"
const EVERY := [20.0, 45.0]          ## s between crossings
const FADE := 0.6                    ## s to fade out when a rally starts
const SIZE := {"gull": 3.0, "pterosaur": 1.8, "satellite": 4.0, "fish": 2.2}

var kind := ""                       ## this venue's, or "" (none)
var flying: Node3D                   ## the one crossing now, or null
var crossings := 0                   ## tests: how many have set off
var wait := 0.0                      ## s till the next may set off
var _rng := RandomNumberGenerator.new()
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0                        ## 0..1 along the crossing
var _secs := 10.0
var _fade := 1.0
var _parts: Array[MeshInstance3D] = []   ## wings or the tail: they flap
var _mats: Array[StandardMaterial3D] = []


## The critter for `venue` at `time`, or "": birds keep to the day.
static func for_venue(venue: int, time: int) -> String:
	match venue:
		Venues.LAKESIDE: return GULL if time != World.NIGHT else ""
		Venues.DINOSAUR: return PTEROSAUR if time != World.NIGHT else ""
		Venues.SPACE: return SATELLITE
		Venues.UNDERSEA: return FISH
	return ""


func _ready() -> void:
	_rng.seed = 1994
	wait = _rng.randf_range(EVERY[0] * 0.5, EVERY[1] * 0.5)


## Between points? (A match between serves, a drill between feeds.)
static func between_points(sim: Sim) -> bool:
	if sim.breakout:
		return false
	if sim.drill:
		return sim.drill.stage == Drill.WAIT or sim.drill.stage == Drill.SETUP or sim.drill.stage == Drill.DONE
	return sim.phase != K.PHASE_LIVE and sim.phase != K.PHASE_TOSS


func update(sim: Sim, delta: float) -> void:
	if kind == "":
		return
	var calm := between_points(sim)
	if flying == null:
		wait -= delta
		if wait <= 0.0 and calm:
			launch()
		return
	if not calm:
		_fade = maxf(_fade - delta / FADE, 0.0)   # a rally: away it goes
	_t += delta / _secs
	if _t >= 1.0 or _fade <= 0.0:
		flying.queue_free()
		flying = null
		wait = _rng.randf_range(EVERY[0], EVERY[1])
		return
	var at := _from.lerp(_to, _t)
	if kind == FISH or kind == GULL:
		at.y += sin(_t * TAU * 1.5) * 0.6        # a little rise and fall
	flying.global_position = at
	var flap := sin(_t * _secs * (9.0 if kind == GULL else (4.0 if kind == PTEROSAUR else 6.0)))
	for p in _parts:
		match kind:
			FISH: p.rotation.y = flap * 0.5
			SATELLITE: pass
			_: p.rotation.z = flap * 0.6 * signf(p.position.x)
	for m in _mats:
		m.albedo_color.a = _fade


## Sends one across now (tests, and the timer).
func launch() -> void:
	if kind == "":
		return
	crossings += 1
	_t = 0.0
	_fade = 1.0
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	var y := _rng.randf_range(14.0, 22.0)
	var z := _rng.randf_range(-40.0, -24.0)
	_secs = _rng.randf_range(9.0, 13.0)
	match kind:
		FISH:
			y = _rng.randf_range(2.6, 4.5)
			z = _rng.randf_range(-15.0, -12.0)    # inside the kelp, past the far fence
			_secs = _rng.randf_range(12.0, 16.0)
		SATELLITE:
			y = _rng.randf_range(30.0, 45.0)
			z = _rng.randf_range(-70.0, -50.0)
			_secs = _rng.randf_range(16.0, 22.0)
	_from = Vector3(-45.0 * side, y, z)
	_to = Vector3(45.0 * side, y + _rng.randf_range(-3.0, 3.0), z + _rng.randf_range(-6.0, 6.0))
	flying = _build()
	add_child(flying)
	flying.look_at_from_position(_from, _to, Vector3.UP)
	flying.scale = Vector3.ONE * SIZE[kind]   # storybook size: far off, it still reads


func _build() -> Node3D:
	_parts = []
	_mats = []
	var n := Node3D.new()
	match kind:
		GULL:
			_part(n, Vector3.ZERO, Vector3(0.18, 0.16, 0.55), Color(0.95, 0.95, 0.95), false)
			for s in [-1.0, 1.0]:
				_part(n, Vector3(s * 0.45, 0.04, 0), Vector3(0.8, 0.04, 0.22), Color(0.82, 0.84, 0.86), true)
		PTEROSAUR:
			_part(n, Vector3.ZERO, Vector3(0.35, 0.3, 1.3), Color(0.5, 0.36, 0.26), false)
			_part(n, Vector3(0, 0.2, -0.9), Vector3(0.12, 0.35, 0.6), Color(0.55, 0.4, 0.3), false)   # the crest
			for s in [-1.0, 1.0]:
				_part(n, Vector3(s * 1.4, 0.05, 0.1), Vector3(2.6, 0.05, 0.8), Color(0.45, 0.32, 0.24), true)
		SATELLITE:
			_part(n, Vector3.ZERO, Vector3(0.8, 0.8, 1.2), Color(0.8, 0.78, 0.7), false)
			for s in [-1.0, 1.0]:
				var p := _part(n, Vector3(s * 1.8, 0, 0), Vector3(2.4, 0.05, 1.0), Color(0.2, 0.3, 0.7), false)
				(p.material_override as StandardMaterial3D).metallic = 0.6
			var light := _part(n, Vector3(0, 0.55, 0), Vector3(0.12, 0.12, 0.12), Color(1, 0.3, 0.2), false)
			var lm := light.material_override as StandardMaterial3D
			lm.emission_enabled = true
			lm.emission = Color(1, 0.3, 0.2)
			lm.emission_energy_multiplier = 3.0
		FISH:
			_part(n, Vector3.ZERO, Vector3(0.25, 0.4, 0.9), Color(1.0, 0.55, 0.15), false)
			_part(n, Vector3(0, 0, 0.6), Vector3(0.05, 0.45, 0.35), Color(1.0, 0.75, 0.3), true)   # the tail
	return n


func _part(parent: Node3D, at: Vector3, size: Vector3, c: Color, moves: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 10
	sm.rings = 5
	mi.mesh = sm
	mi.scale = size
	mi.position = at
	var m := World.material(c)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA   # so it can fade
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mats.append(m)
	parent.add_child(mi)
	if moves:
		_parts.append(mi)
	return mi
