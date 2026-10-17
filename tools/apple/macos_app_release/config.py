"""release.json -> a frozen ReleaseConfig.

Every fact about an app that Stenographer kept as a module constant lives in the
app's release.json. Loading validates the whole file and reports *every* problem at
once (a typo'd key, a missing required key, a bad regex) in one ConfigError; nothing
falls back to a default silently. Paths resolve against the repo root, `~` against
the home directory, and `/...` stay absolute -- never against the cwd.

`ConfigError` and `Profile` are the contract names later modules import; they are
aliases of the release-specific classes below so the classes themselves do not
collide with unrelated `ConfigError`/`Profile` types elsewhere in the toolkit.
"""
from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping
from urllib.parse import urlparse

CONFIG_FILE = "release.json"

DEFAULT_ROUTES = {"downloads": "/downloads", "latest": "/downloads/latest",
                  "appcast": "/appcast.xml"}
RELEASES_CHECKOUT_ENV = "RELEASE_RELEASES_CHECKOUT"


class ReleaseConfigError(Exception):
    """release.json is missing, unreadable or wrong; `problems` lists every one."""

    def __init__(self, problems: list[str]) -> None:
        self.problems = list(problems)
        super().__init__("\n".join(self.problems))


@dataclass(frozen=True)
class MustMatch:
    file: Path      # absolute
    pattern: str    # exactly one group


@dataclass(frozen=True)
class ReleaseProfile:
    bundle: str
    env: str
    bundle_id: str
    required: bool


@dataclass(frozen=True)
class BundleCheck:
    name: str
    command: tuple[str, ...]


ConfigError = ReleaseConfigError
Profile = ReleaseProfile


@dataclass(frozen=True)
class ReleaseConfig:
    repo: Path
    main_checkout: Path
    app_name: str
    bundle_id: str
    title: str
    project_yml: Path
    marketing_setting: str
    build_setting: str
    must_match: tuple[MustMatch, ...]
    nested_bundles: tuple[str, ...]
    regenerate: tuple[str, ...] | None
    build_command: tuple[str, ...]
    derived_data: Path
    resolve_kind: str            # "workspace" | "project"
    resolve_path: Path
    resolve_scheme: str
    expect_info: Mapping[str, str]
    layout_required: tuple[str, ...]
    layout_forbidden: tuple[str, ...]
    layout_required_globs: tuple[str, ...]
    checks: tuple[BundleCheck, ...]
    app_identity: str
    installer_identity: str
    notary_profile: str
    entitlements: Mapping[str, Path]
    profiles: tuple[ReleaseProfile, ...]
    sparkle_account: str
    feed_url: str
    public_key_setting: str
    github_repo: str
    releases_checkout: Path
    releases_branch: str
    source_branch: str
    source_tag_prefix: str
    site_routes: Mapping[str, str]
    notes_dir: Path
    cask_token: str
    cask_template: Path
    pkg_must_close: tuple[str, ...]
    pkg_scripts: Path | None
    apps_dir: Path
    hook_tests: tuple[str, ...]
    hook_warnings_build: tuple[str, ...]
    hook_health: tuple[str, ...] | None
    warnings_allowlist: Path
    toolkit: Path
    env_file: Path | None

    @property
    def site_origin(self) -> str:
        u = urlparse(self.feed_url)
        return f"{u.scheme}://{u.netloc}"

    @property
    def asset_basename(self) -> str:
        """The pkg and zip name: app.name with each run of whitespace a hyphen. It is a
        URL path segment, and GitHub rewrites a space in an asset name to a dot."""
        return "-".join(self.app_name.split())

    @property
    def download_prefix(self) -> str:
        return f"https://github.com/{self.github_repo}/releases/download"

    @property
    def cask_file(self) -> str:
        return f"Casks/{self.cask_token}.rb"

    def notes_path(self, version: str) -> Path:
        return self.notes_dir / f"{version}.md"

    def source_tag(self, version: str) -> str:
        return f"{self.source_tag_prefix}{version}"


# Schema ------------------------------------------------------------------------
# key -> (required, kind). Kinds are checked by _KINDS below.

_TOP: dict[str, tuple[bool, str]] = {
    "schema": (True, "schema"),
    "checks": (False, "checks"),
    "notes_dir": (False, "path"),
    "warnings_allowlist": (True, "path"),
    "toolkit": (False, "path"),
    "env_file": (False, "path"),
}

