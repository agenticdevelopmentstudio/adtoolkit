#!/usr/bin/env python3
"""Tests for macos_app_release.build_pipeline (the build steps of the release pipeline).

Ported from Stenographer's tests/test_release.py; every test that depends on the app's
configuration runs against both fixture flavors.

Run: python3 -m pytest tools/apple/macos_app_release_build_test.py -q
"""
from __future__ import annotations

import json
import plistlib
import subprocess
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

import pytest

import macos_release as mr
from macos_app_release import build_pipeline as bp
from macos_app_release.state import PREPARE_CMD, sha256_of
from macos_app_release_fixtures import (BUILD, FLAVORS, SOURCE_SHA, VERSION, FakeRunner, entry,
                                         make_app, release, with_artifacts)

FLAVOR_NAMES = ["adkitchen", "stenographer"]
TEAM = "K2NA732JAX"
LIVE = (lambda a: a[0] == "curl", 0, "200")


# helpers -------------------------------------------------------------------------


def _identities(*names):
    return "\n".join(f'  {i}) ABC "{n}: Team ({TEAM})"'
                     for i, n in enumerate(names, 1)) + "\n"


def _profile_plist(bundle_id, *, all_devices=True, team=TEAM):
    info = {"TeamIdentifier": [team],
            "Entitlements": {"com.apple.application-identifier": f"{team}.{bundle_id}"}}
    if all_devices:
        info["ProvisionsAllDevices"] = True
    return plistlib.dumps(info).decode()


def _cms(stdout):
    return (lambda a: a[:3] == ["security", "cms", "-D"], 0, stdout)


def _head_and_tag(*, tag=None, head=SOURCE_SHA):
    """git answers for HEAD and refs/tags/<prefix><version>; tag=None = no such tag."""
    return [(lambda a: any(x.startswith("refs/tags/") for x in a),
             *((0, f"{tag}\n") if tag else (1, ""))),
            (lambda a: "HEAD^{commit}" in a, 0, f"{head}\n")]


def _release_responses(*extra, identities=("Developer ID Application", "Developer ID Installer"),
                       tag=None):
    return [*extra,
            *_head_and_tag(tag=tag),
            (lambda a: a[:2] == ["security", "find-identity"], 0, _identities(*identities)),
            (lambda a: a[:3] == ["gh", "repo", "view"], 0, '{"viewerPermission": "ADMIN"}'),
            (lambda a: a[:3] == ["gh", "release", "view"], 1, "", "release not found"),
            (lambda a: "rev-parse" in a, 0, "main\n"),
            (lambda a: "rev-list" in a, 0, "0\n"),
            LIVE]


def _world(tmp_path, flavor, *extra, identities=("Developer ID Application",
                                                "Developer ID Installer"),
           tag=None, profile_ok=True, **release_kw):
    """A Release whose fake machine passes every build preflight check (the flavor's
    Developer ID profile, if any, is set in env and valid), except as `extra` says."""
    profiles = FLAVORS[flavor].get("signing", {}).get("profiles", [])
    env: dict[str, str] = {}
    responses = list(extra)
    if profiles:
        first = profiles[0]
        devid = tmp_path / "app.provisionprofile"
        devid.write_bytes(b"cms")
        env[first["env"]] = str(devid)
        responses.append(_cms(_profile_plist(first["bundle_id"], all_devices=profile_ok)))
    runner = FakeRunner(_release_responses(*responses, identities=identities, tag=tag))
    return release(tmp_path, runner, flavor=flavor, public_key="abc=", env=env, **release_kw)


def _preflight_error(r) -> str:
    with pytest.raises(mr.PreflightError) as exc:
        bp.step_preflight(r)
    return str(exc.value)


