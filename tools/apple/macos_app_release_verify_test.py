#!/usr/bin/env python3
"""Tests for macos_app_release.verify -- the post-publish check.

Pure: HTTP goes through a fake `fetch` and every command through a fake
runner, so nothing here touches GitHub, the website or a real pkg.

Run: python3 -m pytest tools/apple/macos_app_release_verify_test.py -q
"""
from __future__ import annotations

import hashlib
import http.client
import json
import subprocess

import pytest

import macos_release as mr
from macos_app_release import cask, verify as rv
from macos_app_release.sparkle import SPARKLE_NS
from macos_app_release.state import PROVENANCE
from macos_app_release_fixtures import BUILD, VERSION, config

OLD = "1.0.153"
PKG_BYTES = b"the pkg"
ZIP_BYTES = b"the zip"
PKG_SHA = hashlib.sha256(PKG_BYTES).hexdigest()
ZIP_SHA = hashlib.sha256(ZIP_BYTES).hexdigest()


class World:
    """Every URL and body a published release is made of, for one config."""

    def __init__(self, cfg, *, downloads="/downloads"):
        self.cfg = cfg
        self.site = cfg.site_origin
        self.raw = rv.raw_base(cfg)
        self.name = cfg.app_name
        self.pkg_url = self.asset(VERSION, "pkg")
        self.zip_url = self.asset(VERSION, "zip")
        self.old_pkg_url = self.asset(OLD, "pkg")
        self.downloads = downloads

    def asset(self, version, kind):
        return f"{self.cfg.download_prefix}/v{version}/{self.name}-{version}.{kind}"

    def releases_json(self, *, latest=VERSION, build=BUILD, pkg_sha=PKG_SHA):
        return json.dumps({"schema": 1, "latest": latest, "releases": [
            {"version": VERSION, "build": build, "notes": f"notes/{VERSION}.md",
             "pkg": {"url": self.pkg_url, "size": 7, "sha256": pkg_sha},
             "zip": {"url": self.zip_url, "size": 7, "sha256": ZIP_SHA}},
            {"version": OLD, "build": BUILD - 1 if BUILD > 1 else 0, "notes": f"notes/{OLD}.md",
             "pkg": {"url": self.old_pkg_url, "size": 7, "sha256": "x"},
             "zip": {"url": "z", "size": 7, "sha256": "y"}},
        ]}).encode()

    def appcast(self, *, version=VERSION, build=BUILD, signed=True, newer=None):
        sig = ' sparkle:edSignature="abc"' if signed else ""
        extra = (f"<item><sparkle:version>{newer}</sparkle:version>"
                 "<sparkle:shortVersionString>9.9.9</sparkle:shortVersionString></item>"
                 if newer else "")
        return (f'<?xml version="1.0"?><rss xmlns:sparkle="{SPARKLE_NS}" version="2.0">'
                f"<channel>{extra}<item><sparkle:version>{build}</sparkle:version>"
                f"<sparkle:shortVersionString>{version}</sparkle:shortVersionString>"
                f'<enclosure url="{self.zip_url}" length="7"{sig}/></item></channel></rss>'
                "<!-- sparkle-signatures:\nedSignature: x\n-->").encode()

    def cask(self, *, version=VERSION, sha=PKG_SHA):
        return (f'cask "{self.cfg.cask_token}" do\n  version "{version}"\n  sha256 "{sha}"\n'
                f'  pkg "{self.name}-#{{version}}.pkg"\nend\n').encode()

    def downloads_page(self, first=None):
        return (f'<a href="{first or self.pkg_url}">Download installer</a>'
                f'<table><a href="{self.old_pkg_url}">.pkg</a></table>').encode()

    def gh_ok(self):
        return json.dumps({"isDraft": False, "isPrerelease": False, "assets": [
            {"name": f"{self.name}-{VERSION}.pkg", "digest": f"sha256:{PKG_SHA}"},
            {"name": f"{self.name}-{VERSION}.zip", "digest": f"sha256:{ZIP_SHA}"},
        ]})

    def page(self, path):
        return self.site + path


