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

    def test_font_roles_point_the_theme_at_the_hosted_faces(self) -> None:
        # next/font hashes the family name, so fishlamp's `--font-mono: 'Iosevka', …` never finds
        # the self-hosted face; the role rule points it at the face's variable instead.
        self.config.update(
            {
                "tokens": "theme.css",
                "fonts": [
                    {
                        "variable": "--font-outfit",
                        "role": "--font-display",
                        "fallback": "ui-sans-serif, sans-serif",
                        "files": [{"path": "fonts/outfit-600.woff2", "weight": "600", "style": "normal"}],
                    },
                    {
                        "variable": "--font-plain",
                        "files": [{"path": "fonts/plain-400.woff2", "weight": "400", "style": "normal"}],
                    },
                ],
            }
        )
        self.write("site/theme.css", ":root {\n  --a: 1px;\n}\n")
        self.write("site/fonts/outfit-600.woff2", "woff2")
        self.write("site/fonts/plain-400.woff2", "woff2")
        self.assert_ok(self.assemble())
        css = (self.app / "app/theme.css").read_text()
        mono = (
            "--font-mono: var(--font-iosevka), 'Iosevka Fallback Menlo', "
            "'Iosevka Fallback Courier', ui-monospace, monospace;"
        )
        display = "--font-display: var(--font-outfit), ui-sans-serif, sans-serif;"
        self.assertIn(mono, css)
        self.assertIn(display, css)
        self.assertNotIn("--font-plain", css)
        order = ["site-template/css/frame.css", mono, display, "/* site/theme.css */"]
        positions = [css.index(needle) for needle in order]
        self.assertEqual(positions, sorted(positions))
        fonts = (self.app / "src/site/fonts.ts").read_text()
        self.assertNotIn("-ext", fonts)

    def test_a_font_role_list_fills_each_property(self) -> None:
        fallback = "'Iosevka Fallback Menlo', 'Iosevka Fallback Courier', ui-monospace, monospace"
        self.config["fonts"] = [
            {
                "variable": "--font-outfit",
                "role": ["--font-display", "--font-heading"],
                "fallback": "sans-serif",
                "files": [{"path": "fonts/outfit-600.woff2", "weight": "600", "style": "normal"}],
            }
        ]
        self.write("site/fonts/outfit-600.woff2", "woff2")
        self.assert_ok(self.assemble())
        css = (self.app / "app/theme.css").read_text()
        # fishlamp's own list: every property its sheet names 'Iosevka' in, display excepted.
        for role in ("--font-mono", "--font-sans", "--font-serif"):
            self.assertIn(f"{role}: var(--font-iosevka), {fallback};", css)
        self.assertNotIn("--font-display: var(--font-iosevka)", css)
        self.assertIn("--font-display: var(--font-outfit), sans-serif;", css)
        self.assertIn("--font-heading: var(--font-outfit), sans-serif;", css)

    def test_a_role_filled_twice_is_refused(self) -> None:
        self.config["fonts"] = [
            {
                "variable": "--font-outfit",
                "role": ["--font-display", "--font-sans"],
                "files": [{"path": "fonts/outfit-600.woff2", "weight": "600", "style": "normal"}],
            }
        ]
        self.write("site/fonts/outfit-600.woff2", "woff2")
        self.assert_refused(self.assemble(), "'--font-sans'", "already filled")

    def test_a_malformed_role_is_refused(self) -> None:
        for role in ([], ["font-mono"], 3):
            with self.subTest(role=role):
                self.config["fonts"] = [
                    {
                        "variable": "--font-outfit",
                        "role": role,
                        "files": [{"path": "fonts/outfit-600.woff2", "weight": "600", "style": "normal"}],
                    }
                ]
                self.assert_refused(self.assemble(), "fonts[0].role")

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

    # --- review fixes -----------------------------------------------------------------------

    def test_a_hostile_manifest_cannot_delete_protected_files(self) -> None:
        self.assert_ok(self.assemble())
        kept = ["src/content/x.json", "src/landing.tsx", "public/glyph.svg", "src/Landing.tsx"]
        for rel in kept:
            self.write(f"{OUTPUT}/{rel}", "keep")
        outside = self.write("outside.txt", "keep")
        manifest = json.loads((self.app / ".site-template.json").read_text())
        manifest["files"] += [
            "./src/content/x.json",
            "src//landing.tsx",
            "public/./glyph.svg",
            "SRC/Content/x.json",
            "src/Landing.tsx",
            "/etc/hosts",
            "../../outside.txt",
            "",
            ".",
        ]
        (self.app / ".site-template.json").write_text(json.dumps(manifest))
        # The edited manifest is itself out of date; nothing it smuggled in is stale.
        check = run(self.site, "--check")
        self.assertEqual(check.stdout.strip(), "changed: .site-template.json", check.stderr)
        self.assert_ok(run(self.site))
        self.assert_ok(run(self.site, "--check"))
        for rel in kept:
            self.assertTrue((self.app / rel).is_file(), rel)
        self.assertTrue(outside.is_file())

    def test_a_manifest_entry_through_a_symlink_out_of_the_app_is_ignored(self) -> None:
        self.assert_ok(self.assemble())
        target = self.write("elsewhere/victim.txt", "keep")
        (self.app / "linked").symlink_to(target.parent)
        manifest = json.loads((self.app / ".site-template.json").read_text())
        manifest["files"].append("linked/victim.txt")
        (self.app / ".site-template.json").write_text(json.dumps(manifest))
        self.assert_ok(run(self.site))
        self.assertTrue(target.is_file())

    def test_a_comment_opener_inside_a_string_hides_nothing(self) -> None:
        sheet = ':root { --a: "/*"; } .lp-cards { gap: 0 } :root { --b: "*/"; }\n'
        self.config["tokens"] = "theme.css"
        self.write("site/theme.css", sheet)
        self.assert_refused(self.assemble(), "site/theme.css", ".lp-cards")

    def test_a_comment_opener_inside_a_string_hides_nothing_in_component_css(self) -> None:
        css = 'a { content: "/*" } .lp-band { color: red } b { content: "*/" }\n'
        self.write("site/components/x.css", css)
        self.assert_refused(self.assemble(), "site/components/x.css", ".lp-band")

    def test_real_comments_are_still_ignored(self) -> None:
        self.write("site/components/x.css", "/* .lp-band body html */ .mine { color: red }\n")
        self.assert_ok(self.assemble())

    def test_selector_bypasses_are_refused(self) -> None:
        cases = {
            ".\\6c p-band { color: red }": ".lp-band",
            ".\\6C p-band { color: red }": ".lp-band",
            ".l\\p-band { color: red }": ".lp-band",
            "HTML { color: red }": "html",
            "Body > main { color: red }": "body",
            ":root { color: red }": ":root",
            ":ROOT .x { color: red }": ":root",
            "@scope (.lp-band) { :scope { color: red } }": ".lp-band",
            '[class*="lp-band"] { color: red }': "lp-band",
            "[class^=st-] { color: red }": "st-",
            "[CLASS~='lp-x' i] { color: red }": "lp-x",
            ":root, .lp-x { color: red }": ".lp-x",
            ":is(.lp-x) { color: red }": ".lp-x",
            ".x { .lp-band & { color: red } }": ".lp-band",
        }
        for css, needle in cases.items():
            with self.subTest(css=css):
                self.write("site/components/x.css", css + "\n")
                self.assert_refused(self.assemble(), "site/components/x.css", needle)

    def test_selector_lookalikes_stay_accepted(self) -> None:
        cases = [
            ".my-body .html-ish .help-x { color: red }",
            '[data-x="lp-band"] { color: red }',
            '.x::after { content: ".lp-band body" }',
            "@keyframes lp-spin { from { opacity: 0 } }",
        ]
        for css in cases:
            with self.subTest(css=css):
                self.write("site/components/x.css", css + "\n")
                self.assert_ok(self.assemble())

    def test_output_must_be_under_websites(self) -> None:
        for output in [".", "site", "websites", "websites/./main", "websites/../main", "./websites/main", "/abs", "websites/"]:
            with self.subTest(output=output):
                self.config["output"] = output
                self.assert_refused(self.assemble(), "output")

    def test_output_accepts_a_deeper_websites_path(self) -> None:
        self.config["output"] = "websites/apps/main"
        self.write("site/site.json", json.dumps(self.config))
        self.assert_ok(run(self.site))
        self.assertTrue((self.site / "websites/apps/main/app/layout.tsx").is_file())

    def test_a_site_file_at_the_manifest_path_is_a_collision(self) -> None:
        self.write("site/app-root/.site-template.json", "{}\n")
        self.assert_refused(self.assemble(), "site/app-root/.site-template.json", ".site-template.json")

    def test_tokens_outside_site_is_refused(self) -> None:
        self.write("theme.css", ":root { --a: 1px; }\n")
        self.config["tokens"] = "../theme.css"
        self.assert_refused(self.assemble(), "tokens", "outside site/")

    def test_a_site_font_outside_site_is_refused(self) -> None:
        self.write("x.woff2", "woff2")
        self.config["fonts"] = [
            {"variable": "--font-x", "files": [{"path": "../x.woff2", "weight": "400", "style": "normal"}]}
        ]
        self.assert_refused(self.assemble(), "fonts[0]", "outside site/")

    def test_the_schema_checker_refuses_a_keyword_it_does_not_know(self) -> None:
        module = load_assembler()
        with self.assertRaises(module.SchemaError):
            module.check_schema("x", {"type": "string", "maxLength": 3}, "x", [])
        with self.assertRaises(module.SchemaError):
            module.check_schema("x", {"type": "uuid"}, "x", [])
        with self.assertRaises(module.SchemaError):
            module.check_schema({"a": 1}, {"type": "object", "propertyNames": {"maxLength": 3}}, "", [])

    def test_the_schema_checker_knows_number_and_boolean(self) -> None:
        module = load_assembler()
        problems: list[str] = []
        module.check_schema(True, {"type": "boolean"}, "a", problems)
        module.check_schema(1.5, {"type": "number", "minimum": 1}, "b", problems)
        self.assertEqual(problems, [])
        module.check_schema(1, {"type": "boolean"}, "c", problems)
        module.check_schema(True, {"type": "number"}, "d", problems)
        module.check_schema(0.5, {"type": "number", "minimum": 1}, "e", problems)
        self.assertEqual(len(problems), 3, problems)

    def test_the_real_schema_uses_only_known_keywords(self) -> None:
        module = load_assembler()
        schema = json.loads((ASSEMBLE.parent.parent / "schema" / "site.schema.json").read_text())
        module.check_schema({"output": "websites/main", "port": 1}, schema, "", [])


def load_assembler():  # type: ignore[no-untyped-def]
    import importlib.util

    spec = importlib.util.spec_from_file_location("assemble_site", ASSEMBLE)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


if __name__ == "__main__":
    unittest.main()