# step_preflight / release_preflight ----------------------------------------------


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_preflight_passes_and_records_the_build_context(tmp_path, flavor):
    r = _world(tmp_path, flavor)
    bp.step_preflight(r)
    assert r.team == TEAM
    assert r.source_sha == SOURCE_SHA
    assert r.out.is_dir()
    assert set(r.profiles) == {p["bundle"] for p in FLAVORS[flavor].get("signing", {})
                               .get("profiles", [])[:1]}


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_preflight_clears_a_stale_output_directory(tmp_path, flavor):
    r = _world(tmp_path, flavor)
    r.out.mkdir(parents=True)
    (r.out / "stale.pkg").write_text("x")
    bp.step_preflight(r)
    assert list(r.out.iterdir()) == []


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_missing_notes_fails_preflight(tmp_path, flavor):
    r = _world(tmp_path, flavor, notes=False)
    message = _preflight_error(r)
    assert "release notes missing" in message
    assert str(r.notes) in message
    assert not r.out.exists()


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_preflight_names_generate_keys_when_public_key_empty(tmp_path, flavor):
    r = _world(tmp_path, flavor)
    r.run.responses.insert(0, (lambda a: a[-1] == "-p", 1, ""))
    (r.cfg.project_yml).write_text(
        r.cfg.project_yml.read_text().replace(f'{r.cfg.public_key_setting}: "abc="',
                                              f'{r.cfg.public_key_setting}: ""'))
    message = _preflight_error(r)
    assert f"{r.cfg.public_key_setting} is empty" in message
    assert f"generate_keys --account {r.cfg.sparkle_account}" in message


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_preflight_reports_missing_developer_id_identities(tmp_path, flavor):
    r = _world(tmp_path, flavor, identities=("Apple Development",))
    message = _preflight_error(r)
    assert r.cfg.app_identity in message and r.cfg.installer_identity in message


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_preflight_reports_every_problem_at_once(tmp_path, flavor):
    r = _world(tmp_path, flavor, identities=("Apple Development",), notes=False)
    message = _preflight_error(r)
    assert "missing signing identity" in message and "release notes missing" in message


def test_preflight_names_the_profile_env_var_when_unset(tmp_path):
    r = _world(tmp_path, "stenographer")
    r.env.clear()
    message = _preflight_error(r)
    assert "STENOGRAPHER_DEVID_PROFILE_APP is not set" in message
    assert "developer.apple.com" in message
    # The widget embeds no profile, so its variable is optional.
    assert "STENOGRAPHER_DEVID_PROFILE_WIDGET" not in message


def test_adkitchen_needs_no_profile(tmp_path):
    r = _world(tmp_path, "adkitchen")
    assert r.cfg.profiles == ()
    bp.step_preflight(r)
    assert r.profiles == {}


@pytest.mark.parametrize("all_devices, problem", [
    (False, "ProvisionsAllDevices is not true"),
])
def test_preflight_rejects_an_invalid_profile(tmp_path, all_devices, problem):
    r = _world(tmp_path, "stenographer", profile_ok=all_devices)
    message = _preflight_error(r)
    assert "STENOGRAPHER_DEVID_PROFILE_APP" in message and problem in message
    assert r.run.find("security", "cms", "-D", "-i", r.env["STENOGRAPHER_DEVID_PROFILE_APP"])


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_build_preflight_refuses_a_version_already_tagged(tmp_path, flavor):
    r = _world(tmp_path, flavor, tag="b" * 40)
    message = _preflight_error(r)
    assert f"tag {r.source_tag} already exists" in message
    assert r.source_tag == r.cfg.source_tag_prefix + VERSION


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_preflight_points_at_publish_when_the_release_exists(tmp_path, flavor):
    r = _world(tmp_path, flavor, (lambda a: a[:3] == ["gh", "release", "view"], 0, ""))
    message = _preflight_error(r)
    assert bp.PUBLISH_CMD in message


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_preflight_fails_when_the_site_is_not_live(tmp_path, flavor):
    r = _world(tmp_path, flavor, (lambda a: a[0] == "curl", 0, "404"))
    message = _preflight_error(r)
    assert "HTTP 404" in message and "owner's step" in message


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_preflight_refuses_when_a_must_match_file_disagrees(tmp_path, flavor):
    r = _world(tmp_path, flavor)
    if not r.cfg.must_match:
        pytest.skip("this flavor has no version.must_match")
    r.cfg.must_match[0].file.write_text('public static let daemonVersion = "9.9.9"\n')
    assert "9.9.9" in _preflight_error(r)


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_release_preflight_checks_the_build_number_against_published_builds(
        tmp_path, monkeypatch, flavor):
    calls = []
    monkeypatch.setattr(mr, "preflight", lambda **kw: calls.append(kw))
    r = _world(tmp_path, flavor)
    bp.release_preflight(r, "abc=", [])
    first = calls[0]   # the call for identities and build; the rest check the releases repo
    assert first["build"] == r.build_number == BUILD
    assert first["identities"] == [r.cfg.app_identity, r.cfg.installer_identity]
    assert first["notary_profile"] == r.cfg.notary_profile
    assert first["github_repo"] == r.cfg.github_repo
    assert first["sparkle_account"] == r.cfg.sparkle_account


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_release_preflight_requires_the_configured_branch(tmp_path, flavor):
    def responses(source_branch):
        source = str(tmp_path / "repo")
        return [(lambda a: "rev-parse" in a and source in a, 0, f"{source_branch}\n")]

    r = _world(tmp_path, flavor, *responses("releases"))
    r.branch = "releases"
    failures: list[str] = []
    bp.release_preflight(r, "abc=", failures)
    assert not [f for f in failures if "branch" in f], failures

    (tmp_path / "again").mkdir()
    r = _world(tmp_path / "again", flavor, *responses("main"))
    r.branch = "releases"
    failures = []
    bp.release_preflight(r, "abc=", failures)
    assert any("not releases" in f for f in failures), failures


