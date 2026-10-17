"""Verify a prepare run landed: the source branch, its release tag and the built
artifacts all name the same commit.

prepare builds the release from its worktree, fast-forwards the source branch
onto that commit, and tags it. This proves that happened, so publish can ship
what is on disk without rebuilding it:

    main      the checkout is on the source branch, its tracked files are clean,
              and HEAD is origin/<branch> (fetched first)
    tag       the source tag exists and names HEAD
    version   every must_match file carries the version, and the release notes exist
    artifacts provenance.json says a real, notarized build of HEAD at this
              version and build made them, their digests still match it, and the
              signatures verify
    staged    the staged app and each nested bundle carry this version and build

Read-only: it fetches, and changes nothing.
"""
from __future__ import annotations

import json
import plistlib
import subprocess

from . import state, versions
from .state import Release


def git(r: Release, *args: str) -> subprocess.CompletedProcess[str]:
    return r.run(["git", "-C", str(r.repo), *args])


def main_failures(r: Release) -> list[str]:
    failures: list[str] = []
    fetch = git(r, "fetch", "--quiet", "origin", r.branch)
    if fetch.returncode != 0:
        failures.append(f"cannot fetch origin {r.branch}: {(fetch.stderr or '').strip()}")
    branch = (git(r, "rev-parse", "--abbrev-ref", "HEAD").stdout or "").strip()
    if branch != r.branch:
        failures.append(f"{r.repo} is on {branch!r}, not {r.branch}")
    dirty = (git(r, "status", "--porcelain", "--untracked-files=no").stdout or "").strip()
    if dirty:
        failures.append(f"{r.repo} has uncommitted changes:\n{dirty}")
    origin = (git(r, "rev-parse", "--verify", "--quiet", f"origin/{r.branch}").stdout
              or "").strip()
    if r.source_sha is None:
        failures.append(f"cannot read HEAD in {r.repo}")
    elif origin != r.source_sha:
        failures.append(f"HEAD {r.source_sha[:12]} is not origin/{r.branch} "
                        f"{origin[:12] or '?'} -- push it, or {r.branch} moved after "
                        f"{state.PREPARE_CMD}; prepare again")
    return failures


def staged_failures(r: Release) -> list[str]:
    failures: list[str] = []
    bundles = [("staged app", r.app)]
    bundles += [(f"staged {rel}", r.app / rel) for rel in r.cfg.nested_bundles]
    for label, bundle in bundles:
        plist = bundle / "Contents/Info.plist"
        if not plist.exists():
            failures.append(f"{label}: {plist} is missing")
            continue
        info = plistlib.loads(plist.read_bytes())
        got = (info.get("CFBundleShortVersionString"), info.get("CFBundleVersion"))
        if got != (r.version, str(r.build_number)):
            failures.append(f"{label} is {got[0]} ({got[1]}), not {r.version} ({r.build_number})")
    return failures


def prepared_failures(r: Release) -> dict[str, list[str]]:
    r.source_sha = state.head_sha(r)
    results = {
        "main": main_failures(r),
        "tag": state.source_tag_failures(r),
        "version": versions.must_match_failures(r.cfg, r.version)
                   + ([] if r.notes.exists() else [f"release notes missing -- {r.notes}"]),
    }
    missing = [p for p in (r.pkg_path, r.zip_path) if not p.exists()]
    results["artifacts"] = ([f"{p} is missing" for p in missing] if missing
                            else state.artifact_failures(r))
    results["staged"] = staged_failures(r)
    return results


def run_prepared(r: Release, *, as_json: bool) -> int:
    results = prepared_failures(r)
    ok = not any(results.values())
    if as_json:
        print(json.dumps({"ok": ok, "version": r.version, "build": r.build_number,
                          "sha": r.source_sha, "tag": r.source_tag, "checks": results},
                         indent=2))
    else:
        for name, failures in results.items():
            print(f"{'ok  ' if not failures else 'FAIL'} {name}")
            for failure in failures:
                print(f"    {failure}")
        print(f"\n{'prepared' if ok else 'NOT PREPARED'}: {r.version} ({r.build_number}) "
              f"{r.source_tag} @ {(r.source_sha or '?')[:12]}")
    return 0 if ok else 1
