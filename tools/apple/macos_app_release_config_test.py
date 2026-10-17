#!/usr/bin/env python3
"""Tests for macos_app_release.config.

Run: python3 -m pytest tools/apple/macos_app_release_config_test.py -q
"""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from macos_app_release import config as c
from macos_app_release_fixtures import ADKITCHEN, STENOGRAPHER, config, write_config


def test_minimal_config_resolves_every_default(tmp_path):
    cfg = config(tmp_path)
    repo = tmp_path / "repo"
    assert cfg.title == ADKITCHEN["app"]["title"] == "Agentic Developer Kitchen"
    assert cfg.marketing_setting == "MARKETING_VERSION"
    assert cfg.build_setting == "CURRENT_PROJECT_VERSION"
    assert cfg.app_identity == "Developer ID Application"
    assert cfg.installer_identity == "Developer ID Installer"
    assert cfg.source_branch == "main" and cfg.source_tag_prefix == "release/"
    assert cfg.releases_branch == "main"
    assert cfg.releases_checkout == repo.parent / "adkitchen-releases"
    assert cfg.derived_data == tmp_path / "home/Library/Developer/Xcode/DerivedData/adkitchen-release"
    assert cfg.site_routes == {"downloads": "/downloads", "latest": "/downloads/latest",
                               "appcast": "/appcast.xml"}
    assert cfg.notes_path("1.2.0") == repo / "docs/release-notes/1.2.0.md"
    assert cfg.pkg_must_close == (cfg.bundle_id,)
    assert cfg.apps_dir == Path("/Applications")
    assert cfg.toolkit == repo / "external/agenticdevelopertoolkit"
    assert cfg.site_origin == "https://kitchen.agenticdevelopmentstudio.com"
    assert cfg.download_prefix == "https://github.com/agenticdevelopmentstudio/adkitchen-releases/releases/download"
    assert cfg.cask_file == "Casks/adkitchen.rb"
    assert cfg.source_tag("1.2.0") == "release/1.2.0"
    assert cfg.hook_health is None and cfg.regenerate is None
    assert cfg.must_match == () and cfg.nested_bundles == () and cfg.profiles == ()
    assert cfg.layout_required == () and cfg.checks == () and cfg.expect_info == {}
    assert cfg.pkg_scripts is None
    assert cfg.resolve_kind == "workspace" and cfg.resolve_path == repo / "AgenticDeveloperKitchen.xcworkspace"
    assert cfg.entitlements == {".": repo / "App/Sources/Resources/App.entitlements"}


