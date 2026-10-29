#!/usr/bin/env python3
"""Makes the prank sounds (ADR-025): the soundboard and the silly balls'
and paddles' hits, all synthesized so they're ours and can be remade.
Mono, 16-bit, 44.1 kHz.

  python3 game/tools/make_pranks.py   # writes game/assets/audio/prank/*.wav
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
PEAK = 0.5                           # about -6 dBFS
OUT = Path(__file__).resolve().parent.parent / "assets/audio/prank"


def saw(phase, harmonics):
    """A band-limited sawtooth at `phase` (cycles), `harmonics` partials."""
    return sum(math.sin(2 * math.pi * k * phase) / k for k in range(1, harmonics + 1))


def env(t, attack, length, release):
    if t < attack:
        return t / attack
    if t > length - release:
        return max(0.0, (length - t) / release)
    return 1.0


class Biquad:
    """A band-pass (constant peak gain), for formants and filtered noise."""

    def __init__(self, f, q):
        w = 2 * math.pi * f / RATE
        a = math.sin(w) / (2 * q)
        self.b0, self.b2 = a, -a
        self.a0, self.a1, self.a2 = 1 + a, -2 * math.cos(w), 1 - a
        self.x1 = self.x2 = self.y1 = self.y2 = 0.0

    def __call__(self, x):
        y = (self.b0 * x + self.b2 * self.x2 - self.a1 * self.y1 - self.a2 * self.y2) / self.a0
        self.x2, self.x1, self.y2, self.y1 = self.x1, x, self.y1, y
        return y


def lowpass(xs, k):
    """One-pole smoothing: k near 0 is darker."""
    y, out = 0.0, []
    for x in xs:
        y += k * (x - y)
        out.append(y)
    return out


def airhorn():
    # Two horns a third apart, harsh (clipped), blown short-short-long.
    out = []
    for length in (0.16, 0.16, 0.75):
        n = int(RATE * length)
        for i in range(n):
            t = i / RATE
            v = saw(415 * t, 14) + 0.8 * saw(523 * t, 12)
            out.append(math.tanh(1.8 * v) * env(t, 0.008, length, 0.03))
        out += [0.0] * int(RATE * 0.05)
    return out


def boo():
    # A crowd: a dozen voices each on an "ooo" (formants 300 and 870 Hz),
    # sagging in pitch, with breath.
    rnd = random.Random(94)
    length = 1.7
    n = int(RATE * length)
    out = [0.0] * n
    for v in range(12):
        f0 = rnd.uniform(105, 210)
        start = rnd.uniform(0.0, 0.18)
        f1, f2 = Biquad(300 * rnd.uniform(0.9, 1.1), 6), Biquad(870 * rnd.uniform(0.9, 1.1), 8)
        phase = 0.0
        for i in range(n):
            t = i / RATE - start
            if t < 0:
                continue
            f = f0 * (1.0 - 0.12 * t / length) * (1 + 0.01 * math.sin(2 * math.pi * 5.5 * t + v))
            phase += f / RATE
            src = 2 * (phase % 1.0) - 1 + 0.15 * rnd.uniform(-1, 1)
            out[i] += (f1(src) + 0.5 * f2(src)) * env(t, 0.12, length - start, 0.45)
    return out


def rimshot():
    # Ba-dum-tss: two toms, then a cymbal.
    rnd = random.Random(7)
    length = 1.3
    out = [0.0] * int(RATE * length)
    for at, hi, lo in ((0.0, 190, 95), (0.17, 140, 70)):
        phase = 0.0
        for i in range(int(RATE * 0.35)):
            t = i / RATE
            f = lo + (hi - lo) * math.exp(-t * 18)
            phase += f / RATE
            j = int((at * RATE)) + i
            out[j] += math.sin(2 * math.pi * phase) * math.exp(-t * 9) + 0.25 * rnd.uniform(-1, 1) * math.exp(-t * 40)
    cym = Biquad(7500, 0.7)
    for i in range(int(RATE * 0.85)):
        t = i / RATE
        j = int(0.4 * RATE) + i
        out[j] += 1.4 * cym(rnd.uniform(-1, 1)) * math.exp(-t * 4.5)
    return out


def trombone():
    # Wah wah wah waaah: four falling notes, each "wah" opening the tone up,
    # the last one wobbling.
    out = []
    notes = [(293.7, 0.42), (277.2, 0.42), (261.6, 0.42), (246.9, 1.45)]
    for k, (f0, length) in enumerate(notes):
        phase = 0.0
        last = k == len(notes) - 1
        for i in range(int(RATE * length)):
            t = i / RATE
            f = f0 * (1 + (0.02 * math.sin(2 * math.pi * 5.0 * t) * min(1.0, t / 0.4) if last else 0.0))
            phase += f / RATE
            # The mute: bright in the middle of each wah, dull at its ends.
            open_ = 1.5 + 9.0 * math.sin(math.pi * min(t / (0.6 if last else length), 1.0))
            v = sum(math.sin(2 * math.pi * h * phase) * math.exp(-h / open_) / h for h in range(1, 18))
            out.append(v * env(t, 0.03, length, 0.12 if not last else 0.5))
    return out


def boing():
    length = 0.9
    out, phase = [], 0.0
    for i in range(int(RATE * length)):
        t = i / RATE
        f = 190 * (1 + 0.45 * math.exp(-t * 3.5) * math.sin(2 * math.pi * 13 * t))
        phase += f / RATE
        out.append((math.sin(2 * math.pi * phase) + 0.3 * math.sin(4 * math.pi * phase)) * math.exp(-t * 3.2) * min(1, t / 0.004))
    return out


def whoopee():
    # A whoopee cushion: a low, buzzing flutter that rises and sags.
    rnd = random.Random(3)
    length = 1.0
    out, phase = [], 0.0
    for i in range(int(RATE * length)):
        t = i / RATE
        f = 85 + 40 * math.sin(math.pi * t / length) + 6 * rnd.uniform(-1, 1)
        phase += f / RATE
        flutter = 0.6 + 0.4 * math.sin(2 * math.pi * 27 * t)
        v = (2 * (phase % 1.0) - 1) * flutter + 0.2 * rnd.uniform(-1, 1)
        out.append(v * env(t, 0.02, length, 0.25))
    return lowpass(out, 0.18)


def slide():
    # A slide whistle up, then down.
    length = 1.0
    out, phase = [], 0.0
    for i in range(int(RATE * length)):
        t = i / RATE
        u = t / length
        f = 600 + 1300 * (math.sin(math.pi * u) ** 1.5)
        phase += f / RATE
        out.append((math.sin(2 * math.pi * phase) + 0.08 * math.sin(6 * math.pi * phase)) * env(t, 0.03, length, 0.08))
    return out


def squeak():
    # A rubber duck: two quick, squeezed chirps.
    out = []
    for length in (0.11, 0.16):
        phase = 0.0
        for i in range(int(RATE * length)):
            t = i / RATE
            u = t / length
            f = 1700 + 1100 * math.sin(math.pi * u)
            phase += f / RATE
            v = math.tanh(3 * math.sin(2 * math.pi * phase))
            out.append(v * env(t, 0.01, length, 0.03))
        out += [0.0] * int(RATE * 0.04)
    return lowpass(out, 0.5)


def splat():
    rnd = random.Random(11)
    length = 0.45
    noise = [rnd.uniform(-1, 1) for _ in range(int(RATE * length))]
    wet = lowpass(noise, 0.12)
    out, phase = [], 0.0
    for i, x in enumerate(wet):
        t = i / RATE
        phase += (120 * math.exp(-t * 8) + 50) / RATE
        out.append((2.5 * x + 0.8 * math.sin(2 * math.pi * phase)) * math.exp(-t * 9) * min(1, t / 0.002))
    return out


def clang():
    # A frying pan: a struck metal plate's inharmonic ring.
    length = 1.2
    parts = [(520, 1.0, 3.0), (1180, 0.6, 4.5), (1990, 0.45, 6.0), (2870, 0.3, 8.0), (4120, 0.2, 11.0)]
    out = []
    for i in range(int(RATE * length)):
        t = i / RATE
        out.append(sum(a * math.exp(-d * t) * math.sin(2 * math.pi * f * t) for f, a, d in parts) * min(1, t / 0.001))
    return out


SOUNDS = {"airhorn": airhorn, "boo": boo, "rimshot": rimshot, "trombone": trombone, "boing": boing,
          "whoopee": whoopee, "slide": slide, "squeak": squeak, "splat": splat, "clang": clang}


def write(name, xs):
    k = PEAK / max(abs(v) for v in xs)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / (name + ".wav")), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v * k * 32767)) for v in xs))


def main():
    for name, make in SOUNDS.items():
        write(name, make())
        print("written", OUT / (name + ".wav"))


if __name__ == "__main__":
    main()
