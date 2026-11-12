#!/usr/bin/env python3
"""Makes the outdoor NIGHT ambience (VR-100, ADR-033): crickets over a soft
breeze, a 12 s loop, synthesized so it's ours and can be remade. Mono,
16-bit, 22.05 kHz (an ambience doesn't need more).

  python3 game/tools/make_night.py   # writes game/assets/audio/ambience_night.wav

Each cricket chirps a few pulses of a high tone, again and again at its
own rate; they never all line up. The breeze is filtered noise, faded so
the loop has no seam.
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
SECONDS = 12
OUT = Path(__file__).resolve().parent.parent / "assets/audio/ambience_night.wav"
# (Hz, chirps a second, pulses a chirp, level, where in the loop it starts)
CRICKETS = [(4300, 1.5, 3, 0.30, 0.0), (4700, 2.0, 2, 0.22, 0.31), (3900, 1.0, 4, 0.18, 0.62),
            (5100, 2.5, 2, 0.12, 0.17), (4500, 1.25, 3, 0.15, 0.85)]


def main():
    rng = random.Random(1994)
    n = RATE * SECONDS
    out = [0.0] * n
    for f, rate, pulses, level, phase in CRICKETS:
        period = 1.0 / rate
        for i in range(n):
            t = (i / RATE + phase * period) % period
            pulse = t / 0.018                      # 18 ms a pulse, a gap as long
            if pulse < pulses * 2 and int(pulse) % 2 == 0:
                env = math.sin(math.pi * (pulse % 1.0))
                out[i] += level * env * math.sin(2 * math.pi * f * i / RATE)
    # A soft breeze: noise through a slow one-pole filter, swelling twice a loop.
    y = 0.0
    for i in range(n):
        y += 0.02 * (rng.uniform(-1, 1) - y)
        swell = 0.6 + 0.4 * math.sin(2 * math.pi * 2 * i / n)
        out[i] += 0.5 * y * swell
    fade = RATE // 4                               # the seam: the end crossfades into the start
    for i in range(fade):
        a = i / fade
        out[i] = out[i] * a + out[n - fade + i] * (1 - a)
    out = out[: n - fade]
    k = 0.4 / max(abs(v) for v in out)
    with wave.open(str(OUT), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v * k * 32767)) for v in out))
    print("written", OUT)


if __name__ == "__main__":
    main()
