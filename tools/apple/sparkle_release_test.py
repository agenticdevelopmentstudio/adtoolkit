#!/usr/bin/env python3
"""Tests for sparkle_release.py.

Every external command (xcodebuild, generate_appcast, generate_keys,
sign_update, stapler, spctl, codesign, gh, git) goes through an injected
`run` fake; nothing here touches the network, the keychain or real Sparkle.

Run: python3 -m pytest tools/apple/sparkle_release_test.py -q
"""
from __future__ import annotations

import json
import plistlib
import subprocess

import pytest

import macos_release as mr
import sparkle_release as sr

ACCOUNT = "acct"
SIGNATURE = "c2lnbmF0dXJl"
ZIP_NAME = "Widget-1.2.zip"


def proc(argv, code=0, out="", err=""):
    return subprocess.CompletedProcess(argv, code, out, err)


class Fake:
    """A `run` that records calls; `answers` maps a substring of the joined
    argv to a (code, stdout, stderr) tuple, and `side` runs a callback."""

    def __init__(self, answers=None, side=None):
        self.calls: list[list[str]] = []
        self.answers = answers or {}
        self.side = side

    def __call__(self, argv):
        self.calls.append(list(argv))
        if self.side:
            self.side(argv)
        joined = " ".join(argv)
        for needle, (code, out, err) in self.answers.items():
            if needle in joined:
                return proc(argv, code, out, err)
        return proc(argv)

    def find(self, needle):
        return [c for c in self.calls if needle in " ".join(c)]


def appcast_xml(signature: str | None = SIGNATURE, name: str = ZIP_NAME) -> str:
    sig = f' sparkle:edSignature="{signature}"' if signature else ""
    return (f'<rss xmlns:sparkle="{sr.SPARKLE_NS}" version="2.0"><channel><item>'
            f'<enclosure url="https://example.com/releases/download/v1.2/{name}"{sig} '
            f'length="3" type="application/octet-stream"/></item></channel></rss>')


# sparkle_config_problems ---------------------------------------------------------


def test_sparkle_config_problems_requires_verify_with_signed_feed():
    broken = {"SUPublicEDKey": "abc=", "SURequireSignedFeed": True}
    assert any("SUVerifyUpdateBeforeExtraction" in p for p in sr.sparkle_config_problems(broken))
    assert sr.sparkle_config_problems({**broken, "SUVerifyUpdateBeforeExtraction": True}) == []


def test_sparkle_config_problems_requires_a_public_key():
    assert any("SUPublicEDKey" in p for p in sr.sparkle_config_problems({}))


# sparkle_tools -------------------------------------------------------------------


def test_sparkle_tools_returns_bin_without_resolving_when_present(tmp_path):
    bin_dir = tmp_path / sr.SPARKLE_BIN_REL
    bin_dir.mkdir(parents=True)
    (bin_dir / "generate_keys").write_text("")
    run = Fake()
    got = sr.sparkle_tools(tmp_path, workspace=tmp_path / "W.xcworkspace", scheme="W", run=run)
    assert got == bin_dir
    assert run.calls == []


def test_sparkle_tools_resolves_packages_when_missing(tmp_path):
    bin_dir = tmp_path / sr.SPARKLE_BIN_REL

    def side(argv):
        bin_dir.mkdir(parents=True, exist_ok=True)
        (bin_dir / "generate_keys").write_text("")

    run = Fake(side=side)
    got = sr.sparkle_tools(tmp_path, workspace=tmp_path / "W.xcworkspace", scheme="W", run=run)
    assert got == bin_dir
    argv = run.calls[0]
    assert argv[:2] == ["xcodebuild", "-resolvePackageDependencies"]
    assert argv[argv.index("-workspace") + 1] == str(tmp_path / "W.xcworkspace")
    assert argv[argv.index("-scheme") + 1] == "W"
    assert argv[argv.index("-derivedDataPath") + 1] == str(tmp_path)


def test_sparkle_tools_raises_when_resolving_does_not_produce_them(tmp_path):
    with pytest.raises(RuntimeError, match="Sparkle's tools"):
        sr.sparkle_tools(tmp_path, workspace=tmp_path / "W.xcworkspace", scheme="W", run=Fake())


def test_sparkle_tools_raises_when_xcodebuild_fails(tmp_path):
    run = Fake({"xcodebuild": (65, "", "boom")})
    with pytest.raises(RuntimeError, match="resolvePackageDependencies"):
        sr.sparkle_tools(tmp_path, workspace=tmp_path / "W.xcworkspace", scheme="W", run=run)


