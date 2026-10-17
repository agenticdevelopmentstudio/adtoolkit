"""The build pipeline: preflight, the app's own build hook, bundle checks, sign, notarize, pkg.

Ported function by function from Stenographer's scripts/release.py. What was a module
constant is a field of `r.cfg`; Stenographer's `install.build_release`/`install_app` pair is
`cfg.build_command`, run as the build hook.

(Named build_pipeline, not build: abstractr refuses a module named `build`, which other
repos already export.)
"""
from __future__ import annotations

import plistlib
import shutil
import sys
from datetime import datetime, timezone
from typing import Callable

import macos_release as mr

from . import layout
from .profiles import (entitlements_map, identity_team, profile_failures, signing_entitlements,
                       step_provision)
from .shell import bullet, check, step
from .site import site_failures
from .sparkle import (bundle_info_problems, ensure_sparkle_tools, public_key_failure,
                      sparkle_config_problems, sparkle_public_key, step_appcast,
                      step_sparkle_verify)
from .state import (RELEASE_CMD, Release, artifact_failures, git_count, head_sha,
                    source_tag_failures, tag_sha, write_provenance)
from .versions import must_match_failures, project_setting

BUILD_STEPS = ["preflight", "build", "check-bundle", "provision", "sign", "notarize-app",
               "update-zip", "appcast", "sparkle-verify", "pkg", "notarize-pkg"]



# Steps -----------------------------------------------------------------------


def step_preflight(r: Release) -> None:
    # publish.py imports this module, so it is imported when needed, not at load.
    from . import publish

    mode = "publish" if r.publish else "build"
    step(f"Preflight ({mode} {r.version}, build {r.build_number})")
    failures: list[str] = must_match_failures(r.cfg, r.version)

    # A Sparkle tools failure is one more failure, not the end of the report: only
    # the checks that run Sparkle's generate_keys wait for the tools.
    sparkle_ready = True
    try:
        ensure_sparkle_tools(r)
    except RuntimeError as exc:
        sparkle_ready = False
        failures.append(str(exc))
    public_key = sparkle_public_key(r.cfg)
    r.source_sha = head_sha(r)

    if r.publish:
        publish_preflight(r, public_key, failures, sparkle_ready=sparkle_ready)
    else:
        release_preflight(r, public_key, failures, sparkle_ready=sparkle_ready)

    if failures:
        raise mr.PreflightError("\n".join(failures))

    if r.publish:
        r.publish_state = publish.publish_state(r)
        return
    if r.out.exists():
        shutil.rmtree(r.out)
    r.out.mkdir(parents=True)


def cask_render_failures(r: Release) -> list[str]:
    """The cask template rendered with a stand-in entry, so a template that cannot
    render fails before the notarized build rather than at publish. The OS gate is
    the project's deployment target (the built app's LSMinimumSystemVersion is not
    known yet); a project that sets none is rendered at the newest known macOS."""
    from . import cask

    cfg = r.cfg
    try:
        minimum = project_setting("MACOSX_DEPLOYMENT_TARGET", cfg.project_yml.read_text())
    except (OSError, ValueError):
        minimum = max(cask.HOMEBREW_MACOS, key=int)
    asset = mr.ReleaseAsset(url=f"{cfg.download_prefix}/{r.tag}/{r.pkg_path.name}",
                            size=1, sha256="0" * 64)
    stand_in = mr.ReleaseEntry(version=r.version, build=r.build_number,
                               date="1970-01-01T00:00:00Z", minimum_system_version=minimum,
                               notes=f"notes/{r.version}.md", pkg=asset, zip=asset)
    try:
        cask.cask_ruby(stand_in, cfg)
    except RuntimeError as exc:
        return [f"cask: {exc}"]
    return []