def test_source_branch_comes_from_the_config(tmp_path):
    r = _world(tmp_path, "adkitchen", overrides={"source": {"branch": "trunk"}})
    assert r.branch == "trunk"


# publish_preflight ----------------------------------------------------------------


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_publish_preflight_names_the_missing_artifacts_and_the_prepare_command(tmp_path, flavor):
    r = _world(tmp_path, flavor, publish=True)
    failures: list[str] = []
    bp.publish_preflight(r, "abc=", failures)
    for needed in (r.pkg_path, r.zip_path, r.app / "Contents/Info.plist"):
        assert any(str(needed) in f and PREPARE_CMD in f for f in failures), failures


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_publish_preflight_requires_the_source_tag(tmp_path, flavor):
    r = _world(tmp_path, flavor, publish=True)
    r.source_sha = SOURCE_SHA
    failures: list[str] = []
    bp.publish_preflight(r, "abc=", failures)
    assert any(f"no tag {r.source_tag}" in f for f in failures), failures


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_publish_preflight_requires_gh_auth(tmp_path, flavor):
    r = _world(tmp_path, flavor, (lambda a: a[:3] == ["gh", "auth", "status"], 1, ""),
               publish=True)
    failures: list[str] = []
    bp.publish_preflight(r, "abc=", failures)
    assert any("gh is not authenticated" in f for f in failures), failures


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_publish_preflight_reads_the_staged_apps_os_gate_and_sparkle_config(tmp_path, flavor):
    r = _world(tmp_path, flavor, publish=True)
    with_artifacts(r, appcast=False)
    make_app(r, SUPublicEDKey="")
    failures: list[str] = []
    bp.publish_preflight(r, "abc=", failures)
    assert r.minimum_system_version == "26.0"
    assert any(f.startswith("staged app: SUPublicEDKey is empty") for f in failures), failures


# releases_repo_failures -----------------------------------------------------------


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_releases_repo_clean_and_current_passes(tmp_path, flavor):
    r = release(tmp_path, FakeRunner([(lambda a: "rev-parse" in a, 0, "main\n"),
                                      (lambda a: "rev-list" in a, 0, "0\n")]), flavor=flavor)
    assert bp.releases_repo_failures(r) == []


@pytest.mark.parametrize("responses, expected", [
    ([(lambda a: "status" in a, 0, " M releases.json\n")], "uncommitted changes"),
    ([(lambda a: "rev-parse" in a, 0, "gh-pages\n")], "not main"),
    ([(lambda a: "HEAD..origin/main" in a, 0, "2\n")], "2 commit(s) behind origin/main"),
    ([(lambda a: "fetch" in a, 1, "", "offline")], "fetch origin main` failed"),
])
@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_releases_repo_failures(tmp_path, flavor, responses, expected):
    run = FakeRunner([*responses, (lambda a: "rev-parse" in a, 0, "main\n"),
                      (lambda a: "rev-list" in a, 0, "0\n")])
    failures = bp.releases_repo_failures(release(tmp_path, run, flavor=flavor))
    assert any(expected in f for f in failures), failures