# generate_appcast ----------------------------------------------------------------


def test_generate_appcast_stages_only_this_release_and_carries_the_published_feed(tmp_path):
    zip_path = tmp_path / ZIP_NAME
    zip_path.write_bytes(b"zip")
    notes = tmp_path / "1.2.md"
    notes.write_text("# notes")
    published = tmp_path / "published.xml"
    published.write_text("<rss/>")
    out = tmp_path / "appcast" / "appcast.xml"
    stale = out.parent / "Old-1.0.zip"
    stale.parent.mkdir()
    stale.write_text("old")
    run = Fake()
    got = sr.generate_appcast(tools=tmp_path / "bin", account=ACCOUNT, zip_path=zip_path,
                              notes=notes, published_appcast=published,
                              download_prefix="https://example.com/releases/download/v1.2/",
                              out=out, run=run)
    assert got == out
    assert not stale.exists()
    assert (out.parent / ZIP_NAME).read_bytes() == b"zip"
    assert (out.parent / "Widget-1.2.md").read_text() == "# notes"
    assert (out.parent / "appcast.xml").read_text() == "<rss/>"
    assert run.calls == [[
        str(tmp_path / "bin" / "generate_appcast"), "--account", ACCOUNT,
        "--download-url-prefix", "https://example.com/releases/download/v1.2/",
        "--embed-release-notes", "--maximum-versions", "0",
        "-o", str(out), str(out.parent)]]


def test_generate_appcast_without_notes_or_published_feed(tmp_path):
    zip_path = tmp_path / ZIP_NAME
    zip_path.write_bytes(b"zip")
    out = tmp_path / "appcast" / "appcast.xml"
    sr.generate_appcast(tools=tmp_path, account=ACCOUNT, zip_path=zip_path,
                        notes=tmp_path / "missing.md", published_appcast=None,
                        download_prefix="https://x/", out=out, run=Fake())
    assert sorted(p.name for p in out.parent.iterdir()) == [ZIP_NAME]


def test_generate_appcast_raises_when_the_tool_fails(tmp_path):
    zip_path = tmp_path / ZIP_NAME
    zip_path.write_bytes(b"zip")
    with pytest.raises(RuntimeError, match="generate_appcast"):
        sr.generate_appcast(tools=tmp_path, account=ACCOUNT, zip_path=zip_path,
                            notes=tmp_path / "n.md", published_appcast=None,
                            download_prefix="https://x/", out=tmp_path / "a" / "appcast.xml",
                            run=Fake({"generate_appcast": (1, "", "no key")}))


# enclosure_signature -------------------------------------------------------------


def test_enclosure_signature_reads_the_matching_enclosure(tmp_path):
    feed = tmp_path / "appcast.xml"
    feed.write_text(appcast_xml())
    assert sr.enclosure_signature(feed, ZIP_NAME) == SIGNATURE
    assert sr.enclosure_signature(feed, "Other.zip") is None


def test_enclosure_signature_is_none_when_unsigned(tmp_path):
    feed = tmp_path / "appcast.xml"
    feed.write_text(appcast_xml(None))
    assert sr.enclosure_signature(feed, ZIP_NAME) is None


def test_enclosure_signature_reads_a_real_generate_appcast_layout(tmp_path):
    # generate_appcast wraps the feed in comments before and after <rss>.
    feed = tmp_path / "appcast.xml"
    feed.write_text("<?xml version=\"1.0\" standalone=\"yes\"?><!-- sparkle-sign-warning: x -->"
                    + appcast_xml()
                    + "<!-- sparkle-signatures:\nedSignature: abc\nlength: 1\n-->")
    assert sr.enclosure_signature(feed, ZIP_NAME) == SIGNATURE


# sparkle_verify ------------------------------------------------------------------


def verifiable(tmp_path, *, shipped="abc=", keychain="abc=", appcast=None, sign_update_code=0):
    app = tmp_path / "W.app"
    (app / "Contents").mkdir(parents=True)
    (app / "Contents/Info.plist").write_bytes(plistlib.dumps({"SUPublicEDKey": shipped}))
    zip_path = tmp_path / ZIP_NAME
    zip_path.write_bytes(b"zip")
    feed = tmp_path / "appcast.xml"
    feed.write_text(appcast if appcast is not None else appcast_xml())
    run = Fake({"generate_keys": (0, keychain + "\n", ""),
                "sign_update": (sign_update_code, "", "bad signature" if sign_update_code else "")})
    return dict(tools=tmp_path / "bin", account=ACCOUNT, app=app, zip_path=zip_path,
                appcast=feed, run=run)