class FakeWeb:
    """Answers by exact URL; `follow` is recorded so the no-redirect probe of the
    latest route can be told apart from the download through it."""

    def __init__(self, w: World, **overrides):
        self.routes = {
            f"{w.raw}releases.json": rv.Fetched(200, {}, w.releases_json()),
            f"{w.raw}notes/{VERSION}.md": rv.Fetched(200, {}, b"# notes"),
            f"{w.raw}{w.cfg.cask_file}": rv.Fetched(200, {}, w.cask()),
            w.page(w.downloads): rv.Fetched(200, {}, w.downloads_page()),
            w.page("/downloads/latest"): rv.Fetched(302, {"location": w.pkg_url}, b""),
            w.page("/appcast.xml"): rv.Fetched(200, {}, w.appcast()),
            w.pkg_url: rv.Fetched(200, {}, PKG_BYTES),
            w.zip_url: rv.Fetched(200, {}, ZIP_BYTES),
        }
        self.routes.update(overrides)
        self.calls: list[tuple[str, bool]] = []

    def __call__(self, url, follow):
        self.calls.append((url, follow))
        res = self.routes.get(url, rv.Fetched(404, {}, b""))
        if follow and res.status in rv.REDIRECTS:
            return self(res.headers["location"], True)
        return res


def runner(gh=None, pkgutil_out="Developer ID Installer: Someone (TEAM)", stapler=0, spctl=0,
           w: World | None = None):
    gh = gh or (0, w.gh_ok() if w else "", "")

    def run(argv):
        if argv[:3] == ["gh", "release", "view"]:
            rc, out, err = gh
            return subprocess.CompletedProcess(argv, rc, out, err)
        if argv[0] == "pkgutil":
            return subprocess.CompletedProcess(argv, 0, pkgutil_out, "")
        if argv[:2] == ["xcrun", "stapler"]:
            return subprocess.CompletedProcess(argv, stapler, "", "no ticket")
        if argv[0] == "spctl":
            return subprocess.CompletedProcess(argv, spctl, "", "rejected")
        raise AssertionError(f"unexpected command {argv}")
    return run


@pytest.fixture
def cfg(tmp_path):
    return config(tmp_path)


@pytest.fixture
def w(cfg):
    return World(cfg)


@pytest.fixture
def run(w):
    return runner(w=w)


def expected(cfg, w, **kw):
    exp = rv.Expected(cfg=cfg, version=VERSION, build=BUILD, site=w.site)
    for k, v in kw.items():
        setattr(exp, k, v)
    return exp


def failures(checks):
    return {c.name: c.failures for c in checks if not c.ok}


# the checks ---------------------------------------------------------------------


def test_raw_base_follows_the_config(cfg):
    assert rv.raw_base(cfg) == (
        "https://raw.githubusercontent.com/agenticdevelopmentstudio/adkitchen-releases/main/")


def test_a_published_release_passes_every_check(cfg, w, run):
    checks = rv.check_once(expected(cfg, w), FakeWeb(w), run)
    assert [c.name for c in checks] == ["github", "feed", "cask", "downloads", "latest",
                                        "appcast", "pkg", "zip"]
    assert failures(checks) == {}


def test_without_a_local_record_releases_json_is_the_digest_reference(cfg, w, run):
    exp = expected(cfg, w)
    rv.check_once(exp, FakeWeb(w), run)
    assert exp.sha256 == {"pkg": PKG_SHA, "zip": ZIP_SHA}
    assert exp.sha_source == "releases.json"


def test_without_a_local_record_github_digests_are_checked_on_the_first_attempt(cfg, w):
    bad = json.dumps({**json.loads(w.gh_ok()), "assets": [
        {"name": f"{w.name}-{VERSION}.pkg", "digest": "sha256:" + "0" * 64},
        {"name": f"{w.name}-{VERSION}.zip", "digest": f"sha256:{ZIP_SHA}"},
    ]})
    got = failures(rv.check_once(expected(cfg, w), FakeWeb(w), runner(gh=(0, bad, ""))))
    assert "not the build in releases.json" in got["github"][0]


