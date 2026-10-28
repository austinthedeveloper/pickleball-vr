## A person's body (ADR-018): a rigged model (Quaternius' Universal Base
## Characters, CC0) whose skeleton the Avatar poses each frame from the
## joints it already works out. Display only.
##
## The model stands in a T-pose facing +Z, 1.82 m tall, its bones' +Y
## running to their child. Each frame the Avatar says, per bone, where it
## goes: `orient` (a frame: forward and up, as the rest pose is turned to
## it), `aim` (swing the bone to point at a spot, keeping its twist), or
## nothing (it keeps its rest pose under its parent). `at` is where a bone
## lands with what's been said so far; `apply` writes the pose.
##
## The clothes are painted by a shader from each vertex's place in the
## T-pose (stored in its colour): a shirt between the waist and the collar
## out to the sleeves, shorts above the knees, socks and shoes.
class_name Body
extends Node3D

const DIR := "res://assets/people/"
const SKIN_SHADER := preload("res://view/body_skin.gdshader")
const HAIR_SHADER := preload("res://view/body_hair.gdshader")
## Hairstyles by look: [file, texture].
const HAIR_STYLES := {
	"buzzed": ["hair_buzzed", "hair_1"], "parted": ["hair_simpleparted", "hair_1"],
	"long": ["hair_long", "hair_2"], "buns": ["hair_buns", "hair_2"],
	"buzzed_f": ["hair_buzzedfemale", "hair_1"],
}
const FINGERS := ["index", "middle", "ring", "pinky"]
const COURT_BOX := AABB(Vector3(-12, -1, -16), Vector3(24, 5, 32))  ## where a player can be
const SHOE := Vector3(0.115, 0.095, 0.29)  ## width, height, length

var female := false
var dark := false                    ## the darker skin texture
var tint := Color.WHITE              ## times the skin texture (skin tones between)
var shirt := Color(0.95, 0.55, 0.12)
var shorts := Color(0.15, 0.18, 0.3)
var hair := Color(0.24, 0.15, 0.09)
var style := "parted"
var beard := false

var skel: Skeleton3D
var thigh_len := 0.43
var shin_len := 0.46
var upper_len := 0.25
var fore_len := 0.24
var ankle_h := 0.086                 ## the foot bone above the floor, standing

static var _meshes := {}             ## file -> the body mesh with T-pose places in COLOR

var _rest_local: Array[Transform3D] = []
var _rest_global: Array[Transform3D] = []
var _parent := PackedInt32Array()
var _order := PackedInt32Array()     ## parents before children
var _want: Array = []                ## per bone: null, [0, Basis, origin or null] (orient), [1, Vector3] (aim)
var _g: Array[Transform3D] = []
var _done := PackedByteArray()
var _curl := PackedFloat32Array()    ## per hand (l, r): how far the fingers close


func _ready() -> void:
	top_level = true                 # posed in world space
	global_transform = Transform3D.IDENTITY
	var file := "female" if female else "male"
	var model: Node3D = (load(DIR + file + ".gltf") as PackedScene).instantiate()
	add_child(model)
	skel = model.find_children("*", "Skeleton3D", true, false)[0]
	var n := skel.get_bone_count()
	_rest_local.resize(n)
	_rest_global.resize(n)
	_g.resize(n)
	_want.resize(n)
	_done.resize(n)
	_parent.resize(n)
	for i in n:
		_rest_local[i] = skel.get_bone_rest(i)
		_rest_global[i] = skel.get_bone_global_rest(i)
		_parent[i] = skel.get_bone_parent(i)
	var depth := []
	for i in n:
		var d := 0
		var p := _parent[i]
		while p >= 0:
			d += 1
			p = _parent[p]
		depth.append([d, i])
	depth.sort()
	for e in depth:
		_order.append(e[1])
	thigh_len = _rest_local[_bone("calf_l")].origin.length()
	shin_len = _rest_local[_bone("foot_l")].origin.length()
	upper_len = _rest_local[_bone("lowerarm_r")].origin.length()
	fore_len = _rest_local[_bone("hand_r")].origin.length()
	ankle_h = _rest_global[_bone("foot_l")].origin.y
	_curl.resize(2)
	_dress(model, file)
	_add_hair(HAIR_STYLES[style][0], HAIR_STYLES[style][1])
	if beard:
		_add_hair("hair_beard", "hair_1")
	for side in ["_l", "_r"]:
		_add_shoe(side)