def test_stenographer_shape_loads(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    repo = tmp_path / "repo"
    assert len(cfg.profiles) == 2 and cfg.profiles[0].required and not cfg.profiles[1].required
    assert cfg.must_match[0].file.is_absolute()
    assert cfg.must_match[0].file.name == "StenographerRouter.swift"
    assert cfg.layout_required_globs == ("Contents/PlugIns/*.aiplugin",)
    assert cfg.expect_info == {"AgenticReleaseChannel": "release"}
    assert cfg.pkg_must_close[0] == cfg.bundle_id and len(cfg.pkg_must_close) == 2
    assert cfg.pkg_scripts == repo / "Apple/Stenographer/installer/scripts"
    assert cfg.hook_health is not None
    assert cfg.nested_bundles == ("Contents/PlugIns/StenographerUsageWidget.appex",)
    assert cfg.regenerate is not None and cfg.checks[0].name == "daemon-executable"
    assert cfg.releases_checkout == tmp_path / "home/stenographer-releases"
    assert cfg.apps_dir == tmp_path / "home/Applications"
    assert len(cfg.entitlements) == 5 and "." in cfg.entitlements


def test_stenographer_flavor_sets_every_optional_key():
    """The flavor must keep covering every optional key the schema knows."""
    optional = {name: {k for k, (req, _) in spec.items() if not req}
                for name, spec in c._SECTIONS.items()}
    for section, keys in optional.items():
        assert keys <= set(STENOGRAPHER[section]), (section, keys - set(STENOGRAPHER[section]))
    assert {k for k, (req, _) in c._TOP.items() if not req} <= set(STENOGRAPHER)


def test_every_problem_is_reported_at_once(tmp_path):
    write_config(tmp_path / "repo", {"app": {"nmae": "x"}, "cask": {"token": None}})
    with pytest.raises(c.ConfigError) as e:
        c.load_config(tmp_path / "repo", home=tmp_path / "home", env={})
    text = str(e.value)
    assert "app.nmae" in text and "unknown" in text
    assert "cask.token" in text
    assert len(e.value.problems) >= 2
    assert text == "\n".join(e.value.problems)


def test_unknown_top_level_and_nested_keys_are_named(tmp_path):
    write_config(tmp_path / "repo", {
        "bogus": 1, "signing": {"profiles": [{"bundle": ".", "env": "E", "bundle_id": "b",
                                             "required": True, "extra": 1}]}})
    with pytest.raises(c.ConfigError) as e:
        c.load_config(tmp_path / "repo", home=tmp_path / "home", env={})
    assert "bogus: unknown key" in e.value.problems
    assert "signing.profiles[0].extra: unknown key" in e.value.problems


@pytest.mark.parametrize("key", ["app.name", "app.bundle_id", "version.project_yml",
    "build.command", "build.resolve", "signing.notary_profile", "signing.entitlements",
    "sparkle.account", "sparkle.feed_url", "sparkle.public_key_setting",
    "releases.github_repo", "cask.token", "cask.template", "hooks.tests",
    "hooks.warnings_build", "warnings_allowlist", "schema"])
def test_required_key_missing_is_an_error(tmp_path, key):
    data = json.loads(write_config(tmp_path / "repo").read_text())
    section, _, leaf = key.partition(".")
    if leaf:
        del data[section][leaf]
    else:
        del data[section]
    with pytest.raises(c.ConfigError, match=key.replace(".", r"\.")):
        c.parse_config(data, repo=tmp_path / "repo", main_checkout=tmp_path / "repo",
                       env={}, home=tmp_path / "home")


def test_required_key_set_to_null_is_an_error(tmp_path):
    data = json.loads(write_config(tmp_path / "repo").read_text())
    data["hooks"]["tests"] = None
    with pytest.raises(c.ConfigError, match=r"hooks\.tests: required"):
        c.parse_config(data, repo=tmp_path / "repo", main_checkout=tmp_path / "repo",
                       env={}, home=tmp_path / "home")


def test_entitlements_must_name_the_app(tmp_path):
    write_config(tmp_path / "repo", {"signing": {"entitlements": {"Contents/MacOS/x": "a.entitlements"}}},
                 replace=("signing", "entitlements"))
    with pytest.raises(c.ConfigError, match=r'signing\.entitlements.*"\."'):
        c.load_config(tmp_path / "repo", home=tmp_path / "home", env={})


@pytest.mark.parametrize("pattern", ["no groups", "(a)(b)", "([unclosed"])
def test_must_match_needs_exactly_one_group(tmp_path, pattern):
    write_config(tmp_path / "repo", {"version": {"must_match": [{"file": "x.swift", "pattern": pattern}]}})
    with pytest.raises(c.ConfigError, match="must_match"):
        c.load_config(tmp_path / "repo", home=tmp_path / "home", env={})


def test_must_match_entry_needs_file_and_pattern(tmp_path):
    write_config(tmp_path / "repo", {"version": {"must_match": [{"file": "x.swift"}]}})
    with pytest.raises(c.ConfigError, match=r"must_match\[0\]\.pattern: required"):
        c.load_config(tmp_path / "repo", home=tmp_path / "home", env={})


def test_paths_resolve_against_repo_home_or_absolute(tmp_path):
    cfg = config(tmp_path, {"releases": {"checkout": "~/rel"}, "build": {"derived_data": "/abs/dd"},
                            "notes_dir": "notes"})
    assert cfg.releases_checkout == tmp_path / "home/rel"
    assert cfg.derived_data == Path("/abs/dd")
    assert cfg.notes_dir == tmp_path / "repo/notes"


def test_relative_paths_never_resolve_against_the_cwd(tmp_path, monkeypatch):
    elsewhere = tmp_path / "elsewhere"
    elsewhere.mkdir()
    monkeypatch.chdir(elsewhere)
    cfg = config(tmp_path, {"releases": {"checkout": "rel/co"}})
    assert cfg.releases_checkout == tmp_path / "repo/rel/co"
    assert cfg.project_yml == tmp_path / "repo/App/project.yml"


def test_env_overrides_the_releases_checkout(tmp_path):
    write_config(tmp_path / "repo")
    cfg = c.load_config(tmp_path / "repo", home=tmp_path / "home",
                        env={"RELEASE_RELEASES_CHECKOUT": str(tmp_path / "elsewhere")})
    assert cfg.releases_checkout == tmp_path / "elsewhere"


def test_env_checkout_is_resolved_like_any_path(tmp_path):
    write_config(tmp_path / "repo")
    cfg = c.load_config(tmp_path / "repo", home=tmp_path / "home",
                        env={"RELEASE_RELEASES_CHECKOUT": "~/from-env"})
    assert cfg.releases_checkout == tmp_path / "home/from-env"


def test_a_configured_checkout_beats_the_env_default(tmp_path):
    write_config(tmp_path / "repo", {"releases": {"checkout": "~/rel"}})
    cfg = c.load_config(tmp_path / "repo", home=tmp_path / "home",
                        env={"RELEASE_RELEASES_CHECKOUT": str(tmp_path / "elsewhere")})
    assert cfg.releases_checkout == tmp_path / "home/rel"


def test_releases_checkout_default_is_beside_the_main_checkout(tmp_path):
    write_config(tmp_path / "wt")
    cfg = c.load_config(tmp_path / "wt", main_checkout=tmp_path / "main", home=tmp_path / "home", env={})
    assert cfg.releases_checkout == tmp_path / "adkitchen-releases"
    assert cfg.repo == tmp_path / "wt" and cfg.main_checkout == tmp_path / "main"


def test_missing_file_and_bad_json(tmp_path):
    (tmp_path / "repo").mkdir()
    with pytest.raises(c.ConfigError, match="release.json"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path)
    (tmp_path / "repo/release.json").write_text("{")
    with pytest.raises(c.ConfigError, match="JSON"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path)


def test_top_level_must_be_an_object(tmp_path):
    (tmp_path / "repo").mkdir()
    (tmp_path / "repo/release.json").write_text("[]")
    with pytest.raises(c.ConfigError, match="object"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path)


def test_schema_must_be_1(tmp_path):
    write_config(tmp_path / "repo", {"schema": 2})
    with pytest.raises(c.ConfigError, match="schema"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path / "home")


def test_resolve_needs_exactly_one_of_workspace_or_project(tmp_path):
    write_config(tmp_path / "repo", {"build": {"resolve": {"scheme": "S"}}}, replace=("build", "resolve"))
    with pytest.raises(c.ConfigError, match=r"build\.resolve"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path / "home")
    write_config(tmp_path / "repo", {"build": {"resolve": {"workspace": "a", "project": "b", "scheme": "S"}}},
                 replace=("build", "resolve"))
    with pytest.raises(c.ConfigError, match=r"build\.resolve"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path / "home")


def test_resolve_accepts_a_project(tmp_path):
    cfg = config(tmp_path, {"build": {"resolve": {"project": "A.xcodeproj", "scheme": "S"}}},
                 replace=("build", "resolve"))
    assert cfg.resolve_kind == "project" and cfg.resolve_path == tmp_path / "repo/A.xcodeproj"
    assert cfg.resolve_scheme == "S"


def test_feed_url_must_be_https(tmp_path):
    write_config(tmp_path / "repo", {"sparkle": {"feed_url": "kitchen/appcast.xml"}})
    with pytest.raises(c.ConfigError, match="feed_url"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path / "home")
    write_config(tmp_path / "repo", {"sparkle": {"feed_url": "http://kitchen.example/appcast.xml"}})
    with pytest.raises(c.ConfigError, match="feed_url"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path / "home")


def test_argv_values_must_be_non_empty_string_lists(tmp_path):
    write_config(tmp_path / "repo", {"build": {"command": []}, "hooks": {"tests": "pytest"}})
    with pytest.raises(c.ConfigError) as e:
        c.load_config(tmp_path / "repo", env={}, home=tmp_path / "home")
    assert any(p.startswith("build.command") for p in e.value.problems)
    assert any(p.startswith("hooks.tests") for p in e.value.problems)


def test_site_routes_need_exactly_the_three_keys(tmp_path):
    write_config(tmp_path / "repo", {"site": {"routes": {"downloads": "/dl"}}}, replace=("site", "routes"))
    with pytest.raises(c.ConfigError, match=r"site\.routes"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path / "home")
    cfg = config(tmp_path, {"site": {"routes": {"downloads": "/dl", "latest": "/dl/latest",
                                                  "appcast": "/feed.xml"}}}, replace=("site", "routes"))
    assert cfg.site_routes["downloads"] == "/dl"


def test_pkg_must_close_is_deduplicated_with_the_bundle_id_first(tmp_path):
    bundle = ADKITCHEN["app"]["bundle_id"]
    cfg = config(tmp_path, {"pkg": {"must_close": ["x.y", bundle, "x.y"]}})
    assert cfg.pkg_must_close == (bundle, "x.y")


def test_config_is_frozen(tmp_path):
    cfg = config(tmp_path)
    with pytest.raises(Exception):
        cfg.app_name = "x"  # type: ignore[misc]


# asset_basename and env_file -----------------------------------------------------------


def test_asset_basename_hyphenates_a_spaced_app_name(tmp_path):
    cfg = config(tmp_path, {"app": {"name": "Agentic Developer Kitchen"}})
    assert cfg.asset_basename == "Agentic-Developer-Kitchen"


def test_asset_basename_of_an_unspaced_name_is_the_name(tmp_path):
    cfg = config(tmp_path)
    assert cfg.asset_basename == cfg.app_name


def test_env_file_is_optional_and_resolves_like_any_path(tmp_path):
    assert config(tmp_path).env_file is None
    cfg = config(tmp_path / "set", {"env_file": "~/.local-env/app.env"})
    assert cfg.env_file is not None and cfg.env_file.name == "app.env"
    assert "~" not in str(cfg.env_file)


def test_read_env_file_parses_export_quotes_and_comments(tmp_path):
    from macos_app_release.config import read_env_file
    env = tmp_path / "app.env"
    env.write_text("# a comment\n\nexport A=1\nB=\"two words\"\nC='3'\nnot a pair\n")
    assert read_env_file(env) == {"A": "1", "B": "two words", "C": "3"}


def test_read_env_file_of_a_missing_file_is_empty(tmp_path):
    from macos_app_release.config import read_env_file
    assert read_env_file(tmp_path / "absent.env") == {}
