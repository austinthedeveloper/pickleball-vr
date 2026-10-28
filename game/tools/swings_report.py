#!/usr/bin/env python3
"""Sums up the swing log by mode (ADR-017): play several drills in one
session, then one report per mode: your hits, where they went, the drill's
results and the best streak, and the paddle speeds.
    game/tools/swings.sh > swings.log
    python3 game/tools/swings_report.py swings.log [--since HH:MM]
Lines from before modes were logged count as "(no mode)".
"""
import argparse
import re
from collections import Counter, defaultdict

LINE = re.compile(r"^\S+T(?P<time>\d\d:\d\d:\d\d) assist=(?P<assist>\d+)(?: mode=(?P<mode>[^|]+?) \|)? (?P<rest>.*)$")
SWING = re.compile(r"paddle (?P<paddle>[\d.]+) m/s.*?\| in (?P<vin>[\d.]+) m/s \| raw out (?P<out>[\d.]+) m/s at "
                   r"(?P<angle>-?\d+) deg -> (?P<raw>.+?) \| assisted -> (?P<where>.+)$")
RESULT = re.compile(r"^RESULT (?P<result>.+?) \| streak (?P<streak>\d+)$")


def where(text):
    """IN 1.5 m -> IN; NET; OUT 3.0 m -> OUT; SHORT (own side) -> SHORT."""
    return text.split()[0]


def read(lines, since=None):
    modes = defaultdict(lambda: {"hits": 0, "where": Counter(), "results": Counter(), "best": 0,
                                 "paddle": [], "out": [], "first": None, "last": None})
    for raw in lines:
        m = LINE.match(raw.strip())
        if not m or (since and m["time"] < since):
            continue
        mode = (m["mode"] or "(no mode)").strip()
        d = modes[mode]
        d["first"] = d["first"] or m["time"]
        d["last"] = m["time"]
        rest = m["rest"]
        r = RESULT.match(rest)
        if r:
            d["results"][r["result"]] += 1
            d["best"] = max(d["best"], int(r["streak"]))
            continue
        s = SWING.search(rest)
        if s:
            d["hits"] += 1
            d["where"][where(s["where"])] += 1
            d["paddle"].append(float(s["paddle"]))
            d["out"].append(float(s["out"]))
    return modes


def mean(xs):
    return sum(xs) / len(xs) if xs else 0.0


def report(modes):
    out = []
    for mode, d in modes.items():
        out.append("%s  (%s-%s)" % (mode, d["first"], d["last"]))
        if d["hits"]:
            w = ", ".join("%s %d" % kv for kv in d["where"].most_common())
            out.append("  hits %d: %s" % (d["hits"], w))
            out.append("  paddle %.1f m/s on average (%.1f-%.1f), ball out %.1f m/s" % (
                mean(d["paddle"]), min(d["paddle"]), max(d["paddle"]), mean(d["out"])))
        if d["results"]:
            total = sum(d["results"].values())
            good = d["results"].get("GOOD!", 0)
            r = ", ".join("%s %d" % kv for kv in d["results"].most_common())
            out.append("  results %d, %d%% good, best streak %d: %s" % (total, 100 * good // total, d["best"], r))
        out.append("")
    return "\n".join(out)


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("log")
    p.add_argument("--since", help="HH:MM, the session's start")
    a = p.parse_args()
    with open(a.log) as f:
        print(report(read(f, a.since)))


if __name__ == "__main__":
    main()