def release_preflight(r: Release, public_key: str, failures: list[str], *,
                      sparkle_ready: bool = True) -> None:
    from . import publish

    cfg = r.cfg
    try:
        mr.preflight(
            identities=[cfg.app_identity, cfg.installer_identity],
            notary_profile=cfg.notary_profile,
            releases_json=publish.load_releases_json(r),
            version=r.version,
            run=r.run,
            build=r.build_number,
            require_clean_main=r.repo,
            main_branch=r.branch,
            sparkle_account=cfg.sparkle_account if sparkle_ready else None,
            generate_keys=r.sparkle_bin / "generate_keys" if sparkle_ready else None,
            github_repo=cfg.github_repo,
        )
    except mr.PreflightError as exc:
        lines = str(exc).splitlines()
        failures.extend(lines)
        if any("already exists" in ln or "already released" in ln for ln in lines):
            failures.append("if an earlier run of this version failed while publishing, "
                            f"finish it with `{RELEASE_CMD}` instead")
    if not public_key:
        failures.append(public_key_failure(r))
    if not r.notes.exists():
        failures.append(f"release notes missing -- write {r.notes}")
    failures.extend(releases_repo_failures(r))
    failures.extend(site_failures(r))
    failures.extend(cask_render_failures(r))
    if tag_sha(r) is not None:
        failures.append(f"tag {r.source_tag} already exists in {r.repo} -- {r.version} was "
                        "already prepared; bump the version, or delete the tag if that "
                        "preparation was abandoned")
    identities = r.run(["security", "find-identity", "-v", "-p", "basic"]).stdout or ""
    r.team = identity_team(identities, cfg.app_identity)
    failures.extend(profile_failures(r))


def publish_preflight(r: Release, public_key: str, failures: list[str], *,
                      sparkle_ready: bool = True) -> None:
    cfg = r.cfg
    try:
        mr.preflight(identities=[], notary_profile=None, releases_json={},
                     version=r.version, run=r.run,
                     sparkle_account=cfg.sparkle_account if sparkle_ready else None,
                     generate_keys=r.sparkle_bin / "generate_keys" if sparkle_ready else None,
                     require_clean_main=r.repo, main_branch=r.branch)
    except mr.PreflightError as exc:
        failures.extend(str(exc).splitlines())
    failures.extend(source_tag_failures(r))
    if not public_key:
        failures.append(public_key_failure(r))
    if r.run(["gh", "auth", "status"]).returncode != 0:
        failures.append("gh is not authenticated -- run `gh auth login`")
    if not r.notes.exists():
        failures.append(f"release notes missing -- write {r.notes}")
    info_plist = r.app / "Contents/Info.plist"
    for needed in (r.pkg_path, r.zip_path, info_plist):
        if not needed.exists():
            failures.append(f"{needed} is missing -- publish publishes the artifacts "
                            f"{RELEASE_CMD} built; without them, run {RELEASE_CMD}")
    failures.extend(releases_repo_failures(r))
    failures.extend(site_failures(r))
    if info_plist.exists():
        info = plistlib.loads(info_plist.read_bytes())
        r.minimum_system_version = info.get("LSMinimumSystemVersion", "")
        failures.extend(f"staged app: {p}" for p in sparkle_config_problems(info))
    if all(p.exists() for p in (r.pkg_path, r.zip_path, info_plist)):
        failures.extend(artifact_failures(r))


def releases_repo_failures(r: Release) -> list[str]:
    repo = r.releases_repo
    branch = r.cfg.releases_branch
    if not (repo / ".git").exists():
        return [f"releases repo checkout missing -- `gh repo clone {r.cfg.github_repo} {repo}`"]
    failures: list[str] = []
    try:
        # A publish that failed at `git push` left the release commit ahead of
        # origin on purpose; publish_state pushes it.
        mr.preflight(identities=[], notary_profile=None, releases_json={}, version=r.version,
                     run=r.run, require_clean_main=repo, main_branch=branch,
                     require_pushed=not r.publish)
    except mr.PreflightError as exc:
        failures.extend(str(exc).splitlines())
    fetch = r.run(["git", "-C", str(repo), "fetch", "origin", branch])
    if fetch.returncode != 0:
        failures.append(f"`git -C {repo} fetch origin {branch}` failed "
                        f"({(fetch.stderr or '').strip()}) -- cannot tell whether the checkout "
                        f"is behind origin/{branch}; check the network and rerun")
        return failures
    behind = git_count(r, f"HEAD..origin/{branch}")
    if behind:
        failures.append(f"{repo} is {behind} commit(s) behind origin/{branch} -- "
                        f"`git -C {repo} pull --ff-only`")
    return failures


