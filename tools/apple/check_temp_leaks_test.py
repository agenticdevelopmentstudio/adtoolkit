#!/usr/bin/env python3
"""Tests for check_temp_leaks.py: leaking test files are named, and the toolkit has none.

Run: python3 -m pytest tools/apple/check_temp_leaks_test.py -q
"""
from __future__ import annotations

from pathlib import Path

import check_temp_leaks as ctl


def rules(text: str) -> list[str]:
    return [f.rule for f in ctl.check_text(text, "FooTests.swift")]


def test_a_database_directly_in_the_temp_root_is_flagged():
    text = 'path = NSTemporaryDirectory() + "billing-\\(UUID().uuidString).db"\nremoveItem(atPath: path)\n'
    assert rules(text) == ["sqlite-in-root"]


def test_a_chained_database_component_is_flagged():
    text = ('let url = FileManager.default.temporaryDirectory\n'
            '    .appendingPathComponent("x-\\(UUID()).sqlite")\n'
            'try? FileManager.default.removeItem(at: url)\n')
    assert rules(text) == ["sqlite-in-root"]


def test_a_database_inside_its_own_directory_passes():
    text = ('let dir = FileManager.default.temporaryDirectory\n'
            '    .appendingPathComponent("x-\\(UUID().uuidString)")\n'
            '    .appendingPathComponent("Test.db")\n'
            'try? FileManager.default.removeItem(at: dir)\n')
    assert rules(text) == []


def test_a_temp_path_with_no_removal_is_flagged():
    text = 'let dir = FileManager.default.temporaryDirectory.appendingPathComponent("x-\\(UUID())")\n'
    assert rules(text) == ["no-cleanup"]


def test_a_waived_line_is_not_flagged():
    text = 'let repo = GitRepo(path: NSTemporaryDirectory(), name: "a")  // temp-leak-check: ok path only\n'
    assert rules(text) == []


def test_a_waiver_alone_on_the_line_above_counts():
    text = ('// temp-leak-check: ok path only\n'
            'let repo = GitRepo(path: NSTemporaryDirectory(), name: "a")\n')
    assert rules(text) == []


def test_only_files_under_a_tests_directory_are_checked(tmp_path: Path):
    (tmp_path / "Sources").mkdir()
    (tmp_path / "FooTests").mkdir()
    (tmp_path / "Sources/A.swift").write_text("NSTemporaryDirectory()\n")
    (tmp_path / "FooTests/B.swift").write_text("NSTemporaryDirectory()\n")
    assert [p.name for p in ctl.swift_test_files([tmp_path])] == ["B.swift"]


def test_other_worktrees_under_the_root_are_skipped(tmp_path: Path):
    copy = tmp_path / ".claude/worktrees/w/FooTests"
    copy.mkdir(parents=True)
    (copy / "B.swift").write_text("NSTemporaryDirectory()\n")
    assert ctl.swift_test_files([tmp_path]) == []
    # ...but a root that is itself a worktree is still scanned.
    assert [p.name for p in ctl.swift_test_files([tmp_path / ".claude/worktrees/w"])] == ["B.swift"]


def test_no_toolkit_test_file_leaks():
    findings = ctl.check(list(ctl.DEFAULT_ROOTS), relative_to=ctl.TOOLKIT)
    assert findings == [], "\n".join(f"{f.path}:{f.line}: {f.rule}" for f in findings)
