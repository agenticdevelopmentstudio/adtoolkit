"""Pure helpers for `deployment/run-ci`, split out so they can be tested without pnpm."""
import fnmatch
import json
import subprocess
from pathlib import Path


def _git(repo: Path, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True)


def reached_patterns(package_dir: Path, dist_prefix: str) -> list[str]:
    """Repo-relative globs for every `./dist/...` path the package's `exports` map names.

    `dist_prefix` is the package's dist dir relative to the repo root. A file matching one
    of these has a consumer; one that matches none is an internal byproduct.
    """
    exports = json.loads((package_dir / "package.json").read_text(encoding="utf-8")).get("exports", {})
    found: list[str] = []

    def walk(node: object) -> None:
        if isinstance(node, str):
            if node.startswith("./dist/"):
                found.append(f"{dist_prefix}/{node[len('./dist/'):]}")
        elif isinstance(node, dict):
            for v in node.values():
                walk(v)

    walk(exports)
    return found


def dist_drift(repo: Path, dist: str, reached: list[str] | None = None) -> list[str]:
    """Return one message per way `dist` (repo-relative) differs from what is committed.

    Three ways: a tracked file changed, a file is untracked and not ignored, or a file is
    untracked AND ignored. The last one is the dangerous one: adh's .gitignore ignores
    dist/ on purpose (so a plain `git add` cannot sweep in byproducts), which also means
    a newly built dist file never shows in `git status`.

    `reached` narrows the ignored case. adh's .gitignore deliberately leaves ~70 internal
    .d.ts/.d.ts.map byproducts untracked, so "untracked" alone would be red forever. When
    `reached` (globs of paths the exports map resolves) is given, an ignored untracked
    file fails only if it matches one; a non-ignored untracked file always fails. With
    `reached=None` every untracked file fails.
    """
    problems: list[str] = []
    diff = _git(repo, "diff", "--exit-code", "--stat", "--", dist)
    if diff.returncode != 0:
        problems.append("tracked dist files differ from a fresh build:\n" + diff.stdout.rstrip())
    # No --exclude-standard: this lists ignored files too, and it is the superset of the
    # --exclude-standard listing, so one call covers both new-untracked and new-ignored.
    others = _git(repo, "ls-files", "--others", "--", dist)
    files = [line for line in others.stdout.splitlines() if line]
    if reached is not None:
        visible = set(_git(repo, "ls-files", "--others", "--exclude-standard", "--", dist).stdout.splitlines())
        files = [f for f in files if f in visible or any(fnmatch.fnmatchcase(f, g) for g in reached)]
    if files:
        problems.append("dist files exist on disk but are not tracked:\n" + "\n".join(f"  {f}" for f in files))
    return problems
