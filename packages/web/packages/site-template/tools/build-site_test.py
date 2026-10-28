#!/usr/bin/env python3
"""Tests for build-site.py, the Vercel build entry point every templated site runs.

Run: python3 tools/build-site_test.py
"""
from __future__ import annotations

import importlib.util
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("build_site", HERE / "build-site.py")
build_site = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(build_site)

TOOLKIT = build_site.TOOLKIT


def site_with(root: Path, deps: dict[str, str]) -> Path:
    """A site directory at <root>/site whose package.json carries `deps`."""
    site = root / "site"
    site.mkdir()
    (site / "package.json").write_text(json.dumps({"name": "site", "dependencies": deps}))
    return site


def link(package_dir: str, site: Path) -> str:
    """A relative `link:` spec from `site` to <toolkit>/packages/<package_dir>, the shape the
    assembler writes."""
    target = TOOLKIT / "packages" / package_dir
    return "link:" + os.path.relpath(target, site)


class Toolkit(unittest.TestCase):
    def test_the_toolkit_is_the_workspace_this_file_is_in(self):
        self.assertTrue((TOOLKIT / "pnpm-workspace.yaml").is_file())
        self.assertEqual(HERE, TOOLKIT / "packages" / "site-template" / "tools")


class ToolkitPackages(unittest.TestCase):
    def test_every_link_into_the_toolkit_and_nothing_else(self):
        with tempfile.TemporaryDirectory() as tmp:
            site = Path(tmp).resolve() / "x"
            site.mkdir()
            site = site_with(site, {})
            deps = {
                "@agenticdevelopertoolkit/site-template": link("site-template", site),
                "@agentic-toolkit/bitbag": link("features/bitbag", site),
                "next": "16.0.0",
                "local": "link:../somewhere-else",
            }
            (site / "package.json").write_text(json.dumps({"dependencies": deps}))
            self.assertEqual(
                build_site.toolkit_packages(site / "package.json"),
                ["@agentic-toolkit/bitbag", "@agenticdevelopertoolkit/site-template"],
            )

    def test_a_link_into_another_toolkit_checkout_is_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            other = Path(tmp) / "external" / "agenticdevelopertoolkit" / "packages" / "web" / "packages" / "landing"
            other.mkdir(parents=True)
            site = site_with(Path(tmp), {"@agenticdevelopertoolkit/landing": f"link:{other}"})
            with self.assertRaises(SystemExit) as raised:
                build_site.toolkit_packages(site / "package.json")
            self.assertIn("not the toolkit this script belongs to", str(raised.exception.code))


class ToolkitFilters(unittest.TestCase):
    def test_each_package_is_built_with_its_workspace_dependencies(self):
        self.assertEqual(
            build_site.toolkit_filters(["@agenticdevelopertoolkit/site-template", "@agentic-toolkit/auth"]),
            ["--filter", "@agenticdevelopertoolkit/site-template...", "--filter", "@agentic-toolkit/auth..."],
        )


class AssertFiltersResolve(unittest.TestCase):
    def test_a_package_the_workspace_lacks_stops_the_build(self):
        with self.assertRaises(SystemExit) as raised:
            build_site.assert_filters_resolve(["@x/gone", "@x/here"], {"@x/here"}, Path("p.json"))
        self.assertIn("@x/gone", str(raised.exception.code))

    def test_a_site_linking_nothing_is_refused_rather_than_built_empty(self):
        with self.assertRaises(SystemExit) as raised:
            build_site.assert_filters_resolve([], {"@x/here"}, Path("p.json"))
        self.assertIn("links no package", str(raised.exception.code))

    def test_every_package_present_passes(self):
        build_site.assert_filters_resolve(["@x/here"], {"@x/here", "@x/other"}, Path("p.json"))


class Main(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = Path(self.tmp.name).resolve() / "x"
        root.mkdir()
        self.site = site_with(root, {})
        (self.site / "package.json").write_text(json.dumps({"dependencies": {
            "@agenticdevelopertoolkit/site-template": link("site-template", self.site),
        }}))
        self.calls: list[tuple[list[str], Path, dict[str, str]]] = []
        patches = [
            mock.patch.object(build_site, "run", side_effect=lambda cmd, cwd, env: self.calls.append((cmd, cwd, env))),
            mock.patch.object(build_site, "pnpm", side_effect=lambda args: ["pnpm", *args]),
            mock.patch.object(build_site, "workspace_projects", return_value={"@agenticdevelopertoolkit/site-template"}),
            mock.patch.dict(build_site.os.environ, {"NODE_ENV": "production"}),
        ]
        for patch in patches:
            patch.start()
            self.addCleanup(patch.stop)

    def test_installs_and_builds_the_filtered_toolkit_then_the_site(self):
        self.assertEqual(build_site.main(["--site", str(self.site)]), 0)
        filters = ["--filter", "@agenticdevelopertoolkit/site-template..."]
        self.assertEqual(
            [(cmd, cwd) for cmd, cwd, _ in self.calls],
            [
                (["pnpm", *filters, "install", "--frozen-lockfile"], TOOLKIT),
                (["pnpm", *filters, "--workspace-concurrency=1", "run", "build"], TOOLKIT),
                (["pnpm", "run", "build"], self.site.resolve()),
            ],
        )

    def test_node_env_is_stripped_so_the_toolkit_build_tools_install(self):
        build_site.main(["--site", str(self.site)])
        self.assertTrue(all("NODE_ENV" not in env for _, _, env in self.calls))

    def test_toolkits_only_stops_before_the_site_build(self):
        build_site.main(["--site", str(self.site), "--toolkits-only"])
        self.assertEqual(len(self.calls), 2)
        self.assertTrue(all(cwd == TOOLKIT for _, cwd, _ in self.calls))

    def test_the_site_defaults_to_the_working_directory(self):
        with mock.patch.object(build_site.Path, "cwd", return_value=self.site):
            build_site.main([])
        self.assertEqual(self.calls[-1][1], self.site.resolve())

    def test_refuses_to_run_outside_a_site_directory(self):
        with self.assertRaises(SystemExit) as raised:
            build_site.main(["--site", self.tmp.name])
        self.assertIn("must run from a site directory", str(raised.exception.code))
        self.assertEqual(self.calls, [])


if __name__ == "__main__":
    unittest.main()
