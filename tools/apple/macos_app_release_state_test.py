#!/usr/bin/env python3
"""Tests for macos_app_release.state and .versions.

Run: python3 -m pytest tools/apple/macos_app_release_state_test.py -q
"""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from macos_app_release import state, versions as v
from macos_app_release_fixtures import (BUILD, SOURCE_SHA, VERSION, FakeRunner, config, release,
                                         with_artifacts)

FLAVORS = ["adkitchen", "stenographer"]

DEVID_AUTHORITY = (lambda a: a[:2] == ["codesign", "-d"], 0, "",
                   "Authority=Developer ID Application (K2NA732JAX)\n")


# versions -----------------------------------------------------------------------


def test_next_version():
    assert v.next_version("1.0.154", "patch") == "1.0.155"
    assert v.next_version("1.0.154", "minor") == "1.1.0"
    assert v.next_version("2.9", "minor") == "2.10.0"   # a 2-part version gets a .0 patch
    assert v.next_version("2.9", "patch") == "2.9.1"


def test_next_version_rejects_bad_input():
    with pytest.raises(ValueError):
        v.next_version("1.0.154", "major")
    with pytest.raises(ValueError, match="dotted integers"):
        v.next_version("1.0.x", "patch")


@pytest.mark.parametrize("flavor", FLAVORS)
def test_read_versions_and_key_from_project_yml(tmp_path, flavor):
    cfg = config(tmp_path, flavor=flavor, public_key="abc=")
    assert v.read_versions(cfg) == (VERSION, BUILD)
    assert v.project_setting(cfg.public_key_setting, cfg.project_yml.read_text()) == "abc="


def test_project_setting_strips_quotes_and_names_a_missing_setting():
    text = "a:\n  X: 'q'\n  Y: \"d\"\n  Z: bare\n"
    assert [v.project_setting(n, text) for n in "XYZ"] == ["q", "d", "bare"]
    with pytest.raises(ValueError, match="W not found"):
        v.project_setting("W", text)


