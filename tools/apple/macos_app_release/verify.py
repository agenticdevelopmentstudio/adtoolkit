"""Prove a published release is the build users actually get.

`publish` ends at `git push`; the website picks a release up on its own, from
raw.githubusercontent.com, behind a revalidation window. This starts where
publish stops and checks every hop a user's download or an installed app's
update takes, against the build that was just made:

    github     release v<version> exists, not a draft, pkg + zip attached
    feed       releases.json on the releases repo's branch lists it as latest
    cask       the Homebrew cask (cfg.cask_file, same repo -- it is the tap)
               installs this version's pkg by its sha256
    downloads  <site><routes.downloads> offers this version's pkg
    latest     <site><routes.latest> redirects to this version's pkg
    appcast    <site><routes.appcast> has this version + build as its newest
               item, a signed zip enclosure, and a signed feed
    pkg        the pkg the site hands out: right sha256, installer-identity
               signature, stapled notarization ticket, Gatekeeper accepts it
    zip        the zip the appcast hands out: right sha256

"The build that was just made" is <artifacts>/<version>/provenance.json when a
finished (notarized) run left one, so a pkg on the site that is a DIFFERENT
build of the same version still fails. Without it, releases.json's own digests
are the reference.

The whole set is retried every `interval` seconds until it passes or `timeout`
runs out. The two downloads run only once everything else passes, and a
downloaded artifact that is wrong ends the wait at once. Read-only: it fetches
and inspects, and never publishes, deploys or deletes.
"""
from __future__ import annotations

import http.client
import json
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

from .config import ReleaseConfig
from .shell import Runner, subprocess_runner
from .sparkle import SPARKLE_NS
from .state import PROVENANCE, sha256_of
from .versions import read_versions

SPARKLE = f"{{{SPARKLE_NS}}}"
DEFAULT_TIMEOUT = 900
DEFAULT_INTERVAL = 30
REDIRECTS = (301, 302, 303, 307, 308)


def raw_base(cfg: ReleaseConfig) -> str:
    return f"https://raw.githubusercontent.com/{cfg.github_repo}/{cfg.releases_branch}/"


@dataclass(frozen=True)
class Fetched:
    """One HTTP answer. A status of 0 means nothing answered."""
    status: int
    headers: dict[str, str]
    body: bytes


# (url, follow_redirects) -> Fetched
Fetch = Callable[[str, bool], Fetched]


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def http_fetch(url: str, follow: bool) -> Fetched:
    opener = urllib.request.build_opener(*([] if follow else [_NoRedirect()]))
    request = urllib.request.Request(url, headers={
        "User-Agent": "macos-app-release-verify",
        "Cache-Control": "no-cache",
    })
    try:
        with opener.open(request, timeout=120) as res:
            return Fetched(res.status, {k.lower(): v for k, v in res.headers.items()},
                           res.read())
    except urllib.error.HTTPError as exc:
        return Fetched(exc.code, {k.lower(): v for k, v in (exc.headers or {}).items()},
                       exc.read() or b"")
    except (urllib.error.URLError, http.client.HTTPException, TimeoutError, OSError):
        # A dropped connection mid-body (IncompleteRead) is one more miss to
        # retry, not a reason to abandon the poll.
        return Fetched(0, {}, b"")


def tool_runner(run: Runner) -> Runner:
    """`run`, but a missing tool (gh, xcrun, ...) is a failed command the check
    names rather than a traceback that ends the poll."""
    def safe(argv: list[str]) -> subprocess.CompletedProcess[str]:
        try:
            return run(argv)
        except FileNotFoundError:
            return subprocess.CompletedProcess(argv, 127, "", f"{argv[0]}: command not found")
    return safe


