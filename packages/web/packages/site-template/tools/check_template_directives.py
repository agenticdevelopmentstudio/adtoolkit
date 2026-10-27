#!/usr/bin/env python3
"""Assert that `'use client'` sits on the client entry and nowhere else.

The landing kit's `tools/check-directives.py`, retargeted at this package; that file tells
the whole story. In short: esbuild-plugin-preserve-directives propagates a chunk's directive
to every entry that imports it, so a client module re-exported from `src/index.ts` puts
`'use client'` on the first line of `dist/index.js` and turns `LandingFrame` — every band of
every content site — into a Client Component. tsc, vitest and `next build` all stay green
through that, so the first line of a built file is the only place it shows.

How a built file's leading directive is READ is landing's `first_directive`, loaded from that
script rather than copied: one parser, so the two packages cannot disagree about what a
directive looks like. What is checked against it is this package's own entries.

The client entry's source is `src/client-barrel.ts` (the abstractr hook refuses the stem
`client`), but it is built to `dist/client.js`, which is what this checks.

Run from anywhere (the `build` script does):
    python3 tools/check_template_directives.py [--dist DIR]
"""
from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path

PKG = Path(__file__).resolve().parents[1]
DIST = PKG / "dist"
LANDING_GUARD = PKG.parent / "landing" / "tools" / "check-directives.py"


def _landing_guard():
    """landing's check-directives.py as a module. Its file name has a hyphen, so it is loaded
    by path; its `main` is guarded by `__name__`, so loading it runs nothing."""
    spec = importlib.util.spec_from_file_location("landing_check_directives", LANDING_GUARD)
    if spec is None or spec.loader is None:
        raise SystemExit(f"directives: cannot load landing's guard at {LANDING_GUARD}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_landing = _landing_guard()
DIRECTIVE: str = _landing.DIRECTIVE
read_directive = _landing.first_directive

# entry -> whether dist/<entry>.js must carry the directive on its first line.
EXPECTED: dict[str, bool] = {
    "index": False,  # server-safe barrel: LandingFrame, FrameFooter, the metadata helpers
    "client": True,  # SiteChrome (the drawer's state) and SiteBitbag (next/dynamic)
}


def check(dist: Path) -> list[str]:
    """Every way `dist` breaks the rule, as messages. Empty means it holds."""
    failures: list[str] = []
    for entry, must_have in EXPECTED.items():
        built = dist / f"{entry}.js"
        if not built.is_file():
            failures.append(f"{entry}.js was not built (expected at {built})")
            continue

        found = read_directive(built) == DIRECTIVE
        if found and not must_have:
            failures.append(
                f"dist/{entry}.js starts with '{DIRECTIVE}' and must not.\n"
                f"      Something re-exported a client module from src/{entry}.ts, so the\n"
                f"      directive was hoisted onto the whole bundle and every export in it\n"
                f"      is now a Client Component. Move that export to src/client-barrel.ts."
            )
        elif must_have and not found:
            failures.append(
                f"dist/{entry}.js does NOT start with '{DIRECTIVE}' and must.\n"
                f"      Without it React will not treat SiteChrome as a Client Component\n"
                f"      and its drawer state will fail in a server render."
            )

    # A directive anywhere else in dist/ means a chunk escaped both entries.
    for stray in sorted(dist.glob("*.js")):
        if stray.stem in EXPECTED:
            continue
        if read_directive(stray) == DIRECTIVE:
            failures.append(
                f"dist/{stray.name} carries '{DIRECTIVE}' but is not a declared entry.\n"
                f"      A shared chunk picked up the directive; the two builds in\n"
                f"      tsup.config.ts are no longer independent."
            )
    return failures


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Assert 'use client' sits on the client entry only.")
    parser.add_argument("--dist", type=Path, default=DIST)
    args = parser.parse_args(argv)

    if not args.dist.is_dir():
        print(f"directives: dist/ is missing at {args.dist} — run the build first.", file=sys.stderr)
        return 2

    failures = check(args.dist)
    if failures:
        print("directives: FAILED", file=sys.stderr)
        for f in failures:
            print(f"  ✗ {f}", file=sys.stderr)
        return 1

    summary = ", ".join(
        f"{entry}.js {'has' if must_have else 'has no'} '{DIRECTIVE}'"
        for entry, must_have in EXPECTED.items()
    )
    print(f"directives: ok ({len(EXPECTED)} entries — {summary})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
