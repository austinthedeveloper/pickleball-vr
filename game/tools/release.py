#!/usr/bin/env python3
"""Cuts a release (design/RELEASING.md): checks, a release branch, the
version bump, tests, the release commit and the annotated tag vX.Y.Z, and
the Quest APK and the Mac and Windows games (zips); with --push, main and
the tag go to GitHub and a GitHub release is made with all three attached.
    python3 game/tools/release.py X.Y.Z --dry-run   # the plan, and what would stop it
    python3 game/tools/release.py X.Y.Z             # everything local, nothing pushed
    python3 game/tools/release.py X.Y.Z --push      # and publish

The CHANGELOG entry is written by hand, for players. Without one this
stops and prints a template from the roadmap. The tree must be clean
except CHANGELOG.md and design/ROADMAP.md, which go into the release
commit.
"""
import argparse
import datetime
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import version as versions  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
CHANGELOG = "CHANGELOG.md"
ROADMAP = "design/ROADMAP.md"
MAY_BE_DIRTY = {CHANGELOG, ROADMAP}
APK = "build/pickleball-vr-{v}.apk"
## The computer builds: preset, where it exports, the zip that's attached.
DESKTOP = [("macOS", "build/macos/Pickleball94VR.zip", "build/Pickleball94VR-{v}-macos.zip"),
           ("Windows", "build/windows/Pickleball94VR.exe", "build/Pickleball94VR-{v}-windows.zip")]
TRAILER = "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"


class Stop(Exception):
    """A check failed: the message says why and what to do."""


def run(*cmd, check=True, cwd=None, quiet=False):
    r = subprocess.run(cmd, cwd=cwd or ROOT, capture_output=True, text=True)
    if check and r.returncode != 0:
        raise Stop("`%s` failed:\n%s%s" % (" ".join(cmd), r.stdout[-2000:], r.stderr[-2000:]))
    return r.stdout.strip() if not quiet else r


def changed_files(porcelain):
    """The paths in `git status --porcelain` output. Split on the space, not
    by column: the output arrives stripped, so the first line can lose its
    leading space (" M CHANGELOG.md" read as "HANGELOG.md")."""
    return [l.split(None, 1)[1] for l in porcelain.splitlines() if l.strip()]


def entry(version, text=None):
    """The CHANGELOG entry for `version` (without its heading), or None."""
    text = text if text is not None else (ROOT / CHANGELOG).read_text()
    m = re.search(r"^## \[%s\] - \d{4}-\d{2}-\d{2}\n(.*?)(?=^## \[|\Z)" % re.escape(version), text, re.M | re.S)
    return m.group(1).strip() if m else None


def template(version):
    today = datetime.date.today().isoformat()
    tasks = re.findall(r"^\| (VR-\d+) \| (.+?) \|", (ROOT / ROADMAP).read_text(), re.M)
    lines = "\n".join("- %s (%s)" % (what, task) for task, what in tasks[-8:])
    return "## [%s] - %s\n\nOne paragraph for players: what's new.\n\n### Added\n%s\n" % (version, today, lines)


def checks(version, push):
    """Every reason not to go on, as a list of strings (empty: go)."""
    problems = []
    try:
        versions.code(version)
    except ValueError as e:
        problems.append(str(e))
        return problems
    current = versions.get()
    if current and versions.code(version) <= versions.code(current) and \
            run("git", "tag", "-l", "v" + current) != "":
        problems.append("%s isn't newer than the released %s" % (version, current))
    branch = run("git", "branch", "--show-current")
    if branch != "main":
        problems.append("releases are cut from main (on %s)" % branch)
    dirty = changed_files(run("git", "status", "--porcelain", "--untracked-files=no"))
    extra = [f for f in dirty if f not in MAY_BE_DIRTY]
    if extra:
        problems.append("uncommitted changes outside %s: %s" % (", ".join(sorted(MAY_BE_DIRTY)), ", ".join(extra)))
    if run("git", "tag", "-l", "v" + version):
        problems.append("tag v%s already exists here" % version)
    if push:
        if run("git", "ls-remote", "--tags", "origin", "v" + version):
            problems.append("tag v%s already exists on origin" % version)
        run("git", "fetch", "-q", "origin", "main")
        behind = run("git", "rev-list", "--count", "main..origin/main")
        if behind != "0":
            problems.append("main is %s commit(s) behind origin/main: pull first" % behind)
        if run("gh", "auth", "status", check=False, quiet=True).returncode != 0:
            problems.append("gh isn't logged in (gh auth login)")
    if entry(version) is None:
        problems.append("CHANGELOG.md has no `## [%s] - YYYY-MM-DD` entry. A template:\n\n%s" % (version, template(version)))
    if not (ROOT / "game/addons/godotopenxrvendors").is_dir():
        problems.append("the OpenXR Vendors plugin is missing (game/tools/fetch_openxr_vendors.sh)")
    return problems


