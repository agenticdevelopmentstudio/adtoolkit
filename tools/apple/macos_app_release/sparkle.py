"""Sparkle: Info.plist sanity, tool resolution, the local appcast and its signature checks."""
from __future__ import annotations

import plistlib
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path

from .config import ReleaseConfig
from .shell import bullet, check, step
from .state import Release
from .versions import project_setting

SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"


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
                        "Sparkle refuses to start its updater; set both in "
                        "the app target's Info.plist")
    return problems


def bundle_info_problems(info: dict, cfg: ReleaseConfig, *, version: str,
                         build: int) -> list[str]:
    """What is wrong with an assembled app's Info.plist: version and build, every
    `build.expect_info` pair, SUFeedURL, LSMinimumSystemVersion and Sparkle's config."""
    problems: list[str] = []
    if info.get("CFBundleShortVersionString") != version:
        problems.append(f"built app is {info.get('CFBundleShortVersionString')}, "
                        f"expected {version}")
    if str(info.get("CFBundleVersion")) != str(build):
        problems.append(f"built app's build is {info.get('CFBundleVersion')}, expected {build}")
    for key, expected in cfg.expect_info.items():
        if info.get(key) != expected:
            problems.append(f"built app's {key} is {info.get(key)!r}, expected {expected!r}")
    if info.get("SUFeedURL") != cfg.feed_url:
        problems.append(f"built app's SUFeedURL is {info.get('SUFeedURL')!r}, expected "
                        f"{cfg.feed_url!r} (sparkle.feed_url)")
    if not info.get("LSMinimumSystemVersion"):
        problems.append("built app has no LSMinimumSystemVersion — the pkg's OS gate "
                        "is taken from it")
    sparkle = sparkle_config_problems(info)
    if sparkle:
        problems.append("built app's Sparkle configuration is broken: " + "; ".join(sparkle))
    return problems


def sparkle_public_key(cfg: ReleaseConfig) -> str:
    return project_setting(cfg.public_key_setting, cfg.project_yml.read_text())


def generate_keys_command(r: Release) -> str:
    return f"{r.sparkle_bin / 'generate_keys'} --account {r.cfg.sparkle_account}"


def public_key_failure(r: Release) -> str:
    return (f"{r.cfg.public_key_setting} is empty in project.yml — run "
            f"`{generate_keys_command(r)}`, paste the public key it prints into "
            "project.yml, and back the private key up with "
            f"`{generate_keys_command(r)} -x ~/.sparkle/{r.cfg.sparkle_account}-ed25519.key`")


def ensure_sparkle_tools(r: Release) -> None:
    """generate_keys/sign_update/generate_appcast ship in Sparkle's SPM binary
    artifact, which exists only once packages resolve into the DerivedData."""
    if (r.sparkle_bin / "generate_keys").exists():
        return
    cfg = r.cfg
    bullet(f"resolving packages into {r.derived_data} for Sparkle's tools")
    check(r.run(["xcodebuild", "-resolvePackageDependencies",
                 f"-{cfg.resolve_kind}", str(cfg.resolve_path),
                 "-scheme", cfg.resolve_scheme, "-derivedDataPath", str(r.derived_data),
                 "-skipPackagePluginValidation"]),
          "xcodebuild -resolvePackageDependencies")
    if not (r.sparkle_bin / "generate_keys").exists():
        raise RuntimeError(f"Sparkle's tools are not under {r.sparkle_bin} after resolving packages")


def enclosure_signature(appcast: Path, archive_name: str) -> str | None:
    """The `sparkle:edSignature` on the appcast enclosure whose URL ends in
    `archive_name`, or None when there is no such enclosure or it is unsigned."""
    for enclosure in ET.parse(appcast).getroot().iter("enclosure"):
        if enclosure.get("url", "").endswith(f"/{archive_name}"):
            return enclosure.get(f"{{{SPARKLE_NS}}}edSignature")
    return None


