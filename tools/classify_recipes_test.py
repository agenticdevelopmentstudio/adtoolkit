#!/usr/bin/env python3
"""Self-test: the classifier must report every spec, including ones that share a basename."""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

TOOL = Path(__file__).resolve().parent / "classify_recipes.py"


def run(root: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(TOOL), "--root", str(root)], capture_output=True, text=True
    )


def test_same_basename_in_two_topics_is_two_entries() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        for topic in ("ui", "data"):
            (root / topic).mkdir()
            (root / topic / "model.md").write_text("Plain text.", encoding="utf-8")
        result = run(root)
        assert result.returncode == 0
        clean = json.loads(result.stdout.split("\n\n")[0])["clean"]
        assert sorted(clean) == ["data/model.md", "ui/model.md"]


def test_unmoved_package_is_flagged() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "button.md").write_text("Use `@agentic-toolkit/billing`.", encoding="utf-8")
        buckets = json.loads(run(root).stdout)
        assert buckets["unmoved"] == {"button.md": ["@agentic-toolkit/billing"]}


def test_empty_dir_is_an_error() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        assert run(Path(tmp)).returncode == 2


if __name__ == "__main__":
    test_same_basename_in_two_topics_is_two_entries()
    test_unmoved_package_is_flagged()
    test_empty_dir_is_an_error()
    print("classify_recipes_test: ok")
