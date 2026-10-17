#!/usr/bin/env python3
"""Tests for macos_app_release.publish.

Nothing here reaches GitHub: every gh/git/Sparkle command goes through FakeRunner.

Run: python3 -m pytest tools/apple/macos_app_release_publish_test.py -q
"""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

import pytest

import macos_release as mr
from macos_app_release import publish, state
from macos_app_release_fixtures import (BUILD, VERSION, FakeRunner, new_appcast, release,
                                         with_artifacts)

FLAVORS = ["adkitchen", "stenographer"]


def view_ok(r, **overrides):
    """A `gh release view` response listing r's pkg and zip as they are on disk."""
    assets = []
    for path in (r.pkg_path, r.zip_path):
        a = {"name": path.name, "size": path.stat().st_size}
        a.update(overrides.get(path.name, {}))
        assets.append(a)
    return (lambda a: a[:3] == ["gh", "release", "view"], 0, json.dumps({"assets": assets}))


VIEW_MISSING = (lambda a: a[:3] == ["gh", "release", "view"], 1, "", "release not found")


def ahead(n):
    return (lambda a: "rev-list" in a, 0, f"{n}\n")


def listed(r):
    (r.releases_repo / "releases.json").write_text(json.dumps(
        {"schema": 1, "latest": r.version, "releases": [{"version": r.version}]}))


def git_calls(run, *verbs):
    return [c for c in run.calls if c[0] == "git" and c[3] in (verbs or ("add", "commit", "push"))]


def generating(run):
    """Wrap `run` so generate_appcast leaves the appcast a real one would."""
    def runner(argv):
        if not argv[0].endswith("generate_appcast"):
            return run(argv)
        run.calls.append(list(argv))
        Path(argv[argv.index("-o") + 1]).write_text(new_appcast(runner.release))
        return subprocess.CompletedProcess(argv, 0, "", "")
    return runner


# release_files -------------------------------------------------------------------


