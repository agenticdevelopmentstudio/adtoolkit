#!/usr/bin/env python3
"""Every site under `websites/` must declare, and be able to resolve, what it imports.

The demo site is the only consumer of these packages that ships inside this repo,
and CI does not build it. `deployment/run-ci` installs and builds `packages/web` and
runs its suites; `websites/` is scanned by the guards but nothing in the
job ever enters it. So the one place a reader looks to see the library actually
used is also the one place no automated check has ever looked.

That matters more here than it would in a repo that had always owned these
packages. Eight of them arrived from a private repo under a different scope, and
the demo site's manifest was repointed by hand as part of that arrival. A repoint
has exactly two ways to go wrong, and this guard is the two of them:

  a `file:` specifier that resolves nowhere
      The manifest names `file:../../packages/web/packages/chat`. If that package
      is later renamed or moved, `pnpm install` fails inside `websites/demo` —
      which no job runs, so the break is invisible until a human opens the demo.

  a specifier that resolves to the WRONG package
      Worse, because it installs cleanly. A path that lands on a real directory
      whose package.json declares a different name gives the site a package it
      did not ask for under a name it did. Checking the target's declared `name`
      against the dependency key is what separates "a directory exists there"
      from "the right package is there".

  an import of a package the manifest does not declare
      The mirror failure: source that imports `@agenticdevelopertoolkit/ui` while
      the manifest declares only `chat` and `themes`. In a workspace with a
      hoisted node_modules this resolves anyway, from some other package's
      dependency, and keeps resolving right up until that package drops it.

Only the scopes this repo publishes are checked for declaration. A bare `react`
or `next` is somebody else's dependency graph and this guard has no opinion about
it; `@agenticdevelopertoolkit/*` is the graph this repo is responsible for.

Exit 0 clean, 1 on a finding, 2 if there was nothing to scan — no site manifests
found means the layout moved out from under this guard, and a guard that scans
nothing must never report a pass.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ROOT = "websites"

# The scopes this repo publishes, and therefore the imports it is answerable for.
OWNED_SCOPE = "@agenticdevelopertoolkit/"

# A local specifier, either spelling. pnpm treats `link:` as a symlink and `file:`
# as a copy-or-link depending on the target, but both name a path relative to the
# manifest and both fail the same way when that path is wrong.
LOCAL_SPECIFIER = re.compile(r"^(?:file|link):(.+)$")

# Import and re-export forms that carry a module specifier, plus require(). Bare
# `import '…'` for side effects counts: it still has to resolve.
IMPORT_SPECIFIER = re.compile(
    r"""(?:from\s*|import\s*|require\s*\(\s*)['"]([^'"]+)['"]"""
)

SOURCE_SUFFIXES = {".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"}
SKIP_DIRS = {"node_modules", ".next", "dist", ".turbo", "coverage", ".git"}

DEP_FIELDS = ("dependencies", "devDependencies", "peerDependencies")


def package_name_at(directory: Path) -> str | None:
    """The `name` a package declares, or None if there is no readable manifest."""
    manifest = directory / "package.json"
    try:
        return json.loads(manifest.read_text(encoding="utf-8")).get("name")
    except (OSError, json.JSONDecodeError):
        return None


def declared_deps(manifest_data: dict) -> dict[str, str]:
    """Every dependency the manifest declares, across all three fields."""
    deps: dict[str, str] = {}
    for field in DEP_FIELDS:
        deps.update(manifest_data.get(field, {}))
    return deps


def check_specifiers(site: Path, deps: dict[str, str], rel: Path) -> list[str]:
    """Local specifiers must resolve, and resolve to the package they name."""
    problems: list[str] = []
    for dep_name, specifier in sorted(deps.items()):
        match = LOCAL_SPECIFIER.match(specifier)
        if match is None:
            continue

        target = (site / match.group(1)).resolve()
        if not target.is_dir():
            problems.append(
                f"{rel}/package.json: {dep_name} -> {specifier} resolves to no directory"
            )
            continue

        actual = package_name_at(target)
        if actual is None:
            problems.append(
                f"{rel}/package.json: {dep_name} -> {specifier} has no readable package.json"
            )
        elif actual != dep_name:
            problems.append(
                f"{rel}/package.json: {dep_name} -> {specifier} is package '{actual}'"
            )
    return problems


def imported_owned_packages(site: Path) -> dict[str, Path]:
    """Owned-scope packages this site's source imports, and where each first appears."""
    found: dict[str, Path] = {}
    for path in sorted(site.rglob("*")):
        if not path.is_file() or path.suffix not in SOURCE_SUFFIXES:
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for specifier in IMPORT_SPECIFIER.findall(text):
            if not specifier.startswith(OWNED_SCOPE):
                continue
            # `@scope/pkg/sub/path` is a subpath export of `@scope/pkg` — the
            # dependency is the package, not the subpath.
            parts = specifier.split("/")
            package = "/".join(parts[:2])
            found.setdefault(package, path)
    return found


def check_imports(site: Path, deps: dict[str, str], rel: Path) -> list[str]:
    """Anything imported from an owned scope must be declared by this site."""
    problems: list[str] = []
    for package, first_use in sorted(imported_owned_packages(site).items()):
        if package in deps:
            continue
        where = first_use.relative_to(site)
        problems.append(
            f"{rel}/package.json: imports {package} ({rel}/{where}) but does not declare it"
        )
    return problems


def check_site(site: Path, repo_root: Path) -> list[str]:
    rel = site.relative_to(repo_root)
    try:
        data = json.loads((site / "package.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"{rel}/package.json: unreadable ({exc})"]

    deps = declared_deps(data)
    return check_specifiers(site, deps, rel) + check_imports(site, deps, rel)


def find_sites(root: Path) -> list[Path]:
    """Directories directly under the root that carry a package.json."""
    if not root.is_dir():
        return []
    return sorted(
        child for child in root.iterdir()
        if child.is_dir()
        and child.name not in SKIP_DIRS
        and (child / "package.json").is_file()
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT)
    parser.add_argument(
        "--root",
        default=DEFAULT_ROOT,
        help=f"directory holding the sites, relative to the repo root (default: {DEFAULT_ROOT})",
    )
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    root = repo_root / args.root

    if not root.is_dir():
        print(
            f"check_site_deps: FAILED TO CHECK — no such directory: {root}. "
            "The sites directory this guard exists to scan is not there.",
            file=sys.stderr,
        )
        return 2

    sites = find_sites(root)
    if not sites:
        print(
            f"check_site_deps: FAILED TO CHECK — no site manifests under {root}. "
            "Either the sites moved or their manifests are gone; either way this "
            "guard scanned nothing and cannot report a pass.",
            file=sys.stderr,
        )
        return 2

    problems: list[str] = []
    for site in sites:
        problems.extend(check_site(site, repo_root))

    if problems:
        print(
            f"check_site_deps: {len(problems)} problem(s) in {len(sites)} site(s):\n",
            file=sys.stderr,
        )
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        print(
            "\nNothing in CI builds these sites, so a broken specifier here stays "
            "broken until someone opens the site by hand.",
            file=sys.stderr,
        )
        return 1

    print(f"check_site_deps: {len(sites)} site(s), dependencies declared and resolvable")
    return 0


if __name__ == "__main__":
    sys.exit(main())
