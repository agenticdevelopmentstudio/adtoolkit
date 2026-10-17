"""Profiles, Sparkle, site, cask and layout: the Task 3 modules of macos_app_release."""
from __future__ import annotations

import plistlib
import re
import shutil
import subprocess
from pathlib import Path

import pytest

from macos_app_release import cask, layout, profiles, site, sparkle
from macos_app_release_fixtures import (VERSION, ZIP_SIGNATURE, FakeRunner, config, entry,
                                        new_appcast, release, with_artifacts)

TEAM = "ABCDE12345"
FEED = "https://kitchen.agenticdevelopmentstudio.com/appcast.xml"
STENO_FEED = "https://agenticstenographer.app/appcast.xml"
WIDGET = "Contents/PlugIns/StenographerUsageWidget.appex"
SPARKLE_B = "Contents/Frameworks/Sparkle.framework/Versions/B"


# identity_team ---------------------------------------------------------------------


def test_identity_team():
    out = ('  1) D9CB "Apple Development: Michael Fullerton (585UCD342S)"\n'
           f'  2) ABCD "Developer ID Application: Michael Fullerton ({TEAM})"\n'
           "     2 valid identities found\n")
    assert profiles.identity_team(out, "Developer ID Application") == TEAM
    assert profiles.identity_team(out, "Developer ID Installer") is None


# provisioning profiles ---------------------------------------------------------------


def _profile_plist(*, all_devices=True, team=TEAM, bundle_id=None) -> str:
    bundle_id = bundle_id or "com.agenticdevelopmentstudio.stenographer"
    return plistlib.dumps({
        "ProvisionsAllDevices": all_devices,
        "TeamIdentifier": [team],
        "Entitlements": {"com.apple.application-identifier": f"{team}.{bundle_id}"},
    }).decode()


def _cms(stdout, rc=0, stderr=""):
    return (lambda a: a[:3] == ["security", "cms", "-D"], rc, stdout, stderr)


def _steno(tmp_path, run, **kw):
    return release(tmp_path, run, flavor="stenographer", **kw)


def _staged_app(r, *, widget_profile=False):
    (r.app / "Contents/MacOS").mkdir(parents=True)
    (r.app / "Contents/MacOS/stenographerd").write_text("")
    (r.app / "Contents/embedded.provisionprofile").write_bytes(b"development")
    widget = r.app / WIDGET / "Contents"
    widget.mkdir(parents=True)
    if widget_profile:
        (widget / "embedded.provisionprofile").write_bytes(b"development")
    (r.app / "Contents/Helpers").mkdir(parents=True)
    (r.app / "Contents/Helpers/steno").write_text("")
    sparkle_dir = r.app / SPARKLE_B
    (sparkle_dir / "XPCServices/Installer.xpc").mkdir(parents=True)
    (sparkle_dir / "Updater.app").mkdir(parents=True)
    (sparkle_dir / "Autoupdate").write_text("")
    return r.app


def test_profile_problems_accepts_a_developer_id_profile(tmp_path):
    r = _steno(tmp_path, FakeRunner([_cms(_profile_plist())]))
    assert profiles.profile_problems(r, Path("p"), r.cfg.bundle_id, TEAM) == []


@pytest.mark.parametrize("profile, problem", [
    (_profile_plist(all_devices=False), "ProvisionsAllDevices"),
    (_profile_plist(team="OTHERTEAM1"), "TeamIdentifier"),
    (_profile_plist(bundle_id="com.example.other"), "application-identifier"),
    ("not a plist", "provisioning-profile plist"),
])
def test_profile_problems_names_what_is_wrong(tmp_path, profile, problem):
    r = _steno(tmp_path, FakeRunner([_cms(profile)]))
    found = profiles.profile_problems(r, Path("p"), r.cfg.bundle_id, TEAM)
    assert any(problem in p for p in found)


