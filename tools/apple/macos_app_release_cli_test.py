#!/usr/bin/env python3
"""Tests for release_macos_app -- the CLI: one test per command, exit codes, and the
contract with the /release skill that drives it.

Every external command goes through a FakeRunner and every HTTP request through a fake
fetch; the only real processes are the `python -c` hooks the tests configure themselves.

Run: python3 -m pytest tools/apple/macos_app_release_cli_test.py -q
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

import pytest

import release_macos_app as cli
from macos_app_release import build_pipeline, install as install_mod, publish
from macos_app_release.verify import Fetched
from macos_app_release_fixtures import (BUILD, VERSION, FakeRunner, deep_merge, FLAVORS,
                                        write_config)

def _skill() -> Path:
    """The release skill that drives this CLI: $RELEASE_SKILL when set
    (point it at mydevsetup's source copy while changing both), else an installed copy."""
    import os
    if os.environ.get("RELEASE_SKILL"):
        return Path(os.environ["RELEASE_SKILL"])
    for host in (".claude", ".codex"):
        installed = Path.home() / host / "skills/release/SKILL.md"
        if installed.exists():
            return installed
    return Path("/nonexistent/release/SKILL.md")


SKILL = _skill()


@pytest.fixture(autouse=True)
def _no_releases_env(monkeypatch):
    monkeypatch.delenv("RELEASE_RELEASES_CHECKOUT", raising=False)


class World:
    """A fixture repo plus the fakes `cli.main` is driven with."""

    def __init__(self, tmp_path, overrides=None, *, flavor="adkitchen", gh=None, **kw):
        self.tmp = tmp_path
        self.repo = tmp_path / "repo"
        overrides = deep_merge({"build": {"derived_data": str(tmp_path / "dd")}}
                               if flavor == "adkitchen" else {}, overrides or {})
        write_config(self.repo, overrides, flavor=flavor, **kw)
        responses = [
            (lambda a: a[:2] == ["git", "-C"] and "--git-common-dir" in a,
             0, f"{self.repo}/.git\n"),
            (lambda a: a[:2] == ["git", "rev-parse"], 0, f"{self.repo}\n"),
        ]
        if gh is not None:
            responses.append((lambda a: a[:3] == ["gh", "release", "view"], *gh))
        self.runner = FakeRunner(responses)
        self.fetches: list[str] = []

    def fetch(self, url, follow):
        self.fetches.append(url)
        return Fetched(404, {}, b"")

    def run(self, *argv, repo=True):
        full = (["--repo", str(self.repo)] if repo else []) + list(argv)
        return cli.main(full, runner_factory=lambda verbose=False, cwd=None: self.runner,
                        fetch=self.fetch)


def hook(code=0, text="hello"):
    return [sys.executable, "-c", f"import sys; print({text!r}); sys.exit({code})"]


def out_json(capsys):
    return json.loads(capsys.readouterr().out)


# status ------------------------------------------------------------------------------

LATEST = (0, json.dumps({"tagName": "v1.0.153", "publishedAt": "2026-10-01T12:00:00Z"}))


def test_status_json_adkitchen(tmp_path, capsys):
    w = World(tmp_path, gh=LATEST)
    assert w.run("status", "--json") == 0
    s = out_json(capsys)
    assert set(s) == {"app", "version", "build", "notes", "notes_exists", "source_tag",
                      "source_branch", "releases_checkout", "latest_published",
                      "latest_published_error", "hooks", "regenerate", "artifacts_default",
                      "toolkit"}
    assert s["source_branch"] == "main"
    assert s["latest_published_error"] is None
    assert s["regenerate"] is False
    assert (s["app"], s["version"], s["build"]) == ("AgenticDeveloperKitchen", VERSION, BUILD)
    assert s["notes"] == str(w.repo / f"docs/release-notes/{VERSION}.md")
    assert s["notes_exists"] is True
    assert s["source_tag"] == f"release/{VERSION}"
    assert s["releases_checkout"] == str(tmp_path / "adkitchen-releases")
    assert s["latest_published"] == {"version": "1.0.153", "publishedAt": "2026-10-01T12:00:00Z"}
    assert s["hooks"] == {"tests": True, "warnings_build": True, "health": False}
    assert s["artifacts_default"] == str(w.repo / "build/release")
    assert s["toolkit"] == str(w.repo / "external/agenticdevelopertoolkit")
    assert w.runner.find("gh", "release", "view")[0][3:5] == ["--repo", "agenticdevelopmentstudio/adkitchen-releases"]


def test_status_json_stenographer_flavor(tmp_path, capsys):
    w = World(tmp_path, flavor="stenographer", notes=False,
              gh=(1, "", "release not found"))
    assert w.run("status", "--json") == 0
    s = out_json(capsys)
    assert s["hooks"] == {"tests": True, "warnings_build": True, "health": True}
    assert s["notes_exists"] is False
    assert s["latest_published"] is None
    assert s["latest_published_error"] is None       # a first release, not a failure
    assert s["regenerate"] is True
    assert s["releases_checkout"] == str(Path.home() / "stenographer-releases")


def test_status_reports_a_configured_source_branch(tmp_path, capsys):
    w = World(tmp_path, {"source": {"branch": "trunk"}}, gh=LATEST)
    assert w.run("status", "--json") == 0
    assert out_json(capsys)["source_branch"] == "trunk"


def test_status_warns_but_succeeds_when_gh_cannot_say(tmp_path, capsys):
    w = World(tmp_path, gh=(1, "", "gh: not logged in"))
    assert w.run("status", "--json") == 0
    captured = capsys.readouterr()
    s = json.loads(captured.out)
    assert s["latest_published"] is None
    assert "not logged in" in s["latest_published_error"]
    assert "not logged in" in captured.err


def test_status_never_touches_the_network(tmp_path):
    w = World(tmp_path, gh=LATEST)
    w.run("status")
    assert w.fetches == []


def test_status_human_output(tmp_path, capsys):
    w = World(tmp_path, gh=LATEST)
    assert w.run("status") == 0
    out = capsys.readouterr().out
    assert f"AgenticDeveloperKitchen {VERSION} (build {BUILD})" in out
    assert "1.0.153" in out and "health=unset" in out


# config errors and repo discovery -------------------------------------------------------


def test_bad_config_exits_2_and_prints_every_problem(tmp_path, capsys):
    w = World(tmp_path)
    data = json.loads((w.repo / "release.json").read_text())
    data["app"]["bundel_id"] = data["app"].pop("bundle_id")      # a typo + a missing key
    del data["warnings_allowlist"]
    (w.repo / "release.json").write_text(json.dumps(data))
    assert w.run("status") == 2
    err = capsys.readouterr().err
    assert "app.bundel_id: unknown key" in err
    assert "app.bundle_id: required" in err
    assert "warnings_allowlist: required" in err


def test_missing_release_json_exits_2(tmp_path, capsys):
    w = World(tmp_path)
    (w.repo / "release.json").unlink()
    assert w.run("status") == 2
    assert "release.json" in capsys.readouterr().err


def test_unreadable_project_yml_exits_2(tmp_path, capsys):
    w = World(tmp_path)
    (w.repo / "App/project.yml").write_text("settings: {}\n")
    assert w.run("status") == 2
    assert "MARKETING_VERSION" in capsys.readouterr().err


def test_repo_defaults_to_the_git_toplevel(tmp_path, capsys):
    w = World(tmp_path, gh=LATEST)
    assert w.run("status", "--json", repo=False) == 0
    assert out_json(capsys)["app"] == "AgenticDeveloperKitchen"
    assert w.runner.find("git", "rev-parse", "--show-toplevel")


def test_no_repo_and_not_in_git_exits_2(tmp_path, capsys):
    w = World(tmp_path)
    w.runner.responses.insert(0, (lambda a: a[:3] == ["git", "rev-parse", "--show-toplevel"],
                                  128, "", "fatal: not a git repository"))
    assert w.run("status", repo=False) == 2
    assert "--repo" in capsys.readouterr().err


def test_repo_flag_works_before_or_after_the_command(tmp_path):
    w = World(tmp_path, gh=LATEST)
    assert cli.main(["status", "--repo", str(w.repo)],
                    runner_factory=lambda v=False, cwd=None: w.runner) == 0
    assert w.run("status") == 0


def test_worktree_main_checkout_places_the_releases_checkout(tmp_path, capsys):
    w = World(tmp_path, gh=LATEST)
    main = tmp_path / "elsewhere" / "main-checkout"
    w.runner.responses.insert(0, (lambda a: "--git-common-dir" in a, 0, f"{main}/.git\n"))
    assert w.run("status", "--json") == 0
    assert out_json(capsys)["releases_checkout"] == str(main.parent / "adkitchen-releases")


@pytest.mark.parametrize("argv", [[], ["nope"], ["bump", "major"], ["hook", "warnings_build"],
                                  ["build", "--bogus"]])
def test_usage_errors_exit_2(argv, capsys):
    assert cli.main(argv) == 2
    assert capsys.readouterr().err


def test_help_exits_0_and_lists_every_command(capsys):
    assert cli.main(["--help"]) == 0
    out = capsys.readouterr().out
    for name in cli.COMMANDS:
        assert name in out


# bump -----------------------------------------------------------------------------------


def test_bump_minor_prints_the_new_version_and_writes_it(tmp_path, capsys):
    w = World(tmp_path)
    assert w.run("bump", "minor") == 0
    assert capsys.readouterr().out.strip() == f"1.1.0 (build {BUILD + 1})"
    yml = (w.repo / "App/project.yml").read_text()
    assert 'MARKETING_VERSION: "1.1.0"' in yml and f'CURRENT_PROJECT_VERSION: "{BUILD + 1}"' in yml


def test_bump_patch_json_rewrites_must_match_and_regenerates(tmp_path, capsys):
    w = World(tmp_path, flavor="stenographer")
    assert w.run("bump", "patch", "--json") == 0
    assert json.loads(capsys.readouterr().out) == {"version": "1.0.155", "build": BUILD + 1}
    swift = w.repo / "Apple/Stenographer/stenographerd/Sources/HTTP/StenographerRouter.swift"
    assert '"1.0.155"' in swift.read_text()
    assert w.runner.find("xcodegen", "generate")


def test_bump_failure_exits_1(tmp_path, capsys):
    w = World(tmp_path, flavor="stenographer")
    w.runner.responses.append((lambda a: a[0] == "xcodegen", 1, "", "boom"))
    assert w.run("bump", "patch") == 1
    assert "version.regenerate" in capsys.readouterr().err


# regenerate -----------------------------------------------------------------------------


def test_regenerate_runs_the_configured_command(tmp_path):
    w = World(tmp_path, flavor="stenographer")
    assert w.run("regenerate") == 0
    assert w.runner.find("xcodegen", "generate")


def test_regenerate_unset_is_a_no_op(tmp_path, capsys):
    w = World(tmp_path)
    assert w.run("regenerate") == 0
    assert "nothing to regenerate" in capsys.readouterr().out


def test_regenerate_failure_exits_1(tmp_path, capsys):
    w = World(tmp_path, flavor="stenographer")
    w.runner.responses.insert(0, (lambda a: a[0] == "xcodegen", 1, "", "boom"))
    assert w.run("regenerate") == 1
    assert "boom" in capsys.readouterr().err


# hook -----------------------------------------------------------------------------------


def test_hook_unset_exits_2(tmp_path, capsys):
    w = World(tmp_path)
    assert w.run("hook", "health") == 2
    assert "health hook is not configured" in capsys.readouterr().err


@pytest.mark.parametrize("code", [0, 7])
def test_hook_tests_passes_the_exit_code_through(tmp_path, capfd, code):
    w = World(tmp_path, {"hooks": {"tests": hook(code, "suite output")}})
    assert w.run("hook", "tests") == code
    assert "suite output" in capfd.readouterr().out


def test_hook_health_runs_when_configured(tmp_path):
    w = World(tmp_path, {"hooks": {"health": hook(5)}})
    assert w.run("hook", "health") == 5


def test_hook_runs_from_the_repo_root(tmp_path, capfd):
    script = "import os; print(os.getcwd())"
    w = World(tmp_path, {"hooks": {"tests": [sys.executable, "-c", script]}})
    assert w.run("hook", "tests") == 0
    assert capfd.readouterr().out.strip() == str(w.repo.resolve())


def test_hook_with_a_nonexistent_command_is_an_error_not_a_traceback(tmp_path, capsys):
    w = World(tmp_path, {"hooks": {"tests": [str(tmp_path / "no-such-hook")]}})
    assert w.run("hook", "tests") == 1
    err = capsys.readouterr().err
    assert err.startswith("error: hooks.tests could not run:") and "no-such-hook" in err


# warnings -------------------------------------------------------------------------------

WARN_SCRIPT = ("print('A.swift:1:1: warning: accepted noise'); "
               "print('B.swift:2:2: warning: unaccepted thing')")


def test_warnings_with_a_nonexistent_hook_command_is_an_error(tmp_path, capsys):
    w = World(tmp_path, {"hooks": {"warnings_build": [str(tmp_path / "no-such-hook")]}})
    assert w.run("warnings", "--log-dir", str(tmp_path / "logs")) == 1
    err = capsys.readouterr().err
    assert "error: hooks.warnings_build could not run:" in err and "no-such-hook" in err


def test_warnings_exits_1_and_names_the_unaccepted_one(tmp_path, capsys):
    w = World(tmp_path, {"hooks": {"warnings_build": [sys.executable, "-c", WARN_SCRIPT]}})
    (w.repo / "release/warnings-allowlist.json").write_text(json.dumps(
        {"allowed": [{"pattern": "accepted noise", "reason": "toolchain"}]}))
    assert w.run("warnings", "--log-dir", str(tmp_path / "logs")) == 1
    out = capsys.readouterr().out
    assert "unaccepted thing" in out and "1 warning(s) to fix" in out
    assert "A.swift" not in out.split("warning(s)")[0]
    assert "accepted noise" in (tmp_path / "logs/warnings-build.log").read_text()


def test_warnings_clean_exits_0(tmp_path, capsys):
    w = World(tmp_path, {"hooks": {"warnings_build": hook(0, "BUILD SUCCEEDED")}})
    assert w.run("warnings", "--log-dir", str(tmp_path / "logs"), "--json") == 0
    assert out_json(capsys)["ok"] is True


def test_warnings_hook_failure_exits_1(tmp_path, capsys):
    w = World(tmp_path, {"hooks": {"warnings_build": hook(2, "compile error")}})
    assert w.run("warnings", "--log-dir", str(tmp_path / "logs")) == 1
    assert "compile error" in capsys.readouterr().err


def test_warnings_bad_allowlist_exits_2_before_building(tmp_path, capsys):
    marker = tmp_path / "ran"
    script = f"open({str(marker)!r}, 'w').close()"
    w = World(tmp_path, {"hooks": {"warnings_build": [sys.executable, "-c", script]}})
    (w.repo / "release/warnings-allowlist.json").write_text(json.dumps(
        {"allowed": [{"pattern": "x", "reason": ""}]}))
    assert w.run("warnings", "--log-dir", str(tmp_path / "logs")) == 2
    assert "has no reason" in capsys.readouterr().err
    assert not marker.exists()


# build / publish / prepared -------------------------------------------------------------


def test_build_hands_the_release_to_the_pipeline(tmp_path, monkeypatch):
    w = World(tmp_path)
    seen = []
    monkeypatch.setattr(build_pipeline, "run_build", lambda r: seen.append(r) or 0)
    root = tmp_path / "artifacts"
    assert w.run("build", "--branch", "release-preparation", "--artifacts-root", str(root),
                 "--site", "https://staging.example.com", "-v") == 0
    (r,) = seen
    assert (r.version, r.build_number) == (VERSION, BUILD)
    assert r.branch == "release-preparation" and r.site == "https://staging.example.com"
    assert r.artifacts_root == root and r.out == root / VERSION
    assert r.verbose is True and r.publish is False
    assert r.cfg.repo == w.repo


def test_build_defaults_branch_and_artifacts(tmp_path, monkeypatch):
    w = World(tmp_path)
    seen = []
    monkeypatch.setattr(build_pipeline, "run_build", lambda r: seen.append(r) or 1)
    assert w.run("build") == 1                       # the pipeline's code passes through
    assert seen[0].branch == "main" and seen[0].out == w.repo / "build/release" / VERSION


def test_build_preflight_failure_exits_1_with_the_preflight_output(tmp_path, capsys):
    w = World(tmp_path)
    assert w.run("build", "--branch", "release-preparation") == 1
    captured = capsys.readouterr()
    assert "==> Preflight (build" in captured.out
    assert "Sparkle's tools are not under" in captured.err
    # Nothing real ran: the xcodebuild resolve went through the fake runner.
    assert w.runner.find("xcodebuild", "-resolvePackageDependencies")


def test_publish_hands_a_publish_release_to_the_pipeline(tmp_path, monkeypatch):
    w = World(tmp_path)
    seen = []
    monkeypatch.setattr(publish, "run_publish", lambda r: seen.append(r) or 0)
    assert w.run("publish", "--site", "https://staging.example.com") == 0
    (r,) = seen
    assert r.publish is True and r.site == "https://staging.example.com"
    assert (r.version, r.build_number) == (VERSION, BUILD) and r.branch == "main"


def test_prepared_json_reports_not_prepared(tmp_path, capsys):
    w = World(tmp_path)
    assert w.run("prepared", "--json", "--artifacts-root", str(tmp_path / "none")) == 1
    doc = out_json(capsys)
    assert doc["ok"] is False and doc["version"] == VERSION
    assert doc["tag"] == f"release/{VERSION}"


def test_prepared_human_output_says_not_prepared(tmp_path, capsys):
    w = World(tmp_path)
    assert w.run("prepared", "--branch", "main") == 1
    assert "NOT PREPARED" in capsys.readouterr().out


# install / installed --------------------------------------------------------------------


def test_install_passes_zip_cfg_and_apps_dir(tmp_path, monkeypatch):
    w = World(tmp_path)
    seen = {}

    def fake_install(zip_path, cfg, **kw):
        seen.update(zip=zip_path, cfg=cfg, **kw)
        return 0

    monkeypatch.setattr(install_mod, "install", fake_install)
    assert w.run("install", str(tmp_path / "App.zip"), "--apps-dir", str(tmp_path / "apps")) == 0
    assert seen["zip"] == tmp_path / "App.zip" and seen["apps_dir"] == tmp_path / "apps"
    assert seen["cfg"].app_name == "AgenticDeveloperKitchen"
    assert seen["run"] is w.runner


def test_install_failure_exit_code_passes_through(tmp_path, monkeypatch):
    w = World(tmp_path)
    monkeypatch.setattr(install_mod, "install", lambda *a, **k: 1)
    assert w.run("install", "x.zip") == 1


def test_installed_reports_a_missing_install(tmp_path, capsys):
    w = World(tmp_path)
    assert w.run("installed", "--apps-dir", str(tmp_path / "apps")) == 1
    assert "is not installed" in capsys.readouterr().out


def test_installed_json(tmp_path, capsys):
    w = World(tmp_path)
    assert w.run("installed", "--json", "--apps-dir", str(tmp_path / "apps")) == 1
    doc = out_json(capsys)
    assert doc["ok"] is False and "is not installed" in doc["failures"][0]


def test_installed_healthy_prints_a_check_mark(tmp_path, monkeypatch, capsys):
    w = World(tmp_path)
    monkeypatch.setattr(install_mod, "installed_failures", lambda cfg, **k: [])
    assert w.run("installed") == 0
    assert "✓ AgenticDeveloperKitchen" in capsys.readouterr().out


def test_installed_then_runs_the_health_hook(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(install_mod, "installed_failures", lambda cfg, **k: [])
    ok = World(tmp_path / "ok", {"hooks": {"health": hook(0, "healthy")}}, flavor="adkitchen")
    assert ok.run("installed") == 0
    assert "health hook passed" in capsys.readouterr().out
    bad = World(tmp_path / "bad", {"hooks": {"health": hook(4, "sick")}}, flavor="adkitchen")
    assert bad.run("installed") == 1
    assert "health hook exited 4" in capsys.readouterr().out


def test_installed_skips_the_health_hook_when_the_install_is_wrong(tmp_path, monkeypatch):
    marker = tmp_path / "health-ran"
    script = f"open({str(marker)!r}, 'w').close()"
    w = World(tmp_path, {"hooks": {"health": [sys.executable, "-c", script]}})
    monkeypatch.setattr(install_mod, "installed_failures", lambda cfg, **k: ["wrong version"])
    assert w.run("installed") == 1
    assert not marker.exists()


# verify ---------------------------------------------------------------------------------


def test_verify_json_reports_not_ready_without_polling_when_timeout_is_zero(tmp_path, capsys):
    w = World(tmp_path)
    assert w.run("verify", "--timeout", "0", "--json") == 1
    doc = out_json(capsys)
    assert doc["ready"] is False and doc["version"] == VERSION
    names = {c["name"] for c in doc["checks"]}
    assert {"github", "feed"} <= names
    assert all(url.startswith(("https://raw.githubusercontent.com/",
                               "https://kitchen.agenticdevelopmentstudio.com/"))
               for url in w.fetches)


def test_verify_unpublished_version_exits_2(tmp_path, capsys):
    w = World(tmp_path)
    assert w.run("verify", "--version", "9.9.9", "--timeout", "0") == 2
    assert "9.9.9" in capsys.readouterr().err
    assert w.run("verify", "9.9.9", "--timeout", "0") == 2


def test_verify_version_forms_must_agree(tmp_path, capsys):
    w = World(tmp_path)
    assert w.run("verify", "1.0.0", "--version", "2.0.0") == 2
    assert "disagree" in capsys.readouterr().err


def test_verify_passes_site_timeout_interval(tmp_path, monkeypatch):
    w = World(tmp_path)
    seen = {}
    monkeypatch.setattr(cli.verify, "run_verify", lambda cfg, **kw: seen.update(kw) or 0)
    root = tmp_path / "art"
    assert w.run("verify", "--site", "https://staging.example.com", "--timeout", "5",
                 "--interval", "2", "--artifacts-root", str(root)) == 0
    assert (seen["site"], seen["timeout"], seen["interval"]) == (
        "https://staging.example.com", 5.0, 2.0)
    assert seen["artifacts_root"] == root and seen["as_json"] is False
    assert seen["fetch"] == w.fetch


def test_verify_defaults(tmp_path, monkeypatch):
    w = World(tmp_path)
    seen = {}
    monkeypatch.setattr(cli.verify, "run_verify", lambda cfg, **kw: seen.update(kw) or 0)
    assert w.run("verify") == 0
    assert (seen["timeout"], seen["interval"]) == (900, 30)


# the skill's contract -----------------------------------------------------------------

# Longest first, so `installed` is not read as `install`.
COMMAND_RE = re.compile(r"CLI(?: <\w+>)? ("
                        + "|".join(sorted(cli.COMMANDS, key=len, reverse=True))
                        + r")\b([^`\n]*)")


def skill_invocations(text: str) -> list[tuple[str, list[str]]]:
    """Every `CLI <repo> <cmd> ...` in the skill as (command, argv tail), with each
    <placeholder> filled in, `[optional]` brackets dropped and `a|b` taking `a`."""
    found = []
    for m in COMMAND_RE.finditer(text):
        tail = []
        for token in m.group(2).replace("[", " ").replace("]", " ").split():
            if token.startswith(("(", "—", "-", "<")) or token[0].isalnum() or token[0] == "/":
                tail.append("placeholder" if "<" in token else token.split("|")[0])
        found.append((m.group(1), tail))
    return found


def test_skill_invocation_extraction():
    got = skill_invocations("`CLI <WT> bump patch|minor`, `CLI publish [--site <origin>]`, "
                            "the CLI is fine, `CLI <repo>`")
    assert got == [("bump", ["patch"]), ("publish", ["--site", "placeholder"])]


@pytest.mark.skipif(not SKILL.exists(), reason="the release skill is not installed "
                    "(set RELEASE_SKILL to its SKILL.md)")
def test_every_cli_usage_in_the_skill_is_accepted_by_argparse():
    uses = skill_invocations(SKILL.read_text())
    assert len(uses) >= 15, "the extraction should find the skill's CLI calls"
    assert set(cli.COMMANDS) <= {cmd for cmd, _ in uses}, \
        "a CLI command the skill never calls is dead, or the skill forgot a step"
    parser = cli.build_parser()
    for cmd, tail in uses:
        argv = ["--repo", "/some/repo", cmd, *tail]
        try:
            args = parser.parse_args(argv)
        except SystemExit:
            pytest.fail(f"argparse rejects the skill's `CLI {cmd} {' '.join(tail)}`")
        assert args.command == cmd


def test_skill_flags_have_the_documented_values():
    parser = cli.build_parser()
    a = parser.parse_args(["build", "--branch", "release-preparation",
                           "--artifacts-root", "/m/build/release"])
    assert (a.branch, a.artifacts_root) == ("release-preparation", "/m/build/release")
    v = parser.parse_args(["verify", "--timeout", "0", "--json"])
    assert v.timeout == 0 and v.json is True


EXAMPLES = Path(__file__).resolve().parents[2] / "docs/examples/release-macos-app"


def test_the_documented_examples_load_and_render(tmp_path):
    from macos_app_release import cask
    from macos_app_release.config import load_config
    from macos_app_release_fixtures import entry

    repo = tmp_path / "repo"
    (repo / "release").mkdir(parents=True)
    (repo / "release.json").write_text((EXAMPLES / "release.json").read_text())
    template = (EXAMPLES / "cask.rb.template").read_text()
    (repo / "release/cask.rb.template").write_text(template)
    cfg = load_config(repo, env={}, home=tmp_path / "home")
    for variable in ("token", "version", "sha256", "url", "pkg", "name", "homepage", "feed",
                     "macos", "bundle_id"):
        assert f"${variable}" in template, f"the example cask template omits ${variable}"
    rendered = cask.cask_ruby(entry(cfg), cfg)
    assert 'cask "adkitchen" do' in rendered and "$" not in rendered


def test_the_script_runs_as_a_program():
    proc = subprocess.run([sys.executable, str(Path(cli.__file__)), "--help"],
                          capture_output=True, text=True)
    assert proc.returncode == 0
    assert all(name in proc.stdout for name in cli.COMMANDS)