@pytest.mark.parametrize("flavor", FLAVORS)
def test_release_files_name_the_cask_from_config(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    assert publish.release_files(r.cfg) == (
        "releases.json", "notes/{version}.md", "appcast.xml", f"Casks/{r.cfg.cask_token}.rb")


# load_releases_json ----------------------------------------------------------------


def test_load_releases_json_defaults_when_missing(tmp_path):
    r = release(tmp_path, FakeRunner())
    (r.releases_repo / "releases.json").unlink()
    assert publish.load_releases_json(r) == {"schema": 1, "releases": []}


# github_release_assets -------------------------------------------------------------


def test_github_release_assets_none_when_no_release(tmp_path):
    r = release(tmp_path, FakeRunner([VIEW_MISSING]))
    assert publish.github_release_assets(r) is None


def test_github_release_assets_queries_the_configured_repo(tmp_path):
    run = FakeRunner([(lambda a: a[:3] == ["gh", "release", "view"], 0,
                       json.dumps({"assets": [{"name": "x"}]}))])
    r = release(tmp_path, run)
    assert publish.github_release_assets(r) == [{"name": "x"}]
    argv = run.find("gh", "release", "view")[0]
    assert argv[3] == f"v{VERSION}"
    assert argv[argv.index("--repo") + 1] == r.cfg.github_repo


def test_github_release_assets_other_failure_is_a_preflight_error(tmp_path):
    r = release(tmp_path, FakeRunner([(lambda a: a[:2] == ["gh", "release"], 1, "",
                                       "HTTP 502")]))
    with pytest.raises(mr.PreflightError, match="gh release view v1.0.154 failed: HTTP 502"):
        publish.github_release_assets(r)


def test_github_release_assets_unreadable_json(tmp_path):
    r = release(tmp_path, FakeRunner([(lambda a: a[:2] == ["gh", "release"], 0, "{nope")]))
    with pytest.raises(mr.PreflightError, match="unreadable JSON"):
        publish.github_release_assets(r)


# asset_mismatches ------------------------------------------------------------------


def test_asset_mismatches_accepts_matching_assets(tmp_path):
    r = with_artifacts(release(tmp_path, FakeRunner()))
    sha = state.sha256_of(r.pkg_path)
    assets = [{"name": r.pkg_path.name, "size": 9, "digest": f"sha256:{sha}"},
              {"name": r.zip_path.name, "size": 9}]
    assert publish.asset_mismatches(r, assets) == []


def test_asset_mismatches_reports_every_problem(tmp_path):
    r = with_artifacts(release(tmp_path, FakeRunner()))
    assets = [{"name": r.pkg_path.name, "size": 9, "digest": "sha256:" + "0" * 64},
              {"name": "stray.dmg", "size": 1}]
    problems = publish.asset_mismatches(r, assets)
    assert any("sha256 differs" in p for p in problems)
    assert f"{r.zip_path.name} is not attached" in problems
    assert any("unexpected assets attached: stray.dmg" in p for p in problems)


def test_asset_mismatches_reports_a_wrong_size(tmp_path):
    r = with_artifacts(release(tmp_path, FakeRunner()))
    assets = [{"name": r.pkg_path.name, "size": 1}, {"name": r.zip_path.name, "size": 9}]
    assert any(f"{r.pkg_path.name} is 1 bytes on GitHub, 9 locally" in p
               for p in publish.asset_mismatches(r, assets))


# publish_state ---------------------------------------------------------------------


def test_publish_state_create_when_no_release_yet(tmp_path):
    r = with_artifacts(release(tmp_path, FakeRunner([VIEW_MISSING])))
    assert publish.publish_state(r) == "create"


def test_publish_state_commit_when_release_exists_but_is_not_listed(tmp_path):
    r = with_artifacts(release(tmp_path, FakeRunner()))
    r.run = FakeRunner([view_ok(r)])
    assert publish.publish_state(r) == "commit"


def test_publish_state_push_when_committed_but_unpushed(tmp_path):
    r = with_artifacts(release(tmp_path, FakeRunner()))
    listed(r)
    r.run = run = FakeRunner([view_ok(r), ahead(1)])
    assert publish.publish_state(r) == "push"
    count = run.find("git", "-C", str(r.releases_repo), "rev-list")[0]
    assert count[-1] == "origin/main..HEAD"


def test_publish_state_counts_against_the_configured_branch(tmp_path):
    r = with_artifacts(release(tmp_path, FakeRunner(), overrides={"releases": {"branch": "trunk"}}))
    listed(r)
    r.run = run = FakeRunner([view_ok(r), ahead(1)])
    assert publish.publish_state(r) == "push"
    assert run.find("git", "-C", str(r.releases_repo), "rev-list")[0][-1] == "origin/trunk..HEAD"


def test_publish_state_already_published(tmp_path):
    r = with_artifacts(release(tmp_path, FakeRunner()))
    listed(r)
    r.run = FakeRunner([view_ok(r), ahead(0)])
    with pytest.raises(state.AlreadyPublished, match="already published"):
        publish.publish_state(r)


def test_publish_state_refuses_mismatched_assets(tmp_path):
    r = with_artifacts(release(tmp_path, FakeRunner()))
    r.run = FakeRunner([view_ok(r, **{r.zip_path.name: {"size": 1}})])
    with pytest.raises(mr.PreflightError) as exc:
        publish.publish_state(r)
    message = str(exc.value)
    assert f"gh release delete v{VERSION} --repo {r.cfg.github_repo} --cleanup-tag" in message


def test_publish_state_refuses_a_listed_version_without_a_release(tmp_path):
    r = with_artifacts(release(tmp_path, FakeRunner([VIEW_MISSING])))
    listed(r)
    with pytest.raises(mr.PreflightError, match="by hand"):
        publish.publish_state(r)


# step_publish ----------------------------------------------------------------------


@pytest.mark.parametrize("flavor", FLAVORS)
def test_publish_is_one_commit_after_the_github_release(tmp_path, flavor):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run, flavor=flavor))
    r.publish_state = "create"
    publish.step_publish(r)

    cfg = r.cfg
    gh = run.find("gh", "release", "create")
    assert len(gh) == 1
    argv = gh[0]
    assert argv[3] == r.tag
    assert str(r.pkg_path) in argv and str(r.zip_path) in argv
    assert argv[argv.index("--repo") + 1] == cfg.github_repo
    assert argv[argv.index("--title") + 1] == f"{cfg.title} {VERSION}"
    assert argv[argv.index("--notes-file") + 1] == str(r.notes)

    data = json.loads((r.releases_repo / "releases.json").read_text())
    assert data["schema"] == 1 and data["latest"] == VERSION
    entry = data["releases"][0]
    assert entry["build"] == BUILD
    assert entry["minimumSystemVersion"] == "26.0"
    assert entry["notes"] == f"notes/{VERSION}.md"
    assert entry["pkg"]["url"] == (f"{cfg.download_prefix}/v{VERSION}/"
                                   f"{cfg.app_name}-{VERSION}.pkg")
    assert entry["pkg"]["size"] == len(b"pkg-bytes")
    assert entry["zip"]["url"].endswith(f"/v{VERSION}/{cfg.app_name}-{VERSION}.zip")

    assert (r.releases_repo / "notes" / f"{VERSION}.md").read_text() == r.notes.read_text()
    assert (r.releases_repo / "appcast.xml").read_text() == new_appcast(r)

    git = git_calls(run)
    repo = str(r.releases_repo)
    assert [c[:4] for c in git] == [["git", "-C", repo, "add"], ["git", "-C", repo, "commit"],
                                    ["git", "-C", repo, "push"]]
    assert git[0][git[0].index("--") + 1:] == [
        "releases.json", f"notes/{VERSION}.md", "appcast.xml", cfg.cask_file]
    cask = (r.releases_repo / cfg.cask_file).read_text()
    assert f'version "{VERSION}"' in cask
    assert f'sha256 "{entry["pkg"]["sha256"]}"' in cask
    assert git[1][-1] == f"Release {VERSION}"
    assert git[2][-2:] == ["origin", "main"]
    assert run.calls.index(argv) < run.calls.index(git[0])


