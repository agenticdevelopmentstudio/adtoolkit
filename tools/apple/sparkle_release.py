#!/usr/bin/env python3
"""Sparkle appcast, verification and publish helpers for a macOS release.

The product-agnostic half of a Sparkle release: nothing here names a product;
every account, path, URL and version is a parameter. It sits beside
`macos_release.py` (signing, notarization, pkg, releases.json) and, like it,
runs every external command through an injected `Runner` — never `subprocess`
directly — so tests fake the keychain, Sparkle's tools, Gatekeeper and GitHub.

Failures that a person must fix come back as a list of strings, each carrying
its own fix; conditions that make a step impossible raise.
"""
from __future__ import annotations

import json
import plistlib
import shutil
import subprocess
import urllib.parse
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Callable, Literal

import macos_release as mr

Runner = Callable[[list[str]], "subprocess.CompletedProcess[str]"]

SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"

# Where Sparkle's SPM binary artifact lands under a derived-data directory once
# packages resolve: generate_keys, sign_update and generate_appcast.
SPARKLE_BIN_REL = Path("SourcePackages/artifacts/sparkle/Sparkle/bin")

APP_IDENTITY = "Developer ID Application"

# LSMinimumSystemVersion's major -> the symbol a cask's `depends_on macos:` takes.
HOMEBREW_MACOS = {"14": ":sonoma", "15": ":sequoia", "26": ":tahoe"}

PublishState = Literal["create", "commit", "push", "published"]


def _output(proc: subprocess.CompletedProcess[str]) -> str:
    return (proc.stderr or proc.stdout or "").strip()


def _check(proc: subprocess.CompletedProcess[str], what: str) -> subprocess.CompletedProcess[str]:
    if proc.returncode != 0:
        raise RuntimeError(f"{what} failed (exit {proc.returncode}): {_output(proc)}")
    return proc


def sparkle_config_problems(info: dict) -> list[str]:
    """What in an app's Info.plist would make Sparkle refuse to run at all.

    SPUUpdater's configuration check fails (SUInvalidUpdaterError, and the
    updater never starts) when SURequireSignedFeed is set without
    SUVerifyUpdateBeforeExtraction.
    """
    problems: list[str] = []
    if not info.get("SUPublicEDKey"):
        problems.append("SUPublicEDKey is empty — installed apps could verify no update")
    if info.get("SURequireSignedFeed") and not info.get("SUVerifyUpdateBeforeExtraction"):
        problems.append("SURequireSignedFeed is set without SUVerifyUpdateBeforeExtraction — "
                        "Sparkle refuses to start its updater; set both in the app's Info.plist")
    return problems


def sparkle_tools(derived_data: Path, *, workspace: Path, scheme: str, run: Runner) -> Path:
    """The directory holding generate_keys/sign_update/generate_appcast.

    They ship in Sparkle's SPM binary artifact, which exists only once packages
    resolve into `derived_data`; resolve them when the directory is missing.
    """
    tools = derived_data / SPARKLE_BIN_REL
    if (tools / "generate_keys").exists():
        return tools
    _check(run(["xcodebuild", "-resolvePackageDependencies",
                "-workspace", str(workspace), "-scheme", scheme,
                "-derivedDataPath", str(derived_data),
                "-skipPackagePluginValidation"]),
           "xcodebuild -resolvePackageDependencies")
    if not (tools / "generate_keys").exists():
        raise RuntimeError(f"Sparkle's tools are not under {tools} after resolving packages")
    return tools


def generate_appcast(*, tools: Path, account: str, zip_path: Path, notes: Path,
                     published_appcast: Path | None, download_prefix: str, out: Path,
                     run: Runner) -> Path:
    """Run generate_appcast over a directory holding only this release's zip,
    its notes, and a copy of the published appcast.xml, so every earlier item
    is carried over from the feed itself rather than from old archives.

    The directory is `out`'s parent, rebuilt from scratch. The notes go in as
    `<zip stem>.md`, the name generate_appcast pairs with the archive, and are
    embedded (Sparkle 2.9+ renders Markdown). They are not linked:
    generate_appcast derives a notes URL only from the archive's name.
    --maximum-versions 0 keeps every earlier item instead of the default 3.
    """
    archives = out.parent
    if archives.exists():
        shutil.rmtree(archives)
    archives.mkdir(parents=True)
    shutil.copy2(zip_path, archives / zip_path.name)
    if notes.exists():
        shutil.copy2(notes, archives / f"{zip_path.stem}.md")
    if published_appcast is not None and published_appcast.exists():
        shutil.copy2(published_appcast, archives / "appcast.xml")
    _check(run([str(tools / "generate_appcast"),
                "--account", account,
                "--download-url-prefix", download_prefix,
                "--embed-release-notes",
                "--maximum-versions", "0",
                "-o", str(out),
                str(archives)]), "generate_appcast")
    return out


