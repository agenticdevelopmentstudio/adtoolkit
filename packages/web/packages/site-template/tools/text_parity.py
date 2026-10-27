#!/usr/bin/env python3
"""Compare the visible words of two HTML pages, ignoring markup.

Run: python3 tools/text_parity.py BEFORE.html AFTER.html [--allow FILE]

Visible text is every text node outside `script`, `style` and `noscript`, whitespace-normalised,
one line per block element. Prints a unified diff and exits 1 when the pages differ outside the
allow file; exits 0 when they match. The allow file lists the diff lines a change may produce,
exactly as the diff prints them (`-old line`, `+new line`); blank lines and lines starting with
`#` are ignored.

A `<br>` is not a block boundary, so `a<br>b` is the one line `a b`. `<title>`, `template`, svg
`title` and `[hidden]` text are counted as visible. That is acceptable: parity compares like with
like, so the same text in both files cancels out.
"""
from __future__ import annotations

import argparse
import difflib
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

SKIPPED = {"script", "style", "noscript"}
BLOCKS = {
    "address", "article", "aside", "blockquote", "body", "dd", "details", "div", "dl", "dt",
    "fieldset", "figcaption", "figure", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6", "header",
    "hr", "html", "li", "main", "nav", "ol", "p", "pre", "section", "summary", "table", "tbody", "td",
    "tfoot", "th", "thead", "tr", "ul",
}


class _Collector(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.lines: list[str] = []
        self._buf: list[str] = []
        self._skip = 0

    def flush(self) -> None:
        text = re.sub(r"\s+", " ", "".join(self._buf)).strip()
        self._buf = []
        if text:
            self.lines.append(text)

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in SKIPPED:
            self._skip += 1
        elif tag in BLOCKS:
            self.flush()
        elif tag == "br":
            self._buf.append(" ")

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in BLOCKS:
            self.flush()
        elif tag == "br":
            self._buf.append(" ")

    def handle_endtag(self, tag: str) -> None:
        if tag in SKIPPED:
            self._skip = max(0, self._skip - 1)
        elif tag in BLOCKS:
            self.flush()

    def handle_data(self, data: str) -> None:
        if not self._skip:
            self._buf.append(data)


def visible_lines(html: str) -> list[str]:
    """The page's visible text, one normalised line per block."""
    collector = _Collector()
    collector.feed(html)
    collector.close()
    collector.flush()
    return collector.lines


def diff(before: list[str], after: list[str], before_name: str, after_name: str) -> list[str]:
    """Unified diff lines, with no trailing newlines."""
    return list(difflib.unified_diff(before, after, before_name, after_name, lineterm=""))


def changed_lines(diff_lines: list[str]) -> list[str]:
    """The `-`/`+` body lines of a diff. The two file headers are dropped by position, never by
    prefix, so a content line that starts with `--` or `++` still counts."""
    return [line for line in diff_lines[2:] if line[:1] in ("+", "-")]


def read_allowed(path: Path) -> set[str]:
    return {line for line in path.read_text().splitlines() if line.strip() and not line.startswith("#")}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Diff the visible text of two HTML pages.")
    parser.add_argument("before", type=Path)
    parser.add_argument("after", type=Path)
    parser.add_argument("--allow", type=Path, help="diff lines (`-old`, `+new`) a change may produce")
    args = parser.parse_args(argv)
    lines = diff(visible_lines(args.before.read_text()), visible_lines(args.after.read_text()), str(args.before), str(args.after))
    changed = changed_lines(lines)
    if not changed:
        return 0
    print("\n".join(lines))
    allowed = read_allowed(args.allow) if args.allow else set()
    return 0 if all(line in allowed for line in changed) else 1


if __name__ == "__main__":
    sys.exit(main())
