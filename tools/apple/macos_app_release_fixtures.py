"""Shared test fixtures for the macos_app_release package's tests.

A plain module that tests import (not a conftest), so no toolkit-wide conftest
changes. Nothing here touches a keychain, notarytool, GitHub, the network,
/Applications or a real process: every external command goes through FakeRunner.

Layout of a fixture world under `tmp_path`:

    tmp_path/repo/                 the app repo: release.json + every file it points at
    tmp_path/home/                 the HOME the config resolves `~` against
    tmp_path/<releases repo name>/ the releases checkout (config default, beside the repo)
    tmp_path/dd/                   DerivedData, with Sparkle's generate_keys in place
    tmp_path/releases-repo/        the fake releases checkout `release()` passes in
"""
from __future__ import annotations

import copy
import json
import plistlib
import subprocess
from pathlib import Path
from typing import Any, Iterable

import macos_release as mr
from macos_app_release import config as _config
from macos_app_release.config import ReleaseConfig
from macos_app_release.shell import Runner
from macos_app_release.state import SPARKLE_BIN_REL, Release

VERSION = "1.0.154"
BUILD = 1
SOURCE_SHA = "a" * 40
ZIP_SIGNATURE = "c2lnbmF0dXJl"
SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"

# Every sample cask template variable, so a render exercises the whole set.
CASK_TEMPLATE = '''\
cask "$token" do
  version "$version"
  sha256 "$sha256"

  url "$url"
  name "$name"
  homepage "$homepage"

  livecheck do
    url "$feed"
    strategy :sparkle
  end

  auto_updates true
  depends_on macos: $macos

  pkg "$pkg"

  uninstall quit:    "$bundle_id",
            pkgutil: "$bundle_id"
end
'''

# The spec's minimal example: required keys only, plus app.title.
ADKITCHEN: dict[str, Any] = {
    "schema": 1,
    "app": {
        "name": "AgenticDeveloperKitchen",
        "bundle_id": "com.agenticdevelopmentstudio.agenticdeveloperkitchen",
        "title": "Agentic Developer Kitchen",
    },
    "version": {"project_yml": "App/project.yml"},
    "build": {
        "command": ["python3", "Scripts/release_build.py"],
        "resolve": {"workspace": "AgenticDeveloperKitchen.xcworkspace",
                    "scheme": "AgenticDeveloperKitchen"},
    },
    "signing": {
        "notary_profile": "adkitchen-notary",
        "entitlements": {".": "App/Sources/Resources/App.entitlements"},
    },
    "sparkle": {
        "account": "adkitchen",
        "feed_url": "https://kitchen.agenticdevelopmentstudio.com/appcast.xml",
        "public_key_setting": "ADKITCHEN_SPARKLE_PUBLIC_KEY",
    },
    "releases": {"github_repo": "agenticdevelopmentstudio/adkitchen-releases"},
    "cask": {"token": "adkitchen", "template": "release/cask.rb.template"},
    "hooks": {
        "tests": ["python3", "Scripts/dev.py", "test"],
        "warnings_build": ["python3", "Scripts/release_warnings_build.py"],
    },
    "warnings_allowlist": "release/warnings-allowlist.json",
}

_STENO_BUNDLE = "com.agenticdevelopmentstudio.stenographer"
_STENO_WIDGET = "Contents/PlugIns/StenographerUsageWidget.appex"
_SPARKLE_B = "Contents/Frameworks/Sparkle.framework/Versions/B"
_HELPER = "Apple/Stenographer/installer/helper.entitlements"