@dataclass
class Expected:
    """What the published release must match."""
    cfg: ReleaseConfig
    version: str
    build: int
    site: str
    # sha256 by asset kind ("pkg", "zip"), and where those digests came from.
    sha256: dict[str, str] = field(default_factory=dict)
    sha_source: str = ""

    @property
    def tag(self) -> str:
        return f"v{self.version}"

    def asset_name(self, kind: str) -> str:
        return f"{self.cfg.app_name}-{self.version}.{kind}"

    def asset_url(self, kind: str) -> str:
        return f"{self.cfg.download_prefix}/{self.tag}/{self.asset_name(kind)}"

    def page(self, path: str) -> str:
        return urllib.parse.urljoin(self.site, path)

    def route(self, name: str) -> str:
        """The absolute URL of one of the site's release routes."""
        return self.page(self.cfg.site_routes[name])


@dataclass
class Check:
    name: str
    failures: list[str]
    # True when waiting cannot fix it: the artifact downloaded and is wrong
    # (digest, signature, ticket, Gatekeeper). Site lag is never final.
    final: bool = False

    @property
    def ok(self) -> bool:
        return not self.failures


def local_digests(out: Path, version: str, build: int) -> tuple[dict[str, str], str]:
    """The digests a real release run recorded, or ({}, why there are none)."""
    path = out / PROVENANCE
    try:
        record = json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}, f"no readable {path}"
    if not record.get("notarized"):
        return {}, f"{path} is of a run that never finished notarizing"
    if (record.get("version"), record.get("build")) != (version, build):
        return {}, f"{path} is for {record.get('version')} ({record.get('build')})"
    digests = {"pkg": record.get("pkg_sha256") or "", "zip": record.get("zip_sha256") or ""}
    if not all(digests.values()):
        return {}, f"{path} records no pkg/zip digests"
    return digests, str(path)


def published_entry(cfg: ReleaseConfig, fetch: Fetch, version: str) -> dict | None:
    """releases.json's entry for `version` on the releases repo's branch."""
    res = fetch(f"{raw_base(cfg)}releases.json", True)
    try:
        doc = json.loads(res.body) if res.status == 200 else {}
    except json.JSONDecodeError:
        return None
    return next((e for e in doc.get("releases", []) if e.get("version") == version), None)


def check_github(exp: Expected, run: Runner) -> Check:
    repo = exp.cfg.github_repo
    proc = run(["gh", "release", "view", exp.tag, "--repo", repo,
                "--json", "assets,isDraft,isPrerelease"])
    if proc.returncode != 0:
        why = (proc.stderr or proc.stdout or "").strip()
        return Check("github", [f"no GitHub release {exp.tag} on {repo} ({why})"])
    try:
        info = json.loads(proc.stdout or "{}")
    except json.JSONDecodeError as exc:
        return Check("github", [f"gh release view {exp.tag} returned unreadable JSON: {exc}"])
    failures: list[str] = []
    if info.get("isDraft"):
        failures.append(f"{exp.tag} is still a draft")
    if info.get("isPrerelease"):
        failures.append(f"{exp.tag} is marked a pre-release")
    assets = {a.get("name"): a for a in info.get("assets", [])}
    for kind in ("pkg", "zip"):
        asset = assets.get(exp.asset_name(kind))
        if asset is None:
            failures.append(f"{exp.asset_name(kind)} is not attached to {exp.tag}")
            continue
        digest, want = asset.get("digest"), exp.sha256.get(kind)
        if want and digest and digest != f"sha256:{want}":
            failures.append(f"{exp.asset_name(kind)} on GitHub is not the build in "
                            f"{exp.sha_source} ({digest})")
    return Check("github", failures)