def test_sparkle_verify_passes_and_checks_zip_and_feed_signatures(tmp_path):
    kw = verifiable(tmp_path)
    assert sr.sparkle_verify(**kw) == []
    sign_update = str(tmp_path / "bin" / "sign_update")
    assert kw["run"].find("sign_update") == [
        [sign_update, "--account", ACCOUNT, "--verify", str(kw["zip_path"]), SIGNATURE],
        [sign_update, "--account", ACCOUNT, "--verify", str(kw["appcast"])]]


def test_sparkle_verify_fails_on_key_mismatch(tmp_path):
    failures = sr.sparkle_verify(**verifiable(tmp_path, keychain="zzz="))
    assert len(failures) == 1
    assert "zzz=" in failures[0] and "abc=" in failures[0]
    assert "generate_keys" in failures[0] and "-p" in failures[0]


def test_sparkle_verify_fails_on_missing_ed_signature(tmp_path):
    kw = verifiable(tmp_path, appcast=appcast_xml(None))
    failures = sr.sparkle_verify(**kw)
    assert any("sparkle:edSignature" in f and ZIP_NAME in f for f in failures)
    # Nothing to verify the zip against, but the feed itself is still checked.
    assert len(kw["run"].find("sign_update")) == 1


def test_sparkle_verify_fails_when_sign_update_rejects(tmp_path):
    failures = sr.sparkle_verify(**verifiable(tmp_path, sign_update_code=1))
    assert any(ZIP_NAME in f and "bad signature" in f for f in failures)
    assert any("feed" in f for f in failures)


# provenance ----------------------------------------------------------------------


def artifacts(tmp_path):
    pkg, zip_path = tmp_path / "W-1.2.pkg", tmp_path / ZIP_NAME
    pkg.write_bytes(b"pkg")
    zip_path.write_bytes(b"zip")
    return {"pkg": pkg, "zip": zip_path}


def test_provenance_round_trips_clean(tmp_path):
    arts = artifacts(tmp_path)
    path = tmp_path / "provenance.json"
    sr.write_provenance(path, source_sha="abc123", artifacts=arts, notarized=True)
    record = json.loads(path.read_text())
    assert record["source_sha"] == "abc123" and record["notarized"] is True
    assert record["artifacts"]["pkg"] == mr.asset_for(arts["pkg"], "").sha256
    assert sr.provenance_failures(path, head_sha="abc123", artifacts=arts) == []


def test_provenance_failures_when_missing_or_unreadable(tmp_path):
    arts = artifacts(tmp_path)
    path = tmp_path / "provenance.json"
    assert "missing" in sr.provenance_failures(path, head_sha="a", artifacts=arts)[0]
    path.write_text("{nope")
    assert "unreadable" in sr.provenance_failures(path, head_sha="a", artifacts=arts)[0]


def test_provenance_failures_when_not_notarized(tmp_path):
    arts = artifacts(tmp_path)
    path = tmp_path / "provenance.json"
    sr.write_provenance(path, source_sha="a", artifacts=arts, notarized=False)
    assert "never notarized" in sr.provenance_failures(path, head_sha="a", artifacts=arts)[0]


def test_provenance_failures_on_other_commit_and_changed_artifact(tmp_path):
    arts = artifacts(tmp_path)
    path = tmp_path / "provenance.json"
    sr.write_provenance(path, source_sha="aaaa", artifacts=arts, notarized=True)
    arts["zip"].write_bytes(b"changed")
    failures = sr.provenance_failures(path, head_sha="bbbb", artifacts=arts)
    assert any("aaaa" in f and "bbbb" in f for f in failures)
    assert any(ZIP_NAME in f and "changed" in f for f in failures)
    assert not any("W-1.2.pkg" in f for f in failures)


# artifact_failures ---------------------------------------------------------------


