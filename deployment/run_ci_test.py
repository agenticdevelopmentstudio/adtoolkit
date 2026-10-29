#!/usr/bin/env python3
"""Self-test for run-ci's adh dist drift check. Needs git, not pnpm."""
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_ci_lib import dist_drift, reached_patterns, steps_to_run  # noqa: E402

DIST = "pkg/dist"


def git(repo: Path, *args: str) -> None:
    subprocess.run(["git", "-C", str(repo), *args], check=True, capture_output=True)


def check(label: str, got, want) -> None:
    if got != want:
        print(f"FAIL {label}: got {got!r}, want {want!r}", file=sys.stderr)
        sys.exit(1)


def make_repo(root: Path, ignored: bool) -> None:
    (root / DIST).mkdir(parents=True)
    git(root, "init", "-q")
    git(root, "config", "user.email", "t@example.com")
    git(root, "config", "user.name", "t")
    (root / DIST / "a.js").write_text("one\n")
    if ignored:
        (root / "pkg" / ".gitignore").write_text("dist/\n")
        git(root, "add", "pkg/.gitignore")
        git(root, "add", "-f", f"{DIST}/a.js")  # tracked despite the ignore, as in adh
    else:
        git(root, "add", f"{DIST}/a.js")
    git(root, "commit", "-q", "-m", "init")


with tempfile.TemporaryDirectory() as tmp:
    # (1) A clean repo passes.
    root = Path(tmp) / "clean"
    root.mkdir()
    make_repo(root, ignored=False)
    check("clean repo passes", dist_drift(root, DIST), [])

    # (2) A modified tracked file fails.
    root = Path(tmp) / "modified"
    root.mkdir()
    make_repo(root, ignored=False)
    (root / DIST / "a.js").write_text("two\n")
    check("modified tracked file fails", len(dist_drift(root, DIST)), 1)

    # (3) A new untracked, non-ignored file fails.
    root = Path(tmp) / "untracked"
    root.mkdir()
    make_repo(root, ignored=False)
    (root / DIST / "b.js").write_text("new\n")
    bad = dist_drift(root, DIST)
    check("untracked file fails", len(bad), 1)
    check("names the file", "b.js" in bad[0], True)

    # (4) A new untracked file that IS ignored fails too: git status cannot see it.
    root = Path(tmp) / "ignored"
    root.mkdir()
    make_repo(root, ignored=True)
    check("tracked-but-ignored dist is clean", dist_drift(root, DIST), [])
    (root / DIST / "b.js").write_text("new\n")
    bad = dist_drift(root, DIST)
    check("ignored new file fails", len(bad), 1)
    check("names the ignored file", "b.js" in bad[0], True)

    # (5) With an exports map: an ignored untracked file nothing reaches is a byproduct and
    #     passes; one the map reaches fails; a non-ignored untracked file fails regardless.
    reached = [f"{DIST}/b.js"]
    (root / DIST / "internal.d.ts").write_text("x\n")
    bad = dist_drift(root, DIST, reached)
    check("only the reached file fails", len(bad), 1)
    check("names the reached file", "b.js" in bad[0] and "internal" not in bad[0], True)
    check("unreached ignored file passes", dist_drift(root, DIST, []), [])
    root = Path(tmp) / "visible"
    root.mkdir()
    make_repo(root, ignored=False)
    (root / DIST / "c.js").write_text("new\n")
    check("visible untracked fails despite empty reach", len(dist_drift(root, DIST, [])), 1)

    # (6) reached_patterns reads every ./dist path out of nested exports.
    (root / "pkg" / "package.json").write_text(
        '{"exports": {".": {"types": "./dist/i.d.ts", "import": "./dist/i.js"},'
        ' "./x": {"browser": {"import": "./dist/x/*.js"}}, "./src": "./src/a.ts"}}'
    )
    check("exports globs", sorted(reached_patterns(root / "pkg", DIST)), [f"{DIST}/i.d.ts", f"{DIST}/i.js", f"{DIST}/x/*.js"])

# (7) --skip drops the named steps and keeps the order; --from composes with it; an
#     unknown name is an error rather than a skip of nothing.
names = ["a", "b", "c", "d"]
check("no skip runs all", steps_to_run(names, None, []), names)
check("skip drops one", steps_to_run(names, None, ["b"]), ["a", "c", "d"])
check("skip repeats", steps_to_run(names, None, ["a", "d"]), ["b", "c"])
check("from and skip compose", steps_to_run(names, "b", ["c"]), ["b", "d"])
try:
    steps_to_run(names, None, ["nope"])
    check("unknown skip raises", "returned", "ValueError")
except ValueError:
    pass

print("ok")