def release(version, push, dry):
    problems = checks(version, push)
    plan = [
        "branch feature/cld-release-%s from main" % version,
        "version.py set %s (Android code %d)" % (version, versions.code(version)) if not problems else "version.py set",
        "game/tools/test.sh",
        "commit 'Release %s' and tag v%s" % (version, version),
        "build %s (debug-signed, for sideloading)" % APK.format(v=version),
        "build %s" % ", ".join(z.format(v=version) for _, _, z in DESKTOP),
    ]
    if push:
        plan += ["fast-forward main to the release, push main and the tag",
                 "gh release create v%s with the APK, the zips and the CHANGELOG entry" % version]
    print("Release %s:" % version)
    for step in plan:
        print("  - " + step)
    if problems:
        raise Stop("Not ready:\n" + "\n".join("  * " + p for p in problems))
    if dry:
        print("Dry run: nothing changed.")
        return
    rel = "feature/cld-release-%s" % version
    run("git", "checkout", "-q", "-b", rel)
    versions.set_version(version)
    tests = subprocess.run(["game/tools/test.sh"], cwd=ROOT, capture_output=True, text=True)
    summary = tests.stdout.strip().splitlines()[-1] if tests.stdout.strip() else ""
    if tests.returncode != 0:
        run("git", "checkout", "-q", "--", versions.PROJECT, versions.PRESETS)
        run("git", "checkout", "-q", "main")
        run("git", "branch", "-q", "-D", rel)
        raise Stop("tests failed, nothing committed:\n" + tests.stdout[-3000:])
    print("  tests: " + summary)
    run("git", "add", versions.PROJECT, versions.PRESETS, CHANGELOG, ROADMAP)
    run("git", "commit", "-q", "--allow-empty", "-m", "Release %s\n\n%s" % (version, TRAILER))
    first = entry(version).split("\n\n")[0]
    run("git", "tag", "-a", "v" + version, "-m", "Pickleball '94 VR %s\n\n%s" % (version, first))
    print("  tagged v%s on %s" % (version, rel))
    apk = APK.format(v=version)
    (ROOT / "build").mkdir(exist_ok=True)
    out = run("godot", "--headless", "--path", "game", "--export-debug", "Quest", "../" + apk, check=False, quiet=True)
    if not (ROOT / apk).is_file():
        raise Stop("the APK build failed (the release commit and tag are made; fix and run "
                   "`godot --headless --path game --export-debug Quest ../%s`):\n%s" % (apk, out.stderr[-2000:]))
    print("  built %s (%.0f MB)" % (apk, (ROOT / apk).stat().st_size / 1e6))
    zips = desktop(version)
    if not push:
        print("Not pushed. To publish: git checkout main && git merge --ff-only %s && "
              "git push origin main v%s && gh release create v%s %s %s --title ... --notes-file ..." % (rel, version, version, apk, " ".join(zips)))
        return
    run("git", "checkout", "-q", "main")
    run("git", "merge", "-q", "--ff-only", rel)
    run("git", "push", "-q", "origin", "main", "v" + version)
    notes = ROOT / "build" / ("notes-%s.md" % version)
    notes.write_text(entry(version) + "\n\n" + INSTALL.format(v=version))
    url = run("gh", "release", "create", "v" + version, str(ROOT / apk), *[str(ROOT / z) for z in zips], "--title",
              "Pickleball '94 VR %s" % version, "--notes-file", str(notes), "--latest")
    print("  published " + url)


INSTALL = """## Install

- **Quest** (developer mode): `adb install -r pickleball-vr-{v}.apk`, then
  Library > Unknown Sources.
- **Mac** (to coach, watch or play a friend): unzip
  `Pickleball94VR-{v}-macos.zip`, right-click the app > Open the first time
  (it isn't from the App Store). It asks for the microphone the first time
  you HOLD TO TALK.
- **Windows:** unzip `Pickleball94VR-{v}-windows.zip` and keep its two
  files together; run `Pickleball94VR.exe` (More info > Run anyway the
  first time).
"""


## The Mac and Windows games, exported and zipped: the zips' paths.
def desktop(version):
    import shutil
    import zipfile
    zips = []
    for preset, out, z in DESKTOP:
        where = ROOT / out
        shutil.rmtree(where.parent, ignore_errors=True)
        where.parent.mkdir(parents=True)
        res = run("godot", "--headless", "--path", "game", "--export-release", preset, "../" + out,
                  check=False, quiet=True)
        if not where.is_file():
            raise Stop("the %s build failed (the release commit and tag are made; fix and run "
                       "`godot --headless --path game --export-release %s ../%s`):\n%s"
                       % (preset, preset, out, res.stderr[-2000:]))
        z = z.format(v=version)
        if where.suffix == ".zip":
            shutil.copyfile(where, ROOT / z)
        else:                            # the .exe and the OpenXR library beside it
            with zipfile.ZipFile(ROOT / z, "w", zipfile.ZIP_DEFLATED) as f:
                for path in sorted(where.parent.iterdir()):
                    f.write(path, path.name)
        print("  built %s (%.0f MB)" % (z, (ROOT / z).stat().st_size / 1e6))
        zips.append(z)
    return zips


def main(argv):
    p = argparse.ArgumentParser(prog="release.py", description=__doc__.split("\n")[0])
    p.add_argument("version")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--push", action="store_true")
    a = p.parse_args(argv)
    try:
        release(a.version, a.push, a.dry_run)
    except Stop as e:
        print(e)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