def test_releases_repo_uses_the_configured_branch(tmp_path):
    run = FakeRunner([(lambda a: "HEAD..origin/trunk" in a, 0, "3\n"),
                      (lambda a: "rev-parse" in a, 0, "trunk\n"),
                      (lambda a: "rev-list" in a, 0, "0\n")])
    r = release(tmp_path, run, overrides={"releases": {"branch": "trunk"}})
    [failure] = bp.releases_repo_failures(r)
    assert "3 commit(s) behind origin/trunk" in failure
    assert run.find("git", "-C", str(r.releases_repo), "fetch", "origin", "trunk")
    assert not [c for c in run.calls if "origin/main" in " ".join(c) or "main" in c]


def test_releases_repo_missing_checkout_names_the_clone_command(tmp_path):
    r = release(tmp_path, FakeRunner())
    (r.releases_repo / ".git").rmdir()
    [failure] = bp.releases_repo_failures(r)
    assert f"gh repo clone {r.cfg.github_repo} {r.releases_repo}" in failure


def test_releases_repo_fetch_failure_skips_the_behind_check(tmp_path):
    run = FakeRunner([(lambda a: "fetch" in a, 1, "", "offline"),
                      (lambda a: "rev-parse" in a, 0, "main\n")])
    bp.releases_repo_failures(release(tmp_path, run))
    assert not [c for c in run.calls if "HEAD..origin/main" in c]


def test_releases_repo_must_be_pushed_except_when_resuming_a_failed_push(tmp_path):
    run = FakeRunner([(lambda a: "rev-parse" in a, 0, "main\n"),
                      (lambda a: "@{u}..HEAD" in a, 0, "1\n"),
                      (lambda a: "rev-list" in a, 0, "0\n")])
    r = release(tmp_path, run)
    assert any("not on its upstream" in f for f in bp.releases_repo_failures(r))
    r.publish = True
    assert bp.releases_repo_failures(r) == []


# submodule_drift / build_env / step_build -----------------------------------------

DRIFT = ("+0123456789abcdef external/agenticdevelopertoolkit (heads/feature)\n"
         "-fedcba9876543210 external/agenticdaemon\n"
         " 1111111111111111 external/insync (heads/main)\n")


def test_submodule_drift_names_each_drifted_submodule_and_its_fix(tmp_path):
    r = release(tmp_path, FakeRunner([(lambda a: "submodule" in a, 0, DRIFT)]))
    drift = bp.submodule_drift(r)
    assert len(drift) == 2
    assert "external/agenticdevelopertoolkit is at 0123456789ab" in drift[0]
    assert "external/agenticdaemon is not checked out" in drift[1]
    assert "git submodule update --init --recursive" in drift[1]


def test_submodule_drift_command_failure_is_an_error(tmp_path):
    r = release(tmp_path, FakeRunner([(lambda a: "submodule" in a, 128, "", "not a repo")]))
    with pytest.raises(RuntimeError, match=r"(?s)git submodule status failed.*not a repo"):
        bp.submodule_drift(r)


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_build_refuses_drifted_submodules_and_never_runs_the_hook(tmp_path, flavor):
    run = FakeRunner([(lambda a: "submodule" in a, 0, DRIFT)])
    r = release(tmp_path, run, flavor=flavor)
    with pytest.raises(RuntimeError) as exc:
        bp.step_build(r)
    assert "external/agenticdevelopertoolkit is at 0123456789ab" in str(exc.value)
    assert "insync" not in str(exc.value)
    assert not run.find("/usr/bin/env")


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_build_env_adds_the_release_contract_to_the_inherited_env(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor, env={"KEEP": "1"})
    env = bp.build_env(r)
    assert env == {"KEEP": "1", "RELEASE_APP_DEST": str(r.app),
                   "RELEASE_DERIVED_DATA": str(r.derived_data),
                   "RELEASE_VERSION": VERSION, "RELEASE_BUILD": str(BUILD)}


def test_build_hook_that_leaves_no_app_fails_naming_the_hook(tmp_path):
    r = release(tmp_path, FakeRunner())
    with pytest.raises(RuntimeError, match=r"build\.command.*RELEASE_APP_DEST"):
        bp.step_build(r)


def test_build_hook_that_exits_nonzero_fails_naming_the_hook_and_shows_its_output(tmp_path):
    r = release(tmp_path, FakeRunner([(lambda a: a[0] == "/usr/bin/env", 65, "", "xcodebuild died")]))
    with pytest.raises(RuntimeError, match=r"(?s)build\.command failed \(exit 65\).*"
                                           r"RELEASE_APP_DEST.*xcodebuild died"):
        bp.step_build(r)


