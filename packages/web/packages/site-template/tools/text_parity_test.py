#!/usr/bin/env python3
"""Tests for text_parity.py: the words must survive a layout change, and only the words.

Run: python3 tools/text_parity_test.py
"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import text_parity as parity  # noqa: E402

BEFORE = "<html><head><style>p{}</style><script>var x=1</script></head><body><h1>Hello  world</h1><p>One two.</p></body></html>"


class ParityTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def write(self, name: str, text: str) -> Path:
        path = self.dir / name
        path.write_text(text)
        return path

    def test_lines_skip_script_style_and_normalise_whitespace(self) -> None:
        self.assertEqual(parity.visible_lines(BEFORE), ["Hello world", "One two."])

    def test_inline_markup_does_not_split_a_block(self) -> None:
        self.assertEqual(parity.visible_lines("<p>One <b>two</b>\n three</p>"), ["One two three"])

    def test_noscript_is_skipped(self) -> None:
        self.assertEqual(parity.visible_lines("<p>a</p><noscript><p>hidden</p></noscript><p>b</p>"), ["a", "b"])

    def test_same_text_different_markup_passes(self) -> None:
        after = "<main><section><h1>Hello <em>world</em></h1></section><div><p>One\n two.</p></div><noscript>no</noscript></main>"
        self.assertEqual(parity.main([str(self.write("a.html", BEFORE)), str(self.write("b.html", after))]), 0)

    def test_changed_word_fails_with_a_diff(self) -> None:
        after = BEFORE.replace("One two.", "One three.")
        a, b = self.write("a.html", BEFORE), self.write("b.html", after)
        self.assertEqual(parity.main([str(a), str(b)]), 1)
        diff = "\n".join(parity.diff(parity.visible_lines(BEFORE), parity.visible_lines(after), "a", "b"))
        self.assertIn("-One two.", diff)
        self.assertIn("+One three.", diff)

    def test_br_does_not_split_a_line(self) -> None:
        self.assertEqual(parity.visible_lines("<p>a<br>b</p>"), ["a b"])

    def test_removed_line_starting_with_dashes_fails(self) -> None:
        a = self.write("a.html", "<p>keep</p><p>-- old</p>")
        b = self.write("b.html", "<p>keep</p>")
        self.assertEqual(parity.main([str(a), str(b)]), 1)

    def test_allowed_line_passes(self) -> None:
        after = BEFORE.replace("One two.", "One three.")
        a, b = self.write("a.html", BEFORE), self.write("b.html", after)
        allow = self.write("allow.txt", "# reworded\n-One two.\n+One three.\n")
        self.assertEqual(parity.main([str(a), str(b), "--allow", str(allow)]), 0)

    def test_allow_does_not_cover_other_changes(self) -> None:
        after = BEFORE.replace("One two.", "One three.").replace("Hello  world", "Bye")
        a, b = self.write("a.html", BEFORE), self.write("b.html", after)
        allow = self.write("allow.txt", "-One two.\n+One three.\n")
        self.assertEqual(parity.main([str(a), str(b), "--allow", str(allow)]), 1)


if __name__ == "__main__":
    unittest.main()