def test_a_missing_tool_is_a_named_failure_not_a_traceback(cfg, w):
    def run(argv):
        raise FileNotFoundError(argv[0])
    got = failures(rv.check_once(expected(cfg, w), FakeWeb(w), rv.tool_runner(run)))
    assert "gh: command not found" in got["github"][0]


def test_a_connection_dropped_mid_body_is_a_miss_not_a_crash(monkeypatch, w):
    class Opener:
        def open(self, *_a, **_k):
            raise http.client.IncompleteRead(b"partial")
    monkeypatch.setattr(rv.urllib.request, "build_opener", lambda *_a: Opener())
    assert rv.http_fetch(w.pkg_url, True).status == 0


def test_a_different_build_of_the_same_version_on_github_fails(cfg, w, run):
    exp = expected(cfg, w, sha256={"pkg": "f" * 64, "zip": ZIP_SHA}, sha_source="provenance.json")
    got = failures(rv.check_once(exp, FakeWeb(w), run))
    assert any("not the build in provenance.json" in f for f in got["github"])
    assert any("pkg sha256 is not the build" in f for f in got["feed"])


def test_no_github_release_fails_github(cfg, w):
    got = failures(rv.check_once(expected(cfg, w), FakeWeb(w),
                                 runner(gh=(1, "", "release not found"))))
    assert f"no GitHub release v{VERSION} on {cfg.github_repo}" in got["github"][0]


def test_a_draft_release_fails(cfg, w):
    draft = json.dumps({**json.loads(w.gh_ok()), "isDraft": True})
    got = failures(rv.check_once(expected(cfg, w), FakeWeb(w), runner(gh=(0, draft, ""))))
    assert got["github"] == [f"v{VERSION} is still a draft"]


def test_a_stale_feed_fails_feed_and_skips_the_downloads(cfg, w, run):
    web = FakeWeb(w, **{f"{w.raw}releases.json":
                        rv.Fetched(200, {}, w.releases_json(latest=OLD))})
    checks = rv.check_once(expected(cfg, w), web, run)
    assert f"releases.json's latest is '{OLD}'" in failures(checks)["feed"][0]
    assert "pkg" not in [c.name for c in checks]
    assert (w.pkg_url, True) not in web.calls


def test_the_real_cask_template_passes_the_cask_check(cfg, w, run):
    entry = mr.ReleaseEntry(
        version=VERSION, build=BUILD, date="2026-10-01", minimum_system_version="26.0",
        notes=f"notes/{VERSION}.md", pkg=mr.ReleaseAsset(w.pkg_url, 7, PKG_SHA),
        zip=mr.ReleaseAsset(w.zip_url, 7, ZIP_SHA))
    body = cask.cask_ruby(entry, cfg).encode()
    web = FakeWeb(w, **{f"{w.raw}{cfg.cask_file}": rv.Fetched(200, {}, body)})
    assert failures(rv.check_once(expected(cfg, w), web, run)) == {}


@pytest.mark.parametrize("make, needle", [
    (lambda w: w.cask(version=OLD), f"version is '{OLD}'"),
    (lambda w: w.cask(sha="0" * 64), "sha256 is not the pkg"),
])
def test_a_stale_or_wrong_cask_fails_cask(cfg, w, run, make, needle):
    web = FakeWeb(w, **{f"{w.raw}{cfg.cask_file}": rv.Fetched(200, {}, make(w))})
    got = failures(rv.check_once(expected(cfg, w), web, run))
    assert list(got) == ["cask"] and needle in got["cask"][0]


def test_the_cask_is_read_from_the_configured_file(tmp_path):
    cfg = config(tmp_path, {"cask": {"token": "kitchen"}})
    w = World(cfg)
    web = FakeWeb(w)
    rv.check_cask(expected(cfg, w), web)
    assert (f"{w.raw}Casks/kitchen.rb", True) in web.calls


def test_a_releases_repo_without_a_cask_fails_cask(cfg, w, run):
    web = FakeWeb(w, **{f"{w.raw}{cfg.cask_file}": rv.Fetched(404, {}, b"")})
    got = failures(rv.check_once(expected(cfg, w), web, run))
    assert list(got) == ["cask"] and "HTTP 404" in got["cask"][0]