# Every optional key set, shaped like Stenographer's own release.json would be.
STENOGRAPHER: dict[str, Any] = {
    "schema": 1,
    "app": {"name": "Stenographer", "bundle_id": _STENO_BUNDLE, "title": "Stenographer"},
    "version": {
        "project_yml": "Apple/Stenographer/project.yml",
        "marketing_setting": "MARKETING_VERSION",
        "build_setting": "CURRENT_PROJECT_VERSION",
        "must_match": [{
            "file": "Apple/Stenographer/stenographerd/Sources/HTTP/StenographerRouter.swift",
            "pattern": 'daemonVersion\\s*=\\s*"([^"]+)"',
        }],
        "nested_bundles": [_STENO_WIDGET],
        "regenerate": ["xcodegen", "generate", "--spec", "Apple/Stenographer/project.yml"],
    },
    "build": {
        "command": ["python3", "Scripts/release_build.py"],
        "derived_data": "~/Library/Developer/Xcode/DerivedData/stenographer-release",
        "resolve": {"workspace": "Apple/Stenographer.xcworkspace", "scheme": "Stenographer"},
        "expect_info": {"AgenticReleaseChannel": "release"},
    },
    "layout": {
        "required": ["Contents/MacOS/Stenographer", "Contents/MacOS/stenographerd",
                     "Contents/Info.plist"],
        "forbidden": ["Contents/PlugIns/Debug.aiplugin"],
        "required_globs": ["Contents/PlugIns/*.aiplugin"],
    },
    "checks": [{"name": "daemon-executable",
                "command": ["test", "-x", "Contents/MacOS/stenographerd"]}],
    "signing": {
        "app_identity": "Developer ID Application",
        "installer_identity": "Developer ID Installer",
        "notary_profile": "stenographer-notary",
        "entitlements": {
            ".": "Apple/Stenographer/Stenographer/Stenographer.entitlements",
            "Contents/MacOS/stenographerd": "Apple/Stenographer/stenographerd/stenographerd.entitlements",
            _STENO_WIDGET: "Apple/Stenographer/StenographerUsageWidget/StenographerUsageWidget.entitlements",
            "Contents/Helpers/steno": _HELPER,
            f"{_SPARKLE_B}/Autoupdate": _HELPER,
        },
        "profiles": [
            {"bundle": ".", "env": "STENOGRAPHER_DEVID_PROFILE_APP",
             "bundle_id": _STENO_BUNDLE, "required": True},
            {"bundle": _STENO_WIDGET, "env": "STENOGRAPHER_DEVID_PROFILE_WIDGET",
             "bundle_id": f"{_STENO_BUNDLE}.usagewidget", "required": False},
        ],
    },
    "sparkle": {
        "account": "stenographer",
        "feed_url": "https://agenticstenographer.app/appcast.xml",
        "public_key_setting": "STENOGRAPHER_SPARKLE_PUBLIC_KEY",
    },
    "releases": {"github_repo": "agenticdevelopmentstudio/stenographer-releases",
                 "checkout": "~/stenographer-releases", "branch": "main"},
    "source": {"branch": "main", "tag_prefix": "release/"},
    "site": {"routes": {"downloads": "/downloads", "latest": "/downloads/latest",
                        "appcast": "/appcast.xml"}},
    "notes_dir": "docs/release-notes",
    "cask": {"token": "stenographer", "template": "release/cask.rb.template"},
    "pkg": {"must_close": [f"{_STENO_BUNDLE}.menubar"],
            "scripts": "Apple/Stenographer/installer/scripts"},
    "install": {"apps_dir": "~/Applications"},
    "hooks": {
        "tests": ["python3", "scripts/run_all_tests.py"],
        "warnings_build": ["python3", "scripts/release_warnings_build.py"],
        "health": ["python3", "scripts/install_health.py", "--release"],
    },
    "warnings_allowlist": "scripts/build_warnings_allowlist.json",
    "toolkit": "external/agenticdevelopertoolkit",
    "env_file": "~/.local-env/stenographer.env",
}

FLAVORS: dict[str, dict[str, Any]] = {"adkitchen": ADKITCHEN, "stenographer": STENOGRAPHER}


class FakeRunner:
    """Records argv; answers by the first matching entry in `responses`,
    each `(match, returncode, stdout[, stderr])`."""

    def __init__(self, responses=None):
        self.calls: list[list[str]] = []
        self.responses = responses or []

    def __call__(self, argv):
        self.calls.append(list(argv))
        for match, rc, out, *err in self.responses:
            if match(argv):
                return subprocess.CompletedProcess(argv, rc, out, err[0] if err else "")
        return subprocess.CompletedProcess(argv, 0, "", "")

    def find(self, *prefix):
        return [c for c in self.calls if c[:len(prefix)] == list(prefix)]


# release.json -------------------------------------------------------------------


def deep_merge(base: dict, over: dict) -> dict:
    """Deep-merge `over` into a copy of `base`. A None value deletes the key; a
    non-dict value (list, str, ...) replaces."""
    out = copy.deepcopy(base)
    for key, value in over.items():
        if value is None:
            out.pop(key, None)
        elif isinstance(value, dict) and isinstance(out.get(key), dict):
            out[key] = deep_merge(out[key], value)
        else:
            out[key] = copy.deepcopy(value)
    return out


def _dig(data: Any, *keys: str) -> Any:
    for key in keys:
        if not isinstance(data, dict):
            return None
        data = data.get(key)
    return data


def _replace_paths(replace: Iterable) -> list[tuple[str, ...]]:
    """`replace` is one key path (("signing", "entitlements")) or a list of them."""
    items = list(replace)
    if items and isinstance(items[0], str):
        return [tuple(items)]
    return [tuple(p) for p in items]


