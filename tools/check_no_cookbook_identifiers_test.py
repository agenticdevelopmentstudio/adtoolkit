"""No identifier in the toolkit may still say agentic-cookbook / agenticcookbook.

Excluded: the cookbook's own domain and repo name (references to a different
project), archived docs and session logs (history), the historical-bug fixtures
in tools/check_doc_subpaths*, docs/web/migrate-consumer.md (its "old" columns
quote the pre-rename package scope on purpose), and the one real
`LEGACY_THEME_ID` line in the adh themes module, which maps a persisted
pre-rename theme key to its new one.
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
ALLOWED_FILE_PREFIXES = ("tools/check_doc_subpaths", "docs/web/migrate-consumer.md")
# The one declaration of the pre-rename theme id (packages/web/packages/adh/src/themes/adh-themes.ts).
# Also its emitted forms in the tracked dist/ (`var ... = "..."`, `export declare const ... = "..."`).
ALLOWED_LEGACY_LINE = re.compile(
    r"""^(export const|var|export declare const) LEGACY_THEME_ID = ['"]agenticcookbookweb['"];?$"""
)
THIS_FILE = "tools/check_no_cookbook_identifiers_test.py"
# Only the adh package's tracked dist source maps embed the allowed legacy line.
SOURCE_MAP_DIR = "packages/web/packages/adh/dist/"


def is_excluded(relative: str) -> bool:
    parts = relative.split("/")
    if "archive" in parts[:-1] or relative.startswith("docs/sessions/"):
        return True
    if relative.startswith(SOURCE_MAP_DIR) and relative.endswith(".map"):
        return True  # adh dist source maps embed source text, including the allowed legacy line
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
            if ALLOWED_LEGACY_LINE.search(line.strip()):
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


def test_map_exclusion_is_limited_to_adh_dist() -> None:
    assert is_excluded("packages/web/packages/adh/dist/themes/adh-themes.js.map")
    assert not is_excluded("packages/web/packages/other/dist/x.js.map")
    assert not is_excluded("docs/stray.map")
    assert not is_excluded("x.map")