def test_profile_problems_reports_an_undecodable_profile(tmp_path):
    r = _steno(tmp_path, FakeRunner([_cms("", rc=1, stderr="bad cms")]))
    [problem] = profiles.profile_problems(r, Path("p"), r.cfg.bundle_id, None)
    assert "cannot decode" in problem and "bad cms" in problem


def test_profile_failures_names_the_env_var_when_a_required_profile_is_unset(tmp_path):
    r = _steno(tmp_path, FakeRunner())
    [failure] = profiles.profile_failures(r)
    assert "STENOGRAPHER_DEVID_PROFILE_APP is not set" in failure
    assert "STENOGRAPHER_DEVID_PROFILE_WIDGET" not in failure   # optional
    assert r.profiles == {}


def test_profile_failures_rejects_a_missing_file_and_an_invalid_profile(tmp_path):
    bad = tmp_path / "dev.provisionprofile"
    bad.write_bytes(b"x")
    run = FakeRunner([_cms(_profile_plist(all_devices=False))])
    r = _steno(tmp_path, run, env={
        "STENOGRAPHER_DEVID_PROFILE_APP": str(bad),
        "STENOGRAPHER_DEVID_PROFILE_WIDGET": str(tmp_path / "nope")})
    r.team = TEAM
    failures = profiles.profile_failures(r)
    assert any("is not usable" in f and "ProvisionsAllDevices" in f for f in failures)
    assert any("does not exist" in f for f in failures)
    assert r.profiles == {}


def test_profile_failures_accepts_a_valid_profile_and_records_it(tmp_path):
    good = tmp_path / "devid.provisionprofile"
    good.write_bytes(b"x")
    r = _steno(tmp_path, FakeRunner([_cms(_profile_plist())]),
               env={"STENOGRAPHER_DEVID_PROFILE_APP": str(good)})
    r.team = TEAM
    assert profiles.profile_failures(r) == []
    assert r.profiles == {".": good}


def test_a_config_with_no_profiles_has_no_profile_failures(tmp_path):
    assert profiles.profile_failures(release(tmp_path, FakeRunner())) == []


def test_provision_swaps_the_profile_before_sign(tmp_path):
    run = FakeRunner([_cms(_profile_plist())])
    r = _steno(tmp_path, run)
    _staged_app(r)
    devid = tmp_path / "devid.provisionprofile"
    devid.write_bytes(b"developer-id")
    r.profiles = {".": devid}
    r.team = TEAM
    profiles.step_provision(r)
    assert (r.app / "Contents/embedded.provisionprofile").read_bytes() == b"developer-id"
    staged = str(r.app / "Contents/embedded.provisionprofile")
    assert run.find("security", "cms", "-D", "-i", staged)


def test_provision_refuses_a_profile_nothing_replaces(tmp_path):
    r = _steno(tmp_path, FakeRunner([_cms(_profile_plist())]))
    _staged_app(r, widget_profile=True)
    devid = tmp_path / "devid.provisionprofile"
    devid.write_bytes(b"developer-id")
    r.profiles = {".": devid}
    with pytest.raises(RuntimeError, match="STENOGRAPHER_DEVID_PROFILE_WIDGET"):
        profiles.step_provision(r)


def test_provision_refuses_an_embedded_profile_with_no_config_entry(tmp_path):
    r = release(tmp_path, FakeRunner())          # adkitchen: no profiles configured
    (r.app / "Contents").mkdir(parents=True)
    (r.app / "Contents/embedded.provisionprofile").write_bytes(b"development")
    with pytest.raises(RuntimeError, match="signing.profiles"):
        profiles.step_provision(r)


def test_check_developer_id_profile_passes_on_a_developer_id_profile(tmp_path):
    r = _steno(tmp_path, FakeRunner([_cms(_profile_plist())]))
    _staged_app(r)
    r.team = TEAM
    profiles.check_developer_id_profile(r)


def test_check_developer_id_profile_fails_on_the_development_profile(tmp_path):
    r = _steno(tmp_path, FakeRunner([_cms(_profile_plist(all_devices=False))]))
    _staged_app(r)
    r.team = TEAM
    with pytest.raises(RuntimeError, match="ProvisionsAllDevices"):
        profiles.check_developer_id_profile(r)


