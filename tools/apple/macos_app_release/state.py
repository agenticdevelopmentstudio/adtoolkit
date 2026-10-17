"""One run's derived paths and state, and the provenance record that ties artifacts to a commit."""
from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from pathlib import Path

import macos_release as mr

from .config import ReleaseConfig, read_env_file
from .shell import Runner

PROVENANCE = "provenance.json"
SPARKLE_BIN_REL = Path("SourcePackages/artifacts/sparkle/Sparkle/bin")

#: What failure messages tell the owner to run: the skill, which finds where the
#: version stands and prepares, rebuilds or finishes publishing it.
RELEASE_CMD = "/release"


class AlreadyPublished(Exception):
    """publish found nothing left to do."""


@dataclass
class Release:
    cfg: ReleaseConfig
    version: str
    build_number: int
    run: Runner
    verbose: bool = False
    publish: bool = False
    branch: str | None = None           # None -> cfg.source_branch
    site: str | None = None             # origin override; None -> cfg.site_origin
    # Where <version>/ lives; None = build/release inside the repo.
    artifacts_root: Path | None = None
    releases_repo: Path | None = None   # None -> cfg.releases_checkout
    derived_data: Path | None = None    # None -> cfg.derived_data
    env: dict[str, str] = field(default_factory=lambda: dict(os.environ))
    # Filled in as the steps run.
    bin_path: Path | None = None
    team: str | None = None
    profiles: dict[str, Path] = field(default_factory=dict)
    minimum_system_version: str = ""
    # The commit being built (preflight reads it); recorded in provenance.json.
    source_sha: str | None = None
    # publish only: "create", "commit" or "push" -- what publishing has left to do.
    publish_state: str | None = None

    def __post_init__(self) -> None:
        if self.branch is None:
            self.branch = self.cfg.source_branch
        if self.releases_repo is None:
            self.releases_repo = self.cfg.releases_checkout
        if self.derived_data is None:
            self.derived_data = self.cfg.derived_data
        if self.cfg.env_file is not None:
            for key, value in read_env_file(self.cfg.env_file).items():
                self.env.setdefault(key, value)

    @property
    def repo(self) -> Path:
        return self.cfg.repo

    @property
    def out(self) -> Path:
        return (self.artifacts_root or self.repo / "build/release") / self.version

    @property
    def app(self) -> Path:
        return self.out / "staging" / f"{self.cfg.app_name}.app"

    @property
    def zip_path(self) -> Path:
        return self.out / f"{self.cfg.asset_basename}-{self.version}.zip"

    @property
    def pkg_path(self) -> Path:
        return self.out / f"{self.cfg.asset_basename}-{self.version}.pkg"

    @property
    def appcast_path(self) -> Path:
        return self.out / "appcast" / "appcast.xml"

    @property
    def notes(self) -> Path:
        return self.cfg.notes_path(self.version)

    @property
    def tag(self) -> str:
        """The GitHub release's tag on the public releases repo."""
        return f"v{self.version}"

    @property
    def source_tag(self) -> str:
        """This repo's tag on the commit the release was built from."""
        return self.cfg.source_tag(self.version)

    @property
    def sparkle_bin(self) -> Path:
        return self.derived_data / SPARKLE_BIN_REL

    @property
    def provenance_path(self) -> Path:
        return self.out / PROVENANCE

    @property
    def origin(self) -> str:
        return self.site or self.cfg.site_origin


def sha256_of(path: Path) -> str:
    return mr.asset_for(path, "").sha256


def head_sha(r: Release) -> str | None:
    proc = r.run(["git", "-C", str(r.repo), "rev-parse", "--verify", "HEAD^{commit}"])
    sha = (proc.stdout or "").strip()
    return sha if proc.returncode == 0 and sha else None


def tag_sha(r: Release) -> str | None:
    """The commit r.source_tag names in r.repo, or None when there is no such tag."""
    proc = r.run(["git", "-C", str(r.repo), "rev-parse", "--verify", "--quiet",
                  f"refs/tags/{r.source_tag}^{{commit}}"])
    sha = (proc.stdout or "").strip()
    return sha if proc.returncode == 0 and sha else None