func _bone(name: String) -> int:
	return skel.find_bone(name)


## The skin and clothes, the eyes, the brows.
func _dress(model: Node, file: String) -> void:
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mi.custom_aabb = COURT_BOX     # its own box is the T-pose's, at the origin
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mi.name == "Eyes":
			var em := StandardMaterial3D.new()
			em.albedo_texture = load(DIR + "eye.png")
			em.roughness = 0.2
			mi.material_override = em
		elif mi.name == "Eyebrows":
			mi.material_override = _hair_mat("hair_1")
		else:
			mi.mesh = _marked(file, mi.mesh)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			var m := ShaderMaterial.new()
			m.shader = SKIN_SHADER
			m.set_shader_parameter("skin_tex", load(DIR + "%s_%s.png" % [file, "dark" if dark else "light"]))
			m.set_shader_parameter("normal_tex", load(DIR + file + "_normal.png"))
			m.set_shader_parameter("tint", tint)
			m.set_shader_parameter("shirt", shirt)
			m.set_shader_parameter("shorts", shorts)
			var box := mi.mesh.get_aabb()
			m.set_shader_parameter("box_pos", box.position)
			m.set_shader_parameter("box_size", box.size)
			m.set_shader_parameter("female", female)
			mi.material_override = m


## The body mesh with each vertex's T-pose place in its colour (0..1 of the
## box), for the clothes; made once per model.
static func _marked(file: String, mesh: Mesh) -> Mesh:
	if _meshes.has(file):
		return _meshes[file]
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var box := mesh.get_aabb()
	var cols := PackedColorArray()
	cols.resize(verts.size())
	for i in verts.size():
		var q := (verts[i] - box.position) / box.size
		cols[i] = Color(q.x, q.y, q.z)
	arrays[Mesh.ARRAY_COLOR] = cols
	for c in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3]:
		arrays[c] = null
	var out := ArrayMesh.new()
	var flags := 0
	if (arrays[Mesh.ARRAY_BONES] as PackedInt32Array).size() == verts.size() * 8:
		flags = Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
	_meshes[file] = out
	return out


