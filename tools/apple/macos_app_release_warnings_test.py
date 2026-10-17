#!/usr/bin/env python3
"""Tests for macos_app_release.warnings -- zero warnings except the owner's allowlist.

Ported from Stenographer's tests/test_build_warnings.py. The clean-build orchestration
runs a real `python -c` hook, which touches nothing outside tmp_path.

Run: python3 -m pytest tools/apple/macos_app_release_warnings_test.py -q
"""
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

import pytest

from macos_app_release import warnings as bw
from macos_app_release_fixtures import config

LOG = """\
CompileSwift normal arm64 /r/App/Sources/A.swift
/r/App/Sources/A.swift:10:5: warning: variable 'x' was never used
/r/App/Sources/A.swift:10:5: warning: variable 'x' was never used
/r/external/toolkit/Sources/B.swift:3:1: warning: deprecated API
warning: Metadata extraction skipped. No AppIntents.framework dependency found.
note: nothing to see
"""
UNUSED_X = "/r/App/Sources/A.swift:10:5: warning: variable 'x' was never used"


def _allow(tmp_path, entries):
    path = tmp_path / "allow.json"
    path.write_text(json.dumps({"allowed": entries}))
    return path


def test_log_warnings_dedupes_in_order():
    assert bw.log_warnings(LOG) == [
        UNUSED_X,
        "/r/external/toolkit/Sources/B.swift:3:1: warning: deprecated API",
        "warning: Metadata extraction skipped. No AppIntents.framework dependency found.",
    ]


def test_sort_warnings_splits_accepted_from_unaccepted(tmp_path):
    allow = bw.load_allowlist(_allow(tmp_path, [
        {"pattern": "Metadata extraction skipped", "reason": "toolchain"},
        {"pattern": r"external/toolkit/.*deprecated API", "reason": "submodule"},
        {"pattern": "never-hit", "reason": "old"},
    ]))
    unaccepted, accepted, unused = bw.sort_warnings(bw.log_warnings(LOG), allow)
    assert unaccepted == [UNUSED_X]
    assert list(accepted) == ["Metadata extraction skipped", r"external/toolkit/.*deprecated API"]
    assert unused == ["never-hit"]


def test_allowlist_entry_needs_a_reason(tmp_path):
    with pytest.raises(ValueError, match="has no reason"):
        bw.load_allowlist(_allow(tmp_path, [{"pattern": "x", "reason": " "}]))


def test_allowlist_rejects_a_bad_regex(tmp_path):
    with pytest.raises(ValueError, match="not a valid regex"):
        bw.load_allowlist(_allow(tmp_path, [{"pattern": "(", "reason": "r"}]))


def test_allowlist_reports_every_problem_at_once(tmp_path):
    with pytest.raises(ValueError) as exc:
        bw.load_allowlist(_allow(tmp_path, [{"pattern": "a", "reason": ""},
                                            {"pattern": "(", "reason": "r"}]))
    assert "has no reason" in str(exc.value) and "not a valid regex" in str(exc.value)


@pytest.mark.parametrize("content", ["not json", "[]", '{"allowed": 3}'])
def test_allowlist_rejects_a_malformed_file(tmp_path, content):
    path = tmp_path / "a.json"
    path.write_text(content)
    with pytest.raises(ValueError, match="a.json"):
        bw.load_allowlist(path)


def test_allowlist_path_is_required_and_a_missing_file_is_named(tmp_path):
    with pytest.raises(TypeError):
        bw.load_allowlist()  # type: ignore[call-arg]
    with pytest.raises(ValueError, match="missing.json"):
        bw.load_allowlist(tmp_path / "missing.json")


def test_gate_log_exit_codes_and_json(tmp_path, capsys):
    ok = bw.load_allowlist(_allow(tmp_path, [{"pattern": "warning", "reason": "everything"}]))
    assert bw.gate_log(LOG, ok, "allow.json", as_json=False) == 0
    capsys.readouterr()
    assert bw.gate_log(LOG, [], "allow.json", as_json=True) == 1
    doc = json.loads(capsys.readouterr().out)
    assert doc["ok"] is False and UNUSED_X in doc["unaccepted"]


def test_gate_log_names_the_unaccepted_and_unused(tmp_path, capsys):
    allow = bw.load_allowlist(_allow(tmp_path, [{"pattern": "never-hit", "reason": "old"}]))
    assert bw.gate_log(LOG, allow, "allow.json", as_json=False) == 1
    out = capsys.readouterr().out
    assert UNUSED_X in out and "unused allowlist pattern: never-hit" in out


# run_warnings --------------------------------------------------------------------

HOOK_SCRIPT = (
    "import os, sys; d = os.environ['RELEASE_WARNINGS_DERIVED_DATA']; "
    "print('DD=' + d); print('exists=' + str(os.path.isdir(d))); "
    "print('a.swift:1:1: warning: accepted noise'); "
    "print('b.swift:2:2: warning: needs a fix', file=sys.stderr); sys.exit({code})"
)


def _cfg(tmp_path, *, code=0, entries=({"pattern": "accepted noise", "reason": "toolchain"},)):
    cfg = config(tmp_path, {"hooks": {"warnings_build": [sys.executable, "-c",
                                                         HOOK_SCRIPT.format(code=code)]}})
    cfg.warnings_allowlist.write_text(json.dumps({"allowed": list(entries)}))
    return cfg


def test_run_warnings_gates_the_log_and_cleans_up(tmp_path, capsys):
    logs = tmp_path / "logs"
    assert bw.run_warnings(_cfg(tmp_path), log_dir=logs, as_json=False) == 1
    out = capsys.readouterr().out
    assert "b.swift:2:2: warning: needs a fix" in out
    log = (logs / "warnings-build.log").read_text()
    derived = Path(log.split("DD=")[1].splitlines()[0])
    assert "exists=True" in log
    assert not derived.exists(), "DerivedData must be deleted"


def test_run_warnings_passes_when_everything_is_accepted(tmp_path, capsys):
    cfg = _cfg(tmp_path, entries=({"pattern": "accepted noise", "reason": "a"},
                                  {"pattern": "needs a fix", "reason": "b"}))
    assert bw.run_warnings(cfg, log_dir=tmp_path / "logs", as_json=True) == 0
    assert json.loads(capsys.readouterr().out)["ok"] is True


def test_run_warnings_hook_failure_prints_the_tail_and_fails(tmp_path, capsys):
    assert bw.run_warnings(_cfg(tmp_path, code=3), log_dir=tmp_path / "logs",
                           as_json=False) == 1
    err = capsys.readouterr().err
    assert "exited 3" in err and "needs a fix" in err
    assert (tmp_path / "logs/warnings-build.log").exists()


def test_run_warnings_default_log_dir_is_the_temp_parent(tmp_path, monkeypatch):
    scratch = tmp_path / "tmp"
    scratch.mkdir()
    monkeypatch.setattr(tempfile, "tempdir", str(scratch))
    bw.run_warnings(_cfg(tmp_path), log_dir=None, as_json=False)
    assert (scratch / "warnings-build.log").exists()


def test_run_warnings_bad_allowlist_fails_before_building(tmp_path):
    cfg = _cfg(tmp_path, entries=({"pattern": "x", "reason": ""},))
    ran = []
    with pytest.raises(ValueError, match="has no reason"):
        bw.run_warnings(cfg, log_dir=tmp_path, as_json=False,
                        hook=lambda *a, **k: ran.append(1))
    assert ran == []