def test_check_developer_id_profile_fails_when_missing(tmp_path):
    r = _steno(tmp_path, FakeRunner())
    r.app.mkdir(parents=True)
    with pytest.raises(RuntimeError, match="STENOGRAPHER_DEVID_PROFILE_APP"):
        profiles.check_developer_id_profile(r)


def test_check_developer_id_profile_needs_a_config_entry(tmp_path):
    r = release(tmp_path, FakeRunner())
    with pytest.raises(RuntimeError, match="signing.profiles has no entry"):
        profiles.check_developer_id_profile(r)


# entitlements_map ---------------------------------------------------------------------


def _bundle_items(app: Path, cfg) -> None:
    for rel in cfg.entitlements:
        if rel != ".":
            (app / rel).mkdir(parents=True, exist_ok=True)


def test_entitlements_map_covers_every_configured_item(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    app = tmp_path / "Stenographer.app"
    _bundle_items(app, cfg)
    mapping = profiles.entitlements_map(app, cfg)
    assert mapping[app] == cfg.entitlements["."]
    assert mapping[app / WIDGET] == cfg.entitlements[WIDGET]
    assert mapping[app / "Contents/Helpers/steno"] == cfg.entitlements["Contents/Helpers/steno"]
    assert set(mapping) == {profiles.bundle_at(app, rel) for rel in cfg.entitlements}
    assert all(p.exists() for p in mapping.values())


def test_entitlements_map_for_the_minimal_config_is_just_the_app(tmp_path):
    cfg = config(tmp_path)
    app = tmp_path / "App.app"
    app.mkdir()
    assert profiles.entitlements_map(app, cfg) == {app: cfg.entitlements["."]}


def test_entitlements_map_fails_when_the_layout_changes(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    app = tmp_path / "Stenographer.app"
    (app / "Contents").mkdir(parents=True)
    with pytest.raises(RuntimeError, match=r"update signing\.entitlements"):
        profiles.entitlements_map(app, cfg)


# Sparkle: Info.plist -------------------------------------------------------------------


def test_sparkle_config_requires_verify_before_extraction_with_a_signed_feed():
    broken = {"SUPublicEDKey": "abc=", "SURequireSignedFeed": True}
    assert any("SUVerifyUpdateBeforeExtraction" in p for p in sparkle.sparkle_config_problems(broken))
    assert sparkle.sparkle_config_problems({**broken, "SUVerifyUpdateBeforeExtraction": True}) == []
    assert any("SUPublicEDKey" in p for p in sparkle.sparkle_config_problems({}))


def _good_info(cfg, **over):
    info = {"CFBundleShortVersionString": VERSION, "CFBundleVersion": "1",
            "SUFeedURL": cfg.feed_url, "SUPublicEDKey": "k", "LSMinimumSystemVersion": "15.0",
            **{k: v for k, v in cfg.expect_info.items()}}
    info.update(over)
    return info


@pytest.mark.parametrize("flavor", ["adkitchen", "stenographer"])
def test_bundle_info_problems_accepts_a_matching_bundle(tmp_path, flavor):
    cfg = config(tmp_path, flavor=flavor)
    assert sparkle.bundle_info_problems(_good_info(cfg), cfg, version=VERSION, build=1) == []


def test_bundle_info_problems_names_each(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    info = {"CFBundleShortVersionString": VERSION, "CFBundleVersion": "1",
            "SUFeedURL": "https://wrong/appcast.xml", "SUPublicEDKey": "k",
            "LSMinimumSystemVersion": "15.0"}
    problems = sparkle.bundle_info_problems(info, cfg, version=VERSION, build=1)
    assert any("SUFeedURL" in p for p in problems)
    assert any("AgenticReleaseChannel" in p for p in problems)


def test_bundle_info_problems_checks_version_build_minimum_and_sparkle(tmp_path):
    cfg = config(tmp_path)
    info = _good_info(cfg, CFBundleShortVersionString="0.9", CFBundleVersion="7",
                      SUPublicEDKey="", LSMinimumSystemVersion="")
    text = "\n".join(sparkle.bundle_info_problems(info, cfg, version=VERSION, build=1))
    assert "built app is 0.9, expected 1.0.154" in text
    assert "build is 7, expected 1" in text
    assert "LSMinimumSystemVersion" in text
    assert "Sparkle configuration is broken" in text and "SUPublicEDKey" in text


def test_bundle_info_problems_refuses_an_app_sparkle_would_refuse(tmp_path):
    cfg = config(tmp_path)
    info = _good_info(cfg, SURequireSignedFeed=True)
    [problem] = sparkle.bundle_info_problems(info, cfg, version=VERSION, build=1)
    assert "SUVerifyUpdateBeforeExtraction" in problem


# Sparkle: keys, tools -----------------------------------------------------------------


def test_sparkle_public_key_reads_the_configured_setting(tmp_path):
    r = release(tmp_path, FakeRunner(), public_key="abc=")
    assert sparkle.sparkle_public_key(r.cfg) == "abc="


def test_public_key_failure_names_the_setting_and_the_account(tmp_path):
    r = release(tmp_path, FakeRunner())
    text = sparkle.public_key_failure(r)
    assert "ADKITCHEN_SPARKLE_PUBLIC_KEY is empty" in text
    assert f"{r.sparkle_bin / 'generate_keys'} --account adkitchen" in text
    assert "~/.sparkle/adkitchen-ed25519.key" in text


@pytest.mark.parametrize("flavor, kind", [("adkitchen", "workspace")])
def test_ensure_sparkle_tools_resolves_packages_into_derived_data(tmp_path, flavor, kind):
    run = FakeRunner()
    r = release(tmp_path, run, flavor=flavor)
    (r.sparkle_bin / "generate_keys").unlink()
    with pytest.raises(RuntimeError, match="after resolving packages"):
        sparkle.ensure_sparkle_tools(r)
    [call] = run.find("xcodebuild")
    assert call == ["xcodebuild", "-resolvePackageDependencies", f"-{kind}",
                    str(r.cfg.resolve_path), "-scheme", r.cfg.resolve_scheme,
                    "-derivedDataPath", str(r.derived_data), "-skipPackagePluginValidation"]


def test_ensure_sparkle_tools_is_a_no_op_when_the_tools_exist(tmp_path):
    run = FakeRunner()
    sparkle.ensure_sparkle_tools(release(tmp_path, run))
    assert run.calls == []


def test_ensure_sparkle_tools_surfaces_a_failed_resolve(tmp_path):
    run = FakeRunner([(lambda a: a[0] == "xcodebuild", 65, "", "no scheme")])
    r = release(tmp_path, run)
    (r.sparkle_bin / "generate_keys").unlink()
    with pytest.raises(RuntimeError, match=r"(?s)resolvePackageDependencies failed.*no scheme"):
        sparkle.ensure_sparkle_tools(r)


def test_ensure_sparkle_tools_uses_a_project_when_configured(tmp_path):
    run = FakeRunner()
    r = release(tmp_path, run, overrides={
        "build": {"resolve": {"workspace": None, "project": "App.xcodeproj"}}})
    (r.sparkle_bin / "generate_keys").unlink()
    with pytest.raises(RuntimeError):
        sparkle.ensure_sparkle_tools(r)
    assert run.find("xcodebuild")[0][2] == "-project"


# Sparkle: signatures -------------------------------------------------------------------


def _verifiable(tmp_path, *, shipped_key="abc=", keychain_key="abc=", appcast=None,
                responses=()):
    run = FakeRunner([*responses, (lambda a: a[-1] == "-p", 0, keychain_key + "\n")])
    r = with_artifacts(release(tmp_path, run), appcast=False)
    r.appcast_path.parent.mkdir(parents=True, exist_ok=True)
    r.appcast_path.write_text(appcast if appcast is not None else new_appcast(r))
    (r.app / "Contents").mkdir(parents=True)
    (r.app / "Contents/Info.plist").write_bytes(plistlib.dumps({"SUPublicEDKey": shipped_key}))
    return r, run


def test_sparkle_verify_checks_the_zip_and_the_feed_signatures(tmp_path):
    r, run = _verifiable(tmp_path)
    sparkle.step_sparkle_verify(r)
    verifies = [c for c in run.calls if c[0].endswith("sign_update")]
    assert verifies == [
        [str(r.sparkle_bin / "sign_update"), "--account", "adkitchen", "--verify",
         str(r.zip_path), ZIP_SIGNATURE],
        [str(r.sparkle_bin / "sign_update"), "--account", "adkitchen", "--verify",
         str(r.appcast_path)],
    ]
    # Verification only: it writes nothing next to the artifacts.
    assert not list(r.out.glob("*.signature"))


def test_sparkle_verify_refuses_a_keychain_key_the_app_does_not_ship(tmp_path):
    r, run = _verifiable(tmp_path, keychain_key="other=")
    with pytest.raises(RuntimeError, match="SUPublicEDKey") as exc:
        sparkle.step_sparkle_verify(r)
    assert "ADKITCHEN_SPARKLE_PUBLIC_KEY" in str(exc.value)
    assert not [c for c in run.calls if c[0].endswith("sign_update")]


def test_sparkle_verify_refuses_an_unsigned_enclosure(tmp_path):
    r, _ = _verifiable(tmp_path)
    r.appcast_path.write_text(new_appcast(r).replace(
        f' sparkle:edSignature="{ZIP_SIGNATURE}"', ""))
    with pytest.raises(RuntimeError, match="no sparkle:edSignature"):
        sparkle.step_sparkle_verify(r)


def test_sparkle_verify_fails_when_sign_update_rejects_the_signature(tmp_path):
    r, _ = _verifiable(tmp_path, responses=[
        (lambda a: a[0].endswith("sign_update") and ZIP_SIGNATURE in a, 1, "",
         "Error: failed to pass signing verification.")])
    with pytest.raises(RuntimeError, match="failed to pass signing verification"):
        sparkle.step_sparkle_verify(r)


def test_sparkle_verify_is_skipped_when_only_the_push_is_left(tmp_path, capsys):
    r, run = _verifiable(tmp_path)
    r.publish_state = "push"
    sparkle.step_sparkle_verify(r)
    assert run.calls == [] and "Skipping sparkle-verify" in capsys.readouterr().out


def test_enclosure_signature_reads_a_real_generate_appcast_layout(tmp_path):
    # generate_appcast wraps the feed in comments before and after <rss>.
    r = release(tmp_path, FakeRunner())
    feed = tmp_path / "appcast.xml"
    feed.write_text("<?xml version=\"1.0\" standalone=\"yes\"?><!-- sparkle-sign-warning: x -->"
                    + new_appcast(r).split("?>", 1)[1]
                    + "<!-- sparkle-signatures:\nedSignature: abc\nlength: 1\n-->")
    assert sparkle.enclosure_signature(feed, r.zip_path.name) == ZIP_SIGNATURE
    assert sparkle.enclosure_signature(feed, "Other-1.0.zip") is None


# Sparkle: the appcast -------------------------------------------------------------------


def _generating_runner(run, check_archives=None):
    def runner(argv):
        if not argv[0].endswith("generate_appcast"):
            return run(argv)
        run.calls.append(list(argv))
        archives = Path(argv[-1])
        if check_archives:
            check_archives(archives)
        Path(argv[argv.index("-o") + 1]).write_text("<rss>generated</rss>")
        return subprocess.CompletedProcess(argv, 0, "", "")
    return runner


def test_appcast_is_generated_locally_from_the_published_feed(tmp_path):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run), appcast=False)
    (r.releases_repo / "appcast.xml").write_text("<rss>old</rss>")
    stem = r.zip_path.stem

    def check_archives(archives):
        assert sorted(p.name for p in archives.iterdir()) == [
            f"{stem}.md", f"{stem}.zip", "appcast.xml"]
        assert (archives / "appcast.xml").read_text() == "<rss>old</rss>"

    r.run = _generating_runner(run, check_archives)
    sparkle.step_appcast(r)

    [gen] = [c for c in run.calls if c[0].endswith("generate_appcast")]
    assert gen[gen.index("--account") + 1] == "adkitchen"
    assert gen[gen.index("--download-url-prefix") + 1] == (
        "https://github.com/agenticdevelopmentstudio/adkitchen-releases/releases/"
        f"download/v{VERSION}/")
    assert "--embed-release-notes" in gen and "--release-notes-url-prefix" not in gen
    assert gen[gen.index("--maximum-versions") + 1] == "0"
    assert r.appcast_path.read_text() == "<rss>generated</rss>"
    # Nothing leaves the machine and the checkout is untouched until publish.
    assert (r.releases_repo / "appcast.xml").read_text() == "<rss>old</rss>"
    assert not run.find("git") and not run.find("gh")


def test_appcast_without_a_published_feed_or_notes_carries_only_the_zip(tmp_path):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run, notes=False), appcast=False)
    seen = {}
    r.run = _generating_runner(
        run, lambda archives: seen.update(names=sorted(p.name for p in archives.iterdir())))
    sparkle.step_appcast(r)
    assert seen["names"] == [r.zip_path.name]


