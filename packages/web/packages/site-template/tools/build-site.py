#!/usr/bin/env python3
"""Vercel build entry point for every site assembled from this template.

A templated site links its toolkit packages (`site-template`, `landing`, `themes`, and whatever
its `site.json` `toolkitPackages` names) with `link:` dependencies into its
`websites/external/agenticdevelopertoolkit` submodule. That toolkit is its OWN pnpm workspace
(pnpm workspaces cannot nest), so two things follow, and this script exists for both:

  1. Every one of those packages resolves through `main`/`exports` that point at `dist/` for a
     production build, and `dist/` is gitignored. It MUST exist before `next build`, or Vercel
     reports `Module not found: Can't resolve '@agenticdevelopertoolkit/landing'`, which does
     not obviously mean "the submodule was never built".
  2. The websites-root `pnpm install` (the vercel.json `installCommand`) does not build them —
     a separate workspace with its own lockfile is not something the outer install walks into.

So: install and build the toolkit workspace, filtered to what the site links, then run the
site's own `build` (plain `next build`).

ONE copy, here, for every templated site. Each site used to carry its own `tools/build-site.py`
(mikefullerton from Kitchen, Kitchen from Stenographer, Stenographer from fishlamp, ads from
fishlamp), and a fix to one never reached the others. It lives in the template because the
template is the tier every one of them already builds on, and it is run from the submodule
checkout the site's install step has already fetched:

    Root Directory = websites/main (or websites/app)
    buildCommand   = python3 ../external/agenticdevelopertoolkit/packages/web/packages/site-template/tools/build-site.py

`--toolkits-only` stops after the toolkit dists, which is what a dev server wants: its imports
resolve through the same `link:` symlinks, so the dists must exist before `next dev` too, but a
production `next build` first is minutes it then ignores. `--site DIR` names the site directory
(default: the working directory, which is how Vercel runs it).

The toolkit this builds is the one this file is in — the site's own submodule — so a site cannot
be built against a toolkit other than the one it links. A `link:` into anywhere else is refused.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

# tools/ -> site-template/ -> packages/ -> web/: the toolkit's pnpm workspace root.
TOOLKIT = Path(__file__).resolve().parents[3]


def toolkit_packages(package_json: Path, toolkit: Path = TOOLKIT) -> list[str]:
    """The site's dependencies whose `link:` target lies inside the toolkit, sorted.

    The site's package.json is the one source — the assembler writes it from `site.json`, so a
    package named in `toolkitPackages` is built without being restated here, and a rename
    cannot be fixed in the install and missed in the build. A `link:` that resolves to another
    toolkit checkout is an error, not a skip: building this one would leave that one's dist
    missing, and `next build` would say so only as `Module not found`.
    """
    deps = json.loads(package_json.read_text()).get("dependencies", {})
    root = toolkit.resolve()
    names = []
    for name, spec in sorted(deps.items()):
        if not spec.startswith("link:"):
            continue
        target = (package_json.parent / spec[len("link:"):]).resolve()
        if target == root or root in target.parents:
            names.append(name)
        elif "agenticdevelopertoolkit" in target.parts:
            sys.exit(
                f"{package_json} links {name} into {target}, which is not the toolkit this "
                f"script belongs to ({root}). Run the build-site.py inside the site's own "
                "submodule."
            )
    return names


def toolkit_filters(packages: list[str]) -> list[str]:
    """`--filter <name>...` per package; the trailing `...` is pnpm's "and its workspace
    dependencies", so site-template brings landing, themes and the rest with it.

    **The filter binds the install as well as the build.** An unfiltered `pnpm install` resolves
    and downloads every dependency of every package in the workspace — shiki's wasm payload,
    playwright, the lot — which is where the minutes go, and a failure in a package the site
    never imports would break its deploy.
    """
    return [arg for name in packages for arg in ("--filter", f"{name}...")]


def pnpm(args: list[str]) -> list[str]:
    """Prefer a system pnpm >= 9; else fall back to a pinned npx pnpm.

    Vercel's build image has no global pnpm, so the npx fallback keeps this path working
    without a corepack/pnpm preinstall step.
    """
    found = shutil.which("pnpm")
    if found:
        result = subprocess.run([found, "--version"], capture_output=True, text=True)
        try:
            if int(result.stdout.strip().split(".")[0]) >= 9:
                return [found, *args]
        except (ValueError, IndexError):
            pass
    return ["npx", "--yes", "pnpm@9.15.9", *args]


def run(cmd: list[str], cwd: Path, env: dict[str, str]) -> None:
    print(f"==> {' '.join(str(c) for c in cmd)}  (cwd={cwd})", flush=True)
    subprocess.run(cmd, cwd=cwd, check=True, env=env)


def workspace_projects(env: dict[str, str], toolkit: Path = TOOLKIT) -> set[str]:
    """The toolkit workspace's own project names (`pnpm ls -r --depth -1 --json` reads
    pnpm-workspace.yaml, so it needs no node_modules)."""
    result = subprocess.run(
        pnpm(["ls", "-r", "--depth", "-1", "--json"]),
        cwd=toolkit,
        capture_output=True,
        text=True,
        env=env,
    )
    if result.returncode != 0:
        sys.exit(f"could not enumerate the toolkit workspace at {toolkit}:\n{result.stderr.strip()}")
    try:
        return {project.get("name") for project in json.loads(result.stdout)}
    except (ValueError, AttributeError) as exc:
        sys.exit(f"could not parse `pnpm ls -r --json` output: {exc}")


def assert_filters_resolve(packages: list[str], present: set[str], package_json: Path) -> None:
    """Fail loudly if a filter matches nothing — pnpm does not.

    A `--filter` naming a package the workspace lacks selects zero projects, prints a line
    nobody reads, and EXITS 0. The install and build would both "succeed" with no dist, and the
    failure would surface as `next build`'s `Module not found` — or not at all, while a dist
    from an earlier build is still on disk.
    """
    if not packages:
        sys.exit(f"{package_json} links no package into the toolkit at {TOOLKIT}; nothing to build.")
    missing = [name for name in packages if name not in present]
    if missing:
        sys.exit(
            f"{package_json} links these packages into the toolkit, but its workspace has no "
            f"such project: {', '.join(missing)}.\npnpm would filter them to nothing and exit 0, "
            "so the build stops here. Either the toolkit renamed or moved them (re-assemble the "
            "site) or the submodule is checked out at the wrong commit."
        )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--site", type=Path, default=None, help="the site directory (default: cwd)")
    parser.add_argument("--toolkits-only", action="store_true", help="build the toolkit dists, not the site")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    site = (args.site or Path.cwd()).resolve()
    package_json = site / "package.json"
    if not package_json.is_file():
        sys.exit(
            f"build-site.py must run from a site directory (cwd={site} has no package.json). "
            "On Vercel set Root Directory = the site's output (websites/main or websites/app), "
            "or pass --site."
        )

    # Vercel/CI set NODE_ENV=production, which makes pnpm skip the toolkit's devDependencies
    # (tsup, typescript) — exactly the tools needed to BUILD its dist. Strip it.
    env = {k: v for k, v in os.environ.items() if k != "NODE_ENV"}

    packages = toolkit_packages(package_json)
    assert_filters_resolve(packages, workspace_projects(env), package_json)
    filters = toolkit_filters(packages)
    run(pnpm([*filters, "install", "--frozen-lockfile"]), cwd=TOOLKIT, env=env)
    # --workspace-concurrency=1: pnpm builds independent packages four at a time by default;
    # Vercel's build machine has one shared CPU/memory budget, so one tsup/tsc at a time.
    run(pnpm([*filters, "--workspace-concurrency=1", "run", "build"]), cwd=TOOLKIT, env=env)
    if args.toolkits_only:
        return 0

    # The site's node_modules came from the vercel.json installCommand; its `build` is plain
    # `next build` — no recursion into this script, which is the buildCommand, not an npm script.
    run(pnpm(["run", "build"]), cwd=site, env=env)
    return 0


if __name__ == "__main__":
    sys.exit(main())
