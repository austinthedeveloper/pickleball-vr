#!/usr/bin/env python3
"""Makes ZEN's sounds (ADR-031), synthesized so they're ours and can be
remade. Mono, 16-bit, 48 kHz, like the ding.

  python3 game/tools/make_zen.py   # writes game/assets/audio/zen_*.wav

- zen_drone.wav: an 8 s loop, low and still. Every partial makes a whole
  number of cycles in 8 s, so the loop has no seam.
- zen_tone.wav: a soft struck bowl at A4. Each hit plays it at a note of a
  pentatonic scale (pitch_scale), so a long rally makes a slow melody.
- zen_bell.wav: a low bowl, the exhale when a deep rally ends.
"""
import math
import struct
import wave
from pathlib import Path

RATE = 48000
OUT = Path(__file__).resolve().parent.parent / "assets/audio"


def write(name, samples, peak):
    k = peak / max(abs(v) for v in samples)
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v * k * 32767)) for v in samples))
    print("written", OUT / name)


def drone():
    secs = 8
    # (Hz, level): A1, A2 and its fifth, a slow beat against A2, a soft A3.
    # Each frequency times 8 s is a whole number: the loop is seamless.
    parts = [(55.0, 1.0), (110.0, 0.6), (110.25, 0.45), (165.0, 0.35), (220.0, 0.12), (330.0, 0.05)]
    out = []
    for i in range(RATE * secs):
        t = i / RATE
        breath = 0.8 + 0.2 * math.sin(2 * math.pi * t / secs)      # one swell per loop
        out.append(breath * sum(a * math.sin(2 * math.pi * f * t) for f, a in parts))
    write("zen_drone.wav", out, 0.35)


def bowl(name, f0, secs, partials, peak):
    out = []
    for i in range(int(RATE * secs)):
        t = i / RATE
        attack = min(1.0, t / 0.012)                                  # soft, no click
        fade = min(1.0, (secs - t) / 0.3)
        out.append(attack * fade * sum(a * math.exp(-d * t) * math.sin(2 * math.pi * f0 * r * t)
                                       for r, a, d in partials))
    write(name, out, peak)


def main():
    drone()
    # A bowl's partials (ratio, level, decay per second): a long fundamental,
    # a faint beating pair, the inharmonic ones short.
    bowl("zen_tone.wav", 440.0, 2.6,
         [(1.0, 1.0, 1.6), (1.004, 0.5, 1.8), (2.0, 0.22, 3.0), (2.71, 0.12, 5.0), (5.2, 0.04, 9.0)], 0.4)
    bowl("zen_bell.wav", 146.83, 5.0,
         [(1.0, 1.0, 0.7), (1.006, 0.6, 0.8), (2.0, 0.3, 1.2), (2.76, 0.2, 2.0), (4.1, 0.08, 4.0)], 0.45)


if __name__ == "__main__":
    main()