def check_feed(exp: Expected, fetch: Fetch) -> Check:
    """releases.json and the notes on the releases repo -- the site's data."""
    base = raw_base(exp.cfg)
    url = f"{base}releases.json"
    res = fetch(url, True)
    if res.status != 200:
        return Check("feed", [f"{url} answered HTTP {res.status or 'nothing'}"])
    try:
        doc = json.loads(res.body)
    except json.JSONDecodeError as exc:
        return Check("feed", [f"{url} is not JSON: {exc}"])
    failures: list[str] = []
    if doc.get("latest") != exp.version:
        failures.append(f"releases.json's latest is {doc.get('latest')!r}, not {exp.version!r}")
    entry = next((e for e in doc.get("releases", []) if e.get("version") == exp.version), None)
    if entry is None:
        return Check("feed", failures + [f"releases.json has no {exp.version} entry"])
    if entry.get("build") != exp.build:
        failures.append(f"releases.json lists {exp.version} as build {entry.get('build')}, "
                        f"not {exp.build}")
    for kind in ("pkg", "zip"):
        asset = entry.get(kind) or {}
        if asset.get("url") != exp.asset_url(kind):
            failures.append(f"releases.json's {kind} url is {asset.get('url')!r}, "
                            f"not {exp.asset_url(kind)}")
        want = exp.sha256.get(kind)
        if want and asset.get("sha256") != want:
            failures.append(f"releases.json's {kind} sha256 is not the build in {exp.sha_source}")
    if not exp.sha256 and not failures:
        # No local record of the build: the published one is the reference.
        exp.sha256 = {k: (entry.get(k) or {}).get("sha256", "") for k in ("pkg", "zip")}
        exp.sha_source = "releases.json"
    notes = fetch(f"{base}notes/{exp.version}.md", True)
    if notes.status != 200:
        failures.append(f"notes/{exp.version}.md answered HTTP {notes.status or 'nothing'}")
    return Check("feed", failures)


def check_cask(exp: Expected, fetch: Fetch) -> Check:
    """The tap's cask -- what `brew install --cask <token>` installs."""
    url = f"{raw_base(exp.cfg)}{exp.cfg.cask_file}"
    res = fetch(url, True)
    if res.status != 200:
        return Check("cask", [f"{url} answered HTTP {res.status or 'nothing'}"])
    text = res.body.decode("utf-8", "replace")
    version = re.search(r'^\s*version "([^"]*)"', text, re.M)
    sha256 = re.search(r'^\s*sha256 "([^"]*)"', text, re.M)
    failures: list[str] = []
    if not version or version.group(1) != exp.version:
        failures.append(f"the cask's version is {version and version.group(1)!r}, "
                        f"not {exp.version!r}")
    want = exp.sha256.get("pkg")
    if want and (not sha256 or sha256.group(1) != want):
        failures.append(f"the cask's sha256 is not the pkg in {exp.sha_source}")
    return Check("cask", failures)


def check_downloads(exp: Expected, fetch: Fetch) -> Check:
    url = exp.route("downloads")
    res = fetch(url, True)
    if res.status != 200:
        return Check("downloads", [f"{url} answered HTTP {res.status or 'nothing'}"])
    # The page's copy is free to change (and React splits its text nodes), so
    # match links, not prose: the hero's download button comes before the
    # table of earlier versions, so the FIRST pkg link is the one offered.
    links = re.findall(rf'href="({re.escape(exp.cfg.download_prefix)}/[^"]+\.pkg)"',
                       res.body.decode("utf-8", "replace"))
    if not links:
        return Check("downloads", [f"{url} offers no pkg download"])
    if links[0] != exp.asset_url("pkg"):
        return Check("downloads", [f"{url} offers {links[0]}, not {exp.asset_url('pkg')}"])
    return Check("downloads", [])


def check_latest(exp: Expected, fetch: Fetch) -> Check:
    url = exp.route("latest")
    res = fetch(url, False)
    if res.status not in REDIRECTS:
        return Check("latest", [f"{url} answered HTTP {res.status or 'nothing'}, not a redirect"])
    location = res.headers.get("location", "")
    if location != exp.asset_url("pkg"):
        return Check("latest", [f"{url} redirects to {location or '(nothing)'}, "
                                f"not {exp.asset_url('pkg')}"])
    return Check("latest", [])