def _relative(value: Any) -> Path | None:
    """A repo-relative path from a config string, or None for `~`/absolute/bad values."""
    if not isinstance(value, str) or not value or value.startswith(("/", "~")):
        return None
    return Path(value)


def _put(path: Path, content: str, *, overwrite: bool = False) -> None:
    if overwrite or not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)


def write_config(repo: Path, overrides: dict | None = None, *, flavor: str = "adkitchen",
                 replace: Iterable = (), public_key: str = "", notes: bool = True) -> Path:
    """Write repo/release.json (the flavor, deep-merged with `overrides`) and every
    file it points at; return the release.json path.

    `overrides`: a None value deletes that key. `replace`: a key path whose override
    value replaces the base value instead of merging into it (e.g.
    ``replace=("signing", "entitlements")``); several paths may be given as a list.
    `public_key` is the value written for the Sparkle public-key setting; `notes`
    writes the release notes for VERSION.
    """
    overrides = overrides or {}
    data = deep_merge(FLAVORS[flavor], overrides)
    for path in _replace_paths(replace):
        value = _dig(overrides, *path)
        node = data
        for key in path[:-1]:
            node = node.setdefault(key, {})
        node[path[-1]] = copy.deepcopy(value)

    repo.mkdir(parents=True, exist_ok=True)
    marketing = _dig(data, "version", "marketing_setting") or "MARKETING_VERSION"
    build = _dig(data, "version", "build_setting") or "CURRENT_PROJECT_VERSION"
    key_setting = _dig(data, "sparkle", "public_key_setting")

    yml = _relative(_dig(data, "version", "project_yml"))
    if yml:
        lines = ["settings:", "  base:", f'    {marketing}: "{VERSION}"',
                 f'    {build}: "{BUILD}"']
        if isinstance(key_setting, str):
            lines.append(f'    {key_setting}: "{public_key}"')
        _put(repo / yml, "\n".join(lines) + "\n", overwrite=True)

    must_match = _dig(data, "version", "must_match")
    for entry in must_match if isinstance(must_match, list) else []:
        path = _relative(entry.get("file") if isinstance(entry, dict) else None)
        if path:
            _put(repo / path, f'public static let daemonVersion = "{VERSION}"\n')

    entitlements = _dig(data, "signing", "entitlements")
    for value in entitlements.values() if isinstance(entitlements, dict) else []:
        path = _relative(value)
        if path:
            _put(repo / path, plistlib.dumps({}).decode())

    template = _relative(_dig(data, "cask", "template"))
    if template:
        _put(repo / template, CASK_TEMPLATE)
    allowlist = _relative(data.get("warnings_allowlist"))
    if allowlist:
        _put(repo / allowlist, json.dumps({"allowed": []}, indent=2) + "\n")
    scripts = _relative(_dig(data, "pkg", "scripts"))
    if scripts:
        _put(repo / scripts / "preinstall", "#!/bin/sh\nexit 0\n")
    if notes:
        notes_dir = _relative(data.get("notes_dir")) or Path("docs/release-notes")
        _put(repo / notes_dir / f"{VERSION}.md", f"# {VERSION}\n\n- First release.\n")

    out = repo / _config.CONFIG_FILE
    out.write_text(json.dumps(data, indent=2) + "\n")
    return out


def config(tmp_path: Path, overrides: dict | None = None, *, flavor: str = "adkitchen",
           **write_kw: Any) -> ReleaseConfig:
    """write_config under tmp_path/repo, then load it (home=tmp_path/home, env={},
    main_checkout=the repo)."""
    repo = tmp_path / "repo"
    write_config(repo, overrides, flavor=flavor, **write_kw)
    return _config.load_config(repo, main_checkout=repo, env={}, home=tmp_path / "home")


# Release ------------------------------------------------------------------------


def fake_releases_repo(path: Path, existing: dict | None = None) -> Path:
    """A releases checkout: .git, notes/, and a releases.json."""
    (path / ".git").mkdir(parents=True, exist_ok=True)
    (path / "notes").mkdir(exist_ok=True)
    (path / "releases.json").write_text(json.dumps(
        existing or {"schema": 1, "latest": None, "releases": []}))
    return path


