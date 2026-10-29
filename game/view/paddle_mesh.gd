## A paddle: a handle along +z, the face above it along -z, the face's
## normal along +x (the grip pose's palm axis, ADR-003). The face's centre
## is at FACE_CENTER. A rounded face with an edge guard, a wrapped grip and
## an end cap (ADR-012); the sim's contact disc is unchanged.
class_name PaddleMesh
extends Node3D

const FACE_CENTER := Vector3(0, 0, -0.2)
const FACE_W := 0.198                ## 7.8 in
const FACE_H := 0.26
const FACE_T := 0.013
const CORNER := 0.05
const HANDLE := 0.13

var color := Color(0.85, 0.15, 0.2)
var accent := Color(0.98, 0.95, 0.9)
var skin := ""                       ## a prank's silly paddle (Pranks.PADDLES), "" the real one
var _skin: Node3D


func _ready() -> void:
	# The faces: raw carbon with the paddle's graphic (face_texture); the
	# core's edge under the guard.
	var face := MeshInstance3D.new()
	face.mesh = _rounded_slab(FACE_W, FACE_H, FACE_T, CORNER)
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = face_texture(color, accent)
	fm.roughness = 0.38
	fm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	face.set_surface_override_material(0, fm)
	face.set_surface_override_material(1, _mat(Color(0.1, 0.1, 0.11), 0.6))
	face.position = FACE_CENTER
	add_child(face)
	var guard := MeshInstance3D.new()
	guard.mesh = _rounded_ring(FACE_W + 0.006, FACE_H + 0.006, FACE_T + 0.006, CORNER + 0.003, 0.007)
	guard.material_override = _mat(Color(0.1, 0.1, 0.11), 0.4)
	guard.position = FACE_CENTER
	add_child(guard)
	# The grip: a wrapped handle from the face's base to the end cap.
	var grip := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0155
	cm.bottom_radius = 0.017
	cm.height = HANDLE
	cm.radial_segments = 12
	grip.mesh = cm
	var gm := StandardMaterial3D.new()
	gm.albedo_texture = _grip_texture()
	gm.roughness = 0.95
	grip.material_override = gm
	grip.rotation.x = PI / 2
	grip.position = Vector3(0, 0, FACE_CENTER.z + FACE_H / 2 + HANDLE / 2 - 0.01)
	add_child(grip)
	var cap := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.019
	sm.height = 0.022
	cap.mesh = sm
	cap.material_override = _mat(color.darkened(0.3), 0.5)
	cap.position = grip.position + Vector3(0, 0, HANDLE / 2)
	add_child(cap)


## A prank's silly paddle in place of this one (ADR-025); "" puts it back.
## Only the look: the sim's paddle stays the same.
func set_skin(kind: String) -> void:
	skin = kind
	if _skin:
		_skin.free()
		_skin = null
	for c in get_children():
		(c as Node3D).visible = kind == ""
	if kind != "":
		_skin = Pranks.paddle_skin(kind)
		add_child(_skin)


static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := World.material(c)
	m.roughness = rough
	return m