def test_a_stale_appcast_directory_is_cleared_first(tmp_path):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run), appcast=False)
    (r.appcast_path.parent).mkdir(parents=True)
    (r.appcast_path.parent / "stale.zip").write_text("old")
    seen = {}
    r.run = _generating_runner(
        run, lambda archives: seen.update(names=sorted(p.name for p in archives.iterdir())))
    sparkle.generate_appcast(r)
    assert "stale.zip" not in seen["names"]


def test_appcast_is_skipped_when_only_the_push_is_left(tmp_path, capsys):
    run = FakeRunner()
    r = with_artifacts(release(tmp_path, run))
    r.publish_state = "push"
    sparkle.step_appcast(r)
    assert run.calls == [] and "Skipping appcast" in capsys.readouterr().out


def test_a_failed_generate_appcast_is_an_error(tmp_path):
    run = FakeRunner([(lambda a: a[0].endswith("generate_appcast"), 1, "", "boom")])
    r = with_artifacts(release(tmp_path, run), appcast=False)
    with pytest.raises(RuntimeError, match=r"(?s)generate_appcast failed.*boom"):
        sparkle.step_appcast(r)


# site ---------------------------------------------------------------------------------


def _site(status, *, url=None):
    return ((lambda a: a[0] == "curl" and (url is None or a[-1] == url)),
            0 if status != "000" else 7, str(status))


