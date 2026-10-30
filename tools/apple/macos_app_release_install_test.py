#!/usr/bin/env python3
"""Tests for macos_app_release.processes, .prepared and .install.

Run: python3 -m pytest tools/apple/macos_app_release_install_test.py -q

Nothing here touches /Applications, a real process, a signal or the network:
the apps directory is under tmp_path, and ps, kill, sleep and the clock are injected.
"""
from __future__ import annotations

import json
import os
import plistlib
import signal
import subprocess
import sys
import types
from pathlib import Path

import pytest

from macos_app_release import install as ins, prepared as rp, processes as ap, state
from macos_app_release_fixtures import (BUILD, SOURCE_SHA, VERSION, FakeRunner, config, release,
                                         with_artifacts)

SHA = "b" * 40
FLAVORS = ["adkitchen", "stenographer"]


@pytest.fixture(autouse=True)
def _layout(monkeypatch):
    """Use the real layout module when Task 3 has landed, else a stand-in with the
    same `problems(app, cfg)` contract."""
    try:
        from macos_app_release import layout  # noqa: F401
        return
    except ImportError:
        pass
    stub = types.ModuleType("macos_app_release.layout")

    def problems(app, cfg):
        found = [f"missing {rel}" for rel in cfg.layout_required if not (app / rel).exists()]
        found += [f"forbidden {rel}" for rel in cfg.layout_forbidden if (app / rel).exists()]
        found += [f"no match for {g}" for g in cfg.layout_required_globs
                  if not list(app.glob(g))]
        return found

    stub.problems = problems
    monkeypatch.setitem(sys.modules, "macos_app_release.layout", stub)
    import macos_app_release
    monkeypatch.setattr(macos_app_release, "layout", stub, raising=False)


# processes ------------------------------------------------------------------------

APP = Path("/Applications/Thing.app")


def test_ps_is_scoped_to_this_user(monkeypatch):
    seen = []

    def fake_run(argv, **_kw):
        seen.append(argv)
        return subprocess.CompletedProcess(argv, 0, "", "")

    monkeypatch.setattr(ap.subprocess, "run", fake_run)
    ap.bundle_pids(APP)
    assert seen == [["ps", "-U", str(os.getuid()), "-o", "pid=,comm="]]


def test_matches_everything_inside_the_bundle_and_nothing_beside_it():
    ps = "\n".join([
        f"  10 {APP}/Contents/MacOS/Thing",
        f"  11 {APP}/Contents/MacOS/thingd",
        f"  12 {APP}/Contents/Helpers/helper",
        "  13 /Applications/Thing.app.old/Contents/MacOS/Thing",
        "  14 /usr/bin/python3",
        "  xx garbage",
    ])
    assert ap.parse_bundle_pids(ps, APP) == [10, 11, 12]


def test_quit_terms_then_kills_and_reports_survivors():
    alive = [1, 2]
    signals = []
    clock = [0.0]

    def kill(pid, sig):
        signals.append((pid, sig))
        if pid == 1:
            alive.remove(1)

    def sleep(seconds):
        clock[0] += seconds

    left = ap.quit_pids(lambda: list(alive), term_wait=1.0, kill_wait=0.5, kill=kill,
                        sleep=sleep, monotonic=lambda: clock[0])
    assert left == [2]
    assert (1, signal.SIGTERM) in signals and (2, signal.SIGKILL) in signals


def test_quit_shrugs_off_a_pid_that_is_gone_or_not_ours():
    calls = iter([[5, 6], []])

    def kill(pid, _sig):
        raise ProcessLookupError if pid == 5 else PermissionError

    assert ap.quit_pids(lambda: next(calls), term_wait=1, kill_wait=1, kill=kill) == []


# prepared -------------------------------------------------------------------------