def enclosure_signature(appcast: Path, archive_name: str) -> str | None:
    """The `sparkle:edSignature` on the appcast enclosure whose URL ends in
    `archive_name`, or None when there is no such enclosure or it is unsigned."""
    for enclosure in ET.parse(appcast).getroot().iter("enclosure"):
        if enclosure.get("url", "").endswith(f"/{archive_name}"):
            return enclosure.get(f"{{{SPARKLE_NS}}}edSignature")
    return None


def sparkle_verify(*, tools: Path, account: str, app: Path, zip_path: Path, appcast: Path,
                   run: Runner) -> list[str]:
    """Why installed apps would reject this update, or [] when they would not.

    The EdDSA signing itself is generate_appcast's; this checks its result:

    1. The Sparkle key in the keychain is the one the app ships with — the
       staged Info.plist's SUPublicEDKey. On a mismatch generate_appcast only
       warns and leaves the enclosure unsigned.
    2. The appcast enclosure for this zip carries a `sparkle:edSignature`, and
       `sign_update --verify <zip> <signature>` accepts it.
    3. `sign_update --verify appcast.xml` accepts the feed's own embedded
       signature (an app with SURequireSignedFeed needs it).
    """
    failures: list[str] = []
    shipped = plistlib.loads((app / "Contents/Info.plist").read_bytes()).get("SUPublicEDKey", "")
    generate_keys = str(tools / "generate_keys")
    keys = run([generate_keys, "--account", account, "-p"])
    keychain = (keys.stdout or "").strip() if keys.returncode == 0 else ""
    if keys.returncode != 0:
        failures.append(f"generate_keys -p failed (exit {keys.returncode}: {_output(keys)}); "
                        f"create the key with `{generate_keys} --account {account}`")
    elif keychain != shipped:
        failures.append(
            f"the keychain's Sparkle key ({keychain or 'none'}) is not the app's SUPublicEDKey "
            f"({shipped or 'empty'}) — installed apps would reject this update; set the app's "
            f"public key to the keychain's (`{generate_keys} --account {account} -p`) and rebuild")
    sign_update = str(tools / "sign_update")
    signature = enclosure_signature(appcast, zip_path.name)
    if not signature:
        failures.append(f"{appcast} has no sparkle:edSignature on the {zip_path.name} "
                        "enclosure — generate_appcast did not sign it; fix the key mismatch "
                        "above, if any, and regenerate the appcast")
    else:
        proc = run([sign_update, "--account", account, "--verify", str(zip_path), signature])
        if proc.returncode != 0:
            failures.append(f"sign_update rejects the edSignature on {zip_path.name} "
                            f"(exit {proc.returncode}: {_output(proc)}); regenerate the appcast "
                            "from this exact zip")
    proc = run([sign_update, "--account", account, "--verify", str(appcast)])
    if proc.returncode != 0:
        failures.append(f"sign_update rejects the feed signature of {appcast.name} "
                        f"(exit {proc.returncode}: {_output(proc)}); regenerate the appcast")
    return failures


def write_provenance(path: Path, *, source_sha: str, artifacts: dict[str, Path],
                     notarized: bool) -> None:
    """Record which commit built `artifacts`, their digests, and whether the run
    finished notarizing them. Publishing then ships only what a real run left."""
    path.write_text(json.dumps({
        "source_sha": source_sha,
        "notarized": notarized,
        "artifacts": {name: mr.asset_for(file, "").sha256 for name, file in artifacts.items()},
    }, indent=2) + "\n")


def provenance_failures(path: Path, *, head_sha: str, artifacts: dict[str, Path]) -> list[str]:
    """Why the artifacts on disk are not a finished build of `head_sha`."""
    rebuild = "rebuild them"
    try:
        record = json.loads(path.read_text())
    except FileNotFoundError:
        return [f"{path} is missing — nothing shows these artifacts came from a finished "
                f"release run; {rebuild}"]
    except json.JSONDecodeError as exc:
        return [f"{path} is unreadable ({exc}); {rebuild}"]
    if not record.get("notarized"):
        return [f"the artifacts were never notarized (the run stopped before notarizing "
                f"finished); {rebuild}"]
    failures: list[str] = []
    if not head_sha or record.get("source_sha") != head_sha:
        failures.append(f"the artifacts were built from {str(record.get('source_sha'))[:12]}, "
                        f"not HEAD {(head_sha or '?')[:12]}; {rebuild}")
    digests = record.get("artifacts", {})
    for name, file in artifacts.items():
        if digests.get(name) != mr.asset_for(file, "").sha256:
            failures.append(f"{file.name} changed after the run that built it; {rebuild}")
    return failures


