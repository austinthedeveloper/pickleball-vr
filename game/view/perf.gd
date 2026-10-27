## Frame timing for debug builds (ADR-009): where the CPU's time goes each
## frame, summed by section and printed every couple of seconds (on the
## Quest it lands in logcat under the "godot" tag: `adb logcat -s godot`).
## Release builds skip it all.
class_name Perf
extends RefCounted

const EVERY := 2.0
const SLOW_US := 11000               ## a frame's CPU time that risks a 72 Hz deadline

static var on := OS.is_debug_build() and DisplayServer.get_name() != "headless"
static var _sum := {}                ## section -> usec this period
static var _max := {}                ## section -> worst single usec this period
static var _frames := 0
static var _slow := 0
static var _worst := 0
static var _ticks_max := 0
static var _since := 0.0


static func add(section: String, usec: int) -> void:
	if not on:
		return
	_sum[section] = int(_sum.get(section, 0)) + usec
	_max[section] = maxi(int(_max.get(section, 0)), usec)


## The end of a frame: its CPU time and how many sim ticks it ran.
static func frame(usec: int, ticks: int, delta: float) -> void:
	if not on:
		return
	_frames += 1
	_worst = maxi(_worst, usec)
	_ticks_max = maxi(_ticks_max, ticks)
	if usec > SLOW_US:
		_slow += 1
	_since += delta
	if _since < EVERY:
		return
	var parts := []
	for k in _sum:
		parts.append("%s %.2f/%.1f" % [k, float(_sum[k]) / _frames / 1000.0, float(_max[k]) / 1000.0])
	print("PERF %d frames, worst %.1f ms, slow %d, ticks<=%d | avg/worst ms: %s" % [
		_frames, _worst / 1000.0, _slow, _ticks_max, ", ".join(parts)])
	_sum.clear()
	_max.clear()
	_frames = 0
	_slow = 0
	_worst = 0
	_ticks_max = 0
	_since = 0.0