class Git:
    """A fake runner for one prepared repo; each field is what that query answers."""

    def __init__(self, *, head=SHA, origin=SHA, tag=SHA, branch="main", dirty="",
                 fetch_rc=0, authority="Developer ID Application"):
        self.head, self.origin, self.tag = head, origin, tag
        self.branch, self.dirty, self.fetch_rc = branch, dirty, fetch_rc
        self.authority = authority

    def __call__(self, argv):
        def out(text, rc=0):
            return subprocess.CompletedProcess(argv, rc, text, "")
        joined = " ".join(argv)
        if argv[0] == "codesign" and "-d" in argv:
            return subprocess.CompletedProcess(argv, 0, "", f"Authority={self.authority}\n")
        if argv[0] != "git":
            return out("")
        if " fetch " in f" {joined} ":
            return out("", self.fetch_rc)
        if "--abbrev-ref" in argv:
            return out(self.branch + "\n")
        if "status" in argv:
            return out(self.dirty)
        if "refs/tags/" in joined:
            return out(self.tag + "\n") if self.tag else out("", 1)
        if "HEAD^{commit}" in joined:
            return out(self.head + "\n")
        if "origin/main" in joined:
            return out(self.origin + "\n")
        return out("")


def _plist(bundle: Path, version=VERSION, build=BUILD):
    (bundle / "Contents").mkdir(parents=True, exist_ok=True)
    (bundle / "Contents/Info.plist").write_bytes(plistlib.dumps(
        {"CFBundleShortVersionString": version, "CFBundleVersion": str(build)}))


def _prepared(tmp_path, run, *, flavor="stenographer", notes=True, provenance=None,
              artifacts=True):
    r = release(tmp_path, run, flavor=flavor, notes=notes, branch="main", publish=True)
    if artifacts:
        with_artifacts(r)
        _plist(r.app)
        for rel in r.cfg.nested_bundles:
            _plist(r.app / rel)
        r.provenance_path.write_text(json.dumps({
            "version": VERSION, "build": BUILD, "source_sha": SHA,
            "notarized": True, "pkg_sha256": state.sha256_of(r.pkg_path),
            "zip_sha256": state.sha256_of(r.zip_path), **(provenance or {})}))
    return r


@pytest.mark.parametrize("flavor", FLAVORS)
def test_a_prepared_release_passes(tmp_path, flavor):
    results = rp.prepared_failures(_prepared(tmp_path, Git(), flavor=flavor))
    assert results == {"main": [], "tag": [], "version": [], "artifacts": [], "staged": []}


def test_main_moved_past_the_tag(tmp_path):
    r = _prepared(tmp_path, Git(head="c" * 40, origin="c" * 40))
    results = rp.prepared_failures(r)
    assert "moved after" in results["tag"][0]
    assert any("built from bbbbbbbbbbbb" in f for f in results["artifacts"])


def test_head_not_pushed(tmp_path):
    results = rp.prepared_failures(_prepared(tmp_path, Git(origin="d" * 40)))
    assert "is not origin/main" in results["main"][0]


def test_wrong_branch_dirty_tree_and_failed_fetch(tmp_path):
    results = rp.prepared_failures(_prepared(
        tmp_path, Git(branch="release-preparation", dirty=" M x.swift", fetch_rc=1)))
    joined = "\n".join(results["main"])
    assert "cannot fetch" in joined
    assert "on 'release-preparation', not main" in joined
    assert "uncommitted changes" in joined


def test_missing_tag(tmp_path):
    results = rp.prepared_failures(_prepared(tmp_path, Git(tag=None)))
    assert "no tag release/1.0.154" in results["tag"][0]


def test_must_match_mismatch_and_missing_notes(tmp_path):
    r = _prepared(tmp_path, Git(), notes=False)
    router = r.cfg.must_match[0].file
    router.write_text('public static let daemonVersion = "0.9.0"\n')
    version = rp.prepared_failures(r)["version"]
    assert len(version) == 2
    assert "says 0.9.0" in version[0]
    assert "release notes missing" in version[1]


def test_missing_artifacts(tmp_path):
    results = rp.prepared_failures(_prepared(tmp_path, Git(), artifacts=False))
    assert len(results["artifacts"]) == 2
    assert all("is missing" in f for f in results["artifacts"])


def test_unnotarized_artifacts_refused(tmp_path):
    r = _prepared(tmp_path, Git(), provenance={"notarized": False})
    assert "never notarized" in rp.prepared_failures(r)["artifacts"][0]


def test_staged_nested_bundle_version_mismatch(tmp_path):
    r = _prepared(tmp_path, Git())
    nested = r.cfg.nested_bundles[0]
    _plist(r.app / nested, "1.0.153", 0)
    assert rp.prepared_failures(r)["staged"] == [
        f"staged {nested} is 1.0.153 (0), not {VERSION} ({BUILD})"]


