#!/usr/bin/env python3
"""Tests for macos_app_release.shell.

Run: python3 -m pytest tools/apple/macos_app_release_shell_test.py -q
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest

from macos_app_release import shell


def test_check_raises_with_output():
    p = subprocess.CompletedProcess(["x"], 3, "out", "err")
    with pytest.raises(RuntimeError, match=r"thing failed \(exit 3\):\nerrout"):
        shell.check(p, "thing")


def test_check_passes_a_successful_process_through():
    p = subprocess.CompletedProcess(["x"], 0, "out", "")
    assert shell.check(p, "thing") is p


def test_capture_hook_passes_env_and_cwd(tmp_path):
    p = shell.capture_hook([sys.executable, "-c", "import os;print(os.getcwd());print(os.environ['X'])"],
                           cwd=tmp_path, env={"X": "1"})
    cwd, x = p.stdout.split()
    assert p.returncode == 0 and Path(cwd).resolve() == tmp_path.resolve() and x == "1"


def test_run_hook_returns_exit_code(tmp_path):
    assert shell.run_hook([sys.executable, "-c", "raise SystemExit(4)"], cwd=tmp_path, env={}) == 4


def test_run_hook_streams_output(tmp_path, capfd):
    assert shell.run_hook([sys.executable, "-c", "print('hello')"], cwd=tmp_path, env={}) == 0
    assert "hello" in capfd.readouterr().out


def test_subprocess_runner_runs_in_cwd_and_captures(tmp_path):
    run = shell.subprocess_runner(False, cwd=tmp_path)
    p = run([sys.executable, "-c", "import os;print(os.getcwd())"])
    assert Path(p.stdout.strip()).resolve() == tmp_path.resolve()


def test_step_and_bullet_format(capsys):
    shell.step("go")
    shell.bullet("detail")
    assert capsys.readouterr().out == "==> go\n  → detail\n"


def test_main_checkout_is_parent_of_common_dir(tmp_path):
    def run(argv):
        assert argv[:3] == ["git", "-C", str(tmp_path / "wt")]
        assert "--git-common-dir" in argv
        return subprocess.CompletedProcess(argv, 0, str(tmp_path / "main/.git") + "\n", "")
    assert shell.main_checkout(tmp_path / "wt", run) == tmp_path / "main"


def test_main_checkout_surfaces_a_git_failure(tmp_path):
    run = lambda argv: subprocess.CompletedProcess(argv, 128, "", "not a git repository")
    with pytest.raises(RuntimeError, match="not a git repository"):
        shell.main_checkout(tmp_path, run)