def test_the_downloads_page_still_offering_the_old_pkg_fails(cfg, w, run):
    web = FakeWeb(w, **{w.page("/downloads"):
                        rv.Fetched(200, {}, w.downloads_page(w.old_pkg_url))})
    got = failures(rv.check_once(expected(cfg, w), web, run))
    assert got["downloads"] == [f"{w.page('/downloads')} offers {w.old_pkg_url}, "
                                f"not {w.pkg_url}"]


def test_a_site_without_the_release_routes_fails_each_route(cfg, w, run):
    web = FakeWeb(w, **{w.page(p): rv.Fetched(404, {}, b"")
                        for p in ("/downloads", "/downloads/latest", "/appcast.xml")})
    got = failures(rv.check_once(expected(cfg, w), web, run))
    assert set(got) == {"downloads", "latest", "appcast"}


def test_latest_redirecting_elsewhere_fails(cfg, w, run):
    web = FakeWeb(w, **{w.page("/downloads/latest"):
                        rv.Fetched(302, {"location": w.old_pkg_url}, b"")})
    got = failures(rv.check_once(expected(cfg, w), web, run))
    assert "redirects to" in got["latest"][0]


def test_overridden_site_routes_are_the_urls_fetched(tmp_path):
    routes = {"downloads": "/dl", "latest": "/dl/latest", "appcast": "/feeds/app.xml"}
    cfg = config(tmp_path, {"site": {"routes": routes}})
    w = World(cfg, downloads="/dl")
    web = FakeWeb(w, **{w.page("/dl/latest"): rv.Fetched(302, {"location": w.pkg_url}, b""),
                        w.page("/feeds/app.xml"): rv.Fetched(200, {}, w.appcast())})
    checks = rv.check_once(expected(cfg, w), web, runner(w=w))
    assert failures(checks) == {}
    urls = [u for u, _ in web.calls]
    assert w.page("/dl") in urls and w.page("/dl/latest") in urls
    assert w.page("/feeds/app.xml") in urls
    assert w.page("/downloads") not in urls and w.page("/appcast.xml") not in urls


@pytest.mark.parametrize("make, needle", [
    (lambda w: w.appcast(version=OLD), f"has no item for {VERSION}"),
    (lambda w: w.appcast(build=BUILD + 100), f"is build {BUILD + 100}, not {BUILD}"),
    (lambda w: w.appcast(signed=False), "no sparkle:edSignature"),
    (lambda w: w.appcast(newer=BUILD + 5), f"newest build is {BUILD + 5}"),
    (lambda w: w.appcast().split(b"<!--")[0], "no feed signature"),
])
def test_appcast_problems_are_named(cfg, w, run, make, needle):
    web = FakeWeb(w, **{w.page("/appcast.xml"): rv.Fetched(200, {}, make(w))})
    got = failures(rv.check_once(expected(cfg, w), web, run))
    assert any(needle in f for f in got["appcast"]), got


def test_a_pkg_that_is_not_installer_signed_or_notarized_fails(cfg, w):
    run = runner(w=w, pkgutil_out="Apple Development: x", stapler=65, spctl=3)
    got = failures(rv.check_once(expected(cfg, w), FakeWeb(w), run))
    assert len(got["pkg"]) == 3
    assert f"not signed {cfg.installer_identity}" in got["pkg"][0]


def test_the_pkg_is_downloaded_through_the_sites_latest_redirect(cfg, w, run):
    web = FakeWeb(w)
    rv.check_once(expected(cfg, w), web, run)
    assert (w.page("/downloads/latest"), True) in web.calls


def test_a_downloaded_zip_with_the_wrong_bytes_fails(cfg, w, run):
    web = FakeWeb(w, **{w.zip_url: rv.Fetched(200, {}, b"tampered")})
    got = failures(rv.check_once(expected(cfg, w), web, run))
    assert "zip's sha256" in got["zip"][0]


# polling ------------------------------------------------------------------------