def test_publish_writes_cask_at_configured_token(tmp_path):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run, overrides={"cask": {"token": "kitchen-sink"}}))
    r.publish_state = "create"
    publish.step_publish(r)

    cask = r.releases_repo / "Casks" / "kitchen-sink.rb"
    assert r.cfg.cask_file == "Casks/kitchen-sink.rb"
    assert cask.exists()
    assert 'cask "kitchen-sink" do' in cask.read_text()
    assert [p.name for p in (r.releases_repo / "Casks").iterdir()] == ["kitchen-sink.rb"]
    add = git_calls(run, "add")[0]
    assert "Casks/kitchen-sink.rb" in add[add.index("--") + 1:]


def test_publish_pushes_the_configured_branch(tmp_path):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run, overrides={"releases": {"branch": "trunk"}}))
    r.publish_state = "create"
    publish.step_publish(r)

    pushes = git_calls(run, "push")
    assert len(pushes) == 1
    assert pushes[0] == ["git", "-C", str(r.releases_repo), "push", "origin", "trunk"]
    assert not [c for c in run.calls if c[-2:] == ["origin", "main"]]


def test_publish_merges_into_existing_releases(tmp_path):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run))
    r.publish_state = "create"
    old = {"version": "0.9.0", "build": 0, "date": "2026-09-01T00:00:00Z",
           "minimumSystemVersion": "26.0", "notes": "notes/0.9.0.md",
           "pkg": {"url": "u", "size": 1, "sha256": "x"},
           "zip": {"url": "u", "size": 1, "sha256": "x"}}
    (r.releases_repo / "releases.json").write_text(
        json.dumps({"schema": 1, "latest": "0.9.0", "releases": [old]}))
    publish.step_publish(r)
    data = json.loads((r.releases_repo / "releases.json").read_text())
    assert [e["version"] for e in data["releases"]] == [VERSION, "0.9.0"]
    assert data["latest"] == VERSION