def test_http_status_treats_no_answer_as_empty(tmp_path):
    r = release(tmp_path, FakeRunner([_site("000")]))
    assert site.http_status(r, "https://x") == ""
    r = release(tmp_path / "b", FakeRunner([_site(200)]))
    assert site.http_status(r, "https://x") == "200"


def test_site_check_probes_the_feed_once_an_appcast_is_published(tmp_path):
    run = FakeRunner([_site(200, url=FEED)])
    r = release(tmp_path, run)
    (r.releases_repo / "appcast.xml").write_text("<rss/>")
    assert site.site_failures(r) == []
    assert [c[-1] for c in run.find("curl")] == [FEED]


@pytest.mark.parametrize("status, shown", [(404, "HTTP 404"), (502, "HTTP 502"),
                                           ("000", "HTTP nothing")])
def test_site_check_fails_naming_the_owners_deploy_step(tmp_path, status, shown):
    r = release(tmp_path, FakeRunner([_site(status)]))
    (r.releases_repo / "appcast.xml").write_text("<rss/>")
    [failure] = site.site_failures(r)
    assert FEED in failure and shown in failure
    assert "owner's step" in failure and "live on production" in failure


def test_site_check_before_the_first_release_probes_downloads(tmp_path):
    # No appcast.xml is published yet, so the deployed feed route cannot
    # answer 200; the same deploy's downloads page stands in for it.
    downloads = "https://kitchen.agenticdevelopmentstudio.com/downloads"
    run = FakeRunner([_site(200, url=downloads), _site(502)])
    r = release(tmp_path, run)
    assert site.site_failures(r) == []
    assert [c[-1] for c in run.find("curl")] == [downloads]

    run.responses = [_site(404)]
    [failure] = site.site_failures(r)
    assert downloads in failure and "first release" in failure and "owner's step" in failure