_SECTIONS: dict[str, dict[str, tuple[bool, str]]] = {
    "app": {"name": (True, "str"), "bundle_id": (True, "str"), "title": (False, "str")},
    "version": {"project_yml": (True, "path"), "marketing_setting": (False, "str"),
                "build_setting": (False, "str"), "must_match": (False, "must_match"),
                "nested_bundles": (False, "strlist"), "regenerate": (False, "argv")},
    "build": {"command": (True, "argv"), "derived_data": (False, "path"),
              "resolve": (True, "resolve"), "expect_info": (False, "strmap")},
    "layout": {"required": (False, "strlist"), "forbidden": (False, "strlist"),
               "required_globs": (False, "strlist")},
    "signing": {"app_identity": (False, "str"), "installer_identity": (False, "str"),
                "notary_profile": (True, "str"), "entitlements": (True, "entitlements"),
                "profiles": (False, "profiles")},
    "sparkle": {"account": (True, "str"), "feed_url": (True, "feed"),
                "public_key_setting": (True, "str")},
    "releases": {"github_repo": (True, "str"), "checkout": (False, "path"),
                 "branch": (False, "str")},
    "source": {"branch": (False, "str"), "tag_prefix": (False, "str")},
    "site": {"routes": (False, "routes")},
    "cask": {"token": (True, "str"), "template": (True, "path")},
    "pkg": {"must_close": (False, "strlist"), "scripts": (False, "path")},
    "install": {"apps_dir": (False, "path")},
    "hooks": {"tests": (True, "argv"), "warnings_build": (True, "argv"),
              "health": (False, "argv")},
}


def _is_str(v: Any) -> bool:
    return isinstance(v, str) and bool(v.strip())


def _unknown(obj: dict, allowed: set[str], where: str) -> list[str]:
    prefix = f"{where}." if where else ""
    return [f"{prefix}{k}: unknown key" for k in obj if k not in allowed]


def _k_str(v: Any, w: str) -> list[str]:
    return [] if _is_str(v) else [f"{w}: must be a non-empty string"]


def _k_strlist(v: Any, w: str) -> list[str]:
    if isinstance(v, list) and all(_is_str(x) for x in v):
        return []
    return [f"{w}: must be a list of non-empty strings"]


def _k_argv(v: Any, w: str) -> list[str]:
    if isinstance(v, list) and v and all(_is_str(x) for x in v):
        return []
    return [f"{w}: must be a non-empty list of strings (an argv)"]


def _k_strmap(v: Any, w: str) -> list[str]:
    if isinstance(v, dict) and all(_is_str(k) and isinstance(x, str) for k, x in v.items()):
        return []
    return [f"{w}: must be an object of string keys to string values"]


def _k_schema(v: Any, w: str) -> list[str]:
    return [] if v == 1 and not isinstance(v, bool) else [f"{w}: must be 1 (got {v!r})"]


def _k_feed(v: Any, w: str) -> list[str]:
    if _is_str(v):
        u = urlparse(v)
        if u.scheme == "https" and u.netloc:
            return []
    return [f"{w}: must be an https URL with a host (got {v!r})"]


def _k_resolve(v: Any, w: str) -> list[str]:
    if not isinstance(v, dict):
        return [f"{w}: must be an object with workspace or project, and scheme"]
    out = _unknown(v, {"workspace", "project", "scheme"}, w)
    present = [k for k in ("workspace", "project") if v.get(k) is not None]
    if len(present) != 1:
        out.append(f"{w}: needs exactly one of workspace or project")
    out.extend(f"{w}.{k}: must be a non-empty string" for k in present if not _is_str(v[k]))
    if not _is_str(v.get("scheme")):
        out.append(f"{w}.scheme: required, a non-empty string")
    return out


def _k_entitlements(v: Any, w: str) -> list[str]:
    if not isinstance(v, dict) or not v or not all(_is_str(k) and _is_str(x) for k, x in v.items()):
        return [f"{w}: must be a non-empty object of bundle-relative path to file"]
    return [] if "." in v else [f'{w}: must include "." (the app itself)']


def _k_bool(v: Any, w: str) -> list[str]:
    return [] if isinstance(v, bool) else [f"{w}: must be true or false"]


def _k_pattern(v: Any, w: str) -> list[str]:
    if not _is_str(v):
        return [f"{w}: must be a non-empty string"]
    try:
        groups = re.compile(v).groups
    except re.error as exc:
        return [f"{w}: not a valid regex ({exc})"]
    return [] if groups == 1 else [f"{w}: must have exactly one capture group (has {groups})"]


