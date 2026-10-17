"""Find and quit the processes running out of one app bundle.

The one copy of this for `install` and `installed`. Each decides for itself what to do when something will
not exit; this only finds, signals and waits.

Two rules hold for every caller:

- Only this user's processes. Another account logged in on the same Mac may
  run its own copy of the very same /Applications bundle. Those pids are not
  ours to signal (os.kill answers EPERM), so counting them would make a quit
  wait for processes it can never stop and then blame the wrong thing.
- By executable path, never by process name: `pkill -x <App>` would
  take down every worktree's Debug copy along with the one meant.
"""
from __future__ import annotations

import os
import signal
import subprocess
import time
from pathlib import Path
from typing import Callable


def own_ps(fields: str) -> str:
    """`ps -o <fields>` over this user's processes only."""
    return subprocess.run(
        ["ps", "-U", str(os.getuid()), "-o", fields],
        capture_output=True, text=True,
    ).stdout


def bundle_prefixes(app: Path) -> list[str]:
    """Every spelling of `app/` that `ps` might report: as named, and resolved
    (a DerivedData directory is often a symlink onto another volume, and `ps`
    shows the path the kernel exec'd)."""
    prefixes: list[str] = []
    for candidate in (app, Path(os.path.realpath(app))):
        prefix = f"{candidate}/"
        if prefix not in prefixes:
            prefixes.append(prefix)
    return prefixes


def parse_bundle_pids(output: str, app: Path) -> list[int]:
    """Pids from `ps -o pid=,comm=` output whose executable lives inside `app`:
    the app, its daemon, its helpers and its extensions alike."""
    prefixes = bundle_prefixes(app)
    pids: list[int] = []
    for line in output.splitlines():
        pid_text, _, command = line.strip().partition(" ")
        if pid_text.isdigit() and command.strip().startswith(tuple(prefixes)):
            pids.append(int(pid_text))
    return pids


def bundle_pids(app: Path) -> list[int]:
    """This user's pids running anything inside `app`."""
    return parse_bundle_pids(own_ps("pid=,comm="), app)


def signal_pid(pid: int, sig: int, *, kill: Callable[[int, int], None] | None = None) -> None:
    """Signal one pid, treating "already gone" and "not ours" alike as done."""
    try:
        (kill or os.kill)(pid, sig)
    except (ProcessLookupError, PermissionError):
        pass


def quit_pids(find: Callable[[], list[int]], *, term_wait: float, kill_wait: float,
              first: list[int] | None = None,
              kill: Callable[[int, int], None] | None = None,
              sleep: Callable[[float], None] = time.sleep,
              monotonic: Callable[[], float] = time.monotonic) -> list[int]:
    """SIGTERM what `find` returns, wait up to `term_wait` for it to go, SIGKILL
    whatever is left, then wait up to `kill_wait` for the kernel to reap it.

    `first` is a `find()` the caller already made, so the pids it reports are
    the ones signalled. Returns the pids still running at the end: empty means
    everything exited. `kill`, `sleep` and `monotonic` are seams for tests.
    """
    for pid in (find() if first is None else first):
        signal_pid(pid, signal.SIGTERM, kill=kill)
    deadline = monotonic() + term_wait
    remaining = find()
    while remaining and monotonic() < deadline:
        sleep(0.2)
        remaining = find()
    if not remaining:
        return []
    for pid in remaining:
        signal_pid(pid, signal.SIGKILL, kill=kill)
    # A SIGKILLed pid lingers in `ps` until the kernel reaps it.
    deadline = monotonic() + kill_wait
    remaining = find()
    while remaining and monotonic() < deadline:
        sleep(0.1)
        remaining = find()
    return remaining
