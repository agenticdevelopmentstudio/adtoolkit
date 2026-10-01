#!/usr/bin/env python3
"""Self-test for the doc-link resolve-check. Proves the failure path, not just the happy one."""
import subprocess
import sys
import tempfile
from pathlib import Path

GUARD = Path(__file__).resolve().parent / "check_doc_links.py"


def run(root: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(GUARD), "--root", str(root)],
        capture_output=True, text=True,
    )


def check(label: str, got, want) -> None:
    if got != want:
        print(f"FAIL {label}: got {got!r}, want {want!r}", file=sys.stderr)
        sys.exit(1)


with tempfile.TemporaryDirectory() as tmp:
    # (1) A citation that resolves is silent.
    root = Path(tmp) / "ok"
    (root / "docs").mkdir(parents=True)
    (root / "docs" / "guide.md").write_text("hello\n")
    (root / "src.ts").write_text("// see docs/guide.md for why\n")
    check("resolving citation exits 0", run(root).returncode, 0)

    # (2) A citation that does not resolve fails, and names both ends.
    root = Path(tmp) / "dangling"
    (root / "docs").mkdir(parents=True)
    (root / "docs" / "guide.md").write_text("hello\n")
    (root / "src.ts").write_text("// see docs/gone.md for why\n")
    bad = run(root)
    check("dangling citation exits 1", bad.returncode, 1)
    check("names the cited path", "docs/gone.md" in bad.stdout + bad.stderr, True)
    check("names the citing site", "src.ts:1" in bad.stdout + bad.stderr, True)

    # (3) A relative citation is NOT a repo-relative one — it resolves against the
    #     citing file, so this check must not claim jurisdiction over it.
    root = Path(tmp) / "relative"
    (root / "docs").mkdir(parents=True)
    (root / "src.ts").write_text("// see ./docs/gone.md and ../docs/gone.md\n")
    check("relative paths ignored", run(root).returncode, 0)

    # (4) An empty scan is exit 2, not success. A guard that silently matches nothing
    #     is indistinguishable from a guard that passed, which is how they die.
    root = Path(tmp) / "empty"
    root.mkdir()
    check("empty scan exits 2", run(root).returncode, 2)

    # (5) A recipe corpus URI citation that resolves is silent.
    root = Path(tmp) / "uri-ok"
    (root / "recipes").mkdir(parents=True)
    (root / "recipes" / "button.md").write_text("hello\n")
    (root / "recipes" / "dialog.md").write_text(
        "---\nrelated:\n- agenticdeveloperhub://recipes/button\n---\n"
    )
    check("resolving recipe URI exits 0", run(root).returncode, 0)

    # (6) A recipe corpus URI citation that does not resolve fails, and names the
    #     offending slug.
    root = Path(tmp) / "uri-dangling"
    (root / "recipes").mkdir(parents=True)
    (root / "recipes" / "dialog.md").write_text(
        "---\nrelated:\n- agenticdeveloperhub://recipes/send-invitation-modal\n---\n"
    )
    bad = run(root)
    check("dangling recipe URI exits 1", bad.returncode, 1)
    check(
        "names the offending slug",
        "recipes/send-invitation-modal.md" in bad.stdout + bad.stderr,
        True,
    )

    # (7) The private-scope guard's own self-test carries a recipe-URI fixture
    #     string that does not name a real recipe. It is skipped by filename, not
    #     scanned as a citation into this repo.
    root = Path(tmp) / "private-scope-self-test-skipped"
    (root / "tools").mkdir(parents=True)
    (root / "tools" / "check_no_private_scope_test.py").write_text(
        'domain: agenticdeveloperhub://recipes/does-not-exist\n'
    )
    (root / "recipes").mkdir(parents=True)
    (root / "recipes" / "button.md").write_text("hello\n")
    check(
        "private-scope self-test fixture is skipped",
        run(root).returncode,
        0,
    )

    # (8) The skip is by filename, not by directory: a different file in the same
    #     tools/ dir, carrying the same fixture string, must still be scanned and
    #     fail. Without this half, widening SKIP_DIRS to swallow all of tools/
    #     would pass test (7) too, and that is not what the fix does.
    root = Path(tmp) / "tools-dir-not-fully-skipped"
    (root / "tools").mkdir(parents=True)
    (root / "tools" / "notes.md").write_text(
        'agenticdeveloperhub://recipes/does-not-exist\n'
    )
    (root / "recipes").mkdir(parents=True)
    (root / "recipes" / "button.md").write_text("hello\n")
    check(
        "same fixture string in a non-self-test file still fails",
        run(root).returncode,
        1,
    )

    # (9) THE WIDENING. A recipe citing a source path that does not exist fails —
    #     the shape that sat green in this repo 42 times over, because the old
    #     regex only ever looked at `.md`.
    root = Path(tmp) / "source-dangling"
    (root / "recipes").mkdir(parents=True)
    (root / "websites").mkdir()
    (root / "recipes" / "button.md").write_text(
        "- **React / Web:** `websites/shared/ui/src/components/button.tsx`\n"
    )
    bad = run(root)
    check("dangling source citation exits 1", bad.returncode, 1)
    check(
        "names the cited source path",
        "websites/shared/ui/src/components/button.tsx" in bad.stdout + bad.stderr,
        True,
    )
    check("names the citing recipe", "recipes/button.md:1" in bad.stdout + bad.stderr, True)

    # (10) The same citation, repointed at where the file actually lives, is silent.
    root = Path(tmp) / "source-ok"
    (root / "recipes").mkdir(parents=True)
    (root / "packages" / "web" / "packages" / "ui" / "src" / "components").mkdir(parents=True)
    (root / "packages" / "web" / "packages" / "ui" / "src" / "components" / "button.tsx").write_text("x\n")
    (root / "recipes" / "button.md").write_text(
        "- **React / Web:** `packages/web/packages/ui/src/components/button.tsx`\n"
    )
    check("resolving source citation exits 0", run(root).returncode, 0)

    # (11) The false-positive containment, and the only reason the widening is safe:
    #      a path whose FIRST SEGMENT is not a real top-level directory of this repo
    #      is not a citation into this repo and is never checked. Illustrative
    #      snippets are full of them.
    root = Path(tmp) / "not-top-level"
    (root / "recipes").mkdir(parents=True)
    (root / "packages").mkdir()
    (root / "recipes" / "guide.md").write_text(
        "Put it in `src/components/thing.ts`, or `your-app/pages/index.tsx`.\n"
        "Import order is `parser/renderer`, and the flag is `and/or`.\n"
    )
    check("non-top-level first segment ignored", run(root).returncode, 0)

    # (12) Scope: source paths are checked in docs/ and recipes/ ONLY. A manifest,
    #      an ignore file or a build script names paths relative to ITSELF, and
    #      resolving those against the repo root would be a guard that cried wolf
    #      on every package in the tree.
    root = Path(tmp) / "prose-dirs-only"
    (root / "recipes").mkdir(parents=True)
    (root / "packages").mkdir()
    (root / ".npmignore").write_text("packages/chat/base.css\n")
    (root / "packages" / "uninstall.sh").write_text("rm -f packages/ui/src/lib/utils.ts\n")
    (root / "recipes" / "guide.md").write_text("nothing to see\n")
    check("source paths outside docs/recipes are not checked", run(root).returncode, 0)

    # (13) Three shapes that name no single file, so there is nothing to resolve and
    #      nothing a reader could fix: an elision, a glob, and a parent hop.
    root = Path(tmp) / "unresolvable-shapes"
    (root / "recipes").mkdir(parents=True)
    (root / "packages").mkdir()
    (root / "recipes" / "guide.md").write_text(
        "mirrors `packages/apple/.../Sources` one-to-one\n"
        "reads `packages/themes/src/styles/*.css`\n"
        "see `packages/../packages/gone.ts`\n"
    )
    check("elision, glob and parent hop are skipped", run(root).returncode, 0)

    # (14) An empty scan is STILL exit 2 after the widening — the property that keeps
    #      a mis-rooted run from looking like a pass. Distinct from case (4): here the
    #      tree is non-empty and every file in it is skipped, which is the way a real
    #      run reaches zero.
    root = Path(tmp) / "everything-skipped"
    (root / "node_modules" / "dep").mkdir(parents=True)
    (root / "node_modules" / "dep" / "index.js").write_text("// docs/gone.md\n")
    (root / "logo.png").write_bytes(b"\x89PNG\r\n")
    check("a tree of nothing but skipped files exits 2", run(root).returncode, 2)

    # (15) An archived doc is a point-in-time record: its own dangling coordinates are
    #      not checked, but a live doc citing a missing archived doc still fails.
    root = Path(tmp) / "archive"
    (root / "docs" / "archive" / "plans").mkdir(parents=True)
    (root / "packages").mkdir()
    (root / "docs" / "archive" / "plans" / "old.md").write_text(
        "Delete: `packages/apple/Gone.swift`, see docs/gone.md\n"
    )
    (root / "docs" / "guide.md").write_text("see docs/archive/plans/old.md\n")
    check("an archived doc's own citations are skipped", run(root).returncode, 0)
    (root / "docs" / "guide.md").write_text("see docs/archive/plans/moved.md\n")
    bad = run(root)
    check("a live citation of a missing archived doc fails", bad.returncode, 1)
    check("names the archived target", "docs/archive/plans/moved.md" in bad.stderr, True)

print("check_doc_links_test: 15 passed")