def test_polling_retries_until_the_site_catches_up(cfg, w, run):
    web = FakeWeb(w, **{w.page("/appcast.xml"): rv.Fetched(200, {}, w.appcast(version=OLD))})
    now = [0.0]
    slept = []

    def sleep(s):
        slept.append(s)
        now[0] += s
        if len(slept) == 2:
            web.routes[w.page("/appcast.xml")] = rv.Fetched(200, {}, w.appcast())

    checks = rv.poll_until_ready(expected(cfg, w), fetch=web, run=run, timeout=600, interval=30,
                                 sleep=sleep, clock=lambda: now[0], log=lambda _m: None)
    assert failures(checks) == {}
    assert slept == [30, 30]


def test_polling_gives_up_at_the_deadline(cfg, w, run):
    web = FakeWeb(w, **{w.page("/appcast.xml"): rv.Fetched(404, {}, b"")})
    now = [0.0]

    def sleep(s):
        now[0] += s

    checks = rv.poll_until_ready(expected(cfg, w), fetch=web, run=run, timeout=100, interval=30,
                                 sleep=sleep, clock=lambda: now[0], log=lambda _m: None)
    assert "appcast" in failures(checks)
    assert now[0] == 90


def test_a_wrong_downloaded_artifact_ends_the_wait_at_once(cfg, w):
    slept = []
    checks = rv.poll_until_ready(expected(cfg, w), fetch=FakeWeb(w), run=runner(w=w, stapler=65),
                                 timeout=900, interval=30, sleep=slept.append,
                                 log=lambda _m: None)
    assert "pkg" in failures(checks)
    assert slept == []


def test_a_download_that_does_not_answer_is_still_retried(cfg, w, run):
    web = FakeWeb(w, **{w.zip_url: rv.Fetched(503, {}, b"")})
    now = [0.0]

    def sleep(s):
        now[0] += s
        web.routes[w.zip_url] = rv.Fetched(200, {}, ZIP_BYTES)

    checks = rv.poll_until_ready(expected(cfg, w), fetch=web, run=run, timeout=900, interval=30,
                                 sleep=sleep, clock=lambda: now[0], log=lambda _m: None)
    assert failures(checks) == {}


def test_timeout_zero_checks_exactly_once(cfg, w, run):
    slept = []
    rv.poll_until_ready(expected(cfg, w),
                        fetch=FakeWeb(w, **{w.page("/appcast.xml"): rv.Fetched(404, {}, b"")}),
                        run=run, timeout=0, interval=30, sleep=slept.append, log=lambda _m: None)
    assert slept == []


# expected_for -------------------------------------------------------------------


def _provenance(cfg, record, root=None):
    out = (root or cfg.repo / "build/release") / VERSION
    out.mkdir(parents=True)
    (out / PROVENANCE).write_text(json.dumps(record))


def test_a_finished_runs_provenance_is_the_digest_reference(cfg, w):
    _provenance(cfg, {"version": VERSION, "build": BUILD, "notarized": True,
                      "pkg_sha256": PKG_SHA, "zip_sha256": ZIP_SHA})
    exp = rv.expected_for(cfg, None, w.site, FakeWeb(w))
    assert exp.cfg is cfg
    assert exp.sha256 == {"pkg": PKG_SHA, "zip": ZIP_SHA}
    assert exp.sha_source.endswith("provenance.json")


def test_provenance_is_read_from_the_artifacts_root(cfg, w, tmp_path):
    root = tmp_path / "elsewhere"
    _provenance(cfg, {"version": VERSION, "build": BUILD, "notarized": True,
                      "pkg_sha256": PKG_SHA, "zip_sha256": ZIP_SHA}, root)
    exp = rv.expected_for(cfg, VERSION, w.site, FakeWeb(w), artifacts_root=root)
    assert exp.sha256 == {"pkg": PKG_SHA, "zip": ZIP_SHA}


def test_an_unnotarized_runs_provenance_is_never_the_reference(cfg, w):
    _provenance(cfg, {"version": VERSION, "build": BUILD, "notarized": False,
                      "pkg_sha256": "d", "zip_sha256": "d"})
    exp = rv.expected_for(cfg, None, w.site, FakeWeb(w))
    assert exp.sha256 == {} and exp.sha_source == ""


