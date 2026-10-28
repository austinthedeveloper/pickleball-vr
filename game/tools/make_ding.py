#!/usr/bin/env python3
"""Makes the target ding (ADR-019): a light, bell-like tone, synthesized so
it's ours and can be remade. Mono, 16-bit, 48 kHz, like the other sounds.

  python3 game/tools/make_ding.py   # writes game/assets/audio/5_ding.wav
"""
import math
import struct
import wave
from pathlib import Path

RATE = 48000
SECONDS = 0.7
F0 = 1568.0                          # G6: bright, above the court's noise
# A bell's partials (ratio, level, decay per second): the fundamental
# rings on, the inharmonic ones fade fast so it reads as a ding, not a beep.
PARTIALS = [(1.0, 1.0, 5.5), (2.76, 0.32, 11.0), (5.40, 0.12, 20.0), (2.0, 0.18, 8.0)]
PEAK = 0.45                          # about -7 dBFS


def main():
    n = int(RATE * SECONDS)
    out = []
    for i in range(n):
        t = i / RATE
        attack = min(1.0, t / 0.003)
        v = sum(a * math.exp(-d * t) * math.sin(2 * math.pi * F0 * r * t) for r, a, d in PARTIALS)
        out.append(v * attack)
    k = PEAK / max(abs(v) for v in out)
    path = Path(__file__).resolve().parent.parent / "assets/audio/5_ding.wav"
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v * k * 32767)) for v in out))
    print("written", path)


if __name__ == "__main__":
    main()