## The rounded rectangle's outline in the face's plane (y across, z along),
## counter-clockwise.
static func _outline(w: float, h: float, r: float, seg := 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cx := w / 2 - r
	var cz := h / 2 - r
	for corner in [[cx, cz, 0.0], [-cx, cz, PI / 2], [-cx, -cz, PI], [cx, -cz, 1.5 * PI]]:
		for i in seg + 1:
			var a: float = corner[2] + PI / 2 * i / seg
			pts.append(Vector2(corner[0] + cos(a) * r, corner[1] + sin(a) * r))
	return pts


## A slab of thickness t (along x) with that outline: surface 0 the two
## faces (UV across the face, v down toward the handle, the back face
## mirrored so its graphic reads the same way round), surface 1 the rim.
static func _rounded_slab(w: float, h: float, t: float, r: float) -> ArrayMesh:
	var o := _outline(w, h, r)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := o.size()
	for side in [-1.0, 1.0]:
		st.set_normal(Vector3(side, 0, 0))
		for i in n:
			var a := o[i]
			var b := o[(i + 1) % n]
			var verts := [Vector3(side * t / 2, 0, 0), Vector3(side * t / 2, a.x, a.y), Vector3(side * t / 2, b.x, b.y)]
			if side < 0:
				verts = [verts[0], verts[2], verts[1]]
			for v in verts:
				st.set_uv(Vector2(0.5 + side * v.y / w, 0.5 + v.z / h))
				st.add_vertex(v)
	var mesh := st.commit()
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:                          # the rim
		var a := o[i]
		var b := o[(i + 1) % n]
		var nrm := Vector3(0, (a.x + b.x) / 2, (a.y + b.y) / 2).normalized()
		st.set_normal(nrm)
		for v in [Vector3(-t / 2, a.x, a.y), Vector3(t / 2, a.x, a.y), Vector3(t / 2, b.x, b.y),
				Vector3(-t / 2, a.x, a.y), Vector3(t / 2, b.x, b.y), Vector3(-t / 2, b.x, b.y)]:
			st.add_vertex(v)
	return st.commit(mesh)


static var _faces := {}              ## color+accent -> its face texture, made once
static var _grip: ImageTexture


## The face: raw carbon (a 2x2 twill), and the paddle's own colour
## sweeping up from the throat on a diagonal, edged with the accent, with
## a small "94" in the corner.
static func face_texture(c: Color, acc: Color) -> ImageTexture:
	var key := c.to_html() + acc.to_html()
	if _faces.has(key):
		return _faces[key]
	const W := 128
	const H := 168
	var img := Image.create(W, H, false, Image.FORMAT_RGB8)
	var dark := Color(0.07, 0.075, 0.08)
	var light := Color(0.15, 0.155, 0.165)
	for y in H:
		for x in W:
			# Twill: tows over two, under two, stepping one each row.
			var over := ((x / 3 + y / 3) % 4) < 2
			var px := dark if over else light
			# The colour panel: below a line rising from left to right.
			var edge := H * 0.62 - x * 0.42
			if y > edge + 3:
				px = c.lerp(c.darkened(0.35), float(y - edge) / H)
			elif y > edge:
				px = acc
			img.set_pixel(x, y, px)
	_digits(img, "94", Vector2i(W - 34, 14), acc)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_faces[key] = tex
	return tex


## Two digits in a chunky 3x5 pixel face, each pixel 4 px square.
static func _digits(img: Image, text: String, at: Vector2i, c: Color) -> void:
	const GLYPHS := {"9": ["111", "101", "111", "001", "111"], "4": ["101", "101", "111", "001", "001"]}
	for k in text.length():
		var g: Array = GLYPHS[text[k]]
		for row in 5:
			for col in 3:
				if String(g[row])[col] == "1":
					img.fill_rect(Rect2i(at.x + k * 16 + col * 4, at.y + row * 4, 4, 4), c)


## The grip: black overgrip wound in a spiral, its seams lighter.
static func _grip_texture() -> ImageTexture:
	if _grip:
		return _grip
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var seam := posmod(x + y, 16) < 2
			var dot := posmod(x, 4) == 0 and posmod(y, 4) == 0
			img.set_pixel(x, y, Color(0.2, 0.2, 0.21) if seam else (Color(0.08, 0.08, 0.085) if dot else Color(0.12, 0.12, 0.125)))
	img.generate_mipmaps()
	_grip = ImageTexture.create_from_image(img)
	return _grip


## The edge guard: a band `band` wide around the outline.
static func _rounded_ring(w: float, h: float, t: float, r: float, band: float) -> ArrayMesh:
	var outer := _outline(w, h, r)
	var inner := _outline(w - band * 2, h - band * 2, maxf(r - band, 0.005))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := outer.size()
	for i in n:
		var a := outer[i]
		var b := outer[(i + 1) % n]
		var c := inner[(i + 1) % n]
		var d := inner[i]
		var nrm := Vector3(0, (a.x + b.x) / 2, (a.y + b.y) / 2).normalized()
		st.set_normal(nrm)
		for v in [Vector3(-t / 2, a.x, a.y), Vector3(t / 2, a.x, a.y), Vector3(t / 2, b.x, b.y),
				Vector3(-t / 2, a.x, a.y), Vector3(t / 2, b.x, b.y), Vector3(-t / 2, b.x, b.y)]:
			st.add_vertex(v)
		for side in [-1.0, 1.0]:
			st.set_normal(Vector3(side, 0, 0))
			var q := [Vector3(side * t / 2, a.x, a.y), Vector3(side * t / 2, b.x, b.y), Vector3(side * t / 2, c.x, c.y),
				Vector3(side * t / 2, a.x, a.y), Vector3(side * t / 2, c.x, c.y), Vector3(side * t / 2, d.x, d.y)]
			if side < 0:
				q = [q[0], q[2], q[1], q[3], q[5], q[4]]
			for v in q:
				st.add_vertex(v)
	return st.commit()


## The paddle placed so its face centre is at `center` with normal `n`
## (the handle hangs below the face).
func pose(center: Vector3, n: Vector3) -> void:
	var x := n.normalized()
	var up := Vector3.UP
	if absf(x.dot(up)) > 0.95:
		up = Vector3.FORWARD
	# -z (handle to face) points up as far as the normal allows.
	var nz := -(up - x * x.dot(up)).normalized()
	var y := nz.cross(x)
	var b := Basis(x, y, nz)
	transform = Transform3D(b, center - b * FACE_CENTER)


## The paddle held at `hand` (the grip's middle), pointing along `along`
## (hand to face), its face turned toward `n` as far as `along` allows.
func pose_grip(hand: Vector3, along: Vector3, n: Vector3) -> void:
	var nz := -along.normalized()
	var x := n - nz * n.dot(nz)
	if x.length() < 0.01:
		x = nz.cross(Vector3.UP)
	x = x.normalized()
	var y := nz.cross(x)
	var b := Basis(x, y, nz)
	var grip_mid := Vector3(0, 0, FACE_CENTER.z + FACE_H / 2 + HANDLE / 2 - 0.01)
	transform = Transform3D(b, hand - b * grip_mid)
