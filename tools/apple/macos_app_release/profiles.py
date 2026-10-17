"""Developer ID provisioning profiles: validate the owner's, swap them into the staged bundle."""
from __future__ import annotations

import plistlib
import re
import shutil
from pathlib import Path
from typing import Mapping
from xml.parsers.expat import ExpatError

from .config import Profile, ReleaseConfig
from .shell import bullet, step
from .state import Release

EMBEDDED_PROFILE = Path("Contents/embedded.provisionprofile")


def identity_team(find_identity_stdout: str, prefix: str) -> str | None:
    """The team ID in `"<prefix>: Name (TEAMID)"`, or None if no such identity."""
    m = re.search(rf'"{re.escape(prefix)}:[^"]*\(([A-Z0-9]+)\)"', find_identity_stdout)
    return m.group(1) if m else None


def bundle_at(app: Path, rel: str) -> Path:
    return app if rel == "." else app / rel


def profile_fix(env: str, bundle_id: str, env_file: Path | None = None) -> str:
    where = f" in {env_file}" if env_file is not None else ""
    return (f"create a Developer ID provisioning profile for {bundle_id} "
            "(developer.apple.com → Certificates, IDs & Profiles → Profiles → + → "
            "Developer ID, with the Developer ID Application certificate), download it, "
            f"and set {env}=<path to the .provisionprofile>{where}")


def profile_problems(r: Release, profile: Path, bundle_id: str, team: str | None) -> list[str]:
    """Why `profile` is not a Developer ID profile for `bundle_id` under
    `team` (the signing identity's team; None skips that comparison)."""
    decoded = r.run(["security", "cms", "-D", "-i", str(profile)])
    if decoded.returncode != 0:
        return [f"`security cms -D -i` cannot decode it ({(decoded.stderr or '').strip()})"]
    try:
        info = plistlib.loads((decoded.stdout or "").encode())
    except (ValueError, ExpatError):
        return ["it does not decode to a provisioning-profile plist"]
    problems: list[str] = []
    if info.get("ProvisionsAllDevices") is not True:
        problems.append("ProvisionsAllDevices is not true, so it is not a Developer ID profile")
    teams = info.get("TeamIdentifier") or []
    if team and team not in teams:
        problems.append(f"its TeamIdentifier {teams} does not include the signing "
                        f"identity's team {team}")
    prefix = team or (teams[0] if teams else "?")
    app_id = (info.get("Entitlements") or {}).get("com.apple.application-identifier")
    if app_id != f"{prefix}.{bundle_id}":
        problems.append(f"its application-identifier is {app_id!r}, "
                        f"expected '{prefix}.{bundle_id}'")
    return problems


def profile_failures(r: Release) -> list[str]:
    """Validate every configured Developer ID profile; record the good ones in
    r.profiles for step_provision."""
    failures: list[str] = []
    for profile in r.cfg.profiles:
        value = r.env.get(profile.env, "").strip()
        if not value:
            if profile.required:
                failures.append(f"{profile.env} is not set — "
                                f"{profile_fix(profile.env, profile.bundle_id, r.cfg.env_file)}")
            continue
        path = Path(value).expanduser()
        if not path.is_file():
            failures.append(f"{profile.env}={value} does not exist — "
                            f"{profile_fix(profile.env, profile.bundle_id, r.cfg.env_file)}")
            continue
        problems = profile_problems(r, path, profile.bundle_id, r.team)
        if problems:
            failures.append(f"{profile.env} ({path}) is not usable: {'; '.join(problems)} — "
                            f"{profile_fix(profile.env, profile.bundle_id, r.cfg.env_file)}")
        else:
            r.profiles[profile.bundle] = path
    return failures


def _profile_for(cfg: ReleaseConfig, rel: str) -> Profile | None:
    return next((p for p in cfg.profiles if p.bundle == rel), None)


def step_provision(r: Release) -> None:
    """Replace Xcode's development profile(s) in the staged bundle with the
    validated Developer ID profile(s), before the bundle is re-signed."""
    step("Embedding the Developer ID provisioning profile(s)")
    for rel, source in r.profiles.items():
        target = bundle_at(r.app, rel) / EMBEDDED_PROFILE
        shutil.copy2(source, target)
        bullet(f"{source} → {target.relative_to(r.app.parent)}")
    for embedded in sorted(r.app.rglob(EMBEDDED_PROFILE.name)):
        bundle = embedded.parent.parent
        rel = "." if bundle == r.app else str(bundle.relative_to(r.app))
        if rel not in r.profiles:
            entry = _profile_for(r.cfg, rel)
            env = entry.env if entry else "a new signing.profiles entry"
            raise RuntimeError(f"{bundle.name} embeds a provisioning profile that no Developer "
                               f"ID profile replaces — set {env}")
    for rel in r.profiles:
        check_developer_id_profile(r, rel)