def test_a_run_without_digests_falls_back_to_releases_json(cfg, w, run):
    _provenance(cfg, {"version": VERSION, "build": BUILD, "notarized": True})
    exp = rv.expected_for(cfg, None, w.site, FakeWeb(w))
    assert exp.sha256 == {} and exp.sha_source == ""
    assert failures(rv.check_once(exp, FakeWeb(w), run)) == {}


def test_another_version_takes_its_build_from_releases_json(cfg, w):
    exp = rv.expected_for(cfg, OLD, w.site, FakeWeb(w))
    assert (exp.version, exp.build) == (OLD, BUILD - 1 if BUILD > 1 else 0)


def test_an_unpublished_other_version_is_an_error(cfg, w):
    with pytest.raises(ValueError, match="lists no 1.0.1 "):
        rv.expected_for(cfg, "1.0.1", w.site, FakeWeb(w))


# run_verify ---------------------------------------------------------------------


def _verify(cfg, web, run, **kw):
    kw.setdefault("version", VERSION)
    kw.setdefault("site", None)
    return rv.run_verify(cfg, timeout=0, interval=30, as_json=kw.pop("as_json", True),
                         fetch=web, run=run, **kw)


def test_run_verify_reports_ready_as_json(cfg, w, run, capsys):
    rc = _verify(cfg, FakeWeb(w), run)
    out = json.loads(capsys.readouterr().out)
    assert rc == 0 and out["ready"] is True
    assert out["downloads_url"] == w.page("/downloads")
    assert out["site"] == cfg.site_origin
    assert out["pkg_url"] == w.pkg_url
    assert out["release_url"] == f"https://github.com/{cfg.github_repo}/releases/tag/v{VERSION}"
    assert set(out) == {"version", "build", "site", "ready", "reference", "checks",
                        "downloads_url", "pkg_url", "release_url"}


def test_run_verify_site_replaces_the_origin_and_keeps_the_routes(tmp_path, capsys):
    cfg = config(tmp_path, {"site": {"routes": {"downloads": "/dl", "latest": "/dl/latest",
                                                "appcast": "/appcast.xml"}}})
    w = World(cfg, downloads="/dl")
    staging = "https://staging.example.com"
    web = FakeWeb(w, **{
        f"{staging}/dl": rv.Fetched(200, {}, w.downloads_page()),
        f"{staging}/dl/latest": rv.Fetched(302, {"location": w.pkg_url}, b""),
        f"{staging}/appcast.xml": rv.Fetched(200, {}, w.appcast()),
    })
    rc = _verify(cfg, web, runner(w=w), site=staging + "/")
    out = json.loads(capsys.readouterr().out)
    assert rc == 0 and out["site"] == staging and out["downloads_url"] == f"{staging}/dl"
    assert all(not u.startswith(cfg.site_origin) for u, _ in web.calls)


def test_run_verify_exits_2_for_a_version_that_was_never_published(cfg, w, run):
    assert _verify(cfg, FakeWeb(w), run, version="1.0.1", as_json=False) == 2


def test_run_verify_exits_1_when_not_ready(cfg, w, run, capsys):
    web = FakeWeb(w, **{w.page("/appcast.xml"): rv.Fetched(404, {}, b"")})
    rc = _verify(cfg, web, run, version=None, as_json=False)
    assert rc == 1
    assert "✗ appcast" in capsys.readouterr().out


def test_run_verify_uses_the_injected_clock_and_sleep(cfg, w, run):
    web = FakeWeb(w, **{w.page("/appcast.xml"): rv.Fetched(404, {}, b"")})
    now = [0.0]
    slept = []

    def sleep(s):
        slept.append(s)
        now[0] += s

    rc = rv.run_verify(cfg, version=VERSION, site=None, timeout=70, interval=30, as_json=True,
                       fetch=web, run=run, sleep=sleep, monotonic=lambda: now[0])
    assert rc == 1 and slept == [30, 30]
