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
        # The sections content-buildr marks `slot: true` (`## Label {slot}`).
        self.slotted: set[str] = set()

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
        landing = {
            "hero": {},
            "sections": [
                {"id": s, **({"slot": True} if s in self.slotted else {}), "blocks": []} for s in self.sections
            ],
        }
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
            "app/(frame)/layout.tsx",
            "app/(frame)/page.tsx",
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
            "src/site/next.ts",
            "src/site/analytics.tsx",
            "src/fonts/iosevka-site-400.woff2",
            ".site-template.json",
        ]:
            self.assertTrue((self.app / rel).is_file(), rel)
        self.assertFalse((self.app / "next-env.d.ts").exists())
        self.assertFalse((self.app / "app/page.tsx").exists())
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
        self.assertIn('"--font-iosevka"', fonts)
        self.assertIn('"../fonts/iosevka-site-700.woff2"', fonts)
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

    def test_fishlamp_serves_the_site_cut_and_preloads_regular_and_bold_only(self) -> None:
        # The landing's first screen sets Iosevka regular and bold; italic sets only an <em>
        # in a site's copy, so it is fetched when one paints rather than on every page.
        self.assert_ok(self.assemble())
        fonts = (self.app / "src/site/fonts.ts").read_text()
        eager, lazy = fonts.split("const fontIosevkaLazy = ", 1)
        self.assertIn('"../fonts/iosevka-site-400.woff2"', eager)
        self.assertIn('"../fonts/iosevka-site-700.woff2"', eager)
        self.assertNotIn("italic", eager)
        self.assertNotIn("preload", eager)
        self.assertIn('"../fonts/iosevka-site-400-italic.woff2"', lazy)
        self.assertIn("preload: false", lazy)
        for theme_face in ("iosevka-400.woff2", "iosevka-700.woff2", "iosevka-400-italic.woff2"):
            self.assertFalse((self.app / "src/fonts" / theme_face).exists(), theme_face)

    def test_a_face_that_does_not_preload_joins_its_family_unpreloaded(self) -> None:
        # next/font preloads per call, not per file, so the lazy faces are a second call. Both
        # name ONE family — next/font hashes each call's family apart otherwise, and an italic
        # in another family is never picked for an <em> in this one.
        self.config["fonts"] = [
            {
                "variable": "--font-body",
                "files": [
                    {"path": "fonts/body-400.woff2", "weight": "400", "style": "normal"},
                    {"path": "fonts/body-400-italic.woff2", "weight": "400", "style": "italic", "preload": False},
                ],
            }
        ]
        self.write("site/fonts/body-400.woff2", "woff2")
        self.write("site/fonts/body-400-italic.woff2", "woff2")
        self.assert_ok(self.assemble())
        fonts = (self.app / "src/site/fonts.ts").read_text()
        eager, lazy = fonts.split("const fontBodyLazy = ", 1)
        family = "declarations: [{ prop: 'font-family', value: \"'site-font-body'\" }],"
        self.assertIn(family, eager.split("const fontBody = ", 1)[1])
        self.assertIn(family, lazy)
        self.assertIn('"../fonts/body-400.woff2"', eager)
        self.assertNotIn("body-400-italic", eager)
        self.assertIn('"../fonts/body-400-italic.woff2"', lazy)
        self.assertIn("preload: false", lazy)
        self.assertIn("adjustFontFallback: false", lazy)
        self.assertIn('variable: "--font-body-lazy"', lazy)
        # Its class still goes on <html>, so the lazy call's @font-face rules are in the page.
        self.assertIn("fontBodyLazy.variable", fonts.split("export const fontVariables", 1)[1])

    def test_a_family_that_preloads_every_face_stays_one_call(self) -> None:
        self.config["fonts"] = [
            {"variable": "--font-body", "files": [{"path": "fonts/body-400.woff2", "weight": "400", "style": "normal"}]}
        ]
        self.write("site/fonts/body-400.woff2", "woff2")
        self.assert_ok(self.assemble())
        fonts = (self.app / "src/site/fonts.ts").read_text()
        self.assertNotIn("fontBodyLazy", fonts)
        self.assertNotIn("site-font-body", fonts)

    def test_a_family_with_no_preloaded_face_is_refused(self) -> None:
        # Its variable is the eager call's; with nothing eager there is no call to carry it.
        self.config["fonts"] = [
            {
                "variable": "--font-body",
                "files": [{"path": "fonts/body-400.woff2", "weight": "400", "style": "normal", "preload": False}],
            }
        ]
        self.write("site/fonts/body-400.woff2", "woff2")
        self.assert_refused(self.assemble(), "fonts[0]", "preload")

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

    def test_roles_and_tokens_tie_the_themes_html_root(self) -> None:
        # fishlamp declares its font roles on `html:root` (0,1,1); a `:root` (0,1,0) rule loses
        # to it whatever its order, so the roles and the site's tokens are written at the same
        # specificity, after the theme, and source order decides as the header says.
        self.config.update(
            {
                "tokens": "theme.css",
                "fonts": [
                    {
                        "variable": "--font-outfit",
                        "role": "--font-display",
                        "files": [{"path": "fonts/outfit-600.woff2", "weight": "600", "style": "normal"}],
                    }
                ],
            }
        )
        sheet = "/* a :root { comment } */\n:root {\n  --a: ':root';\n}\n:root { --b: 2px; }\n"
        self.write("site/theme.css", sheet)
        self.write("site/fonts/outfit-600.woff2", "woff2")
        self.assert_ok(self.assemble())
        css = (self.app / "app/theme.css").read_text()
        self.assertIn("html:root {\n  --font-mono: var(--font-iosevka)", css)
        self.assertIn("/* a :root { comment } */\nhtml:root {\n  --a: ':root';\n}\nhtml:root { --b: 2px; }\n", css)
        self.assertNotRegex(css, r"(?m)^:root")

    def test_the_reset_comes_first(self) -> None:
        # The kit draws on a host that resets the document (every pre-template site imported
        # tailwind): without preflight, body keeps the browser's 8px margin.
        self.assert_ok(self.assemble())
        css = (self.app / "app/theme.css").read_text()
        reset = '@import "tailwindcss/preflight.css" layer(base);'
        self.assertLess(css.index(reset), css.index("themes/styles/fishlamp.css"))

    def test_the_reset_is_preflight_alone(self) -> None:
        # The whole of tailwind would add its theme variables and utility generation, and set every
        # site scanning its sources for class names; the frame wants only the document reset.
        self.assert_ok(self.assemble())
        css = (self.app / "app/theme.css").read_text()
        self.assertNotIn('@import "tailwindcss";', css)

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
                "drawer": [{"href": "/downloads", "nav": "downloads"}],
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
            "app/(frame)/downloads/page.tsx",
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
        (self.app / "app/(frame)/page.tsx").write_text("// edited by hand\n")
        result = run(self.site, "--check")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("app/(frame)/page.tsx", result.stdout)
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

    def test_a_slot_section_no_band_slot_fills_is_refused(self) -> None:
        self.sections = ["features", "about"]
        self.slotted = {"about"}
        self.assert_refused(self.assemble(), "'about'", "{slot}", "band:about")
        self.assertFalse((self.app / "app").exists())

    def test_a_slot_section_with_its_band_slot_assembles(self) -> None:
        self.sections = ["features", "about"]
        self.slotted = {"about"}
        self.config["slots"] = {"band:about": "about.tsx#About"}
        self.write("site/components/about.tsx", "export function About() { return null }\n")
        self.assert_ok(self.assemble())
        self.assertIn('"about": BandSlot', (self.app / "src/site/slots.tsx").read_text())

    def test_route_collision_with_the_template_is_refused(self) -> None:
        self.write("site/routes/layout.tsx", "export default function L() { return null }\n")
        self.assert_refused(self.assemble(), "site/routes/layout.tsx", "app/(frame)/layout.tsx")

    def test_app_route_collision_with_the_root_layout_is_refused(self) -> None:
        self.write("site/app-routes/layout.tsx", "export default function L() { return null }\n")
        self.assert_refused(self.assemble(), "site/app-routes/layout.tsx", "app/layout.tsx")

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

    def test_the_og_image_size_reaches_the_config(self) -> None:
        self.config["ogImageSize"] = {"width": 512, "height": 512}
        self.assert_ok(self.assemble())
        config = (self.app / "src/site/config.ts").read_text()
        self.assertIn('ogImageSize: {\n    "width": 512,\n    "height": 512\n  },', config)

    def test_band_looks_reach_the_config(self) -> None:
        self.config["bands"] = {"features": {"tone": "paper", "seam": False}}
        self.assert_ok(self.assemble())
        config = (self.app / "src/site/config.ts").read_text()
        self.assertIn('bands: {\n    "features": {\n      "tone": "paper",\n      "seam": false\n    }\n  },', config)

    def test_no_band_looks_leaves_them_out(self) -> None:
        self.assert_ok(self.assemble())
        self.assertNotIn("bands", (self.app / "src/site/config.ts").read_text())

    def test_a_band_look_naming_no_section_is_refused(self) -> None:
        self.config["bands"] = {"feautres": {"tone": "paper"}}
        self.assert_refused(self.assemble(), "bands", "'feautres'", "'features'")

    def test_a_band_look_with_an_unknown_tone_is_refused(self) -> None:
        self.config["bands"] = {"features": {"tone": "neon"}}
        self.assert_refused(self.assemble(), "bands.features.tone")

    def test_a_bitbag_slot_is_placed(self) -> None:
        self.config["slots"] = {"bitbag": "bitbag.tsx#SiteVoice"}
        self.write("site/components/bitbag.tsx", "export function SiteVoice() { return null }\n")
        self.assert_ok(self.assemble())
        slots = (self.app / "src/site/slots.tsx").read_text()
        self.assertIn("import { SiteVoice as BitbagSlot } from '../components/bitbag'", slots)
        self.assertIn("  bitbag: BitbagSlot,", slots)
        self.assertIn("slots.bitbag", (self.app / "app/(frame)/layout.tsx").read_text())

    def test_the_site_shot_is_worded_from_the_copy_once(self) -> None:
        self.assert_ok(self.assemble())
        shot = (self.app / "src/site/shot.tsx").read_text()
        self.assertIn("import siteCopy from '../content/site/site.json'", shot)
        self.assertIn("export const SiteShot = frameShot(copy.screenshotPending)", shot)

    def test_a_site_url_reaches_the_config_as_frame_site_urls_second_choice(self) -> None:
        self.config["siteUrl"] = "https://kitchen.example"
        self.assert_ok(self.assemble())
        config = (self.app / "src/site/config.ts").read_text()
        self.assertIn('siteUrl: frameSiteUrl(5210, "https://kitchen.example"),', config)

    def test_no_site_url_leaves_frame_site_url_on_the_port_alone(self) -> None:
        self.assert_ok(self.assemble())
        self.assertIn("siteUrl: frameSiteUrl(5210),", (self.app / "src/site/config.ts").read_text())

    def test_a_site_url_that_is_not_an_origin_is_refused(self) -> None:
        for bad in ["kitchen.example", "https://kitchen.example/page", "ftp://kitchen.example", ""]:
            with self.subTest(bad=bad):
                self.config["siteUrl"] = bad
                self.assert_refused(self.assemble(), "siteUrl")

    def test_no_og_image_size_leaves_it_out(self) -> None:
        self.assert_ok(self.assemble())
        self.assertNotIn("ogImageSize", (self.app / "src/site/config.ts").read_text())

    def test_an_og_image_size_missing_a_side_is_refused(self) -> None:
        self.config["ogImageSize"] = {"width": 512}
        self.assert_refused(self.assemble(), "ogImageSize", "'height'")

    def test_drawer_rows_name_their_label_in_the_copy(self) -> None:
        self.config["drawer"] = [{"href": "/home", "nav": "login"}]
        self.write(f"{OUTPUT}/src/content/site/site.json", json.dumps({"nav": {"home": "Home", "extra": {"login": "Login"}}}))
        self.assert_ok(self.assemble())
        self.assertIn('"nav": "login"', (self.app / "src/site/config.ts").read_text())

    def test_a_drawer_row_the_copy_does_not_word_is_refused(self) -> None:
        self.config["drawer"] = [{"href": "/home", "nav": "login"}]
        self.write(f"{OUTPUT}/src/content/site/site.json", json.dumps({"nav": {"home": "Home"}}))
        self.assert_refused(self.assemble(), "drawer[0]", "'login'", "nav.extra")

    def test_a_drawer_row_with_a_label_is_refused(self) -> None:
        # The label is copy, worded in site.md's `# nav`; site.json says only where the row goes.
        self.config["drawer"] = [{"href": "/home", "label": "Login"}]
        self.assert_refused(self.assemble(), "drawer[0]")

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

    # --- probe5: aliases, case, namespaces, broken strings, websites/external ------------------

    def add_to_manifest(self, *entries: str) -> None:
        manifest = json.loads((self.app / ".site-template.json").read_text())
        manifest["files"] += list(entries)
        (self.app / ".site-template.json").write_text(json.dumps(manifest))

    def test_a_manifest_entry_through_a_symlinked_directory_in_the_app_is_ignored(self) -> None:
        self.assert_ok(self.assemble())
        kept = self.write(f"{OUTPUT}/src/content/x.json", "keep")
        (self.app / "lnk").symlink_to("src/content")
        self.add_to_manifest("lnk/x.json")
        self.assert_ok(run(self.site))
        self.assertTrue(kept.is_file())
        self.assertTrue((self.app / "lnk").is_symlink())

    def test_a_manifest_entry_naming_a_symlinked_file_is_ignored(self) -> None:
        self.assert_ok(self.assemble())
        glyph = self.write(f"{OUTPUT}/public/glyph.svg", "keep")
        (self.app / "glyph-link").symlink_to("public/glyph.svg")
        self.add_to_manifest("glyph-link")
        result = run(self.site)
        self.assert_ok(result)
        self.assertIn("0 removed", result.stdout)
        self.assertTrue((self.app / "glyph-link").is_symlink())
        self.assertTrue(glyph.is_file())

    def test_a_symlinked_src_is_never_deleted_through(self) -> None:
        self.assert_ok(self.assemble())
        self.write(f"{OUTPUT}/src/content/x.json", "keep")
        real = self.site / "realsrc"
        (self.app / "src").rename(real)
        (self.app / "src").symlink_to(real)
        self.add_to_manifest("src/content/x.json", "src/site/config.ts", "src/site/old.ts")
        self.write("realsrc/site/old.ts", "keep")
        self.assert_ok(run(self.site))
        for rel in ["content/x.json", "site/old.ts"]:
            self.assertTrue((real / rel).is_file(), rel)
        self.assertTrue((self.app / "src").is_symlink())

    def test_a_case_variant_of_a_written_file_is_never_stale(self) -> None:
        self.assert_ok(self.assemble())
        self.add_to_manifest("PACKAGE.JSON", "App/Layout.tsx", ".site-template.json", ".SITE-TEMPLATE.JSON")
        check = run(self.site, "--check")
        self.assertEqual(check.stdout.strip(), "changed: .site-template.json", check.stderr)
        result = run(self.site)
        self.assert_ok(result)
        self.assertIn("0 removed", result.stdout)
        for rel in ["package.json", "app/layout.tsx", ".site-template.json"]:
            self.assertTrue((self.app / rel).is_file(), rel)
        self.assert_ok(run(self.site, "--check"))

    def test_a_site_file_at_the_manifest_path_in_another_case_is_a_collision(self) -> None:
        self.write("site/app-root/.SITE-TEMPLATE.json", "{}\n")
        self.assert_refused(self.assemble(), "site/app-root/.SITE-TEMPLATE.json", "the template writes")

    def test_a_site_file_at_a_template_path_in_another_case_is_a_collision(self) -> None:
        self.write("site/app-root/App/Layout.tsx", "export {}\n")
        self.assert_refused(self.assemble(), "site/app-root/App/Layout.tsx", "the template writes")

    def test_namespaced_class_attribute_selectors_are_refused(self) -> None:
        cases = {
            '[*|class^="lp-"] { color: red }': "lp-",
            '[|class*="lp-band"] { color: red }': "lp-band",
            "[svg|class*=lp-x] { color: red }": "lp-x",
        }
        for css, needle in cases.items():
            with self.subTest(css=css):
                self.write("site/components/x.css", css + "\n")
                self.assert_refused(self.assemble(), "site/components/x.css", needle)

    def test_a_dash_match_class_attribute_still_parses(self) -> None:
        self.write("site/components/x.css", "[class|=lp] { color: red }\n")
        self.assert_refused(self.assemble(), "site/components/x.css", "lp")

    def test_a_raw_newline_in_a_string_is_refused(self) -> None:
        css = 'a { content: "x\n}\n.lp-band { color: red }\nb { content: "y" }\n'
        self.write("site/components/x.css", css)
        self.assert_refused(self.assemble(), "site/components/x.css", "unterminated string")

    def test_a_raw_newline_in_a_token_sheet_string_is_refused(self) -> None:
        self.config["tokens"] = "theme.css"
        self.write("site/theme.css", ":root { --a: 'x\n; }\n")
        self.assert_refused(self.assemble(), "site/theme.css", "unterminated string")

    def test_an_escaped_newline_in_a_string_is_accepted(self) -> None:
        self.write("site/components/x.css", 'a { content: "x\\\ny" }\n')
        self.assert_ok(self.assemble())

    def test_output_under_websites_external_is_refused(self) -> None:
        for output in ["websites/external", "websites/external/x", "websites/External/x"]:
            with self.subTest(output=output):
                self.config["output"] = output
                self.assert_refused(self.assemble(), "output")

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

    # --- route groups: the frame's routes and the bare app routes -----------------------------

    def test_the_frame_is_a_route_group_and_the_root_is_bare(self) -> None:
        self.assert_ok(self.assemble())
        root = (self.app / "app/layout.tsx").read_text()
        frame = (self.app / "app/(frame)/layout.tsx").read_text()
        for name in ("SiteChrome", "FrameFooter", "SiteBitbag"):
            self.assertNotIn(name, root, name)
            self.assertIn(name, frame, name)
        self.assertIn("import './theme.css'", root)
        self.assertIn("fontVariables", root)
        self.assertIn("export const metadata", root)
        self.assertIn("<SiteAnalytics />", root)
        self.assertIn("LandingFrame", (self.app / "app/(frame)/page.tsx").read_text())
        # Everything a group's file imports from src/ is one level deeper than the root's.
        for rel in ("app/(frame)/layout.tsx", "app/(frame)/page.tsx"):
            text = (self.app / rel).read_text()
            self.assertNotIn("from '../src/", text, rel)
            self.assertIn("from '../../src/", text, rel)
        # The 404 and the metadata routes stay at the root, outside the group.
        for rel in ("app/not-found.tsx", "app/robots.ts", "app/sitemap.ts"):
            self.assertTrue((self.app / rel).is_file(), rel)
        # Next renders a root not-found inside the root layout only, so the 404 wraps itself in the
        # frame: a templated site's 404 had the bar and footer before the frame became a group.
        not_found = (self.app / "app/not-found.tsx").read_text()
        self.assertIn("import FrameLayout from './(frame)/layout'", not_found)
        self.assertIn("<FrameLayout>", not_found)

    def test_routes_land_inside_the_frame_and_app_routes_outside_it(self) -> None:
        self.write("site/routes/downloads/page.tsx", "export default function P() { return null }\n")
        self.write("site/app-routes/home/layout.tsx", "export default function L() { return null }\n")
        self.write("site/app-routes/home/page.tsx", "export default function P() { return null }\n")
        self.write("site/app-routes/auth/callback/page.tsx", "export default function P() { return null }\n")
        self.write("site/app-routes/icon.png", "png")
        self.assert_ok(self.assemble())
        for rel in (
            "app/(frame)/downloads/page.tsx",
            "app/home/layout.tsx",
            "app/home/page.tsx",
            "app/auth/callback/page.tsx",
            "app/icon.png",
        ):
            self.assertTrue((self.app / rel).is_file(), rel)
        self.assert_ok(run(self.site, "--check"))

    def test_the_root_layout_restores_zoom_on_every_route(self) -> None:
        # The viewport's maximum-scale=1 reaches every route, so its off-iOS strip must too: the
        # root layout renders it first in <body>, ahead of any route's own markup.
        self.assert_ok(self.assemble())
        layout = (self.app / "app/layout.tsx").read_text()
        self.assertRegex(layout, r"<body>\s*(\{/\*[^*]*\*/\}\s*)?<FrameZoomGuard />")

    def test_the_404_is_titled_as_nexts_own(self) -> None:
        self.assert_ok(self.assemble())
        text = (self.app / "app/not-found.tsx").read_text()
        self.assertIn("export const metadata: Metadata = frameNotFoundMetadata", text)

    def test_one_url_in_both_trees_is_refused(self) -> None:
        self.write("site/routes/home/page.tsx", "export default function P() { return null }\n")
        self.write("site/app-routes/home/page.tsx", "export default function P() { return null }\n")
        self.assert_refused(self.assemble(), "'/home'", "site/routes/home/page.tsx", "site/app-routes/home/page.tsx")

    def test_an_app_route_at_the_frames_root_url_is_refused(self) -> None:
        self.write("site/app-routes/page.tsx", "export default function P() { return null }\n")
        self.assert_refused(self.assemble(), "'/'", "site/app-routes/page.tsx", "skeleton/app/(frame)/page.tsx")

    def test_a_page_and_a_route_handler_at_one_url_are_refused(self) -> None:
        self.write("site/routes/feed/page.tsx", "export default function P() { return null }\n")
        self.write("site/app-routes/feed/route.ts", "export function GET() { return new Response() }\n")
        self.assert_refused(self.assemble(), "'/feed'")

    def test_a_route_group_of_the_sites_own_maps_to_its_url(self) -> None:
        self.write("site/routes/(docs)/guide/page.tsx", "export default function P() { return null }\n")
        self.write("site/app-routes/guide/page.tsx", "export default function P() { return null }\n")
        self.assert_refused(self.assemble(), "'/guide'")

    def test_dynamic_segments_with_different_names_collide(self) -> None:
        # `[slug]` and `[id]` are one URL pattern to Next, which refuses two names for one segment.
        self.write("site/routes/blog/[slug]/page.tsx", "export default function P() { return null }\n")
        self.write("site/app-routes/blog/[id]/page.tsx", "export default function P() { return null }\n")
        self.assert_refused(
            self.assemble(), "site/routes/blog/[slug]/page.tsx", "site/app-routes/blog/[id]/page.tsx"
        )

    def test_catch_all_segments_with_different_names_collide(self) -> None:
        self.write("site/routes/docs/[...path]/page.tsx", "export default function P() { return null }\n")
        self.write("site/app-routes/docs/[...rest]/page.tsx", "export default function P() { return null }\n")
        self.assert_refused(self.assemble(), "site/routes/docs/[...path]/page.tsx")

    def test_a_dynamic_segment_beside_a_static_one_does_not_collide(self) -> None:
        self.write("site/routes/blog/[slug]/page.tsx", "export default function P() { return null }\n")
        self.write("site/app-routes/blog/new/page.tsx", "export default function P() { return null }\n")
        self.assert_ok(self.assemble())

    def test_app_route_css_naming_the_frame_is_refused(self) -> None:
        self.write("site/app-routes/home/home.css", "html:has(.x) { font-size: 100%; }\n")
        self.assert_refused(self.assemble(), "site/app-routes/home/home.css", "html")

    # --- rewrites and public env ---------------------------------------------------------------

    def test_no_rewrites_or_public_env_writes_an_empty_next_site(self) -> None:
        self.assert_ok(self.assemble())
        text = (self.app / "src/site/next.ts").read_text()
        self.assertIn("import type { FrameNextSite } from '@agenticdevelopertoolkit/site-template/next'", text)
        self.assertIn("export const nextSite: FrameNextSite = {", text)
        self.assertIn("rewrites: [],", text)
        self.assertIn("publicEnv: [],", text)
        self.assertIn("envDefaults: {},", text)
        config = (self.app / "next.config.ts").read_text()
        self.assertIn("import { frameNext } from '@agenticdevelopertoolkit/site-template/next'", config)
        self.assertIn("import { nextSite, transpilePackages } from './src/site/next'", config)

    def test_rewrites_public_env_and_defaults_reach_the_next_site(self) -> None:
        self.config.update(
            {
                "rewrites": [{"source": "/api/:path*", "destination": "${API_BACKEND_URL}/:path*"}],
                "publicEnv": ["NEXT_PUBLIC_AUTH_API_URL"],
                "envDefaults": {
                    "API_BACKEND_URL": {
                        "by": "DEPLOYMENT_ENV",
                        "values": {"production": "https://api.example"},
                        "local": "https://staging.api.example",
                    },
                    "NEXT_PUBLIC_AUTH_API_URL": "${API_BACKEND_URL}",
                },
            }
        )
        self.assert_ok(self.assemble())
        text = (self.app / "src/site/next.ts").read_text()
        self.assertIn('"destination": "${API_BACKEND_URL}/:path*"', text)
        self.assertIn('"NEXT_PUBLIC_AUTH_API_URL"', text)
        self.assertIn('"by": "DEPLOYMENT_ENV"', text)
        self.assertIn('"local": "https://staging.api.example"', text)

    def test_transpile_packages_follow_toolkit_dependencies_transitively(self) -> None:
        # The landing kit's HeroNav imports textlens: an app reaches it through landing's dist
        # without naming it, so it is compiled like every other toolkit package it reaches.
        self.assert_ok(self.assemble())
        block = (self.app / "src/site/next.ts").read_text().split("export const transpilePackages", 1)[1]
        self.assertIn('"@agenticdevelopertoolkit/textlens"', block)
        package = json.loads((self.app / "package.json").read_text())
        self.assertNotIn("@agenticdevelopertoolkit/textlens", package["dependencies"])

    def test_transpile_packages_list_every_toolkit_package(self) -> None:
        # The template's link deps, the toolkit packages the template itself depends on, and the
        # site's own toolkitPackages; never an npm package.
        self.config.update({"toolkitPackages": ["releases"], "dependencies": {"zod": "^3.0.0"}})
        self.assert_ok(self.assemble())
        text = (self.app / "src/site/next.ts").read_text()
        self.assertIn("export const transpilePackages: readonly string[] = [", text)
        block = text.split("export const transpilePackages", 1)[1]
        for name in (
            "@agenticdevelopertoolkit/landing",
            "@agenticdevelopertoolkit/site-template",
            "@agenticdevelopertoolkit/themes",
            "@agenticdevelopertoolkit/chrome",
            "@agentic-toolkit/bitbag",
            "@agenticdevelopertoolkit/releases",
        ):
            self.assertIn(f'"{name}"', block)
        for name in ("zod", "next", "react", "gsap"):
            self.assertNotIn(f'"{name}"', block)
        config = (self.app / "next.config.ts").read_text()
        self.assertIn("import { nextSite, transpilePackages } from './src/site/next'", config)
        self.assertIn("transpilePackages: [...transpilePackages],", config)

    def test_the_suite_hosts_are_allowed_dev_origins(self) -> None:
        self.assert_ok(self.assemble())
        config = (self.app / "next.config.ts").read_text()
        self.assertIn("allowedDevOrigins: ['*.dev.local', 'dev.local', '127.0.0.1'],", config)

    def test_a_malformed_substitution_is_refused(self) -> None:
        for destination in ("${api}/x", "${API/x", "${}/x", "${API:default}/x"):
            with self.subTest(destination=destination):
                self.config["rewrites"] = [{"source": "/a", "destination": destination}]
                self.assert_refused(self.assemble(), "rewrites[0].destination")

    def test_a_malformed_env_default_is_refused(self) -> None:
        self.config["envDefaults"] = {"X": "${bad}"}
        self.assert_refused(self.assemble(), "envDefaults.X")

    def test_a_public_env_name_that_is_not_an_env_name_is_refused(self) -> None:
        self.config["publicEnv"] = ["next-public-x"]
        self.assert_refused(self.assemble(), "publicEnv[0]")

    def test_an_optional_public_env_entry_is_accepted(self) -> None:
        self.config["publicEnv"] = ["NEXT_PUBLIC_A", "${NEXT_PUBLIC_B:-}"]
        self.assert_ok(self.assemble())
        self.assertIn('"${NEXT_PUBLIC_B:-}"', (self.app / "src/site/next.ts").read_text())

    def test_a_public_env_entry_with_a_default_is_refused(self) -> None:
        # The optional form is `${NAME:-}` alone: a value belongs in envDefaults, where every
        # other reference to the variable sees it too.
        for entry in ("${NEXT_PUBLIC_B:-x}", "${NEXT_PUBLIC_B}", "${next_public_b:-}"):
            with self.subTest(entry=entry):
                self.config["publicEnv"] = [entry]
                self.assert_refused(self.assemble(), "publicEnv[0]")

    def test_a_rewrite_needs_a_source_and_a_destination(self) -> None:
        self.config["rewrites"] = [{"source": "/a"}]
        self.assert_refused(self.assemble(), "rewrites[0]", "'destination'")

    # --- analytics ----------------------------------------------------------------------------

    def test_no_analytics_renders_nothing_and_adds_no_dependency(self) -> None:
        self.assert_ok(self.assemble())
        text = (self.app / "src/site/analytics.tsx").read_text()
        self.assertIn("export function SiteAnalytics(): ReactElement | null", text)
        self.assertNotIn("@vercel/", text)
        deps = json.loads((self.app / "package.json").read_text())["dependencies"]
        self.assertNotIn("@vercel/analytics", deps)
        self.assertNotIn("@vercel/speed-insights", deps)

    def test_analytics_mounts_vercels_two_in_production(self) -> None:
        self.config["analytics"] = True
        self.assert_ok(self.assemble())
        text = (self.app / "src/site/analytics.tsx").read_text()
        self.assertIn("import { Analytics } from '@vercel/analytics/next'", text)
        self.assertIn("import { SpeedInsights } from '@vercel/speed-insights/next'", text)
        self.assertIn("process.env.DEPLOYMENT_ENV === 'production'", text)
        deps = json.loads((self.app / "package.json").read_text())["dependencies"]
        self.assertEqual(deps["@vercel/analytics"], "^2.0.1")
        self.assertEqual(deps["@vercel/speed-insights"], "^2.0.0")

    def test_analytics_dependencies_are_the_templates_to_pin(self) -> None:
        self.config.update({"analytics": True, "dependencies": {"@vercel/analytics": "^1.0.0"}})
        self.assert_refused(self.assemble(), "'@vercel/analytics'")

    def test_analytics_must_be_a_boolean(self) -> None:
        self.config["analytics"] = "yes"
        self.assert_refused(self.assemble(), "analytics")

    # --- font formats -------------------------------------------------------------------------

    def test_a_ttf_otf_and_woff_font_are_accepted_and_copied(self) -> None:
        self.config["fonts"] = [
            {
                "variable": "--font-grotesk",
                "files": [
                    {"path": "fonts/Grotesk-Variable.ttf", "weight": "300 700", "style": "normal"},
                    {"path": "fonts/grotesk-italic.otf", "weight": "400", "style": "italic"},
                    {"path": "fonts/grotesk-old.woff", "weight": "400", "style": "normal"},
                ],
            }
        ]
        for name in ("Grotesk-Variable.ttf", "grotesk-italic.otf", "grotesk-old.woff"):
            self.write(f"site/fonts/{name}", name)
        self.assert_ok(self.assemble())
        fonts = (self.app / "src/site/fonts.ts").read_text()
        for name in ("Grotesk-Variable.ttf", "grotesk-italic.otf", "grotesk-old.woff"):
            self.assertTrue((self.app / "src/fonts" / name).is_file(), name)
            self.assertIn(f'"../fonts/{name}"', fonts)

    def test_a_font_in_another_format_is_refused(self) -> None:
        self.config["fonts"] = [
            {"variable": "--font-x", "files": [{"path": "fonts/x.eot", "weight": "400", "style": "normal"}]}
        ]
        self.write("site/fonts/x.eot", "eot")
        self.assert_refused(self.assemble(), "fonts[0].files[0].path")


def load_assembler():  # type: ignore[no-untyped-def]
    import importlib.util

    spec = importlib.util.spec_from_file_location("assemble_site", ASSEMBLE)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


if __name__ == "__main__":
    unittest.main()
