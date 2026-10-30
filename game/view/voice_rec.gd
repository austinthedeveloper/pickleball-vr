## The coach's voice from a computer (ADR-029): held to talk, the mic's
## samples kept, then made into the phone page's "voice" prank (ADR-025)
## as its page makes it: the quiet ends trimmed, at RATE, a silly voice
## if one's picked, loud as it goes, 16-bit PCM. The headset plays it as
## it plays the phone's.
##
## The mic needs audio/driver/enable_input, on for computers only (the
## project's .pc override): the headset never records.
class_name VoiceRec
extends Node

const RATE := 16000                  ## the phone page's VOICE_RATE
const KINDS := ["NORMAL", "ROBOT", "CHIPMUNK", "MONSTER"]
const SPEED := {"CHIPMUNK": 1.55, "MONSTER": 0.7}
const QUIET := 0.02                  ## the ends trimmed below this
const SHORTEST := 0.2                ## seconds: less is nothing heard

## The mic stopped (let go, or the longest a clip may be): its samples, mono.
signal finished(samples: PackedFloat32Array, rate: float)

var recording := false
var samples := PackedFloat32Array()
var mix_rate := 0.0
var _most := 0


## Starts listening, for at most `seconds`. False when there's no mic.
func start(seconds: int) -> bool:
	if recording:
		return true
	if AudioServer.set_input_device_active(true) != OK:
		return false
	mix_rate = AudioServer.get_input_mix_rate()
	if mix_rate <= 0.0:
		AudioServer.set_input_device_active(false)
		return false
	AudioServer.get_input_frames(AudioServer.get_input_frames_available())   # what came before: not theirs
	samples = PackedFloat32Array()
	_most = int(mix_rate * seconds)
	recording = true
	return true


func _process(_delta: float) -> void:
	if not recording:
		return
	var n := AudioServer.get_input_frames_available()
	if n > 0:
		var frames: PackedVector2Array = AudioServer.get_input_frames(n)
		for f in frames:
			samples.append((f.x + f.y) * 0.5)
	if samples.size() >= _most:
		stop()


## Stops listening; `finished` says what was heard.
func stop() -> void:
	if not recording:
		return
	recording = false
	AudioServer.set_input_device_active(false)
	finished.emit(samples, mix_rate)


func _exit_tree() -> void:
	if recording:
		recording = false
		AudioServer.set_input_device_active(false)


## Samples (mono, at `sr`) as the "voice" prank, in `kind`'s voice and at
## most `seconds` long; {} when nothing was heard.
static func message(x: PackedFloat32Array, sr: float, kind := "NORMAL", seconds := 8) -> Dictionary:
	var a := 0
	var b := x.size() - 1
	while a < b and absf(x[a]) < QUIET:
		a += 1
	while b > a and absf(x[b]) < QUIET:
		b -= 1
	if b - a < sr * SHORTEST:
		return {}
	x = x.slice(maxi(0, a - int(sr * 0.05)), mini(x.size(), b + int(sr * 0.1)))
	var step := sr * float(SPEED.get(kind, 1.0)) / RATE
	var n := mini(int(x.size() / step), RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var f := i * step
		var j := int(f)
		var k := f - j
		out[i] = x[j] * (1.0 - k) + (x[j + 1] if j + 1 < x.size() else 0.0) * k
	if kind == "ROBOT":
		for i in n:
			out[i] *= sin(TAU * 55.0 * i / RATE) * 1.6
	if kind == "MONSTER":
		for i in n:
			out[i] = tanh(out[i] * 2.5)
	var peak := 0.0001
	for v in out:
		peak = maxf(peak, absf(v))
	var pcm := PackedByteArray()
	pcm.resize(n * 2)
	for i in n:
		pcm.encode_s16(i * 2, clampi(roundi(out[i] / peak * 0.9 * 32767.0), -32767, 32767))
	return {"type": "prank", "what": "voice", "rate": RATE, "pcm": Marshalls.raw_to_base64(pcm)}