def test_staged_app_missing_plist(tmp_path):
    r = _prepared(tmp_path, Git(), flavor="adkitchen")
    (r.app / "Contents/Info.plist").unlink()
    assert "is missing" in rp.prepared_failures(r)["staged"][0]


def test_adkitchen_has_no_nested_bundles_to_check(tmp_path):
    r = _prepared(tmp_path, Git(), flavor="adkitchen")
    assert r.cfg.nested_bundles == ()
    assert rp.staged_failures(r) == []


def test_run_prepared_json_and_exit_code(tmp_path, capsys):
    r = _prepared(tmp_path, Git())
    assert rp.run_prepared(r, as_json=True) == 0
    data = json.loads(capsys.readouterr().out)
    assert data["ok"] is True and data["tag"] == "release/1.0.154" and data["sha"] == SHA
    r = _prepared(tmp_path / "bad", Git(tag=None))
    assert rp.run_prepared(r, as_json=False) == 1
    assert "NOT PREPARED" in capsys.readouterr().out


# install --------------------------------------------------------------------------


def _make_app(app: Path, cfg, content="new") -> None:
    for rel in cfg.layout_required:
        (app / rel).parent.mkdir(parents=True, exist_ok=True)
        (app / rel).write_text(content)
    for glob in cfg.layout_required_globs:
        (app / glob.replace("*", "X")).mkdir(parents=True, exist_ok=True)
    (app / "Contents").mkdir(parents=True, exist_ok=True)


class Env:
    """An injected world: a recording runner whose `ditto` unpacks a fake app."""

    def __init__(self, tmp_path, *, complete=True, fail_new_move=False):
        self.cfg = config(tmp_path, flavor="stenographer")
        self.name = f"{self.cfg.app_name}.app"
        self.apps = tmp_path / "Applications"
        self.apps.mkdir()
        self.zip = tmp_path / "rel" / f"{self.cfg.app_name}-1.0.1.zip"
        self.zip.parent.mkdir()
        self.zip.write_text("zip")
        self.calls: list[list[str]] = []
        self.renames: list[tuple[Path, Path]] = []
        self.complete = complete
        self.fail_new_move = fail_new_move
        self.signals: list[tuple[int, int]] = []
        self.alive = [111]
        self.die_on_term = True
        self.clock = 0.0
        self.out: list[str] = []
        self.finder_refuses = False

    def run(self, argv):
        self.calls.append(list(argv))
        if argv[0] == "osascript" and self.finder_refuses:
            return subprocess.CompletedProcess(argv, 1, "", "Not authorized (-1743)")
        if argv[0] == "ditto":
            app = Path(argv[-1]) / self.name
            if self.complete:
                _make_app(app, self.cfg)
            else:
                app.mkdir(parents=True)
        return subprocess.CompletedProcess(argv, 0, "", "")

    def rename(self, src, dst):
        self.renames.append((Path(src), Path(dst)))
        if self.fail_new_move and Path(src).parent != self.apps:
            Path(dst).mkdir()
            (Path(dst) / "partial").write_text("x")
            raise OSError("boom")
        os.rename(src, dst)

    def kill(self, pid, sig):
        self.signals.append((pid, sig))
        if sig == signal.SIGKILL or self.die_on_term:
            self.alive = []

    def go(self, uid=None):
        return ins.install(self.zip, self.cfg, apps_dir=self.apps, run=self.run,
                           pids=lambda app: list(self.alive), kill=self.kill,
                           sleep=self._sleep, rename=self.rename,
                           monotonic=lambda: self.clock, pid=4242,
                           uid=os.getuid() if uid is None else uid, say=self.out.append)

    def _sleep(self, seconds):
        self.clock += seconds

    def make_old(self) -> Path:
        old = self.apps / self.name
        (old / "Contents/Helpers").mkdir(parents=True)
        (old / "Contents/Helpers/helper").write_text("old")
        return old

    def dest_marker(self) -> str:
        return (self.apps / self.name / "Contents/Helpers/helper").read_text()


def _new_marker(env) -> str:
    return (env.apps / env.name / env.cfg.layout_required[0]).read_text()


