#!/usr/bin/env python3
"""The game's version, everywhere it's written (design/RELEASING.md):
game/project.godot (application/config/version) and the Quest export
preset (version/name, and version/code, which Android needs to rise).
    python3 game/tools/version.py            # print it
    python3 game/tools/version.py set X.Y.Z  # change it in every place
    python3 game/tools/version.py code X.Y.Z # the Android version code
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROJECT = "game/project.godot"
PRESETS = "game/export_presets.cfg"
SEMVER = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")


def code(version):
    """MAJOR*10000 + MINOR*100 + PATCH: 0.1.0 -> 100, 1.2.3 -> 10203."""
    m = SEMVER.match(version)
    if not m:
        raise ValueError("not X.Y.Z: %s" % version)
    major, minor, patch = (int(g) for g in m.groups())
    if minor > 99 or patch > 99:
        raise ValueError("minor and patch must stay under 100: %s" % version)
    return major * 10000 + minor * 100 + patch


def get(root=ROOT):
    text = (root / PROJECT).read_text()
    m = re.search(r'^config/version="([^"]+)"', text, re.M)
    return m.group(1) if m else None


def set_version(version, root=ROOT):
    c = code(version)
    p = root / PROJECT
    text, n = re.subn(r'^config/version="[^"]*"', 'config/version="%s"' % version, p.read_text(), flags=re.M)
    if n != 1:
        raise ValueError("%s: no config/version line" % PROJECT)
    p.write_text(text)
    e = root / PRESETS
    text = e.read_text()
    text, n1 = re.subn(r'^version/name="[^"]*"', 'version/name="%s"' % version, text, flags=re.M)
    text, n2 = re.subn(r"^version/code=\d+", "version/code=%d" % c, text, flags=re.M)
    if n1 < 1 or n2 < 1:
        raise ValueError("%s: no version/name or version/code" % PRESETS)
    e.write_text(text)


def main(argv):
    if len(argv) == 1:
        print(get())
    elif len(argv) == 3 and argv[1] == "set":
        set_version(argv[2])
        print("version %s (Android code %d)" % (argv[2], code(argv[2])))
    elif len(argv) == 3 and argv[1] == "code":
        print(code(argv[2]))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