def _items(v: Any, w: str, keys: dict[str, Any]) -> list[str]:
    """Validate a list of objects, each key checked by the callable in `keys`."""
    if not isinstance(v, list):
        return [f"{w}: must be a list"]
    out: list[str] = []
    for i, item in enumerate(v):
        where = f"{w}[{i}]"
        if not isinstance(item, dict):
            out.append(f"{where}: must be an object")
            continue
        out.extend(_unknown(item, set(keys), where))
        for key, check in keys.items():
            if item.get(key) is None:
                out.append(f"{where}.{key}: required")
            else:
                out.extend(check(item[key], f"{where}.{key}"))
    return out


def _k_must_match(v: Any, w: str) -> list[str]:
    return _items(v, w, {"file": _k_str, "pattern": _k_pattern})


def _k_profiles(v: Any, w: str) -> list[str]:
    return _items(v, w, {"bundle": _k_str, "env": _k_str, "bundle_id": _k_str,
                         "required": _k_bool})


def _k_checks(v: Any, w: str) -> list[str]:
    return _items(v, w, {"name": _k_str, "command": _k_argv})


def _k_routes(v: Any, w: str) -> list[str]:
    if not isinstance(v, dict) or set(v) != set(DEFAULT_ROUTES):
        return [f"{w}: must have exactly the keys {', '.join(DEFAULT_ROUTES)}"]
    return [f"{w}.{k}: must be a path starting with /" for k, x in v.items()
            if not (_is_str(x) and x.startswith("/"))]


_KINDS = {"str": _k_str, "path": _k_str, "strlist": _k_strlist, "argv": _k_argv,
          "strmap": _k_strmap, "schema": _k_schema, "feed": _k_feed, "resolve": _k_resolve,
          "entitlements": _k_entitlements, "must_match": _k_must_match,
          "profiles": _k_profiles, "checks": _k_checks, "routes": _k_routes}


def _validate(data: dict) -> list[str]:
    problems = _unknown(data, set(_TOP) | set(_SECTIONS), "")

    def walk(obj: dict, spec: dict[str, tuple[bool, str]], where: str) -> None:
        prefix = f"{where}." if where else ""
        for key, (required, kind) in spec.items():
            value = obj.get(key)
            if value is None:
                if required:
                    problems.append(f"{prefix}{key}: required")
                continue
            problems.extend(_KINDS[kind](value, f"{prefix}{key}"))

    walk(data, _TOP, "")
    for name, spec in _SECTIONS.items():
        raw = data.get(name)
        if raw is None:
            raw = {}
        if not isinstance(raw, dict):
            problems.append(f"{name}: must be an object")
            continue
        problems.extend(_unknown(raw, set(spec), name))
        walk(raw, spec, name)
    return problems


# Loading -----------------------------------------------------------------------


def _resolve(value: str, repo: Path, home: Path) -> Path:
    if value == "~":
        return home
    if value.startswith("~/"):
        return home / value[2:]
    if value.startswith("/"):
        return Path(value)
    return repo / value


def _dedupe(items: list[str]) -> tuple[str, ...]:
    return tuple(dict.fromkeys(items))


def _argv_or_none(value: list[str] | None) -> tuple[str, ...] | None:
    return tuple(value) if value else None