def test_site_override_probes_that_deploy_instead_of_the_feed_host(tmp_path):
    staging = "https://staging.kitchen.agenticdevelopmentstudio.com"
    run = FakeRunner([_site(200)])
    r = release(tmp_path, run)
    r.site = staging
    assert site.site_failures(r) == []
    assert [c[-1] for c in run.find("curl")] == [f"{staging}/downloads"]

    (r.releases_repo / "appcast.xml").write_text("<rss/>")
    run.calls.clear()
    assert site.site_failures(r) == []
    assert [c[-1] for c in run.find("curl")] == [f"{staging}/appcast.xml"]
    [failure] = site.site_failures(release(tmp_path / "b", FakeRunner([_site(404)])))
    assert "production" in failure


def test_site_check_uses_the_configured_routes(tmp_path):
    run = FakeRunner([_site(200)])
    r = release(tmp_path, run, overrides={"site": {"routes": {
        "downloads": "/dl", "latest": "/dl/latest", "appcast": "/feed.xml"}}})
    site.site_failures(r)
    (r.releases_repo / "appcast.xml").write_text("<rss/>")
    site.site_failures(r)
    origin = r.cfg.site_origin
    assert [c[-1] for c in run.find("curl")] == [f"{origin}/dl", f"{origin}/feed.xml"]