def check_developer_id_profile(r: Release, rel: str = ".") -> None:
    """A Developer ID-signed app with keychain entitlements needs a Developer ID
    provisioning profile (ProvisionsAllDevices), not the development wildcard.
    Runs on the staged bundle, after step_provision's swap."""
    entry = _profile_for(r.cfg, rel)
    if entry is None:
        raise RuntimeError(f"signing.profiles has no entry for {rel!r}")
    profile = bundle_at(r.app, rel) / EMBEDDED_PROFILE
    if not profile.exists():
        raise RuntimeError(f"{profile} is missing — "
                           f"{profile_fix(entry.env, entry.bundle_id, r.cfg.env_file)}")
    problems = profile_problems(r, profile, entry.bundle_id, r.team)
    if problems:
        raise RuntimeError(f"the staged {profile.relative_to(r.app.parent)} is not a Developer "
                           f"ID profile: {'; '.join(problems)} — "
                           f"{profile_fix(entry.env, entry.bundle_id, r.cfg.env_file)}")
    bullet(f"{bundle_at(r.app, rel).name}: Developer ID profile verified")


_PREFIX_VARIABLES = ("$(AppIdentifierPrefix)", "$(TeamIdentifierPrefix)")


def _expand(value: object, prefix: str) -> object:
    if isinstance(value, str):
        for variable in _PREFIX_VARIABLES:
            value = value.replace(variable, prefix)
        return value
    if isinstance(value, list):
        return [_expand(v, prefix) for v in value]
    if isinstance(value, dict):
        return {k: _expand(v, prefix) for k, v in value.items()}
    return value


def signing_entitlements(r: Release) -> dict[str, Path]:
    """signing.entitlements as a Developer ID signature needs them. Xcode expands
    `$(AppIdentifierPrefix)` and adds the application and team identifiers at build
    time; a re-signature with the raw file carries neither, and an app whose
    entitlements a provisioning profile gates (keychain-access-groups) is killed at
    launch. So a file holding a prefix variable is written expanded, and each item
    that embeds a Developer ID profile also gets the two identifiers. Anything else
    is signed with its file unchanged. Rendered files go in `<out>/entitlements/`."""
    rendered: dict[str, Path] = {}
    for rel, source in r.cfg.entitlements.items():
        data = source.read_bytes()
        profile = _profile_for(r.cfg, rel) if rel in r.profiles else None
        if profile is None and b"$(" not in data:
            rendered[rel] = source
            continue
        if not r.team:
            raise RuntimeError(f"{source} needs the team ID to be signed, and preflight "
                               f"found no '{r.cfg.app_identity}' identity to read it from")
        prefix = f"{r.team}."
        try:
            values = _expand(plistlib.loads(data), prefix)
        except (plistlib.InvalidFileException, ExpatError, ValueError) as exc:
            raise RuntimeError(f"{source} is not a property list: {exc}") from exc
        if not isinstance(values, dict):
            raise RuntimeError(f"{source} is not an entitlements dictionary")
        if profile is not None:
            values["com.apple.application-identifier"] = f"{prefix}{profile.bundle_id}"
            values["com.apple.developer.team-identifier"] = r.team
        out = plistlib.dumps(values)
        if b"$(" in out:
            raise RuntimeError(f"{source} holds a build variable other than "
                               f"{' and '.join(_PREFIX_VARIABLES)}, which a re-signature "
                               "cannot expand -- write its value into the file")
        name = "app" if rel == "." else rel.replace("/", "_")
        dest = r.out / "entitlements" / f"{name}.entitlements"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(out)
        rendered[rel] = dest
    return rendered


def entitlements_map(app: Path, cfg: ReleaseConfig,
                     sources: Mapping[str, Path] | None = None) -> dict[Path, Path]:
    """Bundle item -> entitlements file, for mr.sign_bundle. `sources` is
    signing_entitlements' result; None signs with the configured files as they are."""
    mapping: dict[Path, Path] = {}
    for rel, source in (cfg.entitlements if sources is None else sources).items():
        target = bundle_at(app, rel)
        if not target.exists():
            raise RuntimeError(f"{target} is not in the assembled bundle — "
                               "update signing.entitlements")
        mapping[target] = source
    return mapping