def test_replaces_the_old_bundle_and_opens_the_new(tmp_path):
    env = Env(tmp_path)
    old = env.make_old()
    assert env.go() == 0
    assert _new_marker(env) == "new"
    assert not (env.apps / f"{env.name}.old-4242").exists()
    assert env.calls[0][:4] == ["ditto", "-x", "-k", str(env.zip)]
    staging = env.apps / f".{env.cfg.app_name}-install-4242"
    assert env.calls[0][4] == str(staging)
    assert env.renames == [(old, env.apps / f"{env.name}.old-4242"),
                           (staging / env.name, old)]
    assert not staging.exists()
    finder = env.calls[-2]
    assert finder[:2] == ["osascript", "-e"]
    assert 'tell application "Finder" to update' in finder[2] and str(old) in finder[2]
    assert env.calls[-1] == ["open", "-a", str(old)]


def test_a_finder_that_will_not_refresh_the_icon_does_not_fail_the_install(tmp_path):
    env = Env(tmp_path)
    env.make_old()
    env.finder_refuses = True
    assert env.go() == 0
    assert _new_marker(env) == "new"
    assert env.calls[-1][0] == "open"
    assert any("Finder did not refresh the icon" in line for line in env.out)


def test_first_install_has_nothing_to_move_aside(tmp_path):
    env = Env(tmp_path)
    assert env.go() == 0
    assert _new_marker(env) == "new"
    assert len(env.renames) == 1


def test_apps_dir_defaults_to_the_config(tmp_path):
    env = Env(tmp_path)
    env.apps = env.cfg.apps_dir
    env.apps.mkdir(parents=True)
    assert ins.install(env.zip, env.cfg, run=env.run, pids=lambda app: [], kill=env.kill,
                       sleep=env._sleep, monotonic=lambda: 0.0, say=env.out.append) == 0
    assert (env.cfg.apps_dir / env.name).is_dir()


def test_refuses_an_app_owned_by_someone_else_and_prints_the_chown(tmp_path):
    env = Env(tmp_path)
    (env.apps / env.name).mkdir()
    assert env.go(uid=os.getuid() + 1) == 1
    assert env.calls == []
    said = "\n".join(env.out)
    assert f'sudo chown -R "$(id -un)" {env.apps / env.name}' in said
    assert "install again" in said


def test_a_root_owned_app_is_left_running_and_no_pkg_is_offered(tmp_path):
    """A second pkg install leaves the bundle root's again, so it is never the fix;
    and the next install quits the app itself, so refusing must not quit it."""
    env = Env(tmp_path)
    (env.apps / env.name).mkdir()
    assert env.go(uid=os.getuid() + 1) == 1
    assert env.signals == []
    assert "installer -pkg" not in "\n".join(env.out)


def test_quits_only_the_installed_pids_term_first(tmp_path):
    env = Env(tmp_path)
    assert env.go() == 0
    assert env.signals == [(111, signal.SIGTERM)]


def test_kills_what_ignores_term_after_ten_seconds(tmp_path):
    env = Env(tmp_path)
    env.die_on_term = False
    assert env.go() == 0
    assert env.signals == [(111, signal.SIGTERM), (111, signal.SIGKILL)]
    assert env.clock >= ins.QUIT_TIMEOUT_S


def test_refuses_an_extracted_app_that_fails_the_layout_check(tmp_path):
    env = Env(tmp_path, complete=False)
    env.make_old()
    assert env.go() == 1
    assert env.dest_marker() == "old"
    assert env.signals == [] and env.renames == []
    assert not any(c[0] == "open" for c in env.calls)
    assert not (env.apps / f".{env.cfg.app_name}-install-4242").exists()
    assert "does not match the bundle layout" in "\n".join(env.out)


def test_restores_the_old_bundle_when_the_second_move_fails(tmp_path):
    env = Env(tmp_path, fail_new_move=True)
    env.make_old()
    assert env.go() == 1
    assert not any(c[0] == "open" for c in env.calls)
    assert not (env.apps / f".{env.cfg.app_name}-install-4242").exists()


def test_a_failed_second_rename_restores_the_old_bundle_without_nesting(tmp_path):
    env = Env(tmp_path, fail_new_move=True)
    old = env.make_old()
    env.go()
    assert env.dest_marker() == "old"
    assert not (old / f"{env.name}.old-4242").exists()
    assert not (old / "partial").exists()
    assert not (env.apps / f"{env.name}.old-4242").exists()


def test_a_failed_gate_does_not_touch_the_running_app(tmp_path):
    env = Env(tmp_path, complete=False)
    env.go()
    assert env.signals == [] and env.renames == []