def submodule_drift(r: Release) -> list[str]:
    """Each submodule that is uninitialised or checked out away from its
    recorded gitlink, with the command that fixes it."""
    status = check(r.run(["git", "-C", str(r.repo), "submodule", "status", "--recursive"]),
                   "git submodule status")
    drift: list[str] = []
    for line in (status.stdout or "").splitlines():
        fields = line[1:].split()
        if len(fields) < 2:
            continue
        if line[0] == "-":
            drift.append(f"{fields[1]} is not checked out "
                         "(`git submodule update --init --recursive`)")
        elif line[0] == "+":
            drift.append(f"{fields[1]} is at {fields[0][:12]}, not the recorded commit -- "
                         "commit the new pointer, or `git submodule update` it back")
    return drift


_RELEASE_VARS = ("RELEASE_APP_DEST", "RELEASE_DERIVED_DATA", "RELEASE_VERSION", "RELEASE_BUILD")


def build_env(r: Release) -> dict[str, str]:
    """The environment `build.command` runs in: r.env plus the RELEASE_* contract."""
    return {**r.env,
            "RELEASE_APP_DEST": str(r.app),
            "RELEASE_DERIVED_DATA": str(r.derived_data),
            "RELEASE_VERSION": r.version,
            "RELEASE_BUILD": str(r.build_number)}


def step_build(r: Release) -> None:
    step(f"Building {r.cfg.app_name} {r.version} with build.command")
    # Not a submodule sync: that checks drifted submodules out to their gitlinks,
    # detaching whatever branch the developer has them on. A release builds what
    # is committed, so drift is refused, never repaired.
    drift = submodule_drift(r)
    if drift:
        raise RuntimeError("submodules are not at the commits this checkout records, so the "
                           "build would not be what is committed: " + "; ".join(drift))
    if r.app.exists():
        shutil.rmtree(r.app)
    r.app.parent.mkdir(parents=True, exist_ok=True)
    env = build_env(r)
    proc = r.run(["/usr/bin/env", *(f"{k}={env[k]}" for k in _RELEASE_VARS),
                  *r.cfg.build_command])
    if proc.returncode != 0:
        raise RuntimeError(f"build.command failed (exit {proc.returncode}); it must build the "
                           f"app into RELEASE_APP_DEST ({r.app}):\n"
                           f"{(proc.stderr or '') + (proc.stdout or '')}".rstrip())
    if not r.app.exists():
        raise RuntimeError(f"build.command exited 0 but left no app at RELEASE_APP_DEST "
                           f"({r.app}) -- it must create the finished {r.cfg.app_name}.app "
                           "there")
    bullet(str(r.app))


def step_check_bundle(r: Release) -> None:
    step("Checking the assembled bundle")
    plist = r.app / "Contents/Info.plist"
    if not plist.exists():
        raise RuntimeError(f"{plist} is missing -- build.command left no usable app at "
                           "RELEASE_APP_DEST")
    info = plistlib.loads(plist.read_bytes())
    problems = bundle_info_problems(info, r.cfg, version=r.version, build=r.build_number)
    if problems:
        raise RuntimeError("; ".join(problems))
    r.minimum_system_version = info.get("LSMinimumSystemVersion", "")
    shape = layout.problems(r.app, r.cfg)
    if shape:
        raise RuntimeError("the assembled bundle does not match the bundle layout: "
                           + "; ".join(shape))
    for entry in r.cfg.checks:
        check(r.run(["/usr/bin/env", f"RELEASE_APP={r.app}", *entry.command]),
              f"bundle check '{entry.name}'")
        bullet(f"check '{entry.name}' passes")


def step_sign(r: Release) -> None:
    identity = r.cfg.app_identity
    step(f"Signing {r.app.name} inside-out with '{identity}'")
    entitlements = entitlements_map(r.app, r.cfg, signing_entitlements(r))
    mr.sign_bundle(r.app, identity=identity, entitlements=entitlements,
                   runtime=True, timestamp=True, run=r.run)
    bullet("codesign --verify --deep --strict passes")