def check_appcast(exp: Expected, fetch: Fetch) -> Check:
    url = exp.route("appcast")
    res = fetch(url, True)
    if res.status != 200:
        return Check("appcast", [f"{url} answered HTTP {res.status or 'nothing'}"])
    try:
        root = ET.fromstring(res.body)
    except ET.ParseError as exc:
        return Check("appcast", [f"{url} is not XML: {exc}"])
    builds: list[int] = []
    mine = None
    for item in root.findall("./channel/item"):
        build = (item.findtext(f"{SPARKLE}version") or "").strip()
        if build.isdigit():
            builds.append(int(build))
        if (item.findtext(f"{SPARKLE}shortVersionString") or "").strip() == exp.version:
            mine = item
    if mine is None:
        return Check("appcast", [f"{url} has no item for {exp.version} yet"])
    failures: list[str] = []
    build = (mine.findtext(f"{SPARKLE}version") or "").strip()
    if build != str(exp.build):
        failures.append(f"the appcast's {exp.version} item is build {build or '?'}, not {exp.build}")
    if max(builds, default=exp.build) != exp.build:
        failures.append(f"the appcast's newest build is {max(builds)}, not {exp.build} -- "
                        "installed apps would not be offered this release")
    enclosure = mine.find("enclosure")
    if enclosure is None:
        failures.append(f"the appcast's {exp.version} item has no enclosure")
    else:
        if enclosure.get("url") != exp.asset_url("zip"):
            failures.append(f"the appcast's enclosure is {enclosure.get('url')}, "
                            f"not {exp.asset_url('zip')}")
        if not enclosure.get(f"{SPARKLE}edSignature"):
            failures.append("the appcast's enclosure carries no sparkle:edSignature -- "
                            "Sparkle would refuse the update")
    if b"sparkle-signatures:" not in res.body:
        failures.append("the appcast carries no feed signature (sparkle-signatures block) -- "
                        "a SURequireSignedFeed app would refuse it")
    return Check("appcast", failures)


def _download(url: str, fetch: Fetch, dest: Path) -> str | None:
    res = fetch(url, True)
    if res.status != 200:
        return f"{url} answered HTTP {res.status or 'nothing'}"
    dest.write_bytes(res.body)
    return None


def _digest_failure(path: Path, exp: Expected, kind: str) -> list[str]:
    got = sha256_of(path)
    if got == exp.sha256.get(kind):
        return []
    return [f"the downloaded {kind}'s sha256 {got} is not the build in {exp.sha_source}"]


def check_pkg(exp: Expected, fetch: Fetch, run: Runner, workdir: Path) -> Check:
    """The pkg a reader gets from the site, through the latest route -- the
    same redirect the page's stable link takes."""
    pkg = workdir / exp.asset_name("pkg")
    error = _download(exp.route("latest"), fetch, pkg)
    if error:
        return Check("pkg", [error])
    failures = _digest_failure(pkg, exp, "pkg")
    identity = exp.cfg.installer_identity
    signature = run(["pkgutil", "--check-signature", str(pkg)])
    if f"{identity}:" not in (signature.stdout or ""):
        failures.append(f"the pkg is not signed {identity} "
                        f"({(signature.stdout or signature.stderr or '').strip()[:200]})")
    for argv, what in (
        (["xcrun", "stapler", "validate", str(pkg)], "no stapled notarization ticket"),
        (["spctl", "--assess", "--type", "install", "-vv", str(pkg)], "Gatekeeper rejects it"),
    ):
        proc = run(argv)
        if proc.returncode != 0:
            failures.append(f"the pkg fails `{' '.join(argv[:3])}` -- {what} "
                            f"({(proc.stderr or proc.stdout or '').strip()[:200]})")
    return Check("pkg", failures, final=bool(failures))


def check_zip(exp: Expected, fetch: Fetch, workdir: Path) -> Check:
    """The zip installed apps get: the appcast's enclosure."""
    archive = workdir / exp.asset_name("zip")
    error = _download(exp.asset_url("zip"), fetch, archive)
    if error:
        return Check("zip", [error])
    failures = _digest_failure(archive, exp, "zip")
    return Check("zip", failures, final=bool(failures))


