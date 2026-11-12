## Lays screenshots out on one image, a grid of thumbnails (VR-105):
##   godot --headless --path game -s res://tools/contact_sheet.gd -- <out.png> <columns> <in.png>...
## In the order given, left to right then down; a missing one stays dark.
## shots.sh venues makes one: a row per venue, DAY DUSK NIGHT across.
extends SceneTree

const THUMB := Vector2i(426, 240)
const GAP := 6


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		print("usage: contact_sheet.gd -- <out.png> <columns> <in.png>...")
		quit(2)
		return
	var cols := maxi(int(args[1]), 1)
	var files := args.slice(2)
	var rows := (files.size() + cols - 1) / cols
	var sheet := Image.create(cols * (THUMB.x + GAP) + GAP, rows * (THUMB.y + GAP) + GAP, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.06, 0.07, 0.09))
	for i in files.size():
		var img := Image.load_from_file(files[i])
		if img == null or img.is_empty():
			continue
		img.convert(Image.FORMAT_RGB8)
		img.resize(THUMB.x, THUMB.y, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, THUMB), Vector2i(GAP + (i % cols) * (THUMB.x + GAP), GAP + (i / cols) * (THUMB.y + GAP)))
	sheet.save_png(args[0])
	print("  ", args[0], " (", files.size(), " shots, ", cols, " across)")
	quit()
