#!/usr/bin/env python3
"""The release CLI every macOS app runs: one pipeline, driven by the app's release.json.

    python3 release_macos_app.py [--repo PATH] <command> ...

Commands: status, bump, hook, warnings, build, install, installed, prepared, publish,
verify. `--repo` (also accepted after the command) defaults to the git toplevel of the
current directory. Exit codes: 0 ok, 1 failed (each failure printed), 2 a bad invocation
or a bad release.json.

See docs/release-macos-app.md.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Callable

from macos_app_release import (build_pipeline, install as install_mod,
                               prepared, publish, verify, versions, warnings)
from macos_app_release.config import ReleaseConfig, ReleaseConfigError, load_config
from macos_app_release.shell import (HookError, Runner, main_checkout, run_hook,
                                     subprocess_runner)
from macos_app_release.state import Release

#: runner_factory(verbose, cwd=path_or_None) -> Runner. Tests inject a fake one.
RunnerFactory = Callable[..., Runner]

HOOK_NAMES = ("tests", "health")


class UsageError(Exception):
    """A bad invocation or an unusable repo: exit 2, message to stderr."""


# Parser ------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="release_macos_app.py", description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--repo", help="the app repo (default: git toplevel of the cwd)")
    sub = parser.add_subparsers(dest="command", required=True, metavar="command")

    def command(name: str, help: str) -> argparse.ArgumentParser:
        p = sub.add_parser(name, help=help, description=help)
        # Accepted after the command too, without overwriting one given before it.
        p.add_argument("--repo", default=argparse.SUPPRESS, help="the app repo")
        return p

    def pipeline_flags(p: argparse.ArgumentParser, *, site: bool = True,
                       artifacts: bool = True) -> None:
        p.add_argument("--branch", help="the source branch the run must be on and pushed "
                                        "(default: source.branch)")
        if artifacts:
            p.add_argument("--artifacts-root", help="where <version>/ lives "
                                                    "(default: <repo>/build/release)")
        if site:
            p.add_argument("--site", metavar="ORIGIN",
                           help="probe this site origin instead of the sparkle.feed_url host")
        p.add_argument("-v", "--verbose", action="store_true", help="echo every command")

    p = command("status", "Validate release.json and print the resolved release facts.")
    p.add_argument("--json", action="store_true")

    p = command("bump", "Bump the version and build in project.yml and every must_match file.")
    p.add_argument("kind", choices=("patch", "minor"))
    p.add_argument("--json", action="store_true")

    p = command("hook", "Run one configured hook, passing its exit code through.")
    p.add_argument("name", choices=HOOK_NAMES)

    p = command("warnings", "Clean warnings build, then hold its log to the allowlist.")
    p.add_argument("--log-dir", help="where warnings-build.log goes (default: the temp dir)")
    p.add_argument("--json", action="store_true")

    p = command("build", "The notarized build. Publishes nothing.")
    pipeline_flags(p)

    p = command("install", "No-sudo swap-install of the update zip.")
    p.add_argument("zip", help="the <App>-<version>.zip the build left")
    p.add_argument("--apps-dir", help="install here instead of install.apps_dir")

    p = command("installed", "Check the installed copy is this version, signed and running.")
    p.add_argument("--apps-dir", help="look here instead of install.apps_dir")
    p.add_argument("--json", action="store_true")

    p = command("prepared", "Main, its tag and the artifacts all name one commit.")
    pipeline_flags(p, site=False)
    p.add_argument("--json", action="store_true")

    p = command("publish", "Publish what build left. Idempotent and resumable.")
    pipeline_flags(p)

    p = command("verify", "Prove the live release is this build. Read-only.")
    p.add_argument("version", nargs="?", help="verify this version (default: project.yml's)")
    p.add_argument("--version", dest="version_flag", metavar="VERSION",
                   help="same as the positional VERSION")
    p.add_argument("--site", metavar="ORIGIN")
    p.add_argument("--timeout", type=float, default=verify.DEFAULT_TIMEOUT,
                   help=f"seconds to keep polling (default {verify.DEFAULT_TIMEOUT:g}; 0 = once)")
    p.add_argument("--interval", type=float, default=verify.DEFAULT_INTERVAL,
                   help=f"seconds between polls (default {verify.DEFAULT_INTERVAL:g})")
    p.add_argument("--artifacts-root", help="where <version>/ lives (default: <repo>/build/release)")
    p.add_argument("--json", action="store_true")
    return parser


# Context -----------------------------------------------------------------------


def _repo_path(args: argparse.Namespace, factory: RunnerFactory) -> Path:
    if getattr(args, "repo", None):
        return Path(os.path.abspath(os.path.expanduser(args.repo)))
    proc = factory(False, cwd=None)(["git", "rev-parse", "--show-toplevel"])
    top = (proc.stdout or "").strip()
    if proc.returncode != 0 or not top:
        raise UsageError("no --repo given and the current directory is not in a git "
                         "repository")
    return Path(top)


def _load(repo: Path, factory: RunnerFactory) -> ReleaseConfig:
    """release.json for `repo`; main_checkout comes from git (the repo itself when git
    cannot say, e.g. a directory that is not a repository)."""
    try:
        main = main_checkout(repo, factory(False, cwd=repo))
    except (RuntimeError, OSError):
        main = repo
    if str(main) in ("", "."):
        main = repo
    return load_config(repo, main_checkout=main)


def _versions(cfg: ReleaseConfig) -> tuple[str, int]:
    try:
        return versions.read_versions(cfg)
    except (OSError, ValueError) as exc:
        raise ReleaseConfigError([f"cannot read the version from {cfg.project_yml}: {exc}"])


def _release(args: argparse.Namespace, cfg: ReleaseConfig, factory: RunnerFactory, *,
             publish_mode: bool = False) -> Release:
    version, build = _versions(cfg)
    root = getattr(args, "artifacts_root", None)
    verbose = getattr(args, "verbose", False)
    return Release(cfg=cfg, version=version, build_number=build,
                   run=factory(verbose, cwd=cfg.repo), verbose=verbose, publish=publish_mode,
                   branch=getattr(args, "branch", None), site=getattr(args, "site", None),
                   artifacts_root=Path(os.path.abspath(os.path.expanduser(root))) if root
                   else None)


# Commands ----------------------------------------------------------------------


def latest_published(cfg: ReleaseConfig, run: Runner) -> dict | None:
    """The newest release on the releases repo as {"version", "publishedAt"}, or None
    when there is none (or gh cannot say). Asks GitHub through the injected runner."""
    argv = ["gh", "release", "view", "--repo", cfg.github_repo, "--json",
            "tagName,publishedAt"]
    try:
        proc = run(argv)
    except OSError as exc:
        print(f"warning: latest_published unavailable ({exc})", file=sys.stderr)
        return None
    if proc.returncode != 0:
        why = ((proc.stderr or "") + (proc.stdout or "")).strip()
        if "not found" not in why.lower():
            print(f"warning: latest_published unavailable ({why or 'gh failed'})",
                  file=sys.stderr)
        return None
    try:
        data = json.loads(proc.stdout)
        return {"version": str(data["tagName"]).removeprefix("v"),
                "publishedAt": data["publishedAt"]}
    except (json.JSONDecodeError, KeyError, TypeError):
        print("warning: latest_published unavailable (gh returned unreadable JSON)",
              file=sys.stderr)
        return None


def cmd_status(args: argparse.Namespace, cfg: ReleaseConfig, factory: RunnerFactory,
               **_: object) -> int:
    version, build = _versions(cfg)
    notes = cfg.notes_path(version)
    status = {
        "app": cfg.app_name,
        "version": version,
        "build": build,
        "notes": str(notes),
        "notes_exists": notes.exists(),
        "source_tag": cfg.source_tag(version),
        "releases_checkout": str(cfg.releases_checkout),
        "latest_published": latest_published(cfg, factory(False, cwd=cfg.repo)),
        "hooks": {"tests": bool(cfg.hook_tests),
                  "warnings_build": bool(cfg.hook_warnings_build),
                  "health": bool(cfg.hook_health)},
        "artifacts_default": str(cfg.repo / "build/release"),
        "toolkit": str(cfg.toolkit),
    }
    if args.json:
        print(json.dumps(status, indent=2))
        return 0
    latest = status["latest_published"]
    print(f"{cfg.app_name} {version} (build {build})")
    print(f"  notes:             {notes}{'' if status['notes_exists'] else '  (missing)'}")
    print(f"  source tag:        {status['source_tag']}")
    print(f"  releases checkout: {cfg.releases_checkout}")
    print("  latest published:  " + (f"{latest['version']} ({latest['publishedAt']})"
                                     if latest else "none"))
    print("  hooks:             " + ", ".join(
        f"{name}={'set' if on else 'unset'}" for name, on in status["hooks"].items()))
    print(f"  artifacts:         {status['artifacts_default']}")
    print(f"  toolkit:           {cfg.toolkit}")
    return 0


def cmd_bump(args: argparse.Namespace, cfg: ReleaseConfig, factory: RunnerFactory,
             **_: object) -> int:
    try:
        version, build = versions.bump(cfg, args.kind, run=factory(False, cwd=cfg.repo))
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    if args.json:
        print(json.dumps({"version": version, "build": build}))
    else:
        print(f"{version} (build {build})")
    return 0


def cmd_hook(args: argparse.Namespace, cfg: ReleaseConfig, factory: RunnerFactory,
             **_: object) -> int:
    argv = getattr(cfg, f"hook_{args.name}")
    if not argv:
        print(f"error: {args.name} hook is not configured", file=sys.stderr)
        return 2
    try:
        return run_hook(argv, cwd=cfg.repo, env={})
    except HookError as exc:
        print(f"error: hooks.{args.name} could not run: {exc}", file=sys.stderr)
        return 1


def cmd_warnings(args: argparse.Namespace, cfg: ReleaseConfig, factory: RunnerFactory,
                 **_: object) -> int:
    try:
        return warnings.run_warnings(
            cfg, log_dir=Path(os.path.abspath(args.log_dir)) if args.log_dir else None,
            as_json=args.json)
    except ValueError as exc:
        raise ReleaseConfigError(str(exc).splitlines())


def cmd_build(args: argparse.Namespace, cfg: ReleaseConfig, factory: RunnerFactory,
              **_: object) -> int:
    return build_pipeline.run_build(_release(args, cfg, factory))


def cmd_install(args: argparse.Namespace, cfg: ReleaseConfig, factory: RunnerFactory,
                **_: object) -> int:
    apps_dir = Path(os.path.abspath(os.path.expanduser(args.apps_dir))) if args.apps_dir \
        else None
    return install_mod.install(Path(os.path.abspath(args.zip)), cfg, apps_dir=apps_dir,
                               run=factory(False, cwd=cfg.repo))


def cmd_installed(args: argparse.Namespace, cfg: ReleaseConfig, factory: RunnerFactory,
                  **_: object) -> int:
    apps_dir = Path(os.path.abspath(os.path.expanduser(args.apps_dir))) if args.apps_dir \
        else None
    failures = install_mod.installed_failures(cfg, apps_dir=apps_dir,
                                              run=factory(False, cwd=cfg.repo))
    health: int | None = None
    if not failures and cfg.hook_health:
        if not args.json:
            print("running the health hook")
        try:
            health = run_hook(cfg.hook_health, cwd=cfg.repo, env={})
        except HookError as exc:
            failures.append(f"hooks.health could not run: {exc}")
        else:
            if health != 0:
                failures.append(f"the health hook exited {health}")
    ok = not failures
    if args.json:
        print(json.dumps({"ok": ok, "failures": failures,
                          "health_hook": None if health is None else health == 0}, indent=2))
    elif ok:
        version, build = _versions(cfg)
        print(f"✓ {cfg.app_name} {version} (build {build}) is installed, signed Developer "
              "ID, layout-correct and running"
              + ("; health hook passed" if health is not None else ""))
    else:
        for failure in failures:
            print(f"✗ {failure}")
    return 0 if ok else 1


def cmd_prepared(args: argparse.Namespace, cfg: ReleaseConfig, factory: RunnerFactory,
                 **_: object) -> int:
    return prepared.run_prepared(_release(args, cfg, factory), as_json=args.json)


def cmd_publish(args: argparse.Namespace, cfg: ReleaseConfig, factory: RunnerFactory,
                **_: object) -> int:
    return publish.run_publish(_release(args, cfg, factory, publish_mode=True))


def cmd_verify(args: argparse.Namespace, cfg: ReleaseConfig, factory: RunnerFactory, *,
               fetch: verify.Fetch, **_: object) -> int:
    if args.version and args.version_flag and args.version != args.version_flag:
        raise UsageError("verify: VERSION and --version disagree")
    root = args.artifacts_root
    return verify.run_verify(
        cfg, version=args.version_flag or args.version, site=args.site,
        timeout=args.timeout, interval=args.interval, as_json=args.json, fetch=fetch,
        run=factory(False, cwd=cfg.repo),
        artifacts_root=Path(os.path.abspath(os.path.expanduser(root))) if root else None)


COMMANDS = {"status": cmd_status, "bump": cmd_bump, "hook": cmd_hook,
            "warnings": cmd_warnings, "build": cmd_build, "install": cmd_install,
            "installed": cmd_installed, "prepared": cmd_prepared, "publish": cmd_publish,
            "verify": cmd_verify}


# Entry point -------------------------------------------------------------------


def main(argv: list[str] | None = None, *, runner_factory: RunnerFactory = subprocess_runner,
         fetch: verify.Fetch = verify.http_fetch) -> int:
    """Run one command. `runner_factory(verbose, cwd=...)` builds the Runner every external
    command goes through and `fetch` serves every HTTP request, so tests inject fakes."""
    try:
        args = build_parser().parse_args(argv)
    except SystemExit as exc:  # argparse: --help is 0, a usage error is 2
        return exc.code if isinstance(exc.code, int) else (0 if exc.code is None else 2)
    try:
        cfg = _load(_repo_path(args, runner_factory), runner_factory)
        return COMMANDS[args.command](args, cfg, runner_factory, fetch=fetch)
    except ReleaseConfigError as exc:
        for problem in exc.problems:
            print(f"error: {problem}", file=sys.stderr)
        return 2
    except UsageError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
