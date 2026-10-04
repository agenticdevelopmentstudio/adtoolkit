"""No identifier in the toolkit may still say agentic-cookbook / agenticcookbook.

Excluded: the cookbook's own domain and repo name (references to a different
project), archived docs and session logs (history), the historical-bug fixtures
in tools/check_doc_subpaths*, and the one legacy theme id kept so a persisted
theme choice can be migrated on read.
"""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATTERN = re.compile(r"agentic-?cookbook", re.IGNORECASE)
ALLOWED = (
    re.compile(r"https?://(www\.)?agenticcookbook\.dev"),
    re.compile(r"agenticdevelopmentstudio/agenticcookbook"),
    re.compile(r"Development/projects/agenticcookbook"),
    re.compile(r"\(agenticcookbook `cookr` branch"),
)
# Files that quote the old name on purpose (historical-bug fixtures).
ALLOWED_FILE_PREFIXES = ("tools/check_doc_subpaths",)
# The pre-rename theme id, mapped to the new one when a persisted setting is read.
LEGACY_THEME_ID = "agenticcookbookweb"
ALLOWED_LEGACY_LINE = re.compile(r'LEGACY_THEME_ID\b.*"agenticcookbookweb"')
THIS_FILE = "tools/check_no_cookbook_identifiers_test.py"


def is_excluded(relative: str) -> bool:
    parts = relative.split("/")
    if "archive" in parts[:-1] or relative.startswith("docs/sessions/"):
        return True
    if relative == THIS_FILE:
        return True
    return relative.startswith(ALLOWED_FILE_PREFIXES)


def tracked_files() -> list[Path]:
    out = subprocess.run(["git", "ls-files"], cwd=ROOT, check=True,
                         capture_output=True, text=True).stdout
    return [ROOT / line for line in out.splitlines() if not is_excluded(line)]


def offending_lines() -> list[str]:
    hits: list[str] = []
    for path in tracked_files():
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, FileNotFoundError, IsADirectoryError):
            continue
        for number, line in enumerate(text.splitlines(), 1):
            if ALLOWED_LEGACY_LINE.search(line):
                continue
            stripped = line
            for allowed in ALLOWED:
                stripped = allowed.sub("", stripped)
            if PATTERN.search(stripped):
                hits.append(f"{path.relative_to(ROOT)}:{number}: {line.strip()}")
    return hits


def test_no_cookbook_identifiers() -> None:
    hits = offending_lines()
    assert not hits, f"{len(hits)} hits\n" + "\n".join(hits[:50])