def _hook(seen, *, make=True):
    def run(argv):
        if argv[0] == "/usr/bin/env":
            seen["argv"] = list(argv)
            seen.update(a.split("=", 1) for a in argv[1:] if a.startswith("RELEASE_"))
            if make:
                Path(seen["RELEASE_APP_DEST"]).mkdir(parents=True)
        return subprocess.CompletedProcess(argv, 0, "", "")
    return run


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_build_hook_gets_release_env_and_the_configured_command(tmp_path, flavor):
    seen: dict = {}
    r = release(tmp_path, _hook(seen), flavor=flavor)
    bp.step_build(r)
    assert seen["RELEASE_APP_DEST"] == str(r.app) and seen["RELEASE_VERSION"] == r.version
    assert seen["RELEASE_BUILD"] == str(r.build_number)
    assert seen["RELEASE_DERIVED_DATA"] == str(r.derived_data)
    assert seen["argv"][5:] == list(r.cfg.build_command)
    assert seen["argv"][:5] == ["/usr/bin/env", f"RELEASE_APP_DEST={r.app}",
                                f"RELEASE_DERIVED_DATA={r.derived_data}",
                                f"RELEASE_VERSION={VERSION}", f"RELEASE_BUILD={BUILD}"]


def test_build_hook_gets_a_staging_parent_but_no_app(tmp_path):
    # The contract: RELEASE_APP_DEST's parent exists and the path itself does not.
    r = release(tmp_path, FakeRunner())
    r.app.mkdir(parents=True)
    (r.app / "leftover").write_text("x")
    seen_state = {}

    def run(argv):
        if argv[0] == "/usr/bin/env":
            seen_state.update(parent=r.app.parent.is_dir(), app=r.app.exists())
            r.app.mkdir()
        return subprocess.CompletedProcess(argv, 0, "", "")

    r.run = run
    bp.step_build(r)
    assert seen_state == {"parent": True, "app": False}
    assert not (r.app / "leftover").exists()


