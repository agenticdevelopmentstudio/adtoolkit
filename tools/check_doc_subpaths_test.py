#!/usr/bin/env python3
"""Self-test: the documented-subpath guard must catch a bad subpath AND an
invented scope, and must never fire on a wildcard export or a third party.

Every case is a real shape from the migration. `test_wrong_scope_is_caught`
mirrors chat's README, which named itself `@agentic-cookbook/agenticdevelopertoolkit/chat`
and passed every existing gate because neither greps for the right string.
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

GUARD = Path(__file__).resolve().parent / "check_doc_subpaths.py"


def _make_package(root: Path, dirname: str, name: str, exports: dict, readme: str) -> None:
    pkg = root / dirname
    pkg.mkdir(parents=True, exist_ok=True)
    (pkg / "package.json").write_text(
        json.dumps({"name": name, "exports": exports}), encoding="utf-8"
    )
    (pkg / "README.md").write_text(readme, encoding="utf-8")


def run(root: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(GUARD), "--root", str(root)],
        capture_output=True,
        text=True,
    )


def test_clean_tree_passes() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        _make_package(
            root, "widget", "@agenticdevelopertoolkit/widget",
            {".": "./dist/index.js", "./css/base.css": "./dist/css/base.css"},
            "# `@agenticdevelopertoolkit/widget`\n\n"
            "```tsx\nimport '@agenticdevelopertoolkit/widget/css/base.css'\n```\n",
        )
        result = run(root)
        assert result.returncode == 0, f"clean tree rejected: {result.stderr}"


def test_unexported_subpath_is_caught() -> None:
    """The `controls`-shaped defect: correct scope, a subpath the manifest
    never exports (the DIST path, not the export key)."""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        _make_package(
            root, "widget", "@agenticdevelopertoolkit/widget",
            {".": "./dist/index.js", "./styles.css": "./dist/styles/widget.css"},
            "```tsx\nimport '@agenticdevelopertoolkit/widget/styles/widget.css'\n```\n",
        )
        result = run(root)
        assert result.returncode == 1, "unexported subpath survived the guard"
        assert "is not exported" in result.stderr, result.stderr


def test_wrong_scope_is_caught() -> None:
    """The `chat`-shaped defect: an invented scope, which no scope-string grep
    and no real-name sweep can find, because the correct name never appears."""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        _make_package(
            root, "widget", "@agenticdevelopertoolkit/widget",
            {".": "./dist/index.js"},
            "# `@agentic-cookbook/agenticdevelopertoolkit/widget`\n\n"
            "```tsx\nimport { Widget } from '@agentic-cookbook/agenticdevelopertoolkit/widget'\n```\n",
        )
        result = run(root)
        assert result.returncode == 1, "invented scope survived the guard"
        assert "wrong scope" in result.stderr, result.stderr


def test_filesystem_path_in_a_command_is_not_a_specifier() -> None:
    """A build command naming a submodule checkout on disk contains the package's
    basename as a path segment, and the toolkit's own name before it. That is a
    path, not a mis-scoped specifier."""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        _make_package(
            root, "widget", "@agenticdevelopertoolkit/widget",
            {".": "./dist/index.js"},
            '"buildCommand": "python3 ../external/agenticdevelopertoolkit/packages/web/packages/widget/tools/b.py"\n',
        )
        result = run(root)
        assert result.returncode == 0, result.stderr


def test_wildcard_export_resolves() -> None:
    """`ui` exports `./components/*`. The subpath match must be a GLOB, not a
    set-membership test, or every wildcarded package fails on everything."""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        _make_package(
            root, "widget", "@agenticdevelopertoolkit/widget",
            {".": "./dist/index.js", "./components/*": "./dist/components/*.js"},
            "```tsx\nimport { Button } from '@agenticdevelopertoolkit/widget/components/button'\n```\n",
        )
        result = run(root)
        assert result.returncode == 0, f"wildcard export false-flagged: {result.stderr}"


def test_third_party_subpath_is_skipped() -> None:
    """A README may legitimately name a third-party package sharing this
    basename. This guard has no exports map for it and must not invent one."""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        _make_package(
            root, "widget", "@agenticdevelopertoolkit/widget",
            {".": "./dist/index.js"},
            "See also `some-other-lib/widget/docs` for the underlying primitive.\n",
        )
        result = run(root)
        assert result.returncode == 0, f"third-party reference false-flagged: {result.stderr}"


def test_empty_scan_is_not_a_pass() -> None:
    """A guard that greens on a wrong path, or on packages that ship no docs
    at all, is worse than no guard."""
    with tempfile.TemporaryDirectory() as tmp:
        missing = Path(tmp) / "nope"
        result = run(missing)
        assert result.returncode == 2, f"missing path returned {result.returncode}"

    with tempfile.TemporaryDirectory() as tmp:
        empty = Path(tmp)
        result = run(empty)
        assert result.returncode == 2, f"no packages returned {result.returncode}"

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        pkg = root / "widget"
        pkg.mkdir()
        (pkg / "package.json").write_text(
            json.dumps({"name": "@agenticdevelopertoolkit/widget", "exports": {}}),
            encoding="utf-8",
        )
        result = run(root)
        assert result.returncode == 2, f"package with no markdown returned {result.returncode}"


def main() -> int:
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
    print(f"check_doc_subpaths_test: {len(tests)} passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