def source_tag_failures(r: Release) -> list[str]:
    """publish ships the commit prepare tagged, and nothing else."""
    tagged = tag_sha(r)
    if tagged is None:
        return [f"no tag {r.source_tag} in {r.repo} -- {RELEASE_CMD} tags the commit it "
                "built; run it first"]
    if tagged != r.source_sha:
        return [f"{r.source_tag} is {tagged[:12]} but HEAD is {(r.source_sha or '?')[:12]} -- "
                f"{r.cfg.source_branch} moved after {RELEASE_CMD}; run {RELEASE_CMD} again"]
    return []


def write_provenance(r: Release, *, notarized: bool) -> None:
    r.provenance_path.write_text(json.dumps({
        "version": r.version,
        "build": r.build_number,
        "source_sha": r.source_sha,
        "notarized": notarized,
        "pkg_sha256": sha256_of(r.pkg_path),
        "zip_sha256": sha256_of(r.zip_path),
    }, indent=2) + "\n")


def artifact_failures(r: Release) -> list[str]:
    """publish publishes what is on disk without rebuilding it, so prove it is
    what a finished build of HEAD left: a provenance record saying so, digests that
    still match it, and signatures Gatekeeper accepts."""
    rerun = f"run {RELEASE_CMD} to rebuild them"
    try:
        record = json.loads(r.provenance_path.read_text())
    except FileNotFoundError:
        return [f"{r.provenance_path} is missing -- nothing shows the artifacts in {r.out} "
                f"came from a finished release run; {rerun}"]
    except json.JSONDecodeError as exc:
        return [f"{r.provenance_path} is unreadable ({exc}); {rerun}"]
    if not record.get("notarized"):
        return [f"the pkg in {r.out} was never notarized (the run stopped before "
                f"notarize-pkg finished); {rerun}"]
    failures: list[str] = []
    if not r.source_sha or record.get("source_sha") != r.source_sha:
        failures.append(f"{r.out} was built from {str(record.get('source_sha'))[:12]}, not "
                        f"HEAD {(r.source_sha or '?')[:12]}; {rerun}")
    if (record.get("version"), record.get("build")) != (r.version, r.build_number):
        failures.append(f"{r.out} holds build {record.get('version')} "
                        f"({record.get('build')}), not {r.version} ({r.build_number}); {rerun}")
    for key, path in (("pkg_sha256", r.pkg_path), ("zip_sha256", r.zip_path)):
        if record.get(key) != sha256_of(path):
            failures.append(f"{path.name} changed after the run that built it; {rerun}")
    checks = [
        (["xcrun", "stapler", "validate", str(r.pkg_path)], "the pkg's notarization ticket"),
        (["spctl", "--assess", "--type", "install", "-vv", str(r.pkg_path)],
         "Gatekeeper's install assessment of the pkg"),
        (["codesign", "--verify", "--deep", "--strict", str(r.app)],
         "the staged app's signature"),
    ]
    for argv, what in checks:
        proc = r.run(argv)
        if proc.returncode != 0:
            failures.append(f"{what} does not verify (`{' '.join(argv[:3])} ...` exit "
                            f"{proc.returncode}: {(proc.stderr or proc.stdout or '').strip()}); "
                            f"{rerun}")
    shown = r.run(["codesign", "-d", "--verbose=2", str(r.app)])
    identity = r.cfg.app_identity
    if f"Authority={identity}" not in (shown.stderr or "") + (shown.stdout or ""):
        failures.append(f"the staged app is not signed '{identity}'; {rerun}")
    return failures


def git_count(r: Release, revs: str) -> int:
    out = (r.run(["git", "-C", str(r.releases_repo), "rev-list", "--count", revs]).stdout
           or "0").strip()
    return int(out) if out.isdigit() else 0