# cask ---------------------------------------------------------------------------------


@pytest.mark.parametrize("flavor, feed", [("adkitchen", FEED), ("stenographer", STENO_FEED)])
def test_cask_installs_the_published_pkg_of_this_release(tmp_path, flavor, feed):
    cfg = config(tmp_path, flavor=flavor)
    e = entry(cfg)
    rendered = cask.cask_ruby(e, cfg)
    assert f'cask "{cfg.cask_token}" do' in rendered
    assert f'version "{VERSION}"' in rendered
    # The pkg, never the zip: the pkg is the notarized first-install artifact.
    assert f'sha256 "{e.pkg.sha256}"' in rendered
    assert e.zip.sha256 not in rendered
    url = re.search(r'^  url "(.+)"$', rendered, re.M).group(1)
    assert "#{version}" in url
    assert url.replace("#{version}", VERSION) == e.pkg.url
    assert f'pkg "{cfg.app_name}-#{{version}}.pkg"' in rendered


def test_cask_fills_every_template_variable(tmp_path):
    cfg = config(tmp_path)
    rendered = cask.cask_ruby(entry(cfg), cfg)
    assert 'name "Agentic Developer Kitchen"' in rendered
    assert f'url "{FEED}"' in rendered and "strategy :sparkle" in rendered
    assert 'homepage "https://kitchen.agenticdevelopmentstudio.com/"' in rendered
    assert f'quit:    "{cfg.bundle_id}"' in rendered
    assert 'cask "adkitchen" do' in rendered
    assert "$" not in rendered.replace("#{", "")


def test_cask_keeps_the_apps_own_stanzas_literally(tmp_path):
    cfg = config(tmp_path)
    cfg.cask_template.write_text(cfg.cask_template.read_text()
                                 + '\n# zap trash: ["~/Library/Logs/com.example.daemon"]\n')
    assert '"~/Library/Logs/com.example.daemon"' in cask.cask_ruby(entry(cfg), cfg)


@pytest.mark.parametrize("minimum, symbol", [("26.0", ":tahoe"), ("15.4", ":sequoia"),
                                             ("14.0", ":sonoma")])
