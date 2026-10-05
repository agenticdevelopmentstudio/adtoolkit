#!/usr/bin/env python3
"""Checks that AgenticToolkit's aggregate targets reach every target they claim to.

`AgenticToolkitMacOSAll` promises every macOS framework,
`AgenticToolkitMacOSTestsAll` those plus every test bundle, and
`AgenticToolkitiOSAll` every target that claims iOS. A target added to
`project.yml` but to none of them is compiled by nothing that runs the whole
suite — the Activity framework and its 449 tests sat outside both macOS
aggregates that way. This reads the spec and names each target an aggregate
misses.

Run:  python3 tools/apple/aggregate_targets.py [path/to/project.yml]
Exit: 0 when every aggregate is complete, 1 with one line per miss otherwise.
"""
from __future__ import annotations

import sys
from pathlib import Path

import yaml

DEFAULT_SPEC = Path(__file__).resolve().parents[2] / "packages/apple/AgenticToolkit/project.yml"

MACOS_ALL = "AgenticToolkitMacOSAll"
MACOS_TESTS_ALL = "AgenticToolkitMacOSTestsAll"
IOS_ALL = "AgenticToolkitiOSAll"


def _platforms(target: dict) -> set[str]:
    """The platforms a target builds for. No `platform` key means the
    multi-platform form (`supportedDestinations`), which this spec uses for
    targets that build for both."""
    platform = target.get("platform")
    if platform is None:
        return {"macOS", "iOS"}
    if isinstance(platform, list):
        return set(platform)
    return {platform}


def missing(spec: dict) -> list[str]:
    """One line per (aggregate, target) the aggregate should hold and does not."""
    aggregates = {name: set(body.get("targets", [])) for name, body in spec.get("aggregateTargets", {}).items()}
    problems: list[str] = []
    for name, target in spec.get("targets", {}).items():
        kind = target.get("type", "")
        platforms = _platforms(target)
        wanted: list[str] = []
        if kind == "framework" and "macOS" in platforms:
            wanted += [MACOS_ALL, MACOS_TESTS_ALL]
        if kind == "framework" and "iOS" in platforms:
            wanted.append(IOS_ALL)
        if kind == "bundle.unit-test" and "macOS" in platforms:
            wanted.append(MACOS_TESTS_ALL)
        for aggregate in wanted:
            if name not in aggregates.get(aggregate, set()):
                problems.append(f"{aggregate} is missing {name}")
    return problems


def main(argv: list[str]) -> int:
    path = Path(argv[1]) if len(argv) > 1 else DEFAULT_SPEC
    problems = missing(yaml.safe_load(path.read_text()))
    for line in problems:
        print(line)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
