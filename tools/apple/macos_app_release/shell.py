"""Process plumbing shared by every pipeline module: the injected Runner, hooks, git."""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path
from typing import Callable, Mapping, Sequence

Runner = Callable[[list[str]], "subprocess.CompletedProcess[str]"]


def subprocess_runner(verbose: bool, *, cwd: Path | None = None) -> Runner:
    """A Runner that really runs argv, capturing output; echoes it all when verbose.

    `cwd` is the working directory every command runs in (None = inherit).
    """
    def run(argv: list[str]) -> subprocess.CompletedProcess[str]:
        if verbose:
            print("  $ " + " ".join(argv), flush=True)
        proc = subprocess.run(argv, capture_output=True, text=True, errors="replace",
                              cwd=str(cwd) if cwd is not None else None)
        if verbose:
            sys.stdout.write(proc.stdout)
            sys.stderr.write(proc.stderr)
        return proc
    return run


def step(msg: str) -> None:
    print(f"==> {msg}", flush=True)


def bullet(msg: str) -> None:
    print(f"  → {msg}", flush=True)


def check(proc: subprocess.CompletedProcess[str], what: str) -> subprocess.CompletedProcess[str]:
    if proc.returncode != 0:
        raise RuntimeError(f"{what} failed (exit {proc.returncode}):\n"
                           f"{(proc.stderr or '') + (proc.stdout or '')}".rstrip())
    return proc


def _hook_env(env: Mapping[str, str]) -> dict[str, str]:
    return {**os.environ, **env}


def run_hook(argv: Sequence[str], *, cwd: Path, env: Mapping[str, str]) -> int:
    """Run a configured hook with its output streaming to ours; return its exit code."""
    sys.stdout.flush()
    return subprocess.run(list(argv), cwd=str(cwd), env=_hook_env(env)).returncode


def capture_hook(argv: Sequence[str], *, cwd: Path,
                 env: Mapping[str, str]) -> subprocess.CompletedProcess[str]:
    """Run a configured hook, capturing stdout and stderr."""
    return subprocess.run(list(argv), cwd=str(cwd), env=_hook_env(env),
                          capture_output=True, text=True, errors="replace")


def main_checkout(repo: Path, run: Runner) -> Path:
    """The main checkout of `repo`'s repository (repo itself when it is not a worktree)."""
    proc = check(run(["git", "-C", str(repo), "rev-parse", "--path-format=absolute",
                      "--git-common-dir"]), "git rev-parse --git-common-dir")
    return Path(proc.stdout.strip()).parent