def test_must_match_agrees_with_the_marketing_version(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    assert v.must_match_failures(cfg, VERSION) == []
    stale = v.must_match_failures(cfg, "1.0.155")
    assert len(stale) == 1 and "says 1.0.154" in stale[0] and "1.0.155" in stale[0]
    cfg.must_match[0].file.write_text('public static let daemonVersion = "2.154.0"\n')
    assert v.must_match_failures(cfg, VERSION)


def test_no_must_match_means_no_failures(tmp_path):
    assert v.must_match_failures(config(tmp_path), VERSION) == []


def test_must_match_pattern_matching_nothing_fails(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    cfg.must_match[0].file.write_text("nothing here")
    failures = v.must_match_failures(cfg, "1.0.154")
    assert failures and "matched nothing" in failures[0]


def test_must_match_missing_file_fails(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    cfg.must_match[0].file.unlink()
    assert "unreadable" in v.must_match_failures(cfg, VERSION)[0]


def test_bump_rewrites_yml_and_must_match_and_regenerates(tmp_path):
    cfg = config(tmp_path, flavor="stenographer",
                 overrides={"version": {"regenerate": ["xcodegen", "generate"]}})
    run = FakeRunner()
    assert v.bump(cfg, "minor", run=run) == ("1.1.0", 2)   # fixture starts at 1.0.154 / build 1
    assert v.read_versions(cfg) == ("1.1.0", 2)
    assert v.must_match_failures(cfg, "1.1.0") == []
    assert run.find("xcodegen", "generate")
    assert 'MARKETING_VERSION: "1.1.0"' in cfg.project_yml.read_text()   # quoting kept
    assert 'CURRENT_PROJECT_VERSION: "2"' in cfg.project_yml.read_text()


def test_bump_patch_without_regenerate_runs_nothing(tmp_path):
    cfg = config(tmp_path)
    run = FakeRunner()
    assert v.bump(cfg, "patch", run=run) == ("1.0.155", 2)
    assert run.calls == []


def test_bump_failing_regenerate_raises(tmp_path):
    cfg = config(tmp_path, overrides={"version": {"regenerate": ["xcodegen"]}})
    with pytest.raises(RuntimeError, match="version.regenerate failed"):
        v.bump(cfg, "patch", run=FakeRunner([(lambda a: True, 1, "", "boom")]))


def test_bump_refuses_unknown_kind(tmp_path):
    with pytest.raises(ValueError):
        v.bump(config(tmp_path), "major", run=FakeRunner())


def test_bump_writes_nothing_when_a_must_match_pattern_matches_nothing(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    cfg.must_match[0].file.write_text("nothing here")
    before = cfg.project_yml.read_text()
    with pytest.raises(ValueError, match="matched nothing"):
        v.bump(cfg, "patch", run=FakeRunner())
    assert cfg.project_yml.read_text() == before


# Release ------------------------------------------------------------------------


@pytest.mark.parametrize("flavor", FLAVORS)
def test_release_properties(tmp_path, flavor):
    r = release(tmp_path, FakeRunner(), flavor=flavor)
    name = r.cfg.app_name
    assert r.repo == r.cfg.repo == tmp_path / "repo"
    assert r.out == tmp_path / "repo/build/release" / VERSION
    assert r.app == r.out / "staging" / f"{name}.app"
    assert r.zip_path == r.out / f"{name}-{VERSION}.zip"
    assert r.pkg_path == r.out / f"{name}-{VERSION}.pkg"
    assert r.appcast_path == r.out / "appcast/appcast.xml"
    assert r.notes == tmp_path / "repo/docs/release-notes" / f"{VERSION}.md" and r.notes.exists()
    assert r.tag == f"v{VERSION}" and r.source_tag == f"release/{VERSION}"
    assert r.sparkle_bin == tmp_path / "dd" / state.SPARKLE_BIN_REL
    assert r.provenance_path == r.out / "provenance.json"
    assert r.origin == r.cfg.site_origin
    assert r.branch == "main"


def test_release_overrides_replace_the_config_defaults(tmp_path):
    r = release(tmp_path, FakeRunner(), site="https://staging.example.com",
                branch="release-preparation", artifacts_root=tmp_path / "art")
    assert r.origin == "https://staging.example.com"
    assert r.branch == "release-preparation"
    assert r.out == tmp_path / "art" / VERSION


def test_release_defaults_come_from_the_config(tmp_path):
    cfg = config(tmp_path)
    r = state.Release(cfg=cfg, version=VERSION, build_number=BUILD, run=FakeRunner())
    assert r.releases_repo == cfg.releases_checkout
    assert r.derived_data == cfg.derived_data
    assert r.branch == cfg.source_branch
    assert r.env == dict(__import__("os").environ)


def test_release_fixture_uses_a_custom_source_branch_and_tag_prefix(tmp_path):
    r = release(tmp_path, FakeRunner(), overrides={"source": {"branch": "trunk", "tag_prefix": "v-src/"}})
    assert r.branch == "trunk" and r.source_tag == f"v-src/{VERSION}"


# source tag -----------------------------------------------------------------------


def _tag_runner(tag=SOURCE_SHA):
    return FakeRunner([(lambda a: "--quiet" in a, 0 if tag else 1, f"{tag}\n" if tag else "")])


def test_head_sha_and_tag_sha(tmp_path):
    r = release(tmp_path, FakeRunner([
        (lambda a: a[-1] == "HEAD^{commit}", 0, "h" * 40 + "\n"),
        (lambda a: "--quiet" in a, 0, "t" * 40 + "\n")]))
    assert state.head_sha(r) == "h" * 40
    assert state.tag_sha(r) == "t" * 40
    assert r.run.find("git", "-C", str(r.repo), "rev-parse", "--verify", "--quiet",
                      f"refs/tags/release/{VERSION}^{{commit}}")


def test_head_sha_is_none_when_git_fails(tmp_path):
    r = release(tmp_path, FakeRunner([(lambda a: True, 128, "")]))
    assert state.head_sha(r) is None and state.tag_sha(r) is None


def test_source_tag_failures_accept_a_tag_on_head(tmp_path):
    r = release(tmp_path, _tag_runner())
    r.source_sha = SOURCE_SHA
    assert state.source_tag_failures(r) == []


def test_source_tag_failures_require_the_tag(tmp_path):
    r = release(tmp_path, _tag_runner(None))
    r.source_sha = SOURCE_SHA
    [msg] = state.source_tag_failures(r)
    assert f"no tag release/{VERSION}" in msg and state.PREPARE_CMD in msg


def test_source_tag_failures_refuse_a_head_that_moved(tmp_path):
    r = release(tmp_path, _tag_runner())
    r.source_sha = "d" * 40
    [msg] = state.source_tag_failures(r)
    assert "aaaaaaaaaaaa" in msg and "dddddddddddd" in msg
    assert f"main moved after {state.PREPARE_CMD}" in msg


def test_source_tag_failures_name_the_configured_branch(tmp_path):
    r = release(tmp_path, _tag_runner(), overrides={"source": {"branch": "trunk"}})
    r.source_sha = "d" * 40
    assert "trunk moved after" in state.source_tag_failures(r)[0]


# provenance -----------------------------------------------------------------------


def _write_real_provenance(r, **overrides):
    """What a finished real run's notarize-pkg leaves beside the artifacts."""
    record = {"version": r.version, "build": r.build_number, "source_sha": SOURCE_SHA,
              "notarized": True, "pkg_sha256": state.sha256_of(r.pkg_path),
              "zip_sha256": state.sha256_of(r.zip_path), **overrides}
    r.provenance_path.write_text(json.dumps(record))


def _artifact_release(tmp_path, *responses, flavor="adkitchen"):
    r = release(tmp_path, FakeRunner([*responses, DEVID_AUTHORITY]), flavor=flavor)
    with_artifacts(r, appcast=False)
    r.source_sha = SOURCE_SHA
    return r


@pytest.mark.parametrize("flavor", FLAVORS)
def test_artifact_failures_accepts_a_finished_real_runs_artifacts(tmp_path, flavor):
    r = _artifact_release(tmp_path, flavor=flavor)
    _write_real_provenance(r)
    assert state.artifact_failures(r) == []
    assert r.run.find("xcrun", "stapler", "validate")
    assert r.run.find("spctl", "--assess")
    assert r.run.find("codesign", "--verify", "--deep", "--strict", str(r.app))


def test_artifact_failures_requires_a_provenance_record(tmp_path):
    r = _artifact_release(tmp_path)
    assert "is missing" in state.artifact_failures(r)[0]


def test_artifact_failures_refuses_an_unreadable_record(tmp_path):
    r = _artifact_release(tmp_path)
    r.provenance_path.write_text("{")
    assert "is unreadable" in state.artifact_failures(r)[0]


def test_artifact_failures_refuses_an_unnotarized_pkg(tmp_path):
    r = _artifact_release(tmp_path)
    _write_real_provenance(r, notarized=False)
    assert "never notarized" in state.artifact_failures(r)[0]


def test_artifact_failures_refuses_artifacts_changed_since_the_run(tmp_path):
    r = _artifact_release(tmp_path)
    _write_real_provenance(r)
    r.pkg_path.write_bytes(b"tampered")
    assert any("changed after the run" in f for f in state.artifact_failures(r))


def test_artifact_failures_refuses_artifacts_built_from_another_commit(tmp_path):
    r = _artifact_release(tmp_path)
    _write_real_provenance(r, source_sha="c" * 40)
    assert any("built from cccccccccccc, not HEAD aaaaaaaaaaaa" in f
               for f in state.artifact_failures(r))


def test_artifact_failures_refuses_another_builds_artifacts(tmp_path):
    r = _artifact_release(tmp_path)
    _write_real_provenance(r, build=410)
    assert any(f"not {VERSION} ({BUILD})" in f for f in state.artifact_failures(r))


def test_artifact_failures_refuses_a_failed_gatekeeper_check(tmp_path):
    r = _artifact_release(tmp_path, (lambda a: a[:2] == ["spctl", "--assess"], 3, "", "rejected"))
    _write_real_provenance(r)
    assert any("Gatekeeper" in f and "rejected" in f for f in state.artifact_failures(r))


def test_artifact_failures_refuses_a_non_developer_id_signature(tmp_path):
    r = release(tmp_path, FakeRunner([(lambda a: a[:2] == ["codesign", "-d"], 0, "",
                                       "Authority=Apple Development: Someone\n")]))
    with_artifacts(r, appcast=False)
    r.source_sha = SOURCE_SHA
    _write_real_provenance(r)
    assert any("is not signed 'Developer ID Application'" in f for f in state.artifact_failures(r))


def test_artifact_failures_checks_the_configured_identity(tmp_path):
    r = release(tmp_path, FakeRunner([DEVID_AUTHORITY]),
                overrides={"signing": {"app_identity": "Developer ID Application: Acme"}})
    with_artifacts(r, appcast=False)
    r.source_sha = SOURCE_SHA
    _write_real_provenance(r)
    assert any("Developer ID Application: Acme" in f for f in state.artifact_failures(r))


def test_write_provenance_records_the_artifacts_digests(tmp_path):
    r = _artifact_release(tmp_path)
    state.write_provenance(r, notarized=True)
    record = json.loads(r.provenance_path.read_text())
    assert record == {"version": VERSION, "build": BUILD, "source_sha": SOURCE_SHA,
                      "notarized": True,
                      "pkg_sha256": state.sha256_of(r.pkg_path),
                      "zip_sha256": state.sha256_of(r.zip_path)}


def test_sha256_of_matches_hashlib(tmp_path):
    import hashlib
    f = tmp_path / "f"
    f.write_bytes(b"abc")
    assert state.sha256_of(f) == hashlib.sha256(b"abc").hexdigest()


# git_count ------------------------------------------------------------------------


def test_git_count_reads_rev_list_from_the_releases_repo(tmp_path):
    r = release(tmp_path, FakeRunner([(lambda a: "rev-list" in a, 0, "3\n")]))
    assert state.git_count(r, "origin/main..HEAD") == 3
    assert r.run.find("git", "-C", str(r.releases_repo), "rev-list", "--count", "origin/main..HEAD")


def test_git_count_defaults_to_zero_on_junk(tmp_path):
    r = release(tmp_path, FakeRunner([(lambda a: "rev-list" in a, 0, "oops\n")]))
    assert state.git_count(r, "x") == 0