def step_notarize_app(r: Release) -> None:
    step("Notarizing and stapling the app")
    mr.notarize(r.app, profile=r.cfg.notary_profile, run=r.run)


def step_update_zip(r: Release) -> None:
    step("Building the Sparkle update zip")
    mr.make_update_zip(r.app, r.zip_path, run=r.run)
    bullet(str(r.zip_path))


def distribution_xml(r: Release) -> str:
    if not r.minimum_system_version:
        raise RuntimeError("no LSMinimumSystemVersion read from the staged app -- the pkg "
                           "would install on a macOS the app cannot launch on")
    return mr.render_distribution(
        title=r.cfg.title,
        identifier=r.cfg.bundle_id,
        version=r.version,
        pkg_ref=mr.COMPONENT_PKG,
        # One component: no choices, no installation check, no JavaScript. Its only
        # script is the optional preinstall (pkg.scripts).
        optional_choices=[],
        installation_check_js=None,
        allow_external_scripts=False,
        minimum_os_version=r.minimum_system_version,
        # A running copy would keep serving the old code after the bundle is swapped
        # under it: pkg.must_close, which config already opens with the app's own id.
        must_close=list(r.cfg.pkg_must_close),
    )


def step_pkg(r: Release) -> None:
    step(f"Building {r.pkg_path.name}")
    work = r.out / "pkg-work"
    work.mkdir(parents=True, exist_ok=True)
    distribution = distribution_xml(r)
    (work / "Distribution.xml").write_text(distribution)
    mr.build_pkg(
        r.app,
        identifier=r.cfg.bundle_id,
        version=r.version,
        distribution=distribution,
        identity=r.cfg.installer_identity,
        dest=r.pkg_path,
        run=r.run,
        scripts=r.cfg.pkg_scripts,
    )
    write_provenance(r, notarized=False)
    bullet(str(r.pkg_path))


def step_notarize_pkg(r: Release) -> None:
    step("Notarizing and stapling the pkg")
    mr.notarize(r.pkg_path, profile=r.cfg.notary_profile, run=r.run)
    # After stapling: the ticket changes the pkg's bytes.
    write_provenance(r, notarized=True)


def release_entry(r: Release, *, now: datetime | None = None) -> mr.ReleaseEntry:
    when = now or datetime.now(timezone.utc)
    prefix = f"{r.cfg.download_prefix}/{r.tag}"
    return mr.ReleaseEntry(
        version=r.version,
        build=r.build_number,
        date=when.strftime("%Y-%m-%dT%H:%M:%SZ"),
        minimum_system_version=r.minimum_system_version,
        notes=f"notes/{r.version}.md",
        pkg=mr.asset_for(r.pkg_path, f"{prefix}/{r.pkg_path.name}"),
        zip=mr.asset_for(r.zip_path, f"{prefix}/{r.zip_path.name}"),
    )


# Driver ----------------------------------------------------------------------


def build_steps() -> dict[str, Callable[[Release], None]]:
    return {
        "preflight": step_preflight,
        "build": step_build,
        "check-bundle": step_check_bundle,
        "provision": step_provision,
        "sign": step_sign,
        "notarize-app": step_notarize_app,
        "update-zip": step_update_zip,
        "appcast": step_appcast,
        "sparkle-verify": step_sparkle_verify,
        "pkg": step_pkg,
        "notarize-pkg": step_notarize_pkg,
    }


def run_build(r: Release) -> int:
    """Run BUILD_STEPS in order; print any failure to stderr; return 0 or 1."""
    steps = build_steps()
    try:
        for name in BUILD_STEPS:
            steps[name](r)
    except mr.PreflightError as exc:
        print(f"error: preflight failed:\n{exc}", file=sys.stderr)
        return 1
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    print()
    print(f"✓ Release build {r.version} complete")
    print(f"  pkg: {r.pkg_path}")
    print(f"  zip: {r.zip_path}")
    print(f"  source: {r.source_sha}")
    print("  notarized and stapled; nothing was published")
    return 0
