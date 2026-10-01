#!/usr/bin/env python3
"""A documented subpath must be one the package's `exports` map actually exports.

Task 9's review found three `controls` READMEs instructing the reader to import
`@agenticdevelopertoolkit/controls/filtered-list/styles/filtered-list.css`.
That is the path the `exports` map points AT (`dist/filtered-list/styles/filtered-list.css`),
not the subpath it EXPORTS (`./filtered-list/styles.css`) — following the README's
version raises `ERR_PACKAGE_PATH_NOT_EXPORTED`. No compiler reads a README, and the
scope name was perfectly correct, so nothing caught it until a human read the file.

A second, sharper shape of the same defect shipped in `chat`'s README: five lines
named the package `@agentic-cookbook/agenticdevelopertoolkit/chat` — an invented
scope, not a bad subpath. Neither existing gate could see it. The private-scope
guard (`check_no_private_scope.py`) searches for the literal string
`@agentic-toolkit/` and this string does not contain it. A by-hand sweep keyed on
the package's real name (`@agenticdevelopertoolkit/chat`) misses it for the same
reason in reverse: the bogus prefix means the correct name never appears in the
file for the sweep to find. So this guard does not search prose for a known-bad
string either — it starts from each package's OWN manifest name, finds every place
its short name shows up as a path segment in that package's docs, and checks
whether the specifier surrounding it is what the manifest says it should be.

## What counts as a hit

For every `@agenticdevelopertoolkit/*` package discovered under `--root`, scan its
markdown for a quoted string or backtick span containing `<basename>` as a path
segment (`/<basename>` followed by `/` or end-of-string) and inspect what precedes
it:

  * the text before `/<basename>` is not exactly `@agenticdevelopertoolkit`, and
    the text contains "agenticdevelopertoolkit" somewhere — a real attempt to name
    this package that got the scope wrong. Reported as a wrong-scope finding.
  * the prefix IS `@agenticdevelopertoolkit` and a subpath follows — the subpath
    must match one of the package's own `exports` keys.
  * the prefix does not match and the text never mentions "agenticdevelopertoolkit"
    at all — a genuine third party whose name happens to share this package's
    basename (e.g. some unrelated `.../chat/...`). This guard has no exports map
    for a third-party package and must not invent one, so it is skipped.

## Wildcards are real

`ui` exports `"./components/*"` and `"./blocks/*"`. A subpath is matched against
export keys with `fnmatch`, never as a set-membership test — the set form would
report `ui/components/button` as broken when it resolves fine.

Exit 0 clean, 1 on a finding, 2 on an empty scan (no `@agenticdevelopertoolkit/*`
packages found, or none of them ship any markdown) — an empty scan is never a
pass, it is a guard that scanned nothing and has no business reporting clean.

Fix a finding by correcting the prose to match the manifest, never by widening the
manifest to match the prose — widening grows a public package's API surface on
the strength of a typo.
"""
from __future__ import annotations

import argparse
import fnmatch
import json
import re
import sys
from pathlib import Path

SCOPE = "@agenticdevelopertoolkit"
DEFAULT_ROOT = Path(__file__).resolve().parents[1] / "packages" / "web" / "packages"

SKIP_DIRS = {"node_modules", "dist", ".turbo", ".git", "coverage"}

# The two shapes an npm specifier appears in inside markdown: a JS import
# string ('...'/"...") or an inline-code / heading mention (`...`).
QUOTED_RE = re.compile(r"""(['"])(.*?)\1""")
BACKTICK_RE = re.compile(r"`([^`]+)`")


def discover_packages(root: Path) -> "dict[str, Path]":
    """Top-level dirs under root whose own package.json names an
    @agenticdevelopertoolkit/* package. npm name -> package directory."""
    found: dict[str, Path] = {}
    if not root.is_dir():
        return found
    for entry in sorted(root.iterdir()):
        if not entry.is_dir() or entry.name in SKIP_DIRS:
            continue
        manifest = entry / "package.json"
        if not manifest.is_file():
            continue
        try:
            data = json.loads(manifest.read_text(encoding="utf-8"))
        except (ValueError, OSError):
            continue
        name = data.get("name", "")
        if isinstance(name, str) and name.startswith(SCOPE + "/"):
            found[name] = entry
    return found


def exports_of(pkg_dir: Path) -> dict:
    """The package's exports map, keys only mattering to callers here."""
    manifest = pkg_dir / "package.json"
    try:
        data = json.loads(manifest.read_text(encoding="utf-8"))
    except (ValueError, OSError):
        return {}
    exports = data.get("exports", {})
    if isinstance(exports, str):
        return {".": exports}
    return exports if isinstance(exports, dict) else {}


