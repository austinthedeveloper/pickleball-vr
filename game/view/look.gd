## Shared looks (ADR-012): the pickleball's material, made once.
class_name Look
extends RefCounted

const BALL := Color(0.9, 1.0, 0.16)

static var _ball: StandardMaterial3D


## A pickleball: optic yellow with its rings of holes, painted into a small
## equirectangular texture at load (no image files to ship).
static func ball_material() -> StandardMaterial3D:
	if _ball:
		return _ball
	var w := 128
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	img.fill(BALL)
	var hole := BALL.darkened(0.55)
	# Rings of holes at five latitudes (26 holes, like an outdoor ball).
	for ring in [[0.5, 10], [0.28, 6], [0.72, 6], [0.1, 2], [0.9, 2]]:
		var y := int(ring[0] * h)
		var n: int = ring[1]
		for k in n:
			var x := int((k + 0.5 * (ring[0] < 0.5 as int)) * w / n) % w
			var r := 3 if absf(ring[0] - 0.5) < 0.3 else 2
			for dy in range(-r, r + 1):
				for dx in range(-r * 2, r * 2 + 1):
					if dx * dx / 4.0 + dy * dy <= r * r:
						img.set_pixel(posmod(x + dx, w), clampi(y + dy, 0, h - 1), hole)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.albedo_color = Color(1, 1, 1)
	m.roughness = 0.6
	m.emission_enabled = true
	m.emission = Color(0.22, 0.25, 0.0)    # a touch of glow: easier to track
	_ball = m
	return m