def check_once(exp: Expected, fetch: Fetch, run: Runner) -> list[Check]:
    # The feed runs first because, with no local record, it is what sets the
    # reference digests the github check compares the attached assets against.
    feed = check_feed(exp, fetch)
    checks = [check_github(exp, run), feed, check_cask(exp, fetch),
              check_downloads(exp, fetch), check_latest(exp, fetch), check_appcast(exp, fetch)]
    if all(c.ok for c in checks):
        with tempfile.TemporaryDirectory(prefix="release-verify-") as tmp:
            checks += [check_pkg(exp, fetch, run, Path(tmp)), check_zip(exp, fetch, Path(tmp))]
    return checks


def poll_until_ready(exp: Expected, *, fetch: Fetch, run: Runner, timeout: float,
                     interval: float, sleep: Callable[[float], None] = time.sleep,
                     clock: Callable[[], float] = time.monotonic,
                     log: Callable[[str], None] = print) -> list[Check]:
    """Re-run every check until all pass, one fails in a way waiting cannot fix
    (a downloaded artifact that is wrong), or the next attempt would pass the
    deadline; returns the last attempt's checks."""
    deadline = clock() + timeout
    attempt = 0
    while True:
        attempt += 1
        checks = check_once(exp, fetch, run)
        failing = [c.name for c in checks if not c.ok]
        if not failing or any(c.final for c in checks) or clock() + interval > deadline:
            return checks
        log(f"attempt {attempt}: waiting on {', '.join(failing)} -- retrying in {interval:g}s")
        sleep(interval)


def expected_for(cfg: ReleaseConfig, version: str | None, site: str, fetch: Fetch, *,
                 artifacts_root: Path | None = None) -> Expected:
    """The project's version + build with the local run's digests, or -- for
    another version -- the build releases.json published for it."""
    current, build = read_versions(cfg)
    if version in (None, current):
        exp = Expected(cfg=cfg, version=current, build=build, site=site)
        root = artifacts_root or cfg.repo / "build/release"
        exp.sha256, exp.sha_source = local_digests(root / current, current, build)
        if not exp.sha256:
            exp.sha_source = ""
        return exp
    entry = published_entry(cfg, fetch, version)
    if entry is None or not isinstance(entry.get("build"), int):
        raise ValueError(f"releases.json lists no {version} with a build number -- is it "
                         "published?")
    return Expected(cfg=cfg, version=version, build=entry["build"], site=site)


def run_verify(cfg: ReleaseConfig, *, version: str | None, site: str | None, timeout: float,
               interval: float, as_json: bool, fetch: Fetch = http_fetch,
               run: Runner | None = None, sleep: Callable[[float], None] = time.sleep,
               monotonic: Callable[[], float] = time.monotonic,
               artifacts_root: Path | None = None) -> int:
    """0 = ready, 1 = not ready, 2 = the version cannot be verified (never published)."""
    origin = (site or cfg.site_origin).rstrip("/")
    try:
        exp = expected_for(cfg, version, origin, fetch, artifacts_root=artifacts_root)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    log = (lambda _msg: None) if as_json else print
    log(f"Verifying {exp.version} (build {exp.build}) on {origin}; "
        f"reference: {exp.sha_source or 'releases.json'}")
    checks = poll_until_ready(exp, fetch=fetch, run=tool_runner(run or subprocess_runner(False)),
                              timeout=timeout, interval=interval, sleep=sleep, clock=monotonic,
                              log=log)
    ready = all(c.ok for c in checks)
    downloads = exp.route("downloads")
    if as_json:
        print(json.dumps({
            "version": exp.version, "build": exp.build, "site": origin, "ready": ready,
            "reference": exp.sha_source,
            "checks": [{"name": c.name, "ok": c.ok, "failures": c.failures} for c in checks],
            "downloads_url": downloads,
            "pkg_url": exp.asset_url("pkg"),
            "release_url": f"https://github.com/{cfg.github_repo}/releases/tag/{exp.tag}",
        }, indent=2))
        return 0 if ready else 1
    for c in checks:
        print(f"  {'✓' if c.ok else '✗'} {c.name}")
        for failure in c.failures:
            print(f"      {failure}")
    if ready:
        print(f"✓ {exp.version} (build {exp.build}) is live: {downloads}")
        return 0
    print(f"✗ {exp.version} is not ready", file=sys.stderr)
    return 1