def test_publish_stops_when_gh_release_fails(tmp_path):
    run = FakeRunner([(lambda a: a[:3] == ["gh", "release", "create"], 1, "")])
    r = with_artifacts(release(tmp_path, run))
    r.publish_state = "create"
    with pytest.raises(RuntimeError):
        publish.step_publish(r)
    assert not run.find("git")
    assert json.loads((r.releases_repo / "releases.json").read_text())["releases"] == []
    assert not (r.releases_repo / "appcast.xml").exists()


def test_publish_stops_when_the_push_fails(tmp_path):
    run = FakeRunner([(lambda a: a[:1] == ["git"] and "push" in a, 1, "", "rejected")])
    r = with_artifacts(release(tmp_path, run))
    r.publish_state = "create"
    with pytest.raises(RuntimeError, match=r"git push.*failed \(exit 1\):\nrejected"):
        publish.step_publish(r)


def test_publish_refuses_before_any_remote_step_without_an_appcast(tmp_path):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run), appcast=False)
    r.publish_state = "create"
    with pytest.raises(RuntimeError, match="appcast"):
        publish.step_publish(r)
    assert run.calls == []


def test_publish_refuses_an_unrenderable_cask_before_any_remote_step(tmp_path):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run))
    r.minimum_system_version = "27.0"
    r.publish_state = "create"
    with pytest.raises(RuntimeError, match="HOMEBREW_MACOS"):
        publish.step_publish(r)
    assert run.calls == []


def test_publish_after_a_failed_push_only_pushes(tmp_path):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run), appcast=False)
    r.publish_state = "push"
    publish.step_publish(r)
    assert not run.find("gh", "release", "create")
    assert [c[3] for c in git_calls(run)] == ["push"]


def test_publish_after_a_failed_commit_skips_the_create_and_commits_once(tmp_path):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run))
    r.publish_state = "commit"
    publish.step_publish(r)
    assert not run.find("gh", "release", "create")
    assert [c[3] for c in git_calls(run)] == ["add", "commit", "push"]
    entry = json.loads((r.releases_repo / "releases.json").read_text())["releases"][0]
    assert entry["minimumSystemVersion"] == "26.0"
    assert (r.releases_repo / "appcast.xml").read_text() == new_appcast(r)


# run_publish -----------------------------------------------------------------------


def preflight_stub(r):
    """Task 4's step_preflight, reduced to what decides the publish state."""
    r.publish_state = publish.publish_state(r)


@pytest.fixture
def stub_preflight(monkeypatch):
    from macos_app_release import sparkle

    def steps():
        return {"preflight": preflight_stub, "appcast": sparkle.step_appcast,
                "sparkle-verify": sparkle.step_sparkle_verify,
                "publish": publish.step_publish}
    monkeypatch.setattr(publish, "publish_step_functions", steps)


def staged(tmp_path, *responses, lists=False, **kw):
    """A release with artifacts, a signed-appcast-producing runner, and the Sparkle key
    answers sparkle-verify needs (the staged app carries the same key)."""
    import plistlib

    run = FakeRunner([*responses, (lambda a: a[-1] == "-p", 0, "KEY=\n")])
    r = with_artifacts(release(tmp_path, run, **kw), appcast=False)
    (r.app / "Contents").mkdir(parents=True)
    (r.app / "Contents/Info.plist").write_bytes(plistlib.dumps({"SUPublicEDKey": "KEY="}))
    r.run = generating(run)
    r.run.release = r
    if lists:
        listed(r)
    return r, run


def test_run_publish_with_no_release_yet_publishes_from_existing_artifacts(tmp_path, stub_preflight):
    r, run = staged(tmp_path, VIEW_MISSING)
    assert publish.run_publish(r) == 0
    assert r.publish_state == "create"
    assert len(run.find("gh", "release", "create")) == 1
    assert [c for c in run.calls if c[0].endswith("generate_appcast")]
    assert [c for c in run.calls if c[0].endswith("sign_update")]
    assert not [c for c in run.calls if c[0] == "xcodebuild"]
    assert [c[3] for c in git_calls(run)] == ["add", "commit", "push"]