def test_artifact_failures_runs_every_check_and_passes_when_clean(tmp_path):
    run = Fake({"codesign -d": (0, "", "Authority=Developer ID Application: Me (K2NA732JAX)")})
    app, pkg = tmp_path / "W.app", tmp_path / "W.pkg"
    assert sr.artifact_failures(app=app, pkg=pkg, run=run) == []
    assert run.find("stapler validate") and run.find("spctl --assess")
    assert run.find("codesign --verify --deep --strict")


def test_artifact_failures_reports_each_failing_check_with_its_fix(tmp_path):
    run = Fake({"stapler": (65, "", "no ticket"), "spctl": (3, "", "rejected"),
                "codesign --verify": (1, "", "invalid"),
                "codesign -d": (0, "", "Authority=Apple Development: Me")})
    failures = sr.artifact_failures(app=tmp_path / "W.app", pkg=tmp_path / "W.pkg", run=run)
    assert len(failures) == 4
    assert any("no ticket" in f for f in failures)
    assert any("rejected" in f for f in failures)
    assert any("invalid" in f for f in failures)
    assert any("Developer ID Application" in f for f in failures)
    assert all("rebuild" in f for f in failures)


# publish_state -------------------------------------------------------------------

REPO = "owner/widget-releases"


def checkout(tmp_path, *, listed=()):
    path = tmp_path / "releases"
    path.mkdir()
    (path / "releases.json").write_text(json.dumps(
        {"schema": 1, "releases": [{"version": v} for v in listed]}))
    return path


def local_files(tmp_path):
    pkg, zip_path = tmp_path / "Widget-1.2.pkg", tmp_path / ZIP_NAME
    pkg.write_bytes(b"pkg")
    zip_path.write_bytes(b"zip")
    return [pkg, zip_path]


def gh_assets(files):
    """What `gh release view --json assets` says for exactly `files`."""
    out = []
    for f in files:
        a = mr.asset_for(f, "")
        out.append({"name": f.name, "size": a.size, "digest": f"sha256:{a.sha256}"})
    return out


def state(tmp_path, *, listed=(), view=None, ahead="0", assets=None):
    files = local_files(tmp_path)
    if view is None:
        view = (0, json.dumps({"assets": gh_assets(files) if assets is None else assets}), "")
    run = Fake({"gh release view": view, "rev-list --count": (0, ahead + "\n", "")})
    return run, dict(releases_checkout=checkout(tmp_path, listed=listed), version="1.2",
                     github_repo=REPO, local_artifacts=files, run=run)


def test_publish_state_create_when_no_release_exists(tmp_path):
    run, kw = state(tmp_path, view=(1, "", "release not found"))
    assert sr.publish_state(**kw) == "create"
    assert run.calls[0] == ["gh", "release", "view", "v1.2", "--repo", REPO, "--json", "assets"]


def test_publish_state_refuses_when_listed_but_no_github_release(tmp_path):
    _, kw = state(tmp_path, listed=["1.2"], view=(1, "", "release not found"))
    with pytest.raises(mr.PreflightError, match="repair"):
        sr.publish_state(**kw)


def test_publish_state_raises_on_other_gh_failures(tmp_path):
    _, kw = state(tmp_path, view=(1, "", "HTTP 502"))
    with pytest.raises(mr.PreflightError, match="502"):
        sr.publish_state(**kw)


def test_publish_state_commit_when_release_exists_but_is_not_listed(tmp_path):
    _, kw = state(tmp_path)
    assert sr.publish_state(**kw) == "commit"


def test_publish_state_push_when_committed_but_ahead_of_origin(tmp_path):
    _, kw = state(tmp_path, listed=["1.2"], ahead="1")
    assert sr.publish_state(**kw) == "push"


def test_publish_state_is_published_when_release_and_commit_exist(tmp_path):
    run, kw = state(tmp_path, listed=["1.2"], ahead="0")
    assert sr.publish_state(**kw) == "published"
    assert run.find("rev-list --count origin/main..HEAD")


def mismatch(tmp_path, mutate):
    assets = mutate(gh_assets(local_files(tmp_path)))
    _, kw = state(tmp_path, listed=["1.2"], assets=assets)
    with pytest.raises(mr.PreflightError) as exc:
        sr.publish_state(**kw)
    msg = str(exc.value)
    assert f"gh release delete v1.2 --repo {REPO} --cleanup-tag" in msg
    return msg


def test_publish_state_refuses_a_release_missing_an_asset(tmp_path):
    assert "Widget-1.2.pkg is not attached" in mismatch(tmp_path, lambda a: a[1:])