func _hair_mat(tex: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = HAIR_SHADER
	m.set_shader_parameter("hair_tex", load(DIR + tex + ".png"))
	m.set_shader_parameter("hair", hair)
	return m


## A hairstyle, skinned to the head: its mesh moves onto this skeleton.
func _add_hair(file: String, tex: String) -> void:
	var src: Node = (load(DIR + file + ".gltf") as PackedScene).instantiate()
	for mi: MeshInstance3D in src.find_children("*", "MeshInstance3D", true, false):
		var copy := MeshInstance3D.new()
		copy.mesh = mi.mesh
		copy.skin = mi.skin
		copy.custom_aabb = COURT_BOX
		copy.material_override = _hair_mat(tex)
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		skel.add_child(copy)
		copy.skeleton = copy.get_path_to(skel)
	src.free()


## A trainer on a foot bone: placed as it would sit on the T-pose's foot.
func _add_shoe(side: String) -> void:
	var on := BoneAttachment3D.new()
	on.bone_name = "foot" + side
	skel.add_child(on)
	var x := _rest_global[_bone("foot" + side)].origin.x
	var upper := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = SHOE.x / 2
	m.height = SHOE.z
	upper.mesh = m
	upper.material_override = _shoe_mat(Color(0.94, 0.94, 0.95), 0.6)
	var sole := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(SHOE.x + 0.006, 0.022, SHOE.z - 0.02)
	sole.mesh = b
	sole.material_override = _shoe_mat(Color(0.3, 0.3, 0.32), 0.9)
	var inv := _rest_global[_bone("foot" + side)].affine_inverse()
	# The capsule lies along z, squashed to a shoe's height.
	upper.transform = inv * Transform3D(Basis(Vector3.RIGHT, PI / 2).scaled_local(Vector3(1, 1, SHOE.y / SHOE.x)), Vector3(x, 0.05, 0.035))
	sole.transform = inv * Transform3D(Basis.IDENTITY, Vector3(x, 0.011, 0.035))
	on.add_child(upper)
	on.add_child(sole)


static func _shoe_mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := World.material(c)
	m.roughness = rough
	return m


# --- Posing -------------------------------------------------------------------------

## Starts a frame's pose: every bone back to following its parent at rest.
func begin() -> void:
	_want.fill(null)
	_done.fill(0)
	_curl.fill(0.0)


## The bone turned to face `forward` with `up` up (as the T-pose faces +Z,
## +Y up); at `origin` if given, else where its parent puts it.
func orient(bone: String, forward: Vector3, up: Vector3, origin: Variant = null) -> void:
	var i := _bone(bone)
	_want[i] = [0, frame(forward, up), origin]
	_done[i] = 0                     # `at` may have placed it at rest already


## The bone swung to point at `target`, keeping its twist.
func aim(bone: String, target: Vector3) -> void:
	var i := _bone(bone)
	_want[i] = [1, target]
	_done[i] = 0


## Closes a hand's fingers (0 open .. 1 a fist); `side` 0 left, 1 right.
func curl(side: int, amount: float) -> void:
	_curl[side] = amount


## The turn from the T-pose's facing to `forward` and `up`.
static func frame(forward: Vector3, up: Vector3) -> Basis:
	var f := (forward - up * forward.dot(up)).normalized()
	return Basis(up.cross(f), up, f).orthonormalized()


## Where a bone lands (world), with what's been said this frame.
func at(bone: String) -> Vector3:
	return _global(_bone(bone)).origin


func _global(i: int) -> Transform3D:
	if _done[i]:
		return _g[i]
	var p := _parent[i]
	var g: Transform3D = (_global(p) if p >= 0 else Transform3D.IDENTITY) * _rest_local[i]
	var w = _want[i]
	if w != null:
		if w[0] == 0:
			g.basis = (w[1] as Basis) * _rest_global[i].basis
			if w[2] != null:
				g.origin = w[2]
		else:
			var to: Vector3 = (w[1] as Vector3) - g.origin
			var y := g.basis.y.normalized()
			if to.length() > 0.001:
				to = to.normalized()
				var axis := y.cross(to)
				var ang := y.angle_to(to)
				if axis.length() > 0.0001:
					g.basis = Basis(axis.normalized(), ang) * g.basis
	_g[i] = g
	_done[i] = 1
	return g


## Writes the frame's pose to the skeleton.
func apply() -> void:
	for side in 2:
		if _curl[side] <= 0.0:
			continue
		var s := "_l" if side == 0 else "_r"
		for f in FINGERS:
			for k in 3:
				var i := _bone("%s_0%d%s" % [f, k + 1, s])
				_want[i] = [2, _curl[side] * (1.1 if k == 0 else 1.4)]
		for k in 2:
			_want[_bone("thumb_0%d%s" % [k + 2, s])] = [2, _curl[side] * 0.6]
	for i in _order:
		var w = _want[i]
		if w != null and w[0] == 2:          # a finger: bent about its own x
			var p := _parent[i]
			var pg := _global(p)
			var g := pg * _rest_local[i]
			g.basis = g.basis * Basis(Vector3.RIGHT, w[1])
			_g[i] = g
			_done[i] = 1
		var gi := _global(i)
		var local := gi if _parent[i] < 0 else _global(_parent[i]).affine_inverse() * gi
		skel.set_bone_pose_position(i, local.origin)
		skel.set_bone_pose_rotation(i, local.basis.get_rotation_quaternion())
