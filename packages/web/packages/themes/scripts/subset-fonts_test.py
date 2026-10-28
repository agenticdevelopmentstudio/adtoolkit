#!/usr/bin/env python3
"""Tests for subset-fonts.py: what each cut covers, and which faces a site preloads.

    python3 scripts/subset-fonts_test.py
"""
from __future__ import annotations

import importlib.util
import re
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("subset_fonts", HERE / "subset-fonts.py")
assert SPEC is not None and SPEC.loader is not None
subset_fonts = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(subset_fonts)

LANDING_CSS = HERE.parent.parent / "landing" / "src" / "css"

# Every non-ASCII character the fishlamp content sites set today — ads, Kitchen and
# Stenographer, every route rendered and every content file — from the census run when the
# site cut was made. A site that starts setting something outside these blocks adds it here
# and to SITE_UNICODES together.
CONTENT_SITE_CENSUS = "©·—’“”…→"


def covered(cp: int, spec: str) -> bool:
    return any(lo <= cp <= hi for lo, hi in subset_fonts.unicode_ranges(spec))


class SiteCutTest(unittest.TestCase):
    def test_the_site_cut_covers_what_the_content_sites_set(self) -> None:
        missing = [c for c in CONTENT_SITE_CENSUS if not covered(ord(c), subset_fonts.SITE_UNICODES)]
        self.assertEqual(missing, [])

    def test_the_site_cut_covers_every_mark_the_landing_kit_draws(self) -> None:
        # A block's mark is a CSS `content:` default — the checklist's ✓ and ○, the points'
        # → — so no census of a site's copy sees it, and a mark outside the cut paints in
        # the fallback face beside Iosevka.
        marks: set[str] = set()
        for sheet in sorted(LANDING_CSS.glob("*.css")):
            for value in re.findall(r"content:\s*var\(--[\w-]+,\s*\"([^\"]*)\"\)", sheet.read_text()):
                marks |= {chr(int(m, 16)) for m in re.findall(r"\\([0-9a-fA-F]{2,6})", value)}
                marks |= {c for c in re.sub(r"\\[0-9a-fA-F]{2,6}", "", value) if ord(c) > 0x7F}
        self.assertIn("✓", marks)
        missing = sorted(c for c in marks if not covered(ord(c), subset_fonts.SITE_UNICODES))
        self.assertEqual(missing, [])

    def test_the_site_cut_is_latin_and_its_marks_not_cyrillic_or_greek(self) -> None:
        # The site cut is the whole face a site serves — there is no EXT behind it — so it is
        # bounded by what a content site sets, not by what a user might type.
        for cp in (0x0391, 0x0410, 0x2800):
            self.assertFalse(covered(cp, subset_fonts.SITE_UNICODES), hex(cp))

    def test_the_site_faces_are_their_own_files(self) -> None:
        # The adh theme's faces feed metrics.json and adh.css; the site cut must not
        # overwrite one of them.
        theme = {f"{served}{suffix}.woff2" for served in subset_fonts.FACES.values() for suffix, _u, _p in subset_fonts.SUBSETS}
        site = {face.file for face in subset_fonts.SITE_FACES}
        self.assertEqual(site & theme, set())
        self.assertEqual(len(site), len(subset_fonts.SITE_FACES))

    def test_a_site_cut_comes_from_an_upstream_face(self) -> None:
        for face in subset_fonts.SITE_FACES:
            self.assertIn(face.upstream, subset_fonts.FACES)

    def test_a_site_preloads_regular_and_bold_but_not_italic(self) -> None:
        preload = {(f.weight, f.style): f.preload for f in subset_fonts.SITE_FACES}
        self.assertEqual(preload, {("400", "normal"): True, ("700", "normal"): True, ("400", "italic"): False})


class SubsetArgsTest(unittest.TestCase):
    def test_a_cut_is_woff2_with_its_ranges_and_features(self) -> None:
        args = subset_fonts.subset_args(Path("/py"), Path("/in.woff2"), Path("/out.woff2"), "U+0000-00FF", "calt,kern")
        self.assertEqual(args[:4], ["/py", "-m", "fontTools.subset", "/in.woff2"])
        for flag in ("--output-file=/out.woff2", "--flavor=woff2", "--unicodes=U+0000-00FF",
                     "--layout-features=calt,kern", "--no-prune-unicode-ranges"):
            self.assertIn(flag, args)

    def test_unicode_ranges_reads_single_points_and_spans(self) -> None:
        self.assertEqual(subset_fonts.unicode_ranges("U+0041,U+2190-21FF"), [(0x41, 0x41), (0x2190, 0x21FF)])


class CommittedSiteFacesTest(unittest.TestCase):
    def test_every_site_face_is_committed(self) -> None:
        for face in subset_fonts.SITE_FACES:
            self.assertTrue((subset_fonts.OUT_DIR / face.file).is_file(), face.file)

    def test_a_site_face_is_smaller_than_the_theme_face_it_is_cut_from(self) -> None:
        for face in subset_fonts.SITE_FACES:
            theme = subset_fonts.OUT_DIR / f"{subset_fonts.FACES[face.upstream]}.woff2"
            self.assertLess((subset_fonts.OUT_DIR / face.file).stat().st_size, theme.stat().st_size, face.file)


if __name__ == "__main__":
    unittest.main()
