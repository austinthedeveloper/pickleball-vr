#!/usr/bin/env python3
"""Writes a tuning.cfg's values (ADR-020) into the sim's source as the new
defaults: each tunable is a `static var NAME := literal` (an int, or a list
of ints whose INDEX is the one tuned) in the file the cfg says.

  python3 game/tools/tune_sync.py tuning.cfg [--dry-run]
"""
import re
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent


def parse(path):
    """The cfg's sections as {section: {key: value string}} (Godot ConfigFile)."""
    out, sec = {}, None
    for line in Path(path).read_text().splitlines():
        line = line.strip()
        if not line or line.startswith(";"):
            continue
        m = re.match(r"^\[(.+)\]$", line)
        if m:
            sec = out.setdefault(m.group(1), {})
            continue
        k, _, v = line.partition("=")
        sec[k.strip()] = v.strip().strip('"')
    return out


def declaration(text, name):
    m = re.search(r"^static var %s := (.+?)(\s*##.*)?$" % re.escape(name), text, re.M)
    if not m:
        raise SystemExit("no `static var %s := ...` found" % name)
    return m


def apply(text, name, index, value):
    m = declaration(text, name)
    lit = m.group(1).strip()
    if index < 0:
        if not re.fullmatch(r"-?\d+", lit):
            raise SystemExit("%s isn't a plain int: %s" % (name, lit))
        new = str(value)
    else:
        items = [x.strip() for x in lit.strip("[]").split(",")]
        if not lit.startswith("[") or index >= len(items):
            raise SystemExit("%s has no element %d: %s" % (name, index, lit))
        items[index] = str(value)
        new = "[" + ", ".join(items) + "]"
    return text[:m.start(1)] + new + text[m.start(1) + len(m.group(1).rstrip()):], lit, new


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    if len(args) != 1:
        raise SystemExit(__doc__)
    cfg = parse(args[0])
    tune, where, default = cfg.get("tune", {}), cfg.get("where", {}), cfg.get("default", {})
    if not tune:
        print("nothing tuned")
        return
    files = {}
    for key, value in sorted(tune.items()):
        rel, name, index = where[key].rsplit(":", 2)
        path = GAME / rel
        text = files.get(path) or path.read_text()
        text, old, new = apply(text, name, int(index), int(value))
        files[path] = text
        print("%-14s %s: %s -> %s   (was %s on the headset's build)" % (key, name, old, new, default.get(key, "?")))
    if dry:
        print("(dry run: nothing written)")
        return
    for path, text in files.items():
        path.write_text(text)
    print("written: " + ", ".join(str(p.relative_to(GAME.parent)) for p in files))


if __name__ == "__main__":
    main()
