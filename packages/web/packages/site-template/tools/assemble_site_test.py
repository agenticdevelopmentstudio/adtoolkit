#!/usr/bin/env python3
"""Tests for assemble_site.py.

Each test builds a fake site repo in a temp dir — `site/site.json`, any custom files, and the
`src/landing.json` content-buildr would have written — and runs the real assembler against the
real skeleton and toolkit tree, the way a site repo runs it.

Run: python3 tools/assemble_site_test.py
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ASSEMBLE = Path(__file__).resolve().parent / "assemble_site.py"
OUTPUT = "websites/main"


def run(site: Path, *extra: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(ASSEMBLE), "--site", str(site), *extra],
        capture_output=True,
        text=True,
    )


class AssembleTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.site = Path(self._tmp.name)
        self.app = self.site / OUTPUT
        self.config: dict = {"output": OUTPUT, "port": 5210}
        self.sections: list[str] = ["features"]

    def tearDown(self) -> None:
        self._tmp.cleanup()

    # --- fixtures ---------------------------------------------------------------------------

    def write(self, rel: str, text: str) -> Path:
        path = self.site / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def setup_site(self) -> None:
        self.write("site/site.json", json.dumps(self.config, indent=2))
        landing = {"hero": {}, "sections": [{"id": s, "blocks": []} for s in self.sections]}
        self.write(f"{OUTPUT}/src/landing.json", json.dumps(landing))

    def assemble(self, *extra: str) -> subprocess.CompletedProcess[str]:
        self.setup_site()
        return run(self.site, *extra)

    def assert_ok(self, result: subprocess.CompletedProcess[str]) -> None:
        self.assertEqual(result.returncode, 0, f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}")

    def assert_refused(self, result: subprocess.CompletedProcess[str], *needles: str) -> None:
        self.assertEqual(result.returncode, 2, f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}")
        lines = result.stderr.strip().splitlines()
        self.assertTrue(lines, "exit 2 with nothing on stderr")
        for line in lines:
            self.assertTrue(line.startswith("assemble: "), line)
        for needle in needles:
            self.assertIn(needle, result.stderr)

    # --- a minimal site -------------------------------------------------------------------

    def test_minimal_site_assembles_and_checks_clean(self) -> None:
        self.assert_ok(self.assemble())
        for rel in [
            "app/layout.tsx",
            "app/page.tsx",
            "app/robots.ts",
            "app/sitemap.ts",
            "app/not-found.tsx",
            "app/theme.css",
            "next.config.ts",
            "tsconfig.json",
            "postcss.config.mjs",
            "eslint.config.mjs",
            "package.json",
            "src/site/config.ts",
            "src/site/slots.tsx",
            "src/site/fonts.ts",
            "src/fonts/iosevka-400.woff2",
            ".site-template.json",
        ]:
            self.assertTrue((self.app / rel).is_file(), rel)
        self.assertFalse((self.app / "next-env.d.ts").exists())
        self.assert_ok(run(self.site, "--check"))

    def test_rerun_is_idempotent(self) -> None:
        self.assert_ok(self.assemble())
        before = {p: p.stat().st_mtime_ns for p in self.app.rglob("*") if p.is_file()}
        self.assert_ok(run(self.site))
        after = {p: p.stat().st_mtime_ns for p in self.app.rglob("*") if p.is_file()}
        self.assertEqual(before, after)

    def test_generated_files(self) -> None:
        self.assert_ok(self.assemble())
        pkg = json.loads((self.app / "package.json").read_text())
        self.assertNotIn("//", pkg)
        self.assertEqual(pkg["scripts"]["dev"], "next dev -p 5210")
        self.assertEqual(
            pkg["dependencies"]["@agenticdevelopertoolkit/site-template"],
            "link:../external/agenticdevelopertoolkit/packages/web/packages/site-template",
        )
        config = (self.app / "src/site/config.ts").read_text()
        self.assertIn("frameSiteUrl(5210)", config)
        self.assertIn('"/glyph.svg"', config)
        fonts = (self.app / "src/site/fonts.ts").read_text()
        self.assertEqual(fonts.count("localFont({"), 1)
        self.assertIn('"--font-iosevka"', fonts)
        self.assertIn('"../fonts/iosevka-700.woff2"', fonts)
        css = (self.app / "app/theme.css").read_text()
        order = [
            "themes/styles/fishlamp.css",
            "landing/css/base.css",
            "landing/css/chrome.css",
            "landing/css/blocks.css",
            "landing/css/flow.css",
            "site-template/css/bridge.css",
            "site-template/css/frame.css",
        ]
        positions = [css.index(sheet) for sheet in order]
        self.assertEqual(positions, sorted(positions))
        manifest = json.loads((self.app / ".site-template.json").read_text())
        self.assertEqual(manifest["files"], sorted(manifest["files"]))
        template_pkg = json.loads((ASSEMBLE.parent.parent / "package.json").read_text())
        self.assertEqual(manifest["version"], template_pkg["version"])

    def test_site_inputs_are_copied_and_linked(self) -> None:
        self.config.update(
            {
                "tokens": "theme.css",
                "slots": {"hero": "hero.tsx#Hero", "band:features": "parts/features.tsx#Features"},
                "drawer": [{"href": "/downloads", "label": "Downloads"}],
                "dependencies": {"zod": "^3.0.0"},
                "toolkitPackages": ["releases"],
                "mark": {"src": "/app-icon.png", "shape": "app-icon"},
            }
        )
        self.write("site/theme.css", ":root {\n  --lp-root-size: 87.5%;\n  --st-hero-meta-transform: none;\n}\n")
        self.write("site/components/hero.tsx", "export function Hero() { return null }\n")
        self.write("site/components/parts/features.tsx", "export function Features() { return null }\n")
        self.write("site/routes/downloads/page.tsx", "export default function P() { return null }\n")
        self.write("site/src/releases/config.ts", "export const x = 1\n")
        self.write("site/public/app-icon.png", "png")
        self.write("site/app-root/vercel.json", "{}\n")
        self.assert_ok(self.assemble())
        for rel in [
            "src/components/hero.tsx",
            "src/components/parts/features.tsx",
            "app/downloads/page.tsx",
            "src/releases/config.ts",
            "public/app-icon.png",
            "vercel.json",
        ]:
            self.assertTrue((self.app / rel).is_file(), rel)
        slots = (self.app / "src/site/slots.tsx").read_text()
        self.assertIn("from '../components/hero'", slots)
        self.assertIn("from '../components/parts/features'", slots)
        self.assertIn('"features":', slots)
        self.assertIn("hero:", slots)
        self.assertTrue((self.app / "app/theme.css").read_text().rstrip().endswith("}"))
        self.assertIn("--st-hero-meta-transform: none;", (self.app / "app/theme.css").read_text())
        pkg = json.loads((self.app / "package.json").read_text())
        self.assertEqual(pkg["dependencies"]["zod"], "^3.0.0")
        self.assertEqual(
            pkg["dependencies"]["@agenticdevelopertoolkit/releases"],
            "link:../external/agenticdevelopertoolkit/packages/web/packages/releases",
        )
        self.assert_ok(run(self.site, "--check"))

    # --- --check ------------------------------------------------------------------------

    def test_check_names_an_edited_file(self) -> None:
        self.assert_ok(self.assemble())
        (self.app / "app/page.tsx").write_text("// edited by hand\n")
        result = run(self.site, "--check")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("app/page.tsx", result.stdout)
        self.assertNotIn("app/layout.tsx", result.stdout)

    def test_check_before_any_assemble_lists_missing_files(self) -> None:
        result = self.assemble("--check")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("app/layout.tsx", result.stdout)
        self.assertFalse((self.app / "app").exists())

    # --- refusals -------------------------------------------------------------------------

    def test_band_slot_typo_names_the_id_and_the_sections(self) -> None:
        self.config["slots"] = {"band:feautres": "f.tsx#F"}
        self.write("site/components/f.tsx", "export function F() { return null }\n")
        self.assert_refused(self.assemble(), "'feautres'", "'features'")
        self.assertFalse((self.app / "app").exists())

    def test_route_collision_with_the_template_is_refused(self) -> None:
        self.write("site/routes/layout.tsx", "export default function L() { return null }\n")
        self.assert_refused(self.assemble(), "site/routes/layout.tsx", "app/layout.tsx")

    def test_site_src_collision_with_a_generated_file_is_refused(self) -> None:
        self.write("site/src/site/config.ts", "export const x = 1\n")
        self.assert_refused(self.assemble(), "site/src/site/config.ts", "src/site/config.ts")

    def test_token_sheet_with_a_selector_is_refused(self) -> None:
        self.config["tokens"] = "theme.css"
        self.write("site/theme.css", ":root { --a: 1px; }\n.lp-cards { gap: 0; }\n")
        self.assert_refused(self.assemble(), "site/theme.css", ".lp-cards")

    def test_token_sheet_with_a_plain_property_is_refused(self) -> None:
        self.config["tokens"] = "theme.css"
        self.write("site/theme.css", ":root {\n  --a: 1px;\n  color: red;\n}\n")
        self.assert_refused(self.assemble(), "site/theme.css", "color")

    def test_component_css_naming_the_frame_is_refused(self) -> None:
        self.write("site/components/hero.css", ".my-hero { color: red; }\n.lp-band .x { margin: 0; }\n")
        self.assert_refused(self.assemble(), "site/components/hero.css", ".lp-band")

    def test_route_css_naming_body_is_refused(self) -> None:
        self.write("site/routes/downloads/page.css", "@media (width > 1px) { body { margin: 0; } }\n")
        self.assert_refused(self.assemble(), "site/routes/downloads/page.css", "body")

    def test_component_css_with_lookalike_names_is_accepted(self) -> None:
        self.write(
            "site/components/hero.css",
            ".my-body .html-ish { color: red; }\n@keyframes spin { from { opacity: 0; } to { opacity: 1; } }\n",
        )
        self.assert_ok(self.assemble())

    def test_unknown_key_is_refused(self) -> None:
        self.config["slot"] = {}
        self.assert_refused(self.assemble(), "'slot'")

    def test_unknown_nested_key_is_refused(self) -> None:
        self.config["mark"] = {"src": "/m.svg", "shape": "glyph", "alt": "x"}
        self.assert_refused(self.assemble(), "mark", "'alt'")

    def test_unknown_slot_name_is_refused(self) -> None:
        self.config["slots"] = {"heroo": "h.tsx#H"}
        self.write("site/components/h.tsx", "export function H() { return null }\n")
        self.assert_refused(self.assemble(), "'heroo'")

    def test_missing_slot_file_is_refused(self) -> None:
        self.config["slots"] = {"hero": "nope.tsx#Hero"}
        self.assert_refused(self.assemble(), "site/components/nope.tsx")

    def test_extra_dependency_naming_a_template_dependency_is_refused(self) -> None:
        self.config["dependencies"] = {"next": "^15.0.0"}
        self.assert_refused(self.assemble(), "'next'")

    def test_unknown_toolkit_package_is_refused(self) -> None:
        self.config["toolkitPackages"] = ["no-such-package"]
        self.assert_refused(self.assemble(), "'no-such-package'")

    def test_unknown_theme_is_refused(self) -> None:
        self.config["theme"] = "nope"
        self.assert_refused(self.assemble(), "'nope'", "fishlamp")

    def test_site_file_under_content_is_refused(self) -> None:
        self.write("site/src/content/site.ts", "export const x = 1\n")
        self.assert_refused(self.assemble(), "site/src/content/site.ts")

    def test_several_problems_are_each_reported(self) -> None:
        self.config["bogus"] = 1
        self.config["port"] = "5210"
        lines = self.assemble().stderr.strip().splitlines()
        self.assertGreaterEqual(len(lines), 2, lines)

    # --- stale files and protected paths -------------------------------------------------

    def test_removed_slot_component_is_deleted_and_checked(self) -> None:
        self.config["slots"] = {"hero": "hero.tsx#Hero"}
        self.write("site/components/hero.tsx", "export function Hero() { return null }\n")
        self.assert_ok(self.assemble())
        stale = self.app / "src/components/hero.tsx"
        self.assertTrue(stale.is_file())

        del self.config["slots"]
        (self.site / "site/components/hero.tsx").unlink()
        self.setup_site()
        result = run(self.site, "--check")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("src/components/hero.tsx", result.stdout)
        self.assertIn("src/site/slots.tsx", result.stdout)

        self.assert_ok(run(self.site))
        self.assertFalse(stale.exists())
        self.assertFalse((self.app / "src/components").exists())
        self.assertNotIn("hero", (self.app / "src/site/slots.tsx").read_text())
        self.assert_ok(run(self.site, "--check"))

    def test_content_files_survive_a_rerun(self) -> None:
        self.assert_ok(self.assemble())
        kept = {
            "src/content/x.json": '{"a": 1}\n',
            "src/landing.tsx": "export default {}\n",
            "public/glyph.svg": "<svg/>",
        }
        for rel, text in kept.items():
            self.write(f"{OUTPUT}/{rel}", text)
        landing = (self.app / "src/landing.json").read_text()
        self.assert_ok(run(self.site))
        self.assert_ok(run(self.site, "--check"))
        for rel, text in kept.items():
            self.assertEqual((self.app / rel).read_text(), text, rel)
        self.assertEqual((self.app / "src/landing.json").read_text(), landing)


if __name__ == "__main__":
    unittest.main()
