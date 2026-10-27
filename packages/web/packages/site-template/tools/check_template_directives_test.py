#!/usr/bin/env python3
"""Tests for check_template_directives.py. Each case plants a dist/ and asserts the verdict,
so a "directives: ok" from the build is known to be capable of saying anything else.

Run: python3 tools/check_template_directives_test.py
"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_template_directives as guard  # noqa: E402

CLIENT = "'use client';\nexport { SiteChrome } from './chunk-a.js';\n"
SERVER = "// built\nexport { LandingFrame } from './chunk-b.js';\n"


class CheckTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.dist = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def write(self, name: str, text: str) -> None:
        (self.dist / name).write_text(text, encoding="utf-8")

    def test_holds_when_only_the_client_entry_has_the_directive(self) -> None:
        self.write("index.js", SERVER)
        self.write("client.js", CLIENT)
        self.write("chunk-b.js", "export const x = 1;\n")
        self.assertEqual(guard.check(self.dist), [])
        self.assertEqual(guard.main(["--dist", str(self.dist)]), 0)

    def test_refuses_a_directive_hoisted_onto_the_server_barrel(self) -> None:
        self.write("index.js", CLIENT)
        self.write("client.js", CLIENT)
        failures = guard.check(self.dist)
        self.assertEqual(len(failures), 1)
        self.assertIn("dist/index.js starts with 'use client'", failures[0])
        self.assertEqual(guard.main(["--dist", str(self.dist)]), 1)

    def test_refuses_a_client_entry_without_the_directive(self) -> None:
        self.write("index.js", SERVER)
        self.write("client.js", SERVER)
        self.assertIn("does NOT start with", guard.check(self.dist)[0])

    def test_refuses_a_stray_chunk_carrying_the_directive(self) -> None:
        self.write("index.js", SERVER)
        self.write("client.js", CLIENT)
        self.write("chunk-c.js", CLIENT)
        self.assertIn("chunk-c.js carries", guard.check(self.dist)[0])

    def test_refuses_a_missing_entry(self) -> None:
        self.write("client.js", CLIENT)
        self.assertIn("index.js was not built", guard.check(self.dist)[0])

    def test_a_missing_dist_is_an_error_not_a_pass(self) -> None:
        self.assertEqual(guard.main(["--dist", str(self.dist / "nope")]), 2)

    def test_reads_double_quoted_directives(self) -> None:
        self.write("x.js", '"use client";\n')
        self.assertEqual(guard.read_directive(self.dist / "x.js"), "use client")


if __name__ == "__main__":
    unittest.main()
