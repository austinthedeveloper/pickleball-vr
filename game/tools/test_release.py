#!/usr/bin/env python3
"""Self-test for version.py and release.py, on copies in a temp folder
(never the real repo).  python3 game/tools/test_release.py"""
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import release  # noqa: E402
import version  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]


class Versions(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        (self.tmp / "game").mkdir()
        for f in (version.PROJECT, version.PRESETS):
            shutil.copy(ROOT / f, self.tmp / f)

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def test_codes_rise_with_the_version(self):
        self.assertEqual(version.code("0.1.0"), 100)
        self.assertEqual(version.code("1.2.3"), 10203)
        self.assertLess(version.code("0.9.99"), version.code("0.10.0"))
        for bad in ("1.2", "v1.2.3", "0.100.0"):
            with self.assertRaises(ValueError):
                version.code(bad)

    def test_set_writes_every_place(self):
        version.set_version("0.7.2", self.tmp)
        self.assertEqual(version.get(self.tmp), "0.7.2")
        presets = (self.tmp / version.PRESETS).read_text()
        self.assertIn('version/name="0.7.2"', presets)
        self.assertIn("version/code=702", presets)


class Status(unittest.TestCase):
    def test_paths_survive_a_stripped_first_line(self):
        # run() strips its output: the first line's leading space goes.
        out = "M CHANGELOG.md\n M design/ROADMAP.md\nMM game/x.gd"
        self.assertEqual(release.changed_files(out), ["CHANGELOG.md", "design/ROADMAP.md", "game/x.gd"])


class Desktop(unittest.TestCase):
    def test_every_attached_file_is_explained(self):
        notes = release.INSTALL.format(v="1.2.3")
        self.assertIn(Path(release.APK.format(v="1.2.3")).name, notes)
        for preset, out, z in release.DESKTOP:
            self.assertIn(Path(z.format(v="1.2.3")).name, notes, preset)

    def test_every_preset_exists(self):
        presets = (ROOT / "game/export_presets.cfg").read_text()
        for preset, out, z in release.DESKTOP:
            self.assertIn('name="%s"' % preset, presets)
            self.assertIn('export_path="../%s"' % out, presets)


class Changelog(unittest.TestCase):
    TEXT = ("# Changelog\n\n## [0.2.0] - 2026-11-01\n\nNew things.\n\n### Added\n- A\n\n"
            "## [0.1.0] - 2026-10-27\n\nFirst.\n")

    def test_entry_is_the_section(self):
        self.assertEqual(release.entry("0.2.0", self.TEXT), "New things.\n\n### Added\n- A")
        self.assertEqual(release.entry("0.1.0", self.TEXT), "First.")
        self.assertIsNone(release.entry("0.3.0", self.TEXT))

    def test_the_real_changelog_parses(self):
        text = (ROOT / release.CHANGELOG).read_text()
        self.assertIsNotNone(release.entry(version.get(), text) or release.entry("0.1.0", text))


if __name__ == "__main__":
    unittest.main(verbosity=1)
