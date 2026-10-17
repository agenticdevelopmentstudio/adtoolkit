"""project.yml settings, must-match files and the version bump."""
from __future__ import annotations

import re

from .config import ReleaseConfig
from .shell import Runner, check


def project_setting(name: str, text: str) -> str:
    """A `NAME: value` scalar from project.yml's settings, quotes stripped."""
    m = re.search(rf"^\s*{re.escape(name)}:\s*(.*?)\s*$", text, re.MULTILINE)
    if m is None:
        raise ValueError(f"{name} not found in project.yml")
    return m.group(1).strip().strip('"').strip("'")


def read_versions(cfg: ReleaseConfig) -> tuple[str, int]:
    text = cfg.project_yml.read_text()
    return (project_setting(cfg.marketing_setting, text),
            int(project_setting(cfg.build_setting, text)))


def must_match_failures(cfg: ReleaseConfig, version: str) -> list[str]:
    """Every `version.must_match` file must carry `version` in its one regex group --
    one version, everywhere. A file that is missing or a pattern that matches
    nothing is a failure, never a silent pass."""
    failures: list[str] = []
    for entry in cfg.must_match:
        name = _display(entry.file, cfg)
        try:
            text = entry.file.read_text()
        except OSError as exc:
            failures.append(f"{name}: unreadable ({exc})")
            continue
        m = re.search(entry.pattern, text)
        if m is None:
            failures.append(f"{name}: pattern {entry.pattern!r} matched nothing")
        elif m.group(1) != version:
            failures.append(f"{name} says {m.group(1)}, which is not project.yml "
                            f"{cfg.marketing_setting} ({version}) -- bump both together")
    return failures


def _display(path, cfg: ReleaseConfig) -> str:
    try:
        return str(path.relative_to(cfg.repo))
    except ValueError:
        return str(path)


def next_version(version: str, kind: str) -> str:
    """"patch" -> a.b.(c+1); "minor" -> a.(b+1).0. A 2-part version gets a .0 patch."""
    if kind not in ("patch", "minor"):
        raise ValueError(f"unknown bump kind {kind!r} (expected patch or minor)")
    try:
        parts = [int(p) for p in version.split(".")]
    except ValueError:
        raise ValueError(f"version {version!r} is not dotted integers") from None
    parts = (parts + [0, 0, 0])[:3]
    if kind == "patch":
        parts[2] += 1
    else:
        parts[1] += 1
        parts[2] = 0
    return ".".join(str(p) for p in parts)


def _set_setting(text: str, name: str, value: str) -> str:
    """Replace NAME's value in place, keeping its quoting."""
    pattern = re.compile(rf"^(\s*{re.escape(name)}:\s*)([\"']?)[^\"'\n]*?\2[ \t]*$", re.MULTILINE)
    new, count = pattern.subn(lambda m: f"{m.group(1)}{m.group(2)}{value}{m.group(2)}", text, 1)
    if count == 0:
        raise ValueError(f"{name} not found in project.yml")
    return new


def bump(cfg: ReleaseConfig, kind: str, *, run: Runner) -> tuple[str, int]:
    """Rewrite project.yml's version and build (+1) and every must_match group, then
    run `version.regenerate` through `run` (whose working directory is the repo's:
    the CLI builds it with `subprocess_runner(cwd=cfg.repo)`). Nothing is written
    unless every file can be rewritten."""
    if kind not in ("patch", "minor"):
        raise ValueError(f"unknown bump kind {kind!r} (expected patch or minor)")
    version, build = read_versions(cfg)
    new_version, new_build = next_version(version, kind), build + 1

    yml = _set_setting(cfg.project_yml.read_text(), cfg.marketing_setting, new_version)
    yml = _set_setting(yml, cfg.build_setting, str(new_build))
    writes = {cfg.project_yml: yml}
    for entry in cfg.must_match:
        text = writes[entry.file] if entry.file in writes else entry.file.read_text()
        m = re.search(entry.pattern, text)
        if m is None:
            raise ValueError(f"{_display(entry.file, cfg)}: pattern {entry.pattern!r} "
                             "matched nothing")
        writes[entry.file] = text[:m.start(1)] + new_version + text[m.end(1):]
    for path, text in writes.items():
        path.write_text(text)

    if cfg.regenerate:
        check(run(list(cfg.regenerate)), "version.regenerate")
    return new_version, new_build