def artifact_failures(*, app: Path, pkg: Path, run: Runner) -> list[str]:
    """Signatures Gatekeeper accepts: the pkg's stapled ticket and install
    assessment, the staged app's signature, and its Developer ID authority."""
    rebuild = "rebuild and notarize them"
    failures: list[str] = []
    checks = [
        (["xcrun", "stapler", "validate", str(pkg)], "the pkg's notarization ticket"),
        (["spctl", "--assess", "--type", "install", "-vv", str(pkg)],
         "Gatekeeper's install assessment of the pkg"),
        (["codesign", "--verify", "--deep", "--strict", str(app)], "the staged app's signature"),
    ]
    for argv, what in checks:
        proc = run(argv)
        if proc.returncode != 0:
            failures.append(f"{what} does not verify (`{' '.join(argv[:3])} …` exit "
                            f"{proc.returncode}: {_output(proc)}); {rebuild}")
    shown = run(["codesign", "-d", "--verbose=2", str(app)])
    if f"Authority={APP_IDENTITY}" not in (shown.stderr or "") + (shown.stdout or ""):
        failures.append(f"the staged app is not signed '{APP_IDENTITY}'; {rebuild}")
    return failures


def _github_release_assets(version: str, github_repo: str, run: Runner) -> list[dict] | None:
    """The tag's release assets on GitHub, or None when there is no release."""
    tag = f"v{version}"
    view = run(["gh", "release", "view", tag, "--repo", github_repo, "--json", "assets"])
    if view.returncode != 0:
        if "not found" in (view.stderr or "").lower():
            return None
        raise mr.PreflightError(f"gh release view {tag} failed: {(view.stderr or '').strip()}")
    try:
        return json.loads(view.stdout or "{}").get("assets", [])
    except json.JSONDecodeError as exc:
        raise mr.PreflightError(f"gh release view {tag} returned unreadable JSON: {exc}")


def _listed_versions(releases_checkout: Path) -> set[str]:
    path = releases_checkout / "releases.json"
    doc = json.loads(path.read_text()) if path.exists() else {}
    return {entry.get("version") for entry in doc.get("releases", [])}


def _commits_ahead(releases_checkout: Path, run: Runner) -> int:
    out = (run(["git", "-C", str(releases_checkout), "rev-list", "--count",
                "origin/main..HEAD"]).stdout or "0").strip()
    return int(out) if out.isdigit() else 0


def publish_state(*, releases_checkout: Path, version: str, github_repo: str,
                  run: Runner) -> PublishState:
    """What an interrupted publish has left to do.

    "create": no GitHub release yet. "commit": the release exists but the
    releases checkout does not list it. "push": it is committed but not pushed.
    "published": nothing is left. An inconsistent state raises PreflightError.
    """
    tag = f"v{version}"
    assets = _github_release_assets(version, github_repo, run)
    listed = version in _listed_versions(releases_checkout)
    if assets is None:
        if listed:
            raise mr.PreflightError(
                f"releases.json in {releases_checkout} lists {version} but GitHub has no "
                f"release {tag} — repair the releases repo by hand")
        return "create"
    if not listed:
        return "commit"
    if _commits_ahead(releases_checkout, run) > 0:
        return "push"
    return "published"


def homebrew_macos(minimum_system_version: str) -> str:
    major = minimum_system_version.split(".")[0]
    if major not in HOMEBREW_MACOS:
        raise RuntimeError(f"no Homebrew macOS symbol for LSMinimumSystemVersion "
                           f"{minimum_system_version!r} — add its major to HOMEBREW_MACOS")
    return HOMEBREW_MACOS[major]


def render_cask(*, token: str, name: str, entry: mr.ReleaseEntry, feed_url: str,
                app_filename: str, extra_stanzas: str = "") -> str:
    """The Homebrew cask for `entry`, which installs its pkg and follows the
    Sparkle feed for livecheck.

    The url is written with brew's `#{version}` interpolation, the form
    `brew bump-cask-pr` and livecheck expect; it must still name exactly the pkg
    releases.json lists. `extra_stanzas` (desc, zap, caveats, …) are inserted
    verbatim, two-space indented and newline-terminated, before the closing end.
    """
    pkg_url = entry.pkg.url
    pkg_name = pkg_url.rsplit("/", 1)[-1]
    if entry.version not in pkg_url:
        raise RuntimeError(f"the pkg url {pkg_url} does not contain the version "
                           f"{entry.version}, so the cask cannot interpolate it")
    url = pkg_url.replace(entry.version, "#{version}")
    pkg = pkg_name.replace(entry.version, "#{version}")
    site = urllib.parse.urlsplit(feed_url)
    return (
        f'cask "{token}" do\n'
        f'  version "{entry.version}"\n'
        f'  sha256 "{entry.pkg.sha256}"\n'
        '\n'
        f'  url "{url}"\n'
        f'  name "{name}"\n'
        f'  homepage "{site.scheme}://{site.netloc}/"\n'
        '\n'
        '  livecheck do\n'
        f'    url "{feed_url}"\n'
        '    strategy :sparkle\n'
        '  end\n'
        '\n'
        '  auto_updates true\n'
        f'  depends_on macos: {homebrew_macos(entry.minimum_system_version)}\n'
        '\n'
        f'  pkg "{pkg}"\n'
        '\n'
        f'  uninstall delete: "/Applications/{app_filename}"\n'
        f'{extra_stanzas}'
        'end\n'
    )
