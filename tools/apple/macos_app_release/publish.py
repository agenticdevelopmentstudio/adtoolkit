"""The publish pipeline: GitHub release, then one commit to the releases repo.

A port of Stenographer's release.py publish half. `publish_state` decides what an
interrupted run has left to do ("create" the GitHub release, "commit" the releases
repo, or "push" what is already committed); `step_publish` does exactly that.
Nothing here talks to GitHub except through `r.run`.

`build_pipeline` is imported inside the functions that need it: it consumes this module's
`publish_state`, so a top-level import would be circular.
"""
from __future__ import annotations

import json
import shutil
import sys
from typing import Callable

import macos_release as mr

from . import sparkle
from .config import ReleaseConfig
from .shell import bullet, check, step
from .state import AlreadyPublished, Release, git_count

PUBLISH_STEPS = ["preflight", "appcast", "sparkle-verify", "publish"]


def release_files(cfg: ReleaseConfig) -> tuple[str, ...]:
    """What the release commit holds, relative to the releases checkout;
    `{version}` is filled in by the caller."""
    return ("releases.json", "notes/{version}.md", "appcast.xml", cfg.cask_file)


def load_releases_json(r: Release) -> dict:
    path = r.releases_repo / "releases.json"
    return json.loads(path.read_text()) if path.exists() else {"schema": 1, "releases": []}


def github_release_assets(r: Release) -> list[dict] | None:
    """The tag's release assets on GitHub, or None when there is no release."""
    view = r.run(["gh", "release", "view", r.tag, "--repo", r.cfg.github_repo,
                  "--json", "assets"])
    if view.returncode != 0:
        if "not found" in (view.stderr or "").lower():
            return None
        raise mr.PreflightError(f"gh release view {r.tag} failed: {(view.stderr or '').strip()}")
    try:
        return json.loads(view.stdout or "{}").get("assets", [])
    except json.JSONDecodeError as exc:
        raise mr.PreflightError(f"gh release view {r.tag} returned unreadable JSON: {exc}")


def asset_mismatches(r: Release, assets: list[dict]) -> list[str]:
    remote = {a.get("name"): a for a in assets}
    problems: list[str] = []
    for local in (r.pkg_path, r.zip_path):
        mine = mr.asset_for(local, "")
        theirs = remote.get(local.name)
        if theirs is None:
            problems.append(f"{local.name} is not attached")
            continue
        if theirs.get("size") != mine.size:
            problems.append(f"{local.name} is {theirs.get('size')} bytes on GitHub, "
                            f"{mine.size} locally")
        digest = theirs.get("digest")
        if digest and digest != f"sha256:{mine.sha256}":
            problems.append(f"{local.name}'s sha256 differs from the local file")
    extra = sorted(set(remote) - {r.pkg_path.name, r.zip_path.name})
    if extra:
        problems.append(f"unexpected assets attached: {', '.join(map(str, extra))}")
    return problems


def publish_state(r: Release) -> str:
    """What an interrupted publish has left to do: "create", "commit" or "push".
    Raises AlreadyPublished when nothing is left, PreflightError when GitHub and
    the releases repo disagree with each other or with the local artifacts."""
    cfg = r.cfg
    assets = github_release_assets(r)
    listed = r.version in {e.get("version") for e in load_releases_json(r).get("releases", [])}
    if assets is None:
        if listed:
            raise mr.PreflightError(
                f"releases.json in {r.releases_repo} lists {r.version} but GitHub has no "
                f"release {r.tag} — repair the releases repo by hand")
        bullet(f"no GitHub release {r.tag} yet — publishing from {r.out}")
        return "create"
    problems = asset_mismatches(r, assets)
    if problems:
        raise mr.PreflightError(
            f"GitHub release {r.tag} exists but does not match {r.out}: {'; '.join(problems)} — "
            f"delete it with `gh release delete {r.tag} --repo {cfg.github_repo} "
            "--cleanup-tag` and run publish again")
    if not listed:
        bullet(f"GitHub release {r.tag} exists with matching assets — committing the release")
        return "commit"
    if git_count(r, f"origin/{cfg.releases_branch}..HEAD") > 0:
        bullet(f"{r.version} is committed in {r.releases_repo} but not pushed — pushing")
        return "push"
    raise AlreadyPublished(f"{r.version} is already published — nothing to do")


def step_publish(r: Release) -> None:
    from . import build_pipeline, cask

    cfg = r.cfg
    repo = r.releases_repo
    if r.publish_state != "push":
        if not r.appcast_path.exists():
            raise RuntimeError(f"{r.appcast_path} is missing — the appcast step must run first")
        # Everything the commit holds is computed before the first remote step,
        # so a cask that cannot be rendered stops the release before it is public.
        entry = build_pipeline.release_entry(r)
        cask_text = cask.cask_ruby(entry, cfg)

    if r.publish_state in ("commit", "push"):
        step(f"GitHub release {r.tag} already exists with matching assets — not recreating it")
    else:
        step(f"Publishing {r.tag} to {cfg.github_repo}")
        mr.publish_github_release(repo=cfg.github_repo, tag=r.tag,
                                  title=f"{cfg.title} {r.version}", notes_file=r.notes,
                                  assets=[r.pkg_path, r.zip_path], run=r.run)

    if r.publish_state != "push":
        merged = mr.merge_release(load_releases_json(r), entry)
        (repo / "releases.json").write_text(json.dumps(merged, indent=2) + "\n")
        (repo / "notes").mkdir(exist_ok=True)
        shutil.copy2(r.notes, repo / "notes" / f"{r.version}.md")
        shutil.copy2(r.appcast_path, repo / "appcast.xml")
        (repo / cfg.cask_file).parent.mkdir(parents=True, exist_ok=True)
        (repo / cfg.cask_file).write_text(cask_text)
        paths = [p.format(version=r.version) for p in release_files(cfg)]
        check(r.run(["git", "-C", str(repo), "add", "--", *paths]), "git add")
        check(r.run(["git", "-C", str(repo), "commit", "-m", f"Release {r.version}"]),
              "git commit")
    check(r.run(["git", "-C", str(repo), "push", "origin", cfg.releases_branch]),
          "git push (run publish again once it can succeed)")
    bullet(f"Release {r.version}: releases.json, notes, appcast.xml and the Homebrew cask "
           f"pushed from {repo}")


def publish_step_functions() -> dict[str, Callable[[Release], None]]:
    from . import build_pipeline

    return {
        "preflight": build_pipeline.step_preflight,
        "appcast": sparkle.step_appcast,
        "sparkle-verify": sparkle.step_sparkle_verify,
        "publish": step_publish,
    }


def run_publish(r: Release) -> int:
    """Run PUBLISH_STEPS in order; return the process exit code (0 or 1).

    preflight sets r.publish_state; "push" makes the appcast and sparkle-verify
    steps skip themselves. AlreadyPublished prints and returns 0.
    """
    r.publish = True
    steps = publish_step_functions()
    try:
        for name in PUBLISH_STEPS:
            steps[name](r)
    except AlreadyPublished as done:
        print(f"✓ {done}")
        return 0
    except mr.PreflightError as exc:
        print(f"error: preflight failed:\n{exc}", file=sys.stderr)
        return 1
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    print()
    print(f"✓ Release {r.version} complete")
    print(f"  pkg: {r.pkg_path}")
    print(f"  zip: {r.zip_path}")
    print(f"  source: {r.source_sha}")
    return 0
