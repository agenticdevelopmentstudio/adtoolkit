#!/usr/bin/env python3
"""Every repo-relative `docs/…md` or `recipes/…md` citation in this repo must resolve,
and so must every `agenticdeveloperhub://recipes/<slug>` citation — the recipe corpus's
own cross-reference scheme, used in `domain:` (self-resolving), `ingredients:`/`related:`
frontmatter lists, and an ingredient table's Domain column.

AND every repo-relative citation of a SOURCE path made from inside `docs/` or `recipes/`.

That last clause is the widening, and it is worth saying why. The `.md`-only regex was
honest about its scope and completely green while 42 recipe citations pointed at
`websites/shared/ui/…` — a directory tree that does not exist in this repo at all; the
files live at `packages/web/packages/ui/…`. A recipe's "Platform Notes" section is almost
entirely source-path citations, so the one part of a recipe most likely to rot was the one
part this guard could not see. A dangling `.tsx` misleads a reader exactly as much as a
dangling `.md` does.

The false-positive risk that kept the original scope narrow is real: prose is full of
path-shaped strings that are not citations into this repo (`src/foo.ts` in an example
snippet, `your-app/pages/index.tsx` in an integration walkthrough, `and/or`). The
containment is a single rule: a source-path citation is only checked when its FIRST
SEGMENT is a real top-level directory of the scanned root. `websites/shared/ui/x.tsx` is
checked because `websites/` exists here; `src/foo.ts` and `your-app/x.ts` are not checked
at all, because nothing in this repo could ever have been meant by them.

Three shapes are skipped even under a real top-level directory, because none of them is
a coordinate anyone can follow or fix: a `...` elision segment, a `*` glob, and a `..`
parent hop.

The scope guard is a denylist and knows the private scope's name; this is the complement.
It asks only whether a reader following the citation lands on a file, which is the property
that actually matters and the one that survives the private repo being renamed.

Exit 0 clean, 1 dangling citations found, 2 nothing scanned.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# A repo-relative doc path. The lookbehind rejects `./docs/x.md` and `../docs/x.md`
# (relative to the citing file, so not ours to resolve) and `https://…/docs/x.md`.
CITATION = re.compile(r"(?<![./\w-])((?:docs|recipes)/[\w./-]+\.md)\b")

# The recipe corpus's own cross-reference scheme: `agenticdeveloperhub://recipes/<slug>`,
# used in a recipe's `domain:` (self-resolving — the file always exists, it's citing
# itself), `ingredients:`/`related:` frontmatter lists, and an ingredient table's Domain
# column. check_no_private_scope.py's product-name pattern carries a matching
# `(?!://recipes/)` lookahead that carves this same scheme shape out of its leak check —
# that guard is answering "is this a product-name leak?" (no, it's an internal URI
# scheme); this pattern answers the complementary question "does it still resolve to a
# real file?" (not necessarily — a slug can name a recipe that stayed private, or one
# that was never written). Both claims are true of the same string at once.
RECIPE_URI = re.compile(r"agenticdeveloperhub://recipes/([a-z0-9-]+)\b")

# A repo-relative path of two or more segments, checked ONLY inside docs/ and recipes/
# and ONLY when its first segment is a real top-level directory (see the docstring).
# The lookbehind is the same one CITATION uses: `./x/y.ts`, `../x/y.ts` and
# `https://host/x/y.ts` are not repo-relative and are not ours to resolve.
SOURCE_CITATION = re.compile(r"(?<![./\w-])(\w[\w.-]*(?:/[\w.@+-]+)+)")

# Prose directories whose source-path citations are checked. Everything else in the
# repo is left alone: package manifests, ignore files and build scripts are full of
# paths that are relative to themselves rather than to the repo root.
PROSE_DIRS = ("docs", "recipes")

# Trailing sentence punctuation the regex happily swallows.
_TRAILING = "/.,;:)]}\"'`"
SKIP_DIRS = {"node_modules", "dist", ".turbo", ".git", "coverage", ".next"}
# A file under any `archive/` directory is a record of how the code looked when it was
# written — an executed plan's `git rm` list, a research note's "files modified" log.
# Repointing its coordinates would falsify the record, and the files it names are gone
# by design. It is skipped as a citing site only: a live doc citing an archived one is
# still checked, so moving a doc into an archive cannot strand the links to it.
ARCHIVE_DIR = "archive"
SKIP_SUFFIXES = {".png", ".jpg", ".jpeg", ".svg", ".woff2", ".map", ".lock"}
SKIP_NAMES = {"pnpm-lock.yaml", "package-lock.json"}
# The resolve-check's own self-test writes synthetic doc citations into temp
# dirs to prove the pass/fail paths, but those same literal fixture strings
# sit in the self-test's own source, and a repo-root scan (this guard's
# default) walks tools/ same as everything else. Skip that one file rather
# than the strings inside it: they are proof-of-behavior, not a citation
# into this repo. The private-scope guard's self-test carries the same kind
# of fixture — a recipe URI written to prove the `(?!://recipes/)` carve-out
# fires — and is skipped for the same reason.
SKIP_NAMES |= {"check_doc_links_test.py", "check_no_private_scope_test.py"}


def normalize_source_path(raw: str, rest: str, top_level: set[str]) -> str | None:
    """The cited path, or None if it is not a citation this guard claims.

    `rest` is the remainder of the line after the match. `*` is deliberately outside
    the path pattern, so `packages/x/*.css` matches only as far as `packages/x` and
    the glob shows up here as a `rest` beginning `/*` — checking it that way keeps a
    bold-wrapped `**packages/x/y.ts**` (whose `rest` merely STARTS with `*`) a real
    citation rather than silently unchecked.
    """
    if rest.startswith("/*"):
        return None
    # A glob or placeholder inside the FILENAME (`pre_*_test.py`, `pre_<area>_test.py`)
    # stops the pattern mid-name, leaving a half-name that is no coordinate. `**` is not
    # one: that is a bold-wrapper closing a real citation.
    if rest.startswith("<") or (rest.startswith("*") and not rest.startswith("**")
                                and (raw[-1] in "._-" or rest[1:2].isalnum() or rest[1:2] == "_")):
        return None
    cited = raw.rstrip(_TRAILING)
    parts = cited.split("/")
    if len(parts) < 2 or parts[0] not in top_level:
        return None
    # `packages/apple/.../Sources` elides and `../x/y.ts` hops: neither names one file,
    # so neither can be resolved, and neither is a coordinate a reader could fix.
    if any(seg in ("...", "..") for seg in parts):
        return None
    return cited


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent.parent))
    args = ap.parse_args()
    root = Path(args.root).resolve()

    # Real top-level directories of the scanned root — the whole false-positive
    # containment for source-path citations (see the docstring). Computed from the
    # tree rather than hardcoded so a new top-level directory is covered the day it
    # lands, and so the self-test's temp roots behave like the real one.
    top_level = {
        child.name
        for child in root.iterdir()
        if child.is_dir() and not child.name.startswith(".") and child.name not in SKIP_DIRS
    }

    hits: dict[str, list[str]] = {}

    def record(cited: str, where: str) -> None:
        seen = hits.setdefault(cited, [])
        # One line can carry the same path twice (and a doc-path citation is matched
        # by both CITATION and SOURCE_CITATION) — report the site once.
        if where not in seen:
            seen.append(where)

    scanned = 0
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix.lower() in SKIP_SUFFIXES:
            continue
        rel = path.relative_to(root)
        if SKIP_DIRS & set(rel.parts) or path.name in SKIP_NAMES or ARCHIVE_DIR in rel.parts[:-1]:
            continue
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        scanned += 1
        in_prose = rel.parts[0] in PROSE_DIRS
        for i, line in enumerate(lines, 1):
            for m in CITATION.finditer(line):
                cited = m.group(1)
                if not (root / cited).exists():
                    record(cited, f"{rel}:{i}")
            for m in RECIPE_URI.finditer(line):
                cited = f"recipes/{m.group(1)}.md"
                if not (root / cited).exists():
                    record(cited, f"{rel}:{i}")
            if not in_prose:
                continue
            for m in SOURCE_CITATION.finditer(line):
                cited = normalize_source_path(m.group(1), line[m.end():], top_level)
                if cited is None or (root / cited).exists():
                    continue
                record(cited, f"{rel}:{i}")

    if scanned == 0:
        print(f"check_doc_links: scanned NOTHING under {root} — wrong root, or the "
              f"skip list ate the tree. Not a pass.", file=sys.stderr)
        sys.exit(2)

    if hits:
        for cited, where in sorted(hits.items(), key=lambda kv: -len(kv[1])):
            print(f"{cited} does not exist here ({len(where)} citation(s)):", file=sys.stderr)
            for w in where:
                print(f"    {w}", file=sys.stderr)
        print(f"\ncheck_doc_links: {len(hits)} dangling doc path(s) over {scanned} files. "
              f"Either bring the file, or drop the coordinate and keep the claim.",
              file=sys.stderr)
        sys.exit(1)

    print(f"check_doc_links: OK — every citation resolves ({scanned} files scanned)")


if __name__ == "__main__":
    main()