def parse_config(data: dict, *, repo: Path, main_checkout: Path,
                 env: Mapping[str, str], home: Path) -> ReleaseConfig:
    if not isinstance(data, dict):
        raise ReleaseConfigError([f"{CONFIG_FILE}: the top level must be an object"])
    problems = _validate(data)
    if problems:
        raise ReleaseConfigError(problems)

    def sec(name: str) -> dict:
        return data.get(name) or {}

    def path(value: str) -> Path:
        return _resolve(value, repo, home)

    app, ver, bld = sec("app"), sec("version"), sec("build")
    lay, sign, spk = sec("layout"), sec("signing"), sec("sparkle")
    rel, src, site = sec("releases"), sec("source"), sec("site")
    cask, pkg, inst, hooks = sec("cask"), sec("pkg"), sec("install"), sec("hooks")

    if rel.get("checkout"):
        checkout = path(rel["checkout"])
    elif env.get(RELEASES_CHECKOUT_ENV):
        checkout = path(env[RELEASES_CHECKOUT_ENV])
    else:
        checkout = main_checkout.parent / rel["github_repo"].rsplit("/", 1)[-1]

    derived = (path(bld["derived_data"]) if bld.get("derived_data") else
               home / "Library/Developer/Xcode/DerivedData" / f"{cask['token']}-release")
    resolve = bld["resolve"]
    kind = "workspace" if resolve.get("workspace") else "project"

    return ReleaseConfig(
        repo=repo, main_checkout=main_checkout,
        app_name=app["name"], bundle_id=app["bundle_id"], title=app.get("title") or app["name"],
        project_yml=path(ver["project_yml"]),
        marketing_setting=ver.get("marketing_setting") or "MARKETING_VERSION",
        build_setting=ver.get("build_setting") or "CURRENT_PROJECT_VERSION",
        must_match=tuple(MustMatch(path(m["file"]), m["pattern"])
                         for m in ver.get("must_match") or []),
        nested_bundles=tuple(ver.get("nested_bundles") or ()),
        regenerate=_argv_or_none(ver.get("regenerate")),
        build_command=tuple(bld["command"]), derived_data=derived,
        resolve_kind=kind, resolve_path=path(resolve[kind]), resolve_scheme=resolve["scheme"],
        expect_info=dict(bld.get("expect_info") or {}),
        layout_required=tuple(lay.get("required") or ()),
        layout_forbidden=tuple(lay.get("forbidden") or ()),
        layout_required_globs=tuple(lay.get("required_globs") or ()),
        checks=tuple(BundleCheck(c["name"], tuple(c["command"]))
                     for c in data.get("checks") or []),
        app_identity=sign.get("app_identity") or "Developer ID Application",
        installer_identity=sign.get("installer_identity") or "Developer ID Installer",
        notary_profile=sign["notary_profile"],
        entitlements={k: path(v) for k, v in sign["entitlements"].items()},
        profiles=tuple(ReleaseProfile(p["bundle"], p["env"], p["bundle_id"], p["required"])
                       for p in sign.get("profiles") or []),
        sparkle_account=spk["account"], feed_url=spk["feed_url"],
        public_key_setting=spk["public_key_setting"],
        github_repo=rel["github_repo"], releases_checkout=checkout,
        releases_branch=rel.get("branch") or "main",
        source_branch=src.get("branch") or "main",
        source_tag_prefix=src.get("tag_prefix") or "release/",
        site_routes=dict(site.get("routes") or DEFAULT_ROUTES),
        notes_dir=path(data["notes_dir"]) if data.get("notes_dir") else repo / "docs/release-notes",
        cask_token=cask["token"], cask_template=path(cask["template"]),
        pkg_must_close=_dedupe([app["bundle_id"], *(pkg.get("must_close") or [])]),
        pkg_scripts=path(pkg["scripts"]) if pkg.get("scripts") else None,
        apps_dir=path(inst["apps_dir"]) if inst.get("apps_dir") else Path("/Applications"),
        hook_tests=tuple(hooks["tests"]), hook_warnings_build=tuple(hooks["warnings_build"]),
        hook_health=_argv_or_none(hooks.get("health")),
        warnings_allowlist=path(data["warnings_allowlist"]),
        toolkit=(path(data["toolkit"]) if data.get("toolkit")
                 else repo / "external/agenticdevelopertoolkit"),
        env_file=path(data["env_file"]) if data.get("env_file") else None,
    )


def read_env_file(path: Path) -> dict[str, str]:
    """`KEY=value` lines (an optional `export`, optional quotes; `#` comments) from
    `path`. A missing file is an empty result: what it would have set is then
    reported by whatever needed it, with the file named in the fix."""
    try:
        text = path.read_text()
    except FileNotFoundError:
        return {}
    values: dict[str, str] = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, sep, value = line.removeprefix("export ").strip().partition("=")
        if sep and key.strip():
            values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def load_config(repo: Path, *, main_checkout: Path | None = None,
                env: Mapping[str, str] | None = None, home: Path | None = None) -> ReleaseConfig:
    file = repo / CONFIG_FILE
    try:
        text = file.read_text()
    except FileNotFoundError:
        raise ReleaseConfigError([f"{file}: no {CONFIG_FILE} in {repo} -- see docs/release-macos-app.md"])
    except OSError as exc:
        raise ReleaseConfigError([f"{file}: unreadable ({exc})"])
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        raise ReleaseConfigError([f"{file}: not valid JSON ({exc})"])
    return parse_config(data, repo=repo, main_checkout=main_checkout or repo,
                        env=os.environ if env is None else env,
                        home=home or Path.home())
