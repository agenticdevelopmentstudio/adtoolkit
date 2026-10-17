"""Hold a clean Release build's log to zero warnings, except the owner-accepted ones.

Ported from Stenographer's scripts/build_warnings.py. Every `warning:` line in an
xcodebuild log is either fixed or listed in the app's allowlist (`warnings_allowlist` in
release.json). An entry there is a regular expression and the reason the warning cannot
be fixed here -- toolchain noise, a third-party package, or a submodule this repo does
not own. Entries are added only with the owner's approval: a new warning is fixed, or it
is shown to the owner, and only once they accept it does it go on the list.

Only a CLEAN build reports every warning; an incremental build skips the files it did not
recompile, and their warnings with them. `run_warnings` therefore runs the app's
`hooks.warnings_build` into a fresh DerivedData it creates and deletes.

The log's repeats (xcodebuild prints a warning once per architecture and once more in its
summary) collapse to one entry. An allowlist entry that matched nothing is reported as
unused, never as a failure: one build need not hit every accepted warning.

The allowlist path is required: there is no default, because the file lives in the app's
repo and only release.json knows where.
"""
from __future__ import annotations

import json
import re
import shutil
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Mapping

from .config import ReleaseConfig
from .shell import capture_hook, step

WARNING = re.compile(r"\bwarning: ")
LOG_NAME = "warnings-build.log"
DERIVED_DATA_ENV = "RELEASE_WARNINGS_DERIVED_DATA"
TAIL_LINES = 40


@dataclass(frozen=True)
class Allowed:
    pattern: str
    reason: str

    def matches(self, line: str) -> bool:
        return re.search(self.pattern, line) is not None


def load_allowlist(path: Path) -> list[Allowed]:
    """The accepted warnings in `path`. Raises ValueError naming every problem."""
    try:
        document = json.loads(path.read_text())
        entries = document["allowed"]
    except OSError as exc:
        raise ValueError(f"{path}: unreadable ({exc})") from None
    except json.JSONDecodeError as exc:
        raise ValueError(f"{path}: not valid JSON ({exc})") from None
    except (KeyError, TypeError):
        raise ValueError(f'{path}: must be an object with an "allowed" list') from None
    if not isinstance(entries, list):
        raise ValueError(f'{path}: "allowed" must be a list')

    problems: list[str] = []
    allowed: list[Allowed] = []
    for i, entry in enumerate(entries):
        if not isinstance(entry, dict) or not isinstance(entry.get("pattern"), str):
            problems.append(f"{path}: entry {i} needs a string pattern")
            continue
        pattern = entry["pattern"]
        reason = entry.get("reason")
        if not isinstance(reason, str) or not reason.strip():
            problems.append(f"{path}: {pattern!r} has no reason — every accepted warning "
                            "says why it cannot be fixed")
            continue
        try:
            re.compile(pattern)
        except re.error as exc:
            problems.append(f"{path}: {pattern!r} is not a valid regex ({exc})")
            continue
        allowed.append(Allowed(pattern, reason))
    if problems:
        raise ValueError("\n".join(problems))
    return allowed


def log_warnings(text: str) -> list[str]:
    """Each distinct warning line, in first-seen order."""
    seen: dict[str, None] = {}
    for line in text.splitlines():
        if WARNING.search(line):
            seen.setdefault(line.strip(), None)
    return list(seen)


def sort_warnings(warnings: list[str],
                  allowlist: list[Allowed]) -> tuple[list[str], dict[str, list[str]], list[str]]:
    """(unaccepted warnings, accepted warnings by pattern, unused patterns)."""
    accepted: dict[str, list[str]] = {a.pattern: [] for a in allowlist}
    unaccepted = []
    for line in warnings:
        entry = next((a for a in allowlist if a.matches(line)), None)
        if entry is None:
            unaccepted.append(line)
        else:
            accepted[entry.pattern].append(line)
    unused = [pattern for pattern, hits in accepted.items() if not hits]
    return unaccepted, {p: hits for p, hits in accepted.items() if hits}, unused


def gate_log(text: str, allowlist: list[Allowed], allowlist_name: str, *,
             as_json: bool) -> int:
    """Print the verdict for one log; 1 when any warning is neither fixed nor accepted."""
    unaccepted, accepted, unused = sort_warnings(log_warnings(text), allowlist)
    if as_json:
        print(json.dumps({"ok": not unaccepted, "unaccepted": unaccepted,
                          "accepted": accepted, "unused_patterns": unused}, indent=2))
    else:
        for line in unaccepted:
            print(line)
        total = sum(len(hits) for hits in accepted.values())
        print(f"\n{len(unaccepted)} warning(s) to fix or have accepted; "
              f"{total} accepted by {allowlist_name}")
        for pattern in unused:
            print(f"  unused allowlist pattern: {pattern}")
    return 1 if unaccepted else 0


def run_warnings(cfg: ReleaseConfig, *, log_dir: Path | None, as_json: bool,
                 env: Mapping[str, str] | None = None,
                 hook: Callable[..., object] = capture_hook) -> int:
    """The clean warnings build and its gate. 0 = clean, 1 = failed.

    1. Create a fresh DerivedData directory.
    2. Run `hooks.warnings_build` with RELEASE_WARNINGS_DERIVED_DATA set to it, capturing
       its combined output.
    3. Write the log to `log_dir`/warnings-build.log (default: the temp dir's parent).
    4. Delete the DerivedData.
    5. A hook exit other than 0 prints the log's tail and fails; otherwise the log is
       gated against the allowlist.

    Raises ValueError for a bad allowlist, before the (slow) build starts.
    """
    allowlist = load_allowlist(cfg.warnings_allowlist)
    say = (lambda _msg: None) if as_json else step

    derived = Path(tempfile.mkdtemp(prefix="release-warnings-"))
    try:
        say(f"Clean Release build for warnings (DerivedData {derived}); this takes a while")
        proc = hook(cfg.hook_warnings_build, cwd=cfg.repo,
                    env={**(env or {}), DERIVED_DATA_ENV: str(derived)})
        text = (proc.stdout or "") + (proc.stderr or "")
        target = log_dir if log_dir is not None else derived.parent
        try:
            target.mkdir(parents=True, exist_ok=True)
            log = target / LOG_NAME
            log.write_text(text)
        except OSError as exc:
            print(f"error: cannot write the warnings log under {target}: {exc}",
                  file=sys.stderr)
            return 1
    finally:
        shutil.rmtree(derived, ignore_errors=True)

    if proc.returncode != 0:
        tail = "\n".join(text.splitlines()[-TAIL_LINES:])
        print(f"error: the warnings_build hook exited {proc.returncode}; "
              f"last {TAIL_LINES} lines of {log}:\n{tail}", file=sys.stderr)
        return 1
    say(f"log: {log}")
    return gate_log(text, allowlist, cfg.warnings_allowlist.name, as_json=as_json)