def test_cask_gates_on_the_apps_minimum_macos(tmp_path, minimum, symbol):
    cfg = config(tmp_path)
    assert f"depends_on macos: {symbol}\n" in cask.cask_ruby(entry(cfg, minimum=minimum), cfg)


def test_cask_refuses_a_macos_it_has_no_symbol_for(tmp_path):
    cfg = config(tmp_path)
    with pytest.raises(RuntimeError, match="HOMEBREW_MACOS"):
        cask.cask_ruby(entry(cfg, minimum="27.0"), cfg)


def test_cask_unknown_variable_fails(tmp_path):
    cfg = config(tmp_path)
    cfg.cask_template.write_text("cask \"$token\" do\n  version \"$nope\"\nend\n")
    with pytest.raises(KeyError):
        cask.cask_ruby(entry(cfg), cfg)


def test_cask_url_must_resolve_to_the_pkg(tmp_path):
    cfg = config(tmp_path)
    cfg.cask_template.write_text('cask "$token" do\n  url "https://example.com/x.pkg"\nend\n')
    # template that hardcodes a url not equal to entry.pkg.url
    with pytest.raises(ValueError, match="url"):
        cask.cask_ruby(entry(cfg), cfg)


def test_cask_without_a_url_stanza_is_refused(tmp_path):
    cfg = config(tmp_path)
    cfg.cask_template.write_text('cask "$token" do\n  version "$version"\nend\n')
    with pytest.raises(ValueError, match="url"):
        cask.cask_ruby(entry(cfg), cfg)


def test_cask_refuses_a_pkg_url_that_is_not_the_download_prefix(tmp_path):
    cfg = config(tmp_path)
    e = entry(cfg)
    wrong = e.pkg.__class__(url="https://elsewhere/x.pkg", size=1, sha256="s")
    e = e.__class__(**{**e.__dict__, "pkg": wrong})
    with pytest.raises(ValueError, match="would not resolve"):
        cask.cask_ruby(e, cfg)


@pytest.mark.skipif(not shutil.which("ruby"), reason="no ruby to syntax-check with")
def test_cask_is_valid_ruby(tmp_path):
    cfg = config(tmp_path)
    path = tmp_path / "adkitchen.rb"
    path.write_text(cask.cask_ruby(entry(cfg), cfg))
    proc = subprocess.run(["ruby", "-c", str(path)], capture_output=True, text=True)
    assert proc.returncode == 0, proc.stderr


# layout -------------------------------------------------------------------------------

PLUGIN = "Contents/PlugIns/ClaudeAPI.aiplugin/Contents/Info.plist"


def make_layout(tmp_path: Path, files: list[str]) -> Path:
    app = tmp_path / "App.app"
    for rel in files:
        path = app / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("x")
    return app


def test_complete_bundle_has_no_problems(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    app = make_layout(tmp_path, list(cfg.layout_required) + [PLUGIN])
    assert layout.problems(app, cfg) == []


def test_missing_required_path_reported(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    files = [f for f in cfg.layout_required if f != "Contents/MacOS/stenographerd"]
    app = make_layout(tmp_path, files + [PLUGIN])
    assert layout.problems(app, cfg) == ["missing Contents/MacOS/stenographerd"]


def test_forbidden_path_reported(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    app = make_layout(tmp_path, list(cfg.layout_required) + [PLUGIN, *cfg.layout_forbidden])
    assert layout.problems(app, cfg) == [f"forbidden {cfg.layout_forbidden[0]}"]


def test_layout_glob_requires_a_match(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    app = make_layout(tmp_path, list(cfg.layout_required))
    (app / "Contents/PlugIns").mkdir(parents=True, exist_ok=True)
    problems = layout.problems(app, cfg)
    assert problems == ["no path matches Contents/PlugIns/*.aiplugin"]


def test_an_empty_layout_config_checks_nothing(tmp_path):
    cfg = config(tmp_path, overrides={"layout": {"required": []}})
    assert layout.problems(tmp_path / "Nope.app", cfg) == []