def test_refuses_a_symlinked_destination(tmp_path):
    env = Env(tmp_path)
    target = tmp_path / "elsewhere.app"
    target.mkdir()
    (env.apps / env.name).symlink_to(target)
    assert env.go() == 1
    assert env.calls == [] and env.signals == []
    assert "symlink" in "\n".join(env.out)


def test_a_failed_ditto_stops_before_anything_is_touched(tmp_path):
    env = Env(tmp_path)
    env.make_old()
    env.run = lambda argv: subprocess.CompletedProcess(argv, 1, "", "bad zip")
    assert env.go() == 1
    assert env.signals == [] and env.dest_marker() == "old"
    assert "ditto failed: bad zip" in "\n".join(env.out)


# installed ------------------------------------------------------------------------


class Installed:
    """An installed copy in a fake apps dir, plus the fakes `installed_failures` takes."""

    def __init__(self, tmp_path, *, version=VERSION, build=BUILD,
                 authority="Developer ID Application: Someone (K2NA732JAX)", running=(7,),
                 flavor="stenographer", layout_ok=True, overrides=None):
        self.cfg = config(tmp_path, overrides, flavor=flavor)
        self.apps = tmp_path / "Applications"
        self.app = self.apps / f"{self.cfg.app_name}.app"
        if layout_ok:
            _make_app(self.app, self.cfg)
        _plist(self.app, version, build)
        self.authority = authority
        self.running = list(running)
        self.calls: list[list[str]] = []

    def run(self, argv):
        self.calls.append(list(argv))
        return subprocess.CompletedProcess(argv, 0, "", f"Authority={self.authority}\n"
                                           "Authority=Developer ID Certification Authority\n")

    def failures(self):
        return ins.installed_failures(self.cfg, apps_dir=self.apps, run=self.run,
                                      pids=lambda app: list(self.running))


@pytest.mark.parametrize("flavor", FLAVORS)
def test_a_healthy_installed_copy_has_no_failures(tmp_path, flavor):
    w = Installed(tmp_path, flavor=flavor)
    assert w.failures() == []
    assert w.calls and w.calls[0][0] == "codesign"


def test_installed_version_mismatch(tmp_path):
    failures = Installed(tmp_path, version="1.0.153", build=0).failures()
    assert failures == [f"installed app is 1.0.153 (0), not {VERSION} ({BUILD})"]


def test_installed_build_mismatch_alone_is_a_failure(tmp_path):
    failures = Installed(tmp_path, build=BUILD + 1).failures()
    assert len(failures) == 1 and f"({BUILD + 1})" in failures[0]


def test_installed_not_developer_id_signed(tmp_path):
    failures = Installed(tmp_path, authority="Apple Development: Someone (ABC)").failures()
    assert len(failures) == 1
    assert "not signed Developer ID Application" in failures[0]
    assert "Apple Development" in failures[0]


def test_installed_signed_by_another_identity_than_the_pinned_one_fails(tmp_path):
    w = Installed(tmp_path, authority="Developer ID Application: Other (ZZZZZZZZZZ)",
                  overrides={"signing": {"app_identity":
                                         "Developer ID Application: Someone (K2NA732JAX)"}})
    failures = w.failures()
    assert len(failures) == 1 and "Other (ZZZZZZZZZZ)" in failures[0]
    assert "Developer ID Application: Someone (K2NA732JAX)" in failures[0]


def test_installed_unsigned_has_no_authority(tmp_path):
    w = Installed(tmp_path)
    w.run = lambda argv: subprocess.CompletedProcess(argv, 1, "", "code object is not signed")
    assert "authority: none" in w.failures()[0]


def test_installed_not_running(tmp_path):
    failures = Installed(tmp_path, running=()).failures()
    assert len(failures) == 1 and "is not running" in failures[0]


def test_installed_layout_failure_is_reported(tmp_path):
    failures = Installed(tmp_path, layout_ok=False).failures()
    assert failures and all(f.startswith("layout: ") for f in failures)


def test_installed_missing_app(tmp_path):
    w = Installed(tmp_path)
    w.apps = tmp_path / "nowhere"
    assert "is not installed" in w.failures()[0]


def test_installed_collects_every_failure(tmp_path):
    failures = Installed(tmp_path, version="0.0.1", authority="Mac Developer: x",
                         running=()).failures()
    assert len(failures) == 3
