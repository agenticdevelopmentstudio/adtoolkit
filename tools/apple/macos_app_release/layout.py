"""The shipped bundle's layout: what must be in it and what must never be again.

One config (`layout.*` in release.json), read by the build's check-bundle step (before
signing), by `prepared` and by `install`/`installed` (on the unpacked or installed copy),
so "assembled at build time" is checked, not assumed.
"""
from __future__ import annotations

from pathlib import Path

from .config import ReleaseConfig


def problems(app: Path, cfg: ReleaseConfig) -> list[str]:
    """Missing required paths, present forbidden paths, and each required glob that
    matches nothing. Empty means the bundle matches the layout."""
    found = [f"missing {rel}" for rel in cfg.layout_required if not (app / rel).exists()]
    found += [f"forbidden {rel}" for rel in cfg.layout_forbidden if (app / rel).exists()]
    for pattern in cfg.layout_required_globs:
        if not any(app.glob(pattern)):
            found.append(f"no path matches {pattern}")
    return found
