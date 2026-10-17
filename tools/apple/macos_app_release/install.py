"""Install a released app from its Sparkle zip, without sudo; check the installed copy.

`install` unpacks the zip beside the install, checks the unpacked bundle against
the layout, and only then quits the installed app (only the pids running from the
bundle in the apps directory, so a Debug build from a worktree survives), swaps it
in and opens it.

The old bundle is moved aside, not deleted, until the new one is in place; if the
second move fails the old one goes back. When the installed app belongs to another
user (the first-install .pkg makes it root's) this quits the installed app,
refuses, and prints the one-time `sudo installer` command for the owner to run and
the `open` to follow it; it never runs sudo.

`installed_failures` proves the copy in the apps directory is this version and
build, signed Developer ID, layout-correct and running.
"""
from __future__ import annotations

import os
import plistlib
import shutil
import subprocess
import time
from pathlib import Path
from typing import Callable

from . import processes, versions
from .config import ReleaseConfig
from .shell import Runner

QUIT_TIMEOUT_S = 10.0
# How long a SIGKILLed pid may linger before the swap goes ahead anyway: a
# running copy keeps its old inode, so the rename is still safe.
REAP_TIMEOUT_S = 5.0


def run_command(argv: list[str]) -> "subprocess.CompletedProcess[str]":
    return subprocess.run(argv, capture_output=True, text=True)


def quit_app(app: Path, *, pids: Callable[[Path], list[int]],
             kill: Callable[[int, int], None], sleep: Callable[[float], None],
             monotonic: Callable[[], float]) -> list[int]:
    """SIGTERM this user's pids inside `app`, wait up to QUIT_TIMEOUT_S, then
    SIGKILL. Returns any that still have not exited."""
    return processes.quit_pids(lambda: pids(app), term_wait=QUIT_TIMEOUT_S,
                               kill_wait=REAP_TIMEOUT_S, kill=kill, sleep=sleep,
                               monotonic=monotonic)


def install(zip_path: Path, cfg: ReleaseConfig, *, apps_dir: Path | None = None,
            run: Runner = run_command,
            pids: Callable[[Path], list[int]] = processes.bundle_pids,
            kill: Callable[[int, int], None] = os.kill,
            sleep: Callable[[float], None] = time.sleep,
            monotonic: Callable[[], float] = time.monotonic,
            rename: Callable[[Path, Path], object] = os.rename,
            pid: int | None = None, uid: int | None = None,
            say: Callable[[str], None] = print) -> int:
    """Order: ownership check, extract, layout gate, quit, swap, open. A bad zip
    leaves the running app untouched; the swap is two same-volume renames.
    Returns 0 on success, 1 on any refusal."""
    from . import layout

    apps_dir = cfg.apps_dir if apps_dir is None else apps_dir
    pid = os.getpid() if pid is None else pid
    uid = os.getuid() if uid is None else uid
    app_name = f"{cfg.app_name}.app"
    dest = apps_dir / app_name
    if dest.is_symlink():
        say(f"error: {dest} is a symlink; remove it or install by hand.")
        return 1
    if dest.exists() and dest.lstat().st_uid != uid:
        pkg = zip_path.with_suffix(".pkg")
        # The pkg may have no scripts: a copy left running would keep serving the
        # old code after the bundle is swapped under it.
        survivors = quit_app(dest, pids=pids, kill=kill, sleep=sleep, monotonic=monotonic)
        say(f"error: {dest} is not owned by you (the installer package made it), so it "
            "cannot be replaced without root.")
        if survivors:
            say(f"The installed app did not quit (pids {survivors}); quit it from the "
                "menu bar first.")
        else:
            say("The installed app has been quit.")
        say("Run this once yourself; later releases swap in without sudo:")
        say(f"  sudo installer -pkg {pkg} -target /")
        say(f"  open -a {dest}")
        return 1

    # Staged inside the apps dir so the swap renames within one volume.
    staging = apps_dir / f".{cfg.app_name}-install-{pid}"
    aside = apps_dir / f"{app_name}.old-{pid}"
    try:
        staging.mkdir(parents=True, exist_ok=True)
        unpacked = run(["ditto", "-x", "-k", str(zip_path), str(staging)])
        if unpacked.returncode != 0:
            say(f"error: ditto failed: {(unpacked.stderr or '').strip()}")
            return 1
        new = staging / app_name
        problems = layout.problems(new, cfg)
        if problems:
            say(f"error: {zip_path.name} does not match the bundle layout:")
            for problem in problems:
                say(f"  {problem}")
            return 1

        quit_app(dest, pids=pids, kill=kill, sleep=sleep, monotonic=monotonic)

        had_old = dest.exists()
        try:
            if had_old:
                rename(dest, aside)
        except OSError as exc:
            say(f"error: could not move {dest} aside: {exc}")
            return 1
        try:
            rename(new, dest)
        except OSError as exc:
            if had_old:
                shutil.rmtree(dest, ignore_errors=True)  # any partial new copy
                rename(aside, dest)
            say(f"error: could not move the new app into place: {exc}")
            return 1
        if had_old:
            shutil.rmtree(aside, ignore_errors=True)
    finally:
        shutil.rmtree(staging, ignore_errors=True)

    opened = run(["open", "-a", str(dest)])
    if opened.returncode != 0:
        say(f"error: installed {dest} but could not open it: {(opened.stderr or '').strip()}")
        return 1
    say(f"installed {dest} from {zip_path.name}")
    return 0


def installed_failures(cfg: ReleaseConfig, *, apps_dir: Path | None = None,
                       run: Runner = run_command,
                       pids: Callable[[Path], list[int]] = processes.bundle_pids) -> list[str]:
    """What is wrong with the installed copy; empty means healthy."""
    from . import layout

    app = (cfg.apps_dir if apps_dir is None else apps_dir) / f"{cfg.app_name}.app"
    plist = app / "Contents/Info.plist"
    if not plist.exists():
        return [f"{app} is not installed ({plist} is missing)"]
    failures: list[str] = []
    version, build = versions.read_versions(cfg)
    info = plistlib.loads(plist.read_bytes())
    got = (info.get("CFBundleShortVersionString"), info.get("CFBundleVersion"))
    if got != (version, str(build)):
        failures.append(f"installed app is {got[0]} ({got[1]}), not {version} ({build})")
    shown = run(["codesign", "-dv", "--verbose=2", str(app)])
    authorities = [line.split("=", 1)[1] for line in
                   ((shown.stderr or "") + (shown.stdout or "")).splitlines()
                   if line.startswith("Authority=")]
    if shown.returncode != 0 or not authorities or not authorities[0].startswith(
            "Developer ID Application"):
        failures.append(f"installed app is not signed Developer ID Application "
                        f"(authority: {authorities[0] if authorities else 'none'})")
    failures += [f"layout: {p}" for p in layout.problems(app, cfg)]
    if not pids(app):
        failures.append(f"{cfg.app_name} is not running from {app}")
    return failures