def step_sparkle_verify(r: Release) -> None:
    """Verify, before anything is published, that installed apps will accept
    this update. The EdDSA signing itself is generate_appcast's (step_appcast);
    this checks its result three ways:

    1. The Sparkle key in the keychain is the one the app ships with — the
       staged Info.plist's SUPublicEDKey. On a mismatch generate_appcast only
       warns and leaves the enclosure unsigned.
    2. The appcast enclosure for this zip carries a `sparkle:edSignature`, and
       `sign_update --verify <zip> <signature>` accepts it.
    3. `sign_update --verify appcast.xml` accepts the feed's own embedded
       signature (an app may set SURequireSignedFeed).
    """
    if r.publish_state == "push":
        step(f"Skipping sparkle-verify (appcast already committed in {r.releases_repo})")
        return
    step("Verifying the appcast's EdDSA signatures")
    account = r.cfg.sparkle_account
    shipped = plistlib.loads((r.app / "Contents/Info.plist").read_bytes()).get("SUPublicEDKey", "")
    keychain = check(r.run([str(r.sparkle_bin / "generate_keys"), "--account", account,
                            "-p"]), "generate_keys -p").stdout.strip()
    if keychain != shipped:
        raise RuntimeError(
            f"the keychain's Sparkle key ({keychain or 'none'}) is not the app's SUPublicEDKey "
            f"({shipped or 'empty'}) — installed apps would reject this update; set "
            f"{r.cfg.public_key_setting} in project.yml to the keychain's public key "
            f"(`{generate_keys_command(r)} -p`) and rebuild")
    signature = enclosure_signature(r.appcast_path, r.zip_path.name)
    if not signature:
        raise RuntimeError(f"{r.appcast_path} has no sparkle:edSignature on the "
                           f"{r.zip_path.name} enclosure — generate_appcast did not sign it")
    sign_update = str(r.sparkle_bin / "sign_update")
    check(r.run([sign_update, "--account", account, "--verify", str(r.zip_path),
                 signature]), f"sign_update --verify {r.zip_path.name}")
    bullet(f"{r.zip_path.name}: edSignature verifies")
    check(r.run([sign_update, "--account", account, "--verify", str(r.appcast_path)]),
          "sign_update --verify appcast.xml")
    bullet("appcast.xml: feed signature verifies")


def generate_appcast(r: Release) -> Path:
    """Run generate_appcast over a directory holding only this release's zip,
    its notes, and a copy of the published appcast.xml, so every earlier item
    is carried over from the feed itself rather than from old archives.

    The notes go in as `<zip stem>.md`, the name generate_appcast pairs with
    the archive, and are embedded (Sparkle 2.9+ renders Markdown). They are
    not linked: generate_appcast derives a notes URL only from the archive's
    name, which cannot reach notes/<version>.md.
    --maximum-versions 0 keeps every earlier item instead of the default 3.
    """
    archives = r.appcast_path.parent
    if archives.exists():
        shutil.rmtree(archives)
    archives.mkdir(parents=True)
    shutil.copy2(r.zip_path, archives / r.zip_path.name)
    if r.notes.exists():
        shutil.copy2(r.notes, archives / f"{r.zip_path.stem}.md")
    published = r.releases_repo / "appcast.xml"
    if published.exists():
        shutil.copy2(published, archives / "appcast.xml")
    check(r.run([str(r.sparkle_bin / "generate_appcast"),
                 "--account", r.cfg.sparkle_account,
                 "--download-url-prefix", f"{r.cfg.download_prefix}/{r.tag}/",
                 "--embed-release-notes",
                 "--maximum-versions", "0",
                 "-o", str(r.appcast_path),
                 str(archives)]), "generate_appcast")
    return r.appcast_path


def step_appcast(r: Release) -> None:
    """Generate the feed locally, before anything goes public; step_publish
    commits it together with releases.json and the notes."""
    if r.publish_state == "push":
        step(f"Skipping appcast (already committed in {r.releases_repo})")
        return
    step("Generating appcast.xml (local; published with the release commit)")
    bullet(str(generate_appcast(r)))