# step_check_bundle ----------------------------------------------------------------


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_check_bundle_passes_a_correct_app_and_reads_the_os_gate(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    make_app(r)
    bp.step_check_bundle(r)
    assert r.minimum_system_version == "26.0"


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_check_bundle_refuses_a_wrong_version_or_build(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    make_app(r, CFBundleShortVersionString="0.0.1", CFBundleVersion="99")
    with pytest.raises(RuntimeError) as exc:
        bp.step_check_bundle(r)
    assert f"built app is 0.0.1, expected {VERSION}" in str(exc.value)
    assert f"build is 99, expected {BUILD}" in str(exc.value)


def test_check_bundle_refuses_a_wrong_expect_info_value(tmp_path):
    r = release(tmp_path, FakeRunner(), flavor="stenographer")
    make_app(r, AgenticReleaseChannel="debug")
    with pytest.raises(RuntimeError, match="AgenticReleaseChannel is 'debug', expected 'release'"):
        bp.step_check_bundle(r)


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_check_bundle_refuses_the_wrong_feed_url(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    make_app(r, SUFeedURL="https://example.com/other.xml")
    with pytest.raises(RuntimeError, match=r"SUFeedURL .*sparkle\.feed_url"):
        bp.step_check_bundle(r)


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_check_bundle_refuses_an_app_sparkle_would_refuse(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    make_app(r, SURequireSignedFeed=True)
    with pytest.raises(RuntimeError, match="SUVerifyUpdateBeforeExtraction"):
        bp.step_check_bundle(r)


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_check_bundle_refuses_an_app_without_an_os_gate(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    make_app(r, LSMinimumSystemVersion=None)
    with pytest.raises(RuntimeError, match="LSMinimumSystemVersion"):
        bp.step_check_bundle(r)


def test_check_bundle_refuses_a_bundle_that_fails_the_layout(tmp_path):
    r = release(tmp_path, FakeRunner(), flavor="stenographer")
    make_app(r)
    (r.app / "Contents/MacOS/stenographerd").unlink()
    (r.app / "Contents/PlugIns/Debug.aiplugin").mkdir(parents=True)
    with pytest.raises(RuntimeError) as exc:
        bp.step_check_bundle(r)
    message = str(exc.value)
    assert "does not match the bundle layout" in message
    assert "missing Contents/MacOS/stenographerd" in message
    assert "forbidden Contents/PlugIns/Debug.aiplugin" in message


def test_check_bundle_without_an_info_plist_names_the_build_hook(tmp_path):
    r = release(tmp_path, FakeRunner())
    r.app.mkdir(parents=True)
    with pytest.raises(RuntimeError, match=r"Info\.plist is missing.*build\.command"):
        bp.step_check_bundle(r)


def test_bundle_check_command_failure_stops(tmp_path):
    r = release(tmp_path, FakeRunner([(lambda a: a[-1] == "check-x", 1, "bad thing")]),
                overrides={"checks": [{"name": "x", "command": ["check-x"]}]})
    make_app(r)
    with pytest.raises(RuntimeError, match=r"(?s)bundle check 'x' failed \(exit 1\):\nbad thing"):
        bp.step_check_bundle(r)


def test_bundle_checks_run_in_order_with_release_app_set(tmp_path):
    run = FakeRunner()
    r = release(tmp_path, run, overrides={"checks": [
        {"name": "a", "command": ["check-a", "--flag"]},
        {"name": "b", "command": ["check-b"]}]})
    make_app(r)
    bp.step_check_bundle(r)
    assert run.calls == [["/usr/bin/env", f"RELEASE_APP={r.app}", "check-a", "--flag"],
                         ["/usr/bin/env", f"RELEASE_APP={r.app}", "check-b"]]


def test_bundle_checks_do_not_run_when_the_toolkit_checks_fail(tmp_path):
    run = FakeRunner()
    r = release(tmp_path, run, overrides={"checks": [{"name": "a", "command": ["check-a"]}]})
    make_app(r, CFBundleVersion="99")
    with pytest.raises(RuntimeError):
        bp.step_check_bundle(r)
    assert run.calls == []


# provision / sign / notarize / zip -------------------------------------------------


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_sign_uses_the_configured_identity_with_runtime_and_timestamp(tmp_path, monkeypatch,
                                                                      flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    make_app(r)
    got = {}
    monkeypatch.setattr(mr, "sign_bundle", lambda app, **kw: got.update(kw, app=app))
    bp.step_sign(r)
    assert got["identity"] == r.cfg.app_identity
    assert got["runtime"] is True and got["timestamp"] is True
    assert got["app"] == r.app
    expected = {r.app if rel == "." else r.app / rel: path
                for rel, path in r.cfg.entitlements.items()}
    assert got["entitlements"] == expected


def test_sign_fails_when_the_layout_no_longer_has_an_entitled_item(tmp_path, monkeypatch):
    r = release(tmp_path, FakeRunner(), flavor="stenographer")
    make_app(r)
    (r.app / "Contents/MacOS/stenographerd").unlink()
    monkeypatch.setattr(mr, "sign_bundle", lambda *a, **kw: pytest.fail("signed anyway"))
    with pytest.raises(RuntimeError, match=r"stenographerd is not in the assembled bundle"):
        bp.step_sign(r)


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_notarize_app_uses_the_configured_profile(tmp_path, monkeypatch, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    got = {}
    monkeypatch.setattr(mr, "notarize", lambda path, **kw: got.update(kw, path=path))
    bp.step_notarize_app(r)
    assert got["path"] == r.app and got["profile"] == r.cfg.notary_profile


def test_update_zip_goes_to_the_release_zip_path(tmp_path, monkeypatch):
    r = release(tmp_path, FakeRunner())
    got = {}
    monkeypatch.setattr(mr, "make_update_zip", lambda app, dest, **kw: got.update(app=app,
                                                                                  dest=dest))
    bp.step_update_zip(r)
    assert got == {"app": r.app, "dest": r.zip_path}


# distribution / pkg -----------------------------------------------------------------


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_distribution_is_one_choice_with_no_scripts_and_no_check(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    r.minimum_system_version = "26.0"
    xml = bp.distribution_xml(r)
    assert '<os-version min="26.0"/>' in xml
    assert "installation-check" not in xml
    assert "python" not in xml.lower()
    assert "allow-external-scripts" not in xml
    assert xml.count("<choice ") == 1
    assert r.cfg.title in xml


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_distribution_makes_installer_quit_the_running_app(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    r.minimum_system_version = "26.0"
    root = ET.fromstring(bp.distribution_xml(r))
    apps = [a.get("id") for a in root.findall("pkg-ref/must-close/app")]
    assert apps == list(r.cfg.pkg_must_close)
    assert apps[0] == r.cfg.bundle_id and len(set(apps)) == len(apps)


def test_stenographer_distribution_also_closes_the_legacy_menubar_app(tmp_path):
    r = release(tmp_path, FakeRunner(), flavor="stenographer")
    r.minimum_system_version = "26.0"
    root = ET.fromstring(bp.distribution_xml(r))
    apps = [a.get("id") for a in root.findall("pkg-ref/must-close/app")]
    assert apps == [r.cfg.bundle_id, f"{r.cfg.bundle_id}.menubar"]


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_distribution_refuses_to_build_without_an_os_gate(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    with pytest.raises(RuntimeError, match="LSMinimumSystemVersion"):
        bp.distribution_xml(r)


class PkgFakeRunner(FakeRunner):
    """FakeRunner that, like pkgbuild --analyze, leaves the component plist behind."""

    def __call__(self, argv):
        if argv[:2] == ["pkgbuild", "--analyze"]:
            Path(argv[-1]).write_bytes(plistlib.dumps([{"RootRelativeBundlePath": "x.app"}]))
        return super().__call__(argv)


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_pkg_is_one_component_carrying_only_the_configured_scripts(tmp_path, monkeypatch,
                                                                   flavor):
    run = PkgFakeRunner()
    r = release(tmp_path, run, flavor=flavor)
    r.minimum_system_version = "26.0"
    monkeypatch.setattr(bp, "write_provenance", lambda *a, **kw: None)
    bp.step_pkg(r)
    [component] = [c for c in run.find("pkgbuild") if "--analyze" not in c]
    assert "--nopayload" not in component
    assert component[component.index("--identifier") + 1] == r.cfg.bundle_id
    if r.cfg.pkg_scripts is None:
        assert "--scripts" not in component
    else:
        assert Path(component[component.index("--scripts") + 1]) == r.cfg.pkg_scripts
        assert r.cfg.pkg_scripts.is_dir()
    [product] = run.find("productbuild")
    assert product[product.index("--sign") + 1] == r.cfg.installer_identity
    assert product[-1] == str(r.pkg_path)
    assert (r.out / "pkg-work" / "Distribution.xml").exists()


def test_pkg_records_unnotarized_provenance(tmp_path):
    run = PkgFakeRunner()
    r = release(tmp_path, run)
    r.minimum_system_version = "26.0"
    r.source_sha = SOURCE_SHA
    r.out.mkdir(parents=True)
    r.zip_path.write_bytes(b"zip")

    class Writes(PkgFakeRunner):
        def __call__(self, argv):
            if argv[0] == "productbuild":
                r.pkg_path.write_bytes(b"pkg")
            return super().__call__(argv)

    r.run = Writes()
    bp.step_pkg(r)
    record = json.loads(r.provenance_path.read_text())
    assert record["notarized"] is False and record["source_sha"] == SOURCE_SHA
    assert record["version"] == VERSION and record["build"] == BUILD


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_notarize_pkg_rewrites_provenance_after_stapling(tmp_path, monkeypatch, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    with_artifacts(r, appcast=False)
    seen = {}

    def staple(path, **kw):
        seen.update(kw)
        path.write_bytes(path.read_bytes() + b"ticket")

    monkeypatch.setattr(mr, "notarize", staple)
    bp.step_notarize_pkg(r)
    record = json.loads(r.provenance_path.read_text())
    assert seen["profile"] == r.cfg.notary_profile
    assert record["notarized"] is True
    assert record["pkg_sha256"] == sha256_of(r.pkg_path)


# release_entry --------------------------------------------------------------------


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_release_entry_date_is_utc_iso_and_urls_follow_the_config(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    with_artifacts(r, appcast=False)
    when = datetime(2026, 10, 16, 12, 30, 5, tzinfo=timezone.utc)
    got = bp.release_entry(r, now=when)
    assert got.date == "2026-10-16T12:30:05Z"
    assert got.minimum_system_version == "26.0"
    assert got.notes == f"notes/{VERSION}.md"
    want = entry(r.cfg)
    assert got.pkg.url == want.pkg.url and got.zip.url == want.zip.url
    assert got.pkg.sha256 == sha256_of(r.pkg_path)
    assert got.zip.size == len(b"zip-bytes")


def test_release_entry_defaults_to_now(tmp_path):
    r = release(tmp_path, FakeRunner())
    with_artifacts(r, appcast=False)
    assert bp.release_entry(r).date.endswith("Z")


# the driver -------------------------------------------------------------------------


def test_build_steps_are_exactly_the_planned_steps_in_order():
    assert list(bp.build_steps()) == bp.BUILD_STEPS
    assert bp.BUILD_STEPS == ["preflight", "build", "check-bundle", "provision", "sign",
                              "notarize-app", "update-zip", "appcast", "sparkle-verify",
                              "pkg", "notarize-pkg"]
    assert all(callable(fn) for fn in bp.build_steps().values())


def _stub_every_step(monkeypatch, log, *, fail_at=None, exc=None):
    for name, attr in [("preflight", "step_preflight"), ("build", "step_build"),
                       ("check-bundle", "step_check_bundle"), ("provision", "step_provision"),
                       ("sign", "step_sign"), ("notarize-app", "step_notarize_app"),
                       ("update-zip", "step_update_zip"), ("appcast", "step_appcast"),
                       ("sparkle-verify", "step_sparkle_verify"), ("pkg", "step_pkg"),
                       ("notarize-pkg", "step_notarize_pkg")]:
        def stub(r, name=name):
            log.append(name)
            if name == fail_at:
                raise exc
        monkeypatch.setattr(bp, attr, stub)


@pytest.mark.parametrize("flavor", FLAVOR_NAMES)
def test_run_build_runs_every_step_in_order_and_summarizes(tmp_path, monkeypatch, capsys,
                                                          flavor):
    log: list[str] = []
    _stub_every_step(monkeypatch, log)
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    assert bp.run_build(r) == 0
    assert log == bp.BUILD_STEPS
    out = capsys.readouterr().out
    assert f"Release build {VERSION} complete" in out
    assert str(r.pkg_path) in out and str(r.zip_path) in out
    assert "nothing was published" in out


def test_run_build_stops_at_a_failed_step_and_prints_the_failure(tmp_path, monkeypatch, capsys):
    log: list[str] = []
    _stub_every_step(monkeypatch, log, fail_at="sign", exc=RuntimeError("no identity"))
    assert bp.run_build(release(tmp_path, FakeRunner())) == 1
    assert log == ["preflight", "build", "check-bundle", "provision", "sign"]
    captured = capsys.readouterr()
    assert "error: no identity" in captured.err
    assert "complete" not in captured.out


def test_run_build_reports_every_preflight_failure(tmp_path, monkeypatch, capsys):
    log: list[str] = []
    _stub_every_step(monkeypatch, log, fail_at="preflight",
                     exc=mr.PreflightError("first problem\nsecond problem"))
    assert bp.run_build(release(tmp_path, FakeRunner())) == 1
    assert log == ["preflight"]
    err = capsys.readouterr().err
    assert "preflight failed" in err and "first problem" in err and "second problem" in err


def test_run_build_end_to_end_through_the_real_check_steps(tmp_path, monkeypatch, capsys):
    """Real preflight, build hook and bundle check; only the Apple tools are faked."""
    seen: dict = {}
    r = _world(tmp_path, "stenographer")
    hook = _hook(seen, make=False)

    def run(argv):
        if argv[0] == "/usr/bin/env" and argv[1].startswith("RELEASE_APP_DEST"):
            hook(argv)
            make_app(r)
            return subprocess.CompletedProcess(argv, 0, "", "")
        return base(argv)

    base = r.run
    r.run = run
    for attr in ("step_provision", "step_sign", "step_notarize_app", "step_update_zip",
                 "step_appcast", "step_sparkle_verify", "step_pkg", "step_notarize_pkg"):
        monkeypatch.setattr(bp, attr, lambda r, attr=attr: seen.setdefault("later", []).append(attr))
    assert bp.run_build(r) == 0, capsys.readouterr().err
    assert seen["later"][0] == "step_provision" and seen["later"][-1] == "step_notarize_pkg"
    assert r.minimum_system_version == "26.0" and r.app.is_dir()