def subpath_is_exported(subpath: str, exports: dict) -> bool:
    """Match `subpath` against every export key as a GLOB (`fnmatch`), never as
    set membership — `./components/*` legitimately covers `components/button`
    and a naive `in` check would report that as broken."""
    candidate = "./" + subpath.lstrip("./")
    return any(key != "." and fnmatch.fnmatchcase(candidate, key) for key in exports)


def markdown_files(pkg_dir: Path) -> "list[Path]":
    files = []
    for path in sorted(pkg_dir.rglob("*.md")):
        if any(part in SKIP_DIRS for part in path.relative_to(pkg_dir).parts):
            continue
        files.append(path)
    return files


def line_texts(line: str) -> "list[str]":
    return [m.group(2) for m in QUOTED_RE.finditer(line)] + \
           [m.group(1) for m in BACKTICK_RE.finditer(line)]


def candidate_for(text: str, basename: str) -> "tuple[str, str] | None":
    """If `basename` appears as a path SEGMENT of `text` (immediately preceded
    by `/`, and followed by `/` or end-of-string), return (prefix, subpath) —
    subpath is '' for a bare package reference. None if `basename` is not a
    path segment of `text` at all (a plain word, or a substring of some other
    word, never counts)."""
    text = text.strip()
    seg = "/" + basename
    idx = text.rfind(seg)
    while idx != -1:
        end = idx + len(seg)
        after = text[end:end + 1]
        if after in ("", "/"):
            return text[:idx], text[end:].lstrip("/")
        idx = text.rfind(seg, 0, idx)
    return None


def find_violations(root: Path) -> "tuple[list[tuple[Path, int, str]], int, int]":
    """(violations, markdown files scanned, packages discovered).

    A violation is (path, lineno, message)."""
    packages = discover_packages(root)
    basenames = {
        name.split("/", 1)[1]: (name, exports_of(pkg_dir))
        for name, pkg_dir in packages.items()
    }

    violations: "list[tuple[Path, int, str]]" = []
    files_scanned = 0
    for pkg_dir in packages.values():
        for md_path in markdown_files(pkg_dir):
            files_scanned += 1
            lines = md_path.read_text(encoding="utf-8", errors="replace").splitlines()
            for lineno, line in enumerate(lines, 1):
                for text in line_texts(line):
                    for basename, (full_name, exports) in basenames.items():
                        hit = candidate_for(text, basename)
                        if hit is None:
                            continue
                        prefix, subpath = hit
                        if prefix != SCOPE:
                            if "agenticdevelopertoolkit" not in text.lower():
                                continue  # a third party sharing this basename
                            violations.append((
                                md_path, lineno,
                                f"wrong scope in {text!r} — the package is "
                                f"{full_name!r}, not {prefix + '/' + basename!r}",
                            ))
                            continue
                        if not subpath:
                            continue  # bare package import: always the "." export
                        if not subpath_is_exported(subpath, exports):
                            keys = sorted(k for k in exports if k != ".")
                            violations.append((
                                md_path, lineno,
                                f"{full_name}/{subpath} is not exported "
                                f"(exports: {', '.join(keys) or '(none)'})",
                            ))
    return violations, files_scanned, len(packages)


def main(argv: "list[str] | None" = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", type=Path, default=DEFAULT_ROOT,
                    help="packages/web/packages directory to scan (default: this toolkit's)")
    args = ap.parse_args(argv)

    if not args.root.is_dir():
        print(f"check_doc_subpaths: no such path: {args.root}", file=sys.stderr)
        return 2

    packages = discover_packages(args.root)
    if not packages:
        print(
            f"check_doc_subpaths: no {SCOPE}/* packages found under {args.root} — "
            "the guard would have no exports map to check anything against. "
            "Refusing to report clean.",
            file=sys.stderr,
        )
        return 2

    violations, files_scanned, package_count = find_violations(args.root)
    if files_scanned == 0:
        print(
            f"check_doc_subpaths: {package_count} package(s) found under {args.root}, "
            "but none ship any markdown. Refusing to report clean.",
            file=sys.stderr,
        )
        return 2

    if violations:
        for path, lineno, message in violations:
            print(f"{path}:{lineno}: {message}", file=sys.stderr)
        print(
            f"\n{len(violations)} documented subpath violation(s) across "
            f"{package_count} package(s). Fix the prose to match the manifest — "
            "never widen the manifest to match the prose.",
            file=sys.stderr,
        )
        return 1

    print(
        f"check_doc_subpaths: {files_scanned} markdown file(s) across "
        f"{package_count} package(s), all documented subpaths resolve"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