def test_run_publish_state_push_skips_appcast_and_sparkle_verify(tmp_path, stub_preflight):
    r, run = staged(tmp_path, ahead(1), lists=True)
    run.responses.insert(0, view_ok(r))
    assert publish.run_publish(r) == 0
    assert r.publish_state == "push"
    assert not run.find("gh", "release", "create")
    assert [c[3] for c in git_calls(run)] == ["push"]
    assert not [c for c in run.calls if c[0].endswith(("generate_appcast", "sign_update"))]
    assert not [c for c in run.calls if c[0].endswith("generate_keys")]


def test_run_publish_state_commit_commits_once_without_recreating(tmp_path, stub_preflight):
    r, run = staged(tmp_path)
    run.responses.insert(0, view_ok(r))
    assert publish.run_publish(r) == 0
    assert r.publish_state == "commit"
    assert not run.find("gh", "release", "create")
    assert [c[3] for c in git_calls(run)] == ["add", "commit", "push"]


def test_run_publish_reports_already_published_and_exits_zero(tmp_path, stub_preflight, capsys):
    r, run = staged(tmp_path, ahead(0), lists=True)
    run.responses.insert(0, view_ok(r))
    assert publish.run_publish(r) == 0
    assert "already published" in capsys.readouterr().out
    assert not git_calls(run)


def test_run_publish_unknown_cask_variable_is_an_error_not_a_traceback(
        tmp_path, stub_preflight, capsys):
    r, run = staged(tmp_path, VIEW_MISSING)
    r.cfg.cask_template.write_text('cask "$token" do\n  version "$nope"\nend\n')
    assert publish.run_publish(r) == 1
    err = capsys.readouterr().err
    assert err.startswith("error:") and "cask.template" in err
    assert not run.find("gh", "release", "create")


def test_run_publish_missing_cask_template_is_an_error_not_a_traceback(
        tmp_path, stub_preflight, capsys):
    r, run = staged(tmp_path, VIEW_MISSING)
    r.cfg.cask_template.unlink()
    assert publish.run_publish(r) == 1
    assert capsys.readouterr().err.startswith("error:")
    assert not run.find("gh", "release", "create")


def test_run_publish_exits_one_on_a_preflight_error(tmp_path, stub_preflight, capsys):
    r, run = staged(tmp_path)
    run.responses.insert(0, view_ok(r, **{r.zip_path.name: {"size": 1}}))
    assert publish.run_publish(r) == 1
    err = capsys.readouterr().err
    assert "preflight failed" in err and "gh release delete" in err
    assert not run.find("gh", "release", "create")


def test_run_publish_exits_one_when_a_step_raises(tmp_path, stub_preflight, capsys):
    r, run = staged(tmp_path, VIEW_MISSING,
                    (lambda a: a[:3] == ["gh", "release", "create"], 1, "", "boom"))
    assert publish.run_publish(r) == 1
    assert "error: boom" in capsys.readouterr().err
    assert not git_calls(run)


def test_run_publish_runs_the_steps_in_order(tmp_path, monkeypatch):
    seen = []
    monkeypatch.setattr(publish, "publish_step_functions", lambda: {
        name: (lambda r, n=name: seen.append(n)) for name in publish.PUBLISH_STEPS})
    r = release(tmp_path, FakeRunner())
    assert publish.run_publish(r) == 0
    assert seen == ["preflight", "appcast", "sparkle-verify", "publish"]
    assert r.publish is True


def test_publish_step_functions_wire_the_real_steps():
    from macos_app_release import build_pipeline, sparkle

    steps = publish.publish_step_functions()
    assert list(steps) == publish.PUBLISH_STEPS
    assert steps["preflight"] is build_pipeline.step_preflight
    assert steps["appcast"] is sparkle.step_appcast
    assert steps["sparkle-verify"] is sparkle.step_sparkle_verify
    assert steps["publish"] is publish.step_publish
