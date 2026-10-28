## A Body's shirt and shorts (ADR-018): cloth shells made from the body
## mesh itself. The part of the skin a garment covers is copied with its
## skin weights, smoothed until the muscles are gone (Taubin smoothing:
## it doesn't shrink), its edges cut straight (hem, sleeves, legs), and
## pushed out from the body, looser toward the hems. Made once per model
## and garment, when first needed. Display only.
class_name Cloth
extends RefCounted

const SHIRT := 0
const SHORTS := 1
const PASSES := 10
const LAMBDA := 0.55
const MU := -0.58
## Where they end on the T-pose, metres.
const SHIRT_HEM := 0.93
const SLEEVE := [0.37, 0.31]         ## male, female (her arms are shorter)
const SHORTS_TOP := 1.03
const SHORTS_HEM := 0.6

static var _made := {}               ## "file/part" -> ArrayMesh


## The garment for a model's body mesh, made once.
static func garment(file: String, female: bool, part: int, body: Mesh) -> ArrayMesh:
	var key := "%s/%d" % [file, part]
	if not _made.has(key):
		_made[key] = _build(body, female, part)
	return _made[key]


static func _collar(female: bool, ax: float, z: float) -> float:
	var neck := (1.465 if female else 1.51) - 0.05 * smoothstep(0.0, 0.1, z)
	return neck + 4.0 * pow(maxf(ax - 0.04, 0.0), 2.0)


static func _covers(female: bool, part: int, v: Vector3) -> bool:
	var ax := absf(v.x)
	if part == SHIRT:
		return v.y >= SHIRT_HEM and v.y < _collar(female, ax, v.z) and ax < SLEEVE[1 if female else 0]
	return v.y >= SHORTS_HEM and v.y < SHORTS_TOP and ax < 0.3


## How far the cloth stands off the skin there: snug at the shoulders and
## waistband, looser at the hems.
static func _ease(part: int, v: Vector3) -> float:
	if part == SHIRT:
		var ax := absf(v.x)
		return 0.014 + 0.022 * smoothstep(1.3, SHIRT_HEM, v.y) + 0.014 * smoothstep(0.24, 0.36, ax)
	return 0.012 + 0.03 * smoothstep(0.92, SHORTS_HEM, v.y)


static func _build(body: Mesh, female: bool, part: int) -> ArrayMesh:
	var arrays := body.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	# Weld the seams (a vertex per UV island) so the smoothing sees one surface.
	var group := PackedInt32Array()
	group.resize(verts.size())
	var by_pos := {}
	var pos := PackedVector3Array()
	for i in verts.size():
		var k := Vector3i((verts[i] * 10000.0).round())
		if not by_pos.has(k):
			by_pos[k] = pos.size()
			pos.append(verts[i])
		group[i] = by_pos[k]
	# The triangles it covers, and its vertices.
	var tris := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		if _covers(female, part, verts[idx[t]]) and _covers(female, part, verts[idx[t + 1]]) \
				and _covers(female, part, verts[idx[t + 2]]):
			tris.append_array([idx[t], idx[t + 1], idx[t + 2]])
	var edges := {}                  # group pair -> how many triangles share it
	var nbrs := {}                   # group -> its neighbours
	for t in range(0, tris.size(), 3):
		for e in 3:
			var a := group[tris[t + e]]
			var b := group[tris[t + (e + 1) % 3]]
			var key := Vector2i(mini(a, b), maxi(a, b))
			edges[key] = int(edges.get(key, 0)) + 1
			if not nbrs.has(a):
				nbrs[a] = {}
			if not nbrs.has(b):
				nbrs[b] = {}
			nbrs[a][b] = true
			nbrs[b][a] = true
	var edge_of := {}                # the garment's edges: group -> true
	for key: Vector2i in edges:
		if edges[key] == 1:
			edge_of[key.x] = true
			edge_of[key.y] = true
	# Smooth the inside; the edges stay put.
	var p := {}
	for g in nbrs:
		p[g] = pos[g]
	for k in PASSES * 2:
		var f := LAMBDA if k % 2 == 0 else MU
		var next := {}
		for g in nbrs:
			if edge_of.has(g):
				continue
			var avg := Vector3.ZERO
			for n in nbrs[g]:
				avg += p[n]
			avg /= (nbrs[g] as Dictionary).size()
			next[g] = p[g] + (avg - p[g]) * f
		for g in next:
			p[g] = next[g]
	# Straight edges: the hem level, the sleeves and legs square to the limb.
	for g in edge_of:
		var v: Vector3 = p[g]
		if part == SHIRT:
			if v.y < SHIRT_HEM + 0.06:
				v.y = SHIRT_HEM
			elif absf(v.x) > SLEEVE[1 if female else 0] - 0.06:
				v.x = signf(v.x) * SLEEVE[1 if female else 0]
		else:
			if v.y < SHORTS_HEM + 0.06:
				v.y = SHORTS_HEM
			elif v.y > SHORTS_TOP - 0.06:
				v.y = SHORTS_TOP
		p[g] = v
	# The collar: smoothed along itself, so the neckline is a clean curve.
	for k in 6:
		var next := {}
		for g in edge_of:
			var v: Vector3 = p[g]
			if part != SHIRT or v.y < SHIRT_HEM + 0.06 or absf(v.x) > SLEEVE[1 if female else 0] - 0.06:
				continue
			var avg := Vector3.ZERO
			var n := 0
			for o in nbrs[g]:
				if edge_of.has(o):
					avg += p[o]
					n += 1
			if n == 2:
				next[g] = v.lerp(avg / 2, 0.6)
		for g in next:
			p[g] = next[g]
	# Normals from the smoothed faces, then out from the body.
	var nrm := {}
	for g in nbrs:
		nrm[g] = Vector3.ZERO
	for t in range(0, tris.size(), 3):
		var a := group[tris[t]]
		var b := group[tris[t + 1]]
		var c := group[tris[t + 2]]
		var fn: Vector3 = (p[c] - p[a]).cross(p[b] - p[a])   # Godot's front faces wind clockwise
		nrm[a] += fn
		nrm[b] += fn
		nrm[c] += fn
	for g in nbrs:
		nrm[g] = (nrm[g] as Vector3).normalized()
		p[g] += nrm[g] * _ease(part, pos[g])
	# The garment's own arrays: its vertices, with the body's skin weights.
	var src_n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var per := bones.size() / verts.size()
	var remap := {}
	var o_v := PackedVector3Array()
	var o_n := PackedVector3Array()
	var o_uv := PackedVector2Array()
	var o_b := PackedInt32Array()
	var o_w := PackedFloat32Array()
	var o_i := PackedInt32Array()
	for i in tris:
		if not remap.has(i):
			remap[i] = o_v.size()
			var g := group[i]
			o_v.append(p[g])
			var n: Vector3 = nrm[g]
			o_n.append(n if n != Vector3.ZERO else src_n[i])
			o_uv.append(uvs[i])
			o_b.append_array(bones.slice(i * per, i * per + per))
			o_w.append_array(weights.slice(i * per, i * per + per))
		o_i.append(remap[i])
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = o_v
	out[Mesh.ARRAY_NORMAL] = o_n
	out[Mesh.ARRAY_TEX_UV] = o_uv
	out[Mesh.ARRAY_BONES] = o_b
	out[Mesh.ARRAY_WEIGHTS] = o_w
	out[Mesh.ARRAY_INDEX] = o_i
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out, [], {},
		Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if per == 8 else 0)
	return mesh