def release(tmp_path: Path, runner: Runner, *, overrides: dict | None = None,
            flavor: str = "adkitchen", public_key: str = "", notes: bool = True,
            version: str = VERSION, build_number: int = BUILD, env: dict | None = None,
            **release_kw: Any) -> Release:
    """A Release over a fixture repo: DerivedData at tmp_path/dd with Sparkle's
    generate_keys present, a fake releases checkout at tmp_path/releases-repo, and
    env={} (not os.environ). Extra keyword arguments go to Release."""
    cfg = config(tmp_path, overrides, flavor=flavor, public_key=public_key, notes=notes)
    derived = tmp_path / "dd"
    (derived / SPARKLE_BIN_REL).mkdir(parents=True, exist_ok=True)
    (derived / SPARKLE_BIN_REL / "generate_keys").write_text("")
    release_kw.setdefault("releases_repo", fake_releases_repo(tmp_path / "releases-repo"))
    release_kw.setdefault("derived_data", derived)
    return Release(cfg=cfg, version=version, build_number=build_number, run=runner,
                   env=env if env is not None else {}, **release_kw)


def new_appcast(r: Release) -> str:
    """What a generate_appcast run over this release leaves behind: one item whose
    enclosure is EdDSA-signed."""
    url = f"{r.cfg.download_prefix}/v{r.version}/{r.zip_path.name}"
    return ('<?xml version="1.0" standalone="yes"?>'
            f'<rss xmlns:sparkle="{SPARKLE_NS}" version="2.0"><channel><item>'
            f'<enclosure url="{url}" sparkle:edSignature="{ZIP_SIGNATURE}" length="9"/>'
            '</item></channel></rss>')


def with_artifacts(r: Release, *, appcast: bool = True) -> Release:
    """Write the pkg and zip (and the appcast) a build would leave in r.out."""
    r.out.mkdir(parents=True, exist_ok=True)
    r.pkg_path.write_bytes(b"pkg-bytes")
    r.zip_path.write_bytes(b"zip-bytes")
    r.minimum_system_version = "26.0"
    if appcast:
        r.appcast_path.parent.mkdir(parents=True, exist_ok=True)
        r.appcast_path.write_text(new_appcast(r))
    return r


def entry(cfg: ReleaseConfig, *, minimum: str = "26.0", version: str = VERSION,
          build: int = BUILD) -> mr.ReleaseEntry:
    """The releases.json entry for `version`, with assets whose URLs follow the
    config's download prefix (no files are read)."""
    def asset(suffix: str, sha: str) -> mr.ReleaseAsset:
        name = f"{cfg.asset_basename}-{version}.{suffix}"
        return mr.ReleaseAsset(url=f"{cfg.download_prefix}/v{version}/{name}", size=9,
                               sha256=sha)

    return mr.ReleaseEntry(version=version, build=build, date="2026-10-16T00:00:00Z",
                           minimum_system_version=minimum, notes=f"notes/{version}.md",
                           pkg=asset("pkg", "p" * 64), zip=asset("zip", "z" * 64))


_BUNDLE_SUFFIXES = (".app", ".appex", ".framework", ".xpc", ".aiplugin")


def make_app(r: Release, **info: Any) -> Path:
    """Write a layout-correct bundle at r.app with a matching Info.plist; return it.

    It satisfies `layout.problems`, `bundle_info_problems`, `entitlements_map` and every
    configured nested bundle. `info` keys override or (None) delete Info.plist entries.
    """
    cfg, app = r.cfg, r.app
    app.mkdir(parents=True, exist_ok=True)

    def place(rel: str) -> None:
        target = app / rel
        if target.exists():
            return
        if rel.endswith(_BUNDLE_SUFFIXES):
            target.mkdir(parents=True)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("")

    for rel in (*cfg.layout_required, *cfg.entitlements, *cfg.nested_bundles):
        if rel != ".":
            place(rel)
    for pattern in cfg.layout_required_globs:
        place(pattern.replace("*", "x"))
    for rel in cfg.nested_bundles:
        nested = app / rel / "Contents/Info.plist"
        nested.parent.mkdir(parents=True, exist_ok=True)
        nested.write_bytes(plistlib.dumps({"CFBundleShortVersionString": r.version,
                                           "CFBundleVersion": str(r.build_number)}))

    values: dict[str, Any] = {
        "CFBundleShortVersionString": r.version,
        "CFBundleVersion": str(r.build_number),
        "LSMinimumSystemVersion": "26.0",
        "SUFeedURL": cfg.feed_url,
        "SUPublicEDKey": "abc=",
        **cfg.expect_info,
    }
    for key, value in info.items():
        if value is None:
            values.pop(key, None)
        else:
            values[key] = value
    plist = app / "Contents/Info.plist"
    plist.parent.mkdir(parents=True, exist_ok=True)
    plist.write_bytes(plistlib.dumps(values))
    return app