def test_publish_state_refuses_a_release_with_an_extra_asset(tmp_path):
    msg = mismatch(tmp_path, lambda a: a + [{"name": "stray.txt", "size": 1}])
    assert "unexpected assets attached: stray.txt" in msg


def test_publish_state_refuses_a_size_mismatch(tmp_path):
    def mutate(a):
        a[0]["size"] += 1
        return a
    assert "bytes on GitHub" in mismatch(tmp_path, mutate)


def test_publish_state_refuses_a_digest_mismatch(tmp_path):
    def mutate(a):
        a[1]["digest"] = "sha256:deadbeef"
        return a
    assert "sha256 differs" in mismatch(tmp_path, mutate)


def test_publish_state_ignores_the_digest_when_gh_reports_none(tmp_path):
    assets = [{k: v for k, v in a.items() if k != "digest"}
              for a in gh_assets(local_files(tmp_path))]
    _, kw = state(tmp_path, assets=assets)
    assert sr.publish_state(**kw) == "commit"


# render_cask / homebrew_macos ----------------------------------------------------


def entry(version="1.2", minimum="26.0"):
    base = f"https://github.com/{REPO}/releases/download/v{version}"
    return mr.ReleaseEntry(version, 7, "2026-10-16T00:00:00Z", minimum, f"notes/{version}.md",
                           mr.ReleaseAsset(f"{base}/Widget-{version}.pkg", 1, "pkgsha"),
                           mr.ReleaseAsset(f"{base}/Widget-{version}.zip", 2, "zipsha"))


def render(**over):
    kw = dict(token="widget", name="Widget", entry=entry(),
              feed_url="https://widget.example/appcast.xml", app_filename="Widget.app")
    kw.update(over)
    return sr.render_cask(**kw)


def test_render_cask_uses_sparkle_livecheck():
    cask = render()
    assert 'cask "widget" do' in cask
    assert 'version "1.2"' in cask and 'sha256 "pkgsha"' in cask
    assert 'livecheck do\n    url "https://widget.example/appcast.xml"\n    strategy :sparkle' in cask
    assert 'homepage "https://widget.example/"' in cask
    assert "depends_on macos: :tahoe" in cask
    assert "auto_updates true" in cask


def test_render_cask_url_uses_version_interpolation_and_resolves_to_the_pkg():
    cask = render()
    url = f'https://github.com/{REPO}/releases/download/v#{{version}}/Widget-#{{version}}.pkg'
    assert f'url "{url}"' in cask
    assert 'pkg "Widget-#{version}.pkg"' in cask


def test_render_cask_includes_extra_stanzas_inside_the_cask():
    cask = render(extra_stanzas='  zap trash: ["~/.widget"]\n')
    assert '  zap trash: ["~/.widget"]' in cask
    assert cask.rstrip().endswith("end")
    assert cask.index("zap trash") < cask.rindex("end")


def test_render_cask_names_the_installed_app_in_its_uninstall():
    assert '"/Applications/Widget.app"' in render()


def test_render_cask_interpolates_only_the_tag_and_file_name():
    base = "https://github.com/owner/widget-1.2-releases/releases/download/v1.2"
    e = mr.ReleaseEntry("1.2", 7, "d", "26.0", "n",
                        mr.ReleaseAsset(f"{base}/Widget-1.2.pkg", 1, "s"),
                        mr.ReleaseAsset(f"{base}/Widget-1.2.zip", 1, "s"))
    assert ('url "https://github.com/owner/widget-1.2-releases/releases/download/'
            'v#{version}/Widget-#{version}.pkg"') in render(entry=e)


def test_render_cask_refuses_a_pkg_url_without_the_version():
    bad = mr.ReleaseEntry("1.2", 7, "d", "26.0",
                          "n", mr.ReleaseAsset("https://x/Widget.pkg", 1, "s"),
                          mr.ReleaseAsset("https://x/Widget.zip", 1, "s"))
    with pytest.raises(RuntimeError, match="version"):
        render(entry=bad)


def test_homebrew_macos_maps_majors_and_refuses_unknown():
    assert sr.homebrew_macos("14.0") == ":sonoma"
    assert sr.homebrew_macos("15.2") == ":sequoia"
    assert sr.homebrew_macos("26.0") == ":tahoe"
    with pytest.raises(RuntimeError, match="HOMEBREW_MACOS"):
        sr.homebrew_macos("99.0")
