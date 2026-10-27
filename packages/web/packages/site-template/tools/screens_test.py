#!/usr/bin/env python3
"""Tests for screens.py. No browser and no network: only the filenames, the argv and the
generated Node script are checked.

Run: python3 tools/screens_test.py
"""
from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import screens  # noqa: E402


class SlugTest(unittest.TestCase):
    def test_root_is_index(self) -> None:
        self.assertEqual(screens.route_slug("/"), "index")

    def test_root_and_home_never_share_a_slug(self) -> None:
        # A site with a `/home` route would otherwise overwrite `/`'s shots with its own.
        self.assertNotEqual(screens.route_slug("/"), screens.route_slug("/home"))

    def test_nested_route(self) -> None:
        self.assertEqual(screens.route_slug("/docs/getting started/"), "docs-getting-started")


class FilenameTest(unittest.TestCase):
    def test_shot_name(self) -> None:
        self.assertEqual(screens.shot_name("/", 1280, 800, "rest"), "index-1280x800-rest.png")
        self.assertEqual(screens.shot_name("/about", 390, 844, "scrolled"), "about-390x844-scrolled.png")

    def test_a_route_yields_four_shots(self) -> None:
        names = [s.name for s in screens.plan_captures(["/"], Path("/out"))]
        self.assertEqual(
            names,
            [
                "index-1280x800-rest.png",
                "index-1280x800-scrolled.png",
                "index-390x844-rest.png",
                "index-390x844-scrolled.png",
            ],
        )


class ArgvTest(unittest.TestCase):
    def test_argv_pins_playwright(self) -> None:
        self.assertEqual(
            screens.node_argv(Path("/t/s.cjs"), Path("/t/job.json")),
            ["npx", "--yes", "-p", "playwright@1.58.2", "node", "/t/s.cjs", "/t/job.json"],
        )
        self.assertEqual(
            screens.install_argv(), ["npx", "--yes", "-p", "playwright@1.58.2", "playwright", "install", "chromium"]
        )

    def test_script_names_every_shot_and_takes_the_job_from_argv(self) -> None:
        script = screens.node_script()
        self.assertIn("process.argv", script)
        self.assertIn("scrollBy", script)
        self.assertIn("require.resolve('playwright'", script)
        self.assertIn("process.env.PATH", script)
        self.assertIn("waitUntil: 'load'", script)
        self.assertNotIn("waitUntil: 'networkidle'", script)
        job = json.loads(screens.job_json("http://localhost:3000", screens.plan_captures(["/x"], Path("/out"))))
        self.assertEqual(job["base"], "http://localhost:3000")
        self.assertEqual(len(job["shots"]), 4)
        self.assertEqual(job["shots"][0]["path"], "/out/x-1280x800-rest.png")
        self.assertEqual(job["shots"][0]["route"], "/x")


if __name__ == "__main__":
    unittest.main()
