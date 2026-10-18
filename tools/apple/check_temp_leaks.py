#!/usr/bin/env python3
"""Find Swift test files that leave files behind in the system temp directory.

    tools/apple/check_temp_leaks.py              # this toolkit's Apple tests
    tools/apple/check_temp_leaks.py PATH ...     # these files or directories (a consumer's repo)
    tools/apple/check_temp_leaks.py --json       # machine-readable findings

Test runs had piled tens of thousands of entries into $TMPDIR. Foundation
ignores the TMPDIR variable on macOS, so a runner cannot redirect them: each
test has to clean up after itself. The rule this checks:

  every test makes one unique directory under the temp dir, puts everything
  it writes inside it, and removes that whole directory when it finishes.

Two shapes break it, and both are visible in the source:

  no-cleanup      the file builds a temp path but never calls removeItem,
                  so whatever it makes stays forever.
  sqlite-in-root  a SQLite file sits directly in the temp dir
                  (NSTemporaryDirectory() + "x-\\(UUID()).db"). Removing the
                  .db leaves its -wal and -shm behind; the database belongs
                  inside the test's own directory, removed with it.

A line that must break the rule anyway carries `// temp-leak-check: ok` with
the reason, at its end or alone on the line above it. Exit 0 when nothing is
found, 1 otherwise.

Consumers (Stenographer, the Kitchen) import this module from their submodule
checkout and call `check()` over their own roots from a repo guard test, so
the rule has one copy.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

TOOLKIT = Path(__file__).resolve().parents[2]
DEFAULT_ROOTS = (TOOLKIT / "packages/apple",)
# Build output, fetched packages, and other worktrees (which hold their own copy of the tree).
SKIP_PARTS = {".build", "DerivedData", "build", "node_modules", "checkouts", ".claude"}
TEMP_ROOT = re.compile(r"NSTemporaryDirectory\(\)|\.temporaryDirectory\b")
SQLITE_NAME = re.compile(r'\.(db|sqlite3?|store)"')
REMOVAL = re.compile(r"\bremoveItem\(")
WAIVER = "temp-leak-check: ok"


@dataclass(frozen=True)
class Finding:
    path: str
    line: int
    rule: str
    text: str


def is_test_file(path: Path) -> bool:
    return path.suffix == ".swift" and any("Tests" in part for part in path.parts)


def swift_test_files(roots: list[Path]) -> list[Path]:
    files: list[Path] = []
    for root in roots:
        candidates = [root] if root.is_file() else sorted(root.rglob("*.swift"))
        files += [p for p in candidates
                  if is_test_file(p) and not SKIP_PARTS & set(p.relative_to(root).parts)]
    return files


def _statement(lines: list[str], index: int) -> str:
    """The line plus any `.method` continuation lines, so a chained path reads as one."""
    parts = [lines[index]]
    for following in lines[index + 1:index + 4]:
        if not following.lstrip().startswith("."):
            break
        parts.append(following.strip())
    return " ".join(parts)


def _waived(lines: list[str], index: int) -> bool:
    """The waiver sits on the line itself, or alone on the line above (to keep lines short)."""
    above = lines[index - 1].strip() if index else ""
    return WAIVER in lines[index] or (above.startswith("//") and WAIVER in above)


def check_text(text: str, path: str) -> list[Finding]:
    lines = text.splitlines()
    findings: list[Finding] = []
    temp_lines = [i for i, line in enumerate(lines)
                  if TEMP_ROOT.search(line) and not _waived(lines, i)]
    for i in temp_lines:
        statement = _statement(lines, i)
        tail = statement[TEMP_ROOT.search(statement).end():]
        # One path component past the temp root, and it is a SQLite file.
        component = re.match(r'\s*(\+|\.appending(PathComponent)?\()\s*"([^"/]*)"', tail)
        if component and SQLITE_NAME.search(f'"{component.group(3)}"'):
            findings.append(Finding(path, i + 1, "sqlite-in-root", lines[i].strip()))
    if temp_lines and not REMOVAL.search(text):
        first = temp_lines[0]
        findings.append(Finding(path, first + 1, "no-cleanup", lines[first].strip()))
    return findings


def check(roots: list[Path], relative_to: Path | None = None) -> list[Finding]:
    """Every finding under `roots`; paths are shown relative to `relative_to` when inside it."""
    base = (relative_to or Path.cwd()).resolve()
    findings: list[Finding] = []
    for path in swift_test_files([r.resolve() for r in roots]):
        shown = path.relative_to(base) if path.is_relative_to(base) else path
        findings += check_text(path.read_text(errors="ignore"), str(shown))
    return findings


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("paths", nargs="*", type=Path,
                   help="files or directories (default: this toolkit's packages/apple)")
    p.add_argument("--json", action="store_true", help="print the findings as JSON")
    args = p.parse_args(argv)
    findings = check(args.paths or list(DEFAULT_ROOTS))
    if args.json:
        print(json.dumps([asdict(f) for f in findings], indent=2))
    else:
        for f in findings:
            print(f"{f.path}:{f.line}: {f.rule}: {f.text}")
        print(f"{len(findings)} finding(s)" if findings else "no temp-dir leaks found")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
