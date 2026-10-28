#!/usr/bin/env python3
"""Assemble a content site's Next app from the template skeleton, the site's `site/` folder and
the content content-buildr generated.

    python3 <toolkit>/packages/web/packages/site-template/tools/assemble_site.py --site <repo> [--check]

A site repo holds only `site/` — `site.json`, custom components and routes, the code they need,
its public assets and a token sheet — and the app `site.json`'s `output` names. This script
writes that app:

    skeleton/**            -> <output>/**   (verbatim; skeleton/package.json is the base below)
    site/components/**     -> src/components/**
    site/routes/**         -> app/(frame)/**   (inside the frame: its bar, drawer, footer, bitbag)
    site/app-routes/**     -> app/**           (bare: each brings its own layout and providers)
    site/src/**            -> src/**
    site/public/**         -> public/**
    site/app-root/**       -> the app root
    generated              -> src/site/{config.ts,slots.tsx,fonts.ts,shot.tsx,next.ts,analytics.tsx},
                              src/fonts/*, app/theme.css, package.json, .site-template.json

`(frame)` is a route group, so both trees serve the same URLs they would at `app/`; two files
that would serve one URL, in either tree or the skeleton, are refused.

It never writes or deletes `src/content/**`, `src/landing.json`, `src/landing.tsx` or
`public/glyph.svg`, which content-buildr owns. `.site-template.json` lists every path it wrote,
so a re-run deletes what it no longer produces and `--check` can name it.

Exit 0: written, or (`--check`) up to date. Exit 1: `--check` found differences, one path per
line on stdout. Exit 2: the inputs are invalid, one problem per line on stderr. Exit 3: the
template's own schema uses a keyword the checker does not implement (the template's bug).

The toolkit is found from this file's own location, so the template a site is assembled from is
whichever toolkit copy runs the script. Stdlib only. The file is `assemble_site.py` rather than
`assemble.py` because the repo's abstractr hook refuses a name another shared tier exports.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path, PurePosixPath

PACKAGE = Path(__file__).resolve().parent.parent
SKELETON = PACKAGE / "skeleton"
SCHEMA = PACKAGE / "schema" / "site.schema.json"
THEMES = PACKAGE / "themes.json"
MANIFEST = ".site-template.json"

# Where a site repo mounts the toolkit. `link:` dependencies point here, relative to the app dir.
SITE_TOOLKIT = Path("websites/external/agenticdevelopertoolkit/packages/web/packages")

# The landing kit's sheets the frame needs, in the order the kit's own consumers load them, then
# the template's: the bridge (theme tokens -> `--lp-*`) before the frame, which owns the rest.
# bitbag's dock sheet is not here: `SiteBitbag` imports it itself.
KIT_SHEETS = [
    "@agenticdevelopertoolkit/landing/css/base.css",
    "@agenticdevelopertoolkit/landing/css/chrome.css",
    "@agenticdevelopertoolkit/landing/css/blocks.css",
    "@agenticdevelopertoolkit/landing/css/flow.css",
]
# The document reset, first: tailwind's preflight, which the kit's sheets were drawn against
# (every site before the template imported all of tailwind). Preflight alone — not
# `tailwindcss`, whose theme variables and utility generation the frame never uses, and which
# would set every site scanning its sources for class names. It is imported into `@layer base`,
# so the unlayered theme, kit and frame rules all outrank it. The skeleton's package.json and
# postcss config carry tailwind, which resolves the sheet and its `--theme()` fallbacks.
RESET_IMPORT = '@import "tailwindcss/preflight.css" layer(base);\n'
FRAME_SHEETS = [
    "@agenticdevelopertoolkit/site-template/css/bridge.css",
    "@agenticdevelopertoolkit/site-template/css/frame.css",
]

# Where each site folder lands in the app.
SITE_TREES = [
    ("components", "src/components"),
    ("routes", "app/(frame)"),
    ("app-routes", "app"),
    ("src", "src"),
    ("public", "public"),
    ("app-root", ""),
]
# The folders whose CSS is part of a page's styles, and so is checked for frame names. CSS under
# public/ and app-root/ is a static asset served as-is.
STYLED_TREES = ("components", "routes", "app-routes", "src")

# The files that make a URL in the App Router: a page and a route handler cannot share one.
ROUTE_FILE = re.compile(r"^(page|route)\.(tsx|ts|jsx|js|mdx)$")

# `analytics: true` mounts these in the root layout; the template pins their ranges.
ANALYTICS_DEPS = {"@vercel/analytics": "^2.0.1", "@vercel/speed-insights": "^2.0.0"}

# content-buildr's outputs: never written, never deleted.
PROTECTED_DIRS = ("src/content/",)
PROTECTED_FILES = ("src/landing.json", "src/landing.tsx", "public/glyph.svg")

# No `mark` in site.json: content-buildr's glyph, which it writes to public/glyph.svg.
DEFAULT_MARK = {"src": "/glyph.svg", "shape": "glyph"}

IGNORED_NAMES = {".DS_Store", "__pycache__"}

HEADER = "// GENERATED by @agenticdevelopertoolkit/site-template's assembler from site/site.json — do not edit."

# `src/site/shot.tsx`: the same for every site, since the word is read from the copy at build.
SHOT_TS = (
    "// GENERATED by @agenticdevelopertoolkit/site-template's assembler — do not edit.\n"
    "import { frameShot } from '@agenticdevelopertoolkit/site-template'\n"
    "import type { FrameCopy } from '@agenticdevelopertoolkit/site-template'\n"
    "import siteCopy from '../content/site/site.json'\n\n"
    "// Typed for the reason the layout gives.\n"
    "const copy: FrameCopy = siteCopy\n\n"
    "/** The landing kit's `Shot`, worded with the copy's `screenshotPending` unless one shot says otherwise. */\n"
    "export const SiteShot = frameShot(copy.screenshotPending)\n"
)

# `src/site/analytics.tsx`, which the root layout always renders: nothing, or Vercel's two.
ANALYTICS_OFF = (
    f"{HEADER}\n"
    "import type { ReactElement } from 'react'\n\n"
    "/** No analytics: site.json does not set `analytics`. */\n"
    "export function SiteAnalytics(): ReactElement | null {\n"
    "  return null\n"
    "}\n"
)
ANALYTICS_ON = (
    f"{HEADER}\n"
    "import type { ReactElement } from 'react'\n"
    "import { Analytics } from '@vercel/analytics/next'\n"
    "import { SpeedInsights } from '@vercel/speed-insights/next'\n\n"
    "/**\n"
    " * Vercel Web Analytics and Speed Insights, on production deploys only. `DEPLOYMENT_ENV`, not\n"
    " * Vercel's own label: every tier's project makes `VERCEL_ENV=production` deployments.\n"
    " */\n"
    "export function SiteAnalytics(): ReactElement | null {\n"
    "  return process.env.DEPLOYMENT_ENV === 'production' ? (\n"
    "    <>\n"
    "      <Analytics />\n"
    "      <SpeedInsights />\n"
    "    </>\n"
    "  ) : null\n"
    "}\n"
)


class Refused(Exception):
    """The inputs are invalid. Carries every problem found, one line each."""

    def __init__(self, problems: list[str]) -> None:
        super().__init__("\n".join(problems))
        self.problems = problems


def find_toolkit_web() -> Path:
    """The toolkit's `packages/web/`: the nearest ancestor of this file that is that workspace."""
    for parent in Path(__file__).resolve().parents:
        if (parent / "pnpm-workspace.yaml").is_file() and (parent / "packages" / "site-template").is_dir():
            return parent
    raise SystemExit(f"assemble: cannot find the toolkit's packages/web/ above {Path(__file__).resolve()}")


# --- site.json against the schema -------------------------------------------------------------

_TYPES = {
    "object": lambda v: isinstance(v, dict),
    "array": lambda v: isinstance(v, list),
    "string": lambda v: isinstance(v, str),
    "integer": lambda v: isinstance(v, int) and not isinstance(v, bool),
    "number": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
    "boolean": lambda v: isinstance(v, bool),
}

# Every keyword `check_schema` enforces, plus the annotations it may ignore. Anything else in the
# schema is a keyword it would silently skip, so it stops rather than pass what it never checked.
_KEYWORDS = {
    "type", "enum", "anyOf", "required", "properties", "propertyNames", "additionalProperties",
    "items", "minItems", "pattern", "minimum", "maximum",
    "default", "description", "title", "$schema", "$id",
}  # fmt: skip


class SchemaError(Exception):
    """The schema uses something `check_schema` does not implement: the template's bug, not the site's."""


def check_schema(value: object, schema: dict, where: str, problems: list[str]) -> None:
    """A hand-written checker for the subset of JSON Schema `site.schema.json` uses. A closed
    object (`additionalProperties: false`) refuses every key the schema does not list. A keyword
    or type outside that subset raises `SchemaError`."""
    unknown = set(schema) - _KEYWORDS
    unknown |= {f"propertyNames.{k}" for k in set(schema.get("propertyNames", {})) - {"pattern"}}
    if "type" in schema and schema["type"] not in _TYPES:
        unknown.add(f"type {schema['type']!r}")
    if unknown:
        raise SchemaError(f"site.schema.json at {where or '(root)'}: unsupported {', '.join(sorted(unknown))}")
    label = f"site/site.json: {where}" if where else "site/site.json"
    if "anyOf" in schema:
        # Passes if any branch passes; otherwise report the branch that got furthest (fewest problems).
        attempts = []
        for branch in schema["anyOf"]:
            found: list[str] = []
            check_schema(value, branch, where, found)
            if not found:
                return
            attempts.append(found)
        problems.extend(min(attempts, key=len))
        return
    if "enum" in schema and value not in schema["enum"]:
        allowed = ", ".join(repr(v) for v in schema["enum"])
        problems.append(f"{label}: {value!r} is not one of {allowed}")
        return
    kind = schema.get("type")
    if kind is not None and not _TYPES[kind](value):
        problems.append(f"{label}: expected {kind}, found {json.dumps(value)}")
        return
    if isinstance(value, dict):
        props = schema.get("properties", {})
        for key in schema.get("required", []):
            if key not in value:
                problems.append(f"{label}: '{key}' is required")
        names = schema.get("propertyNames", {}).get("pattern")
        extra = schema.get("additionalProperties", True)
        for key, item in value.items():
            inner = f"{where}.{key}" if where else key
            if key in props:
                check_schema(item, props[key], inner, problems)
            elif extra is False or (names is not None and not re.search(names, key)):
                problems.append(f"{label}: unknown key '{key}'")
            elif isinstance(extra, dict):
                check_schema(item, extra, inner, problems)
    elif isinstance(value, list):
        if len(value) < schema.get("minItems", 0):
            problems.append(f"{label}: needs at least {schema['minItems']} item(s)")
        for i, item in enumerate(value):
            if "items" in schema:
                check_schema(item, schema["items"], f"{where}[{i}]", problems)
    elif isinstance(value, str):
        if "pattern" in schema and not re.search(schema["pattern"], value):
            problems.append(f"{label}: {value!r} does not match {schema['pattern']}")
    elif isinstance(value, (int, float)) and not isinstance(value, bool):
        if value < schema.get("minimum", value) or value > schema.get("maximum", value):
            problems.append(f"{label}: {value} is out of range")


# --- paths --------------------------------------------------------------------------------------


def safe_rel(entry: object) -> str | None:
    """`entry` as a plain relative POSIX path, or None: not a string, empty, absolute, or with an
    empty, `.` or `..` segment (`./a`, `a//b`, `a/../b`), which no path the assembler writes has."""
    if not isinstance(entry, str) or not entry or entry.startswith("/") or "\\" in entry:
        return None
    if any(part in ("", ".", "..") for part in entry.split("/")):
        return None
    return PurePosixPath(entry).as_posix()


def is_protected(rel: str) -> bool:
    """A content-buildr path. Case-folded, because the Mac's filesystem is case-insensitive and
    `src/Landing.tsx` there is `src/landing.tsx`."""
    folded = rel.casefold()
    dirs = tuple(d.casefold() for d in PROTECTED_DIRS)
    return folded.startswith(dirs) or folded + "/" in dirs or folded in {f.casefold() for f in PROTECTED_FILES}


def inside(root: Path, rel: str) -> bool:
    """Whether `root/rel`, symlinks resolved, is still under `root`."""
    real = root.resolve()
    return real in (root / rel).resolve().parents


# --- CSS ----------------------------------------------------------------------------------------


def strip_comments(css: str) -> str:
    """`css` with every comment replaced by a space. String-aware: `"/*"` inside a string opens
    nothing, so it cannot hide the rules up to a later `"*/"`."""
    out: list[str] = []
    i = 0
    while i < len(css):
        if css[i] == "\\":
            out.append(css[i : i + 2])
            i += 2
        elif css[i] in "\"'":
            end = _skip_string(css, i)
            out.append(css[i:end])
            i = end
        elif css.startswith("/*", i):
            close = css.find("*/", i + 2)
            i = len(css) if close < 0 else close + 2
            out.append(" ")
        else:
            out.append(css[i])
            i += 1
    return "".join(out)


_ESCAPE = re.compile(r"\\(?:([0-9a-fA-F]{1,6})[ \t\n\r\f]?|(.))", re.S)


def unescape(text: str) -> str:
    """CSS escapes resolved: `.\\6c p-band` is `.lp-band`, `.l\\p-band` is too."""

    def one(match: re.Match[str]) -> str:
        if match.group(2) is not None:
            return match.group(2)
        code = int(match.group(1), 16)
        return chr(code) if 0 < code <= 0x10FFFF and not 0xD800 <= code <= 0xDFFF else "�"

    return _ESCAPE.sub(one, text)


class CssError(Exception):
    """CSS the assembler will not guess at."""


def _skip_string(css: str, i: int) -> int:
    """`css[i]` opens a string; return the index just past its close. A raw newline before the
    close is a broken string, which a browser recovers from by dropping the declaration — a
    recovery this scanner does not emulate, so it is refused instead."""
    quote = css[i]
    i += 1
    while i < len(css) and css[i] != quote:
        if css[i] in "\n\r\f":
            raise CssError("unterminated string (a raw newline before its closing quote)")
        i += 2 if css[i] == "\\" else 1
    return i + 1


def top_level(css: str) -> list[tuple[str, str | None]]:
    """Split comment-free CSS into its top-level items: `(prelude, body)` for a block and
    `(text, None)` for a `;`-terminated statement or declaration. Strings and parentheses are
    honoured, so a `;` or `{` inside `url(...)` or quotes splits nothing."""
    items: list[tuple[str, str | None]] = []
    start = i = 0
    parens = 0
    while i < len(css):
        ch = css[i]
        if ch == "\\":
            i += 2
            continue
        if ch in "\"'":
            i = _skip_string(css, i)
            continue
        if ch == "(":
            parens += 1
        elif ch == ")":
            parens = max(0, parens - 1)
        elif ch == ";" and parens == 0:
            items.append((css[start:i].strip(), None))
            start = i + 1
        elif ch == "{" and parens == 0:
            depth, j = 1, i + 1
            while j < len(css) and depth:
                if css[j] == "\\":
                    j += 2
                    continue
                if css[j] in "\"'":
                    j = _skip_string(css, j)
                    continue
                depth += {"{": 1, "}": -1}.get(css[j], 0)
                j += 1
            items.append((css[start:i].strip(), css[i + 1 : j - 1]))
            start = i = j
            continue
        i += 1
    if css[start:].strip():
        items.append((css[start:].strip(), None))
    return [(prelude, body) for prelude, body in items if prelude or body is not None]


def short(text: str) -> str:
    text = " ".join(text.split())
    return text if len(text) <= 60 else text[:57] + "..."


def check_token_sheet(css: str, label: str) -> list[str]:
    """A token sheet is custom-property declarations inside `:root { }` and nothing else, which
    is what keeps a site from restyling the frame."""
    problems = []
    try:
        items = top_level(strip_comments(css))
    except CssError as error:
        return [f"{label}: {error}"]
    for prelude, body in items:
        if prelude != ":root" or body is None:
            problems.append(f"{label}: only custom properties inside ':root {{ }}' are allowed; found '{short(prelude)}'")
            continue
        for decl, inner in top_level(body):
            if inner is not None:
                problems.append(f"{label}: ':root' may not nest a rule; found '{short(decl)}'")
            elif not re.match(r"--[\w-]+\s*:", decl):
                prop = decl.split(":", 1)[0].strip()
                problems.append(f"{label}: ':root' declares '{short(prop)}', which is not a custom property")
    return problems


# What a site's own CSS may not name in a selector: the landing kit's and the template's classes
# (class names are case-sensitive), and the document roots the frame styles — `html`, `body` and
# `:root`, which is `html` — matched case-insensitively, as browsers do.
_FRAME_CLASS = re.compile(r"\.(?:lp|st)-[\w-]*")
_FRAME_ROOT = re.compile(r"(?<![\w.#:-])(?:html|body)(?![\w-])|:root(?![\w-])", re.I)
# An attribute selector, with its optional namespace (`*|`, `|` or `svg|`); the lookahead keeps
# `[class|=x]`'s `|=` an operator rather than a namespace bar.
_ATTRIBUTE = re.compile(r"\[\s*(?:(?:\*|[\w-]+)?\|(?!=))?([\w-]+)\s*(?:([~|^$*]?=)\s*(\"[^\"]*\"|'[^']*'|[^\s\]]+))?\s*(?:[iIsS]\s*)?\]")
_FRAME_PREFIXES = ("lp-", "st-")
# At-rules whose block holds rules; every other block at-rule (@keyframes, @font-face, …) holds
# no selector worth checking.
_GROUPING = {"media", "supports", "container", "layer", "scope", "starting-style", "document"}


def class_attribute_names(selector: str) -> list[str]:
    """The values of `[class…]` attribute selectors that can match a frame class:
    `[class*="lp-band"]`, `[class^=st-]`, and a fragment of the prefix itself (`[class^="l"]`)."""
    found = []
    for name, op, raw in _ATTRIBUTE.findall(selector):
        value = raw.strip("\"'").casefold()
        if name.casefold() != "class" or not value:
            continue
        names_prefix = any(p in value for p in _FRAME_PREFIXES)
        fragment = (op == "*=" and any(value in p for p in _FRAME_PREFIXES)) or (
            op in ("^=", "|=") and any(p.startswith(value) for p in _FRAME_PREFIXES)
        )
        if names_prefix or fragment:
            found.append(raw.strip("\"'"))
    return found


def selector_frame_names(selector: str) -> list[str]:
    """Every frame name a selector (or an `@scope` prelude) names, escapes resolved."""
    plain = unescape(selector)
    names = class_attribute_names(plain)
    bare = re.sub(r"\"[^\"]*\"|'[^']*'", "", _ATTRIBUTE.sub("", plain))
    names += [m.group(0) for m in _FRAME_CLASS.finditer(bare)]
    names += [m.group(0).casefold() for m in _FRAME_ROOT.finditer(bare)]
    return names


def frame_names(css: str) -> list[tuple[str, str]]:
    """Every `(selector, name)` in comment-free CSS that names the frame, nested rules included."""
    found = []
    for prelude, body in top_level(css):
        if body is None:
            continue
        if prelude.startswith("@"):
            at_rule = re.match(r"@([\w-]*)", prelude)
            keyword = at_rule.group(1).casefold() if at_rule is not None else ""
            if keyword == "scope":
                found += [(prelude, name) for name in selector_frame_names(prelude[len("@scope") :])]
            if keyword in _GROUPING:
                found += frame_names(body)
            continue
        found += [(prelude, name) for name in selector_frame_names(prelude)]
        found += frame_names(body)
    return found


def check_site_css(css: str, label: str) -> list[str]:
    try:
        found = frame_names(strip_comments(css))
    except CssError as error:
        return [f"{label}: {error}"]
    return [f"{label}: the selector '{short(selector)}' names '{name}', which belongs to the frame" for selector, name in found]


# --- the plan: every path the assembler writes, and its bytes ----------------------------------


class AppPlan:
    def __init__(self) -> None:
        self.files: dict[str, bytes] = {}
        # Who claimed each path, keyed case-folded: on the Mac's case-insensitive filesystem
        # `App/Page.tsx` and `app/page.tsx` are one file. The manifest is written last, from the
        # finished plan, but its path is claimed now.
        self.owner: dict[str, str] = {MANIFEST.casefold(): "the template's manifest"}
        self.problems: list[str] = []

    def add(self, target: str, data: bytes, owner: str, from_site: bool = False) -> None:
        """Claim `target` for `owner`. A site file may not land on content-buildr's paths, and
        nothing may land on a path something else already claimed, in any case."""
        if from_site and is_protected(target):
            self.problems.append(f"{owner} would land on {target}, which content-buildr owns")
            return
        other = self.owner.get(target.casefold())
        if other is not None:
            who = f"{other} also lands there" if other.startswith("site/") else "the template writes"
            self.problems.append(f"{owner} would land on {target}, which {who}")
            return
        self.files[target] = data
        self.owner[target.casefold()] = owner


def tree_files(root: Path) -> list[Path]:
    if not root.is_dir():
        return []
    return sorted(
        p for p in root.rglob("*") if p.is_file() and not IGNORED_NAMES.intersection(p.relative_to(root).parts)
    )


def ts(value: object) -> str:
    """A JSON value as a TypeScript literal, its continuation lines indented to sit in an object."""
    return json.dumps(value, indent=2, ensure_ascii=False).replace("\n", "\n  ")


def section_ids(app: Path) -> tuple[list[str], list[str], list[str]]:
    """The landing page's section ids, and the ids of those content-buildr marks `slot: true`
    (`## Label {slot}`, a band whose body the site renders), from `src/landing.json`. No file
    yet (a site whose page has only a hero, or one never generated) is no sections."""
    path = app / "src" / "landing.json"
    if not path.is_file():
        return [], [], []
    try:
        sections = json.loads(path.read_text()).get("sections", [])
        ids = [section["id"] for section in sections]
        return ids, [section["id"] for section in sections if section.get("slot") is True], []
    except (ValueError, KeyError, TypeError, AttributeError) as error:
        return [], [], [f"{path}: cannot read the section ids ({error})"]


def drawer_problems(app: Path, drawer: list[dict]) -> list[str]:
    """A drawer row whose label the copy does not word, refused before a build as SiteChrome
    refuses it at render. The copy is content-buildr's `src/content/site/site.json`; with none
    yet there is nothing to check against, and the render still refuses."""
    path = app / "src" / "content" / "site" / "site.json"
    if not drawer or not path.is_file():
        return []
    try:
        worded = json.loads(path.read_text()).get("nav", {}).get("extra", {})
    except (ValueError, AttributeError) as error:
        return [f"{path}: cannot read the copy's nav ({error})"]
    known = ", ".join(f"'{key}'" for key in worded) or "(none)"
    return [
        f"site/site.json: drawer[{i}]: nav '{row['nav']}' is not worded in the copy's nav.extra "
        f"(site.md's `# nav`, `## extra`); it words: {known}"
        for i, row in enumerate(drawer)
        if row["nav"] not in worded
    ]


def plan_slots(site: Path, slots: dict[str, str], ids: list[str], slotted: list[str]) -> tuple[str, list[str]]:
    """`src/site/slots.tsx`: one import per slot component, and the `SlotMap` that places it.

    A `{slot}` section has no blocks of its own, so one no `band:<id>` fills would be a band
    holding only its eyebrow: refused here, where the slots are known, as content-buildr
    refuses an empty section where they are not."""
    problems: list[str] = [
        f"site/site.json: slots: section '{band}' is a {{slot}} band in the landing markdown, "
        f"but no 'band:{band}' slot fills it"
        for band in slotted
        if f"band:{band}" not in slots
    ]
    imports: list[str] = []
    places: list[str] = []
    bands: list[str] = []
    components = (site / "site" / "components").resolve()
    order = ["hero", "afterHero", "footer", "bitbag"] + [key for key in slots if key.startswith("band:")]
    for n, key in enumerate(key for key in order if key in slots):
        file, name = slots[key].split("#")
        source = (components / file).resolve()
        if components not in source.parents or not source.is_file():
            problems.append(f"site/site.json: slots.{key}: no file site/components/{file}")
            continue
        if key.startswith("band:"):
            band = key[len("band:") :]
            if band not in ids:
                known = ", ".join(f"'{i}'" for i in ids) or "(none)"
                problems.append(f"site/site.json: slots: 'band:{band}' names no section '{band}'; the sections are: {known}")
                continue
            alias = f"BandSlot{n}"
            bands.append(f"    {json.dumps(band)}: {alias},")
        else:
            alias = key[0].upper() + key[1:] + "Slot"
            places.append(f"  {key}: {alias},")
        module = re.sub(r"\.tsx?$", "", file)
        imports.append(f"import {{ {name} as {alias} }} from '../components/{module}'\n")
    body = places + (["  bands: {", *bands, "  },"] if bands else ["  bands: {},"])
    text = (
        f"{HEADER}\n"
        "import type { SlotMap } from '@agenticdevelopertoolkit/site-template'\n"
        + "".join(imports)
        + "\nexport const slots: SlotMap = {\n"
        + "".join(f"{line}\n" for line in body)
        + "}\n"
    )
    return text, problems


def font_identifier(variable: str) -> str:
    """`--font-iosevka` -> `fontIosevka`."""
    head, *rest = variable.lstrip("-").split("-")
    return head + "".join(part[:1].upper() + part[1:] for part in rest)


def font_call(name: str, entries: list[str], variable: str, family: str | None, lazy: bool) -> str:
    """One `localFont` call. `family` names the @font-face family outright, so two calls — the
    preloaded faces and the rest — make one family; next/font hashes each call's apart otherwise.
    The lazy call adds no fallback face of its own: the eager call's is the family's."""
    options = [f"  variable: {json.dumps(variable)},\n", "  display: 'swap',\n"]
    if family is not None:
        quoted = json.dumps("'" + family + "'")
        options.append(f"  declarations: [{{ prop: 'font-family', value: {quoted} }}],\n")
    if lazy:
        options += ["  preload: false,\n", "  adjustFontFallback: false,\n"]
    return f"const {name} = localFont({{\n  src: [\n{''.join(entries)}  ],\n{''.join(options)}}})\n"


def plan_fonts(plan: AppPlan, fonts: list[tuple[dict, Path, str]]) -> str:
    """`src/site/fonts.ts`: one static `localFont` call per family — `next/font/local` must be
    called with literals at module scope — with every font file copied into `src/fonts/`.
    next/font preloads per call, not per file, so a family with a face marked `preload: false`
    is two calls naming one family: the preloaded faces, then the rest."""
    calls: list[str] = []
    names: list[str] = []
    seen: dict[str, str] = {}
    for font, base, label in fonts:
        variable = font["variable"]
        name = font_identifier(variable)
        if name in seen:
            plan.problems.append(f"{label}: the font variable '{variable}' is already declared by {seen[name]}")
            continue
        seen[name] = label
        entries: list[str] = []
        lazy_entries: list[str] = []
        for spec in font["files"]:
            source = base / spec["path"]
            if not inside(base, spec["path"]):
                where = "site/" if label.startswith("site/") else "the toolkit's packages/web/"
                plan.problems.append(f"{label}: font file {spec['path']} is outside {where}")
                continue
            if not source.is_file():
                plan.problems.append(f"{label}: font file {spec['path']} does not exist")
                continue
            target = f"src/fonts/{source.name}"
            # Case-folded, like every claim: `X.woff2` and `x.woff2` are one file on the Mac.
            same = next((k for k in plan.files if k.casefold() == target.casefold()), None)
            if same is not None:
                if plan.files[same] != source.read_bytes():
                    plan.problems.append(f"{label}: font file {source.name} clashes with another font file of that name")
                    continue
                target = same
            plan.files[target] = source.read_bytes()
            plan.owner.setdefault(target.casefold(), label)
            (entries if spec.get("preload", True) else lazy_entries).append(
                f"    {{ path: {json.dumps('../fonts/' + source.name)}, "
                f"weight: {json.dumps(spec['weight'])}, style: {json.dumps(spec['style'])} }},\n"
            )
        if not lazy_entries:
            calls.append(font_call(name, entries, variable, None, lazy=False))
            names.append(f"{name}.variable")
            continue
        if not entries:
            if not any(spec.get("preload", True) for spec in font["files"]):
                plan.problems.append(
                    f"{label}: every face of '{variable}' is preload: false; at least one must preload "
                    "(its call carries the family's variable)"
                )
            continue
        family = f"site-{variable.lstrip('-')}"
        calls.append(font_call(name, entries, variable, family, lazy=False))
        # Its class goes on <html> too: the variable is unused, but the call's @font-face rules
        # then ride in on the same import as the eager call's.
        calls.append(font_call(f"{name}Lazy", lazy_entries, f"{variable}-lazy", family, lazy=True))
        names += [f"{name}.variable", f"{name}Lazy.variable"]
    if not calls:
        return f"{HEADER}\n\n/** No fonts: neither the theme nor the site names one. */\nexport const fontVariables: string = ''\n"
    return (
        f"{HEADER}\nimport localFont from 'next/font/local'\n\n"
        + "\n".join(calls)
        + "\n/** Every family's CSS variable, as the class list for `<html>`. */\n"
        + f"export const fontVariables: string = [{', '.join(names)}].join(' ')\n"
    )


def plan_font_roles(fonts: list[tuple[dict, Path, str]], problems: list[str]) -> str:
    """The `html:root` rule that points each font's theme `role` at its self-hosted face. next/font
    hashes the family name, so a theme sheet that names the family (`'Iosevka'`) never finds it;
    the face is reachable only through its variable. Written after the theme and frame sheets so
    it wins over the theme's own value, and before the site's tokens so a site can still override."""
    lines: list[str] = []
    seen: dict[str, str] = {}
    for font, _base, label in fonts:
        roles = font.get("role", [])
        fallback = font.get("fallback")
        stack = f"var({font['variable']})" + (f", {fallback}" if fallback else "")
        # One role or several: a family can fill every property a theme names it in.
        for role in [roles] if isinstance(roles, str) else roles:
            if role in seen:
                problems.append(f"{label}: the role '{role}' is already filled by {seen[role]}")
                continue
            seen[role] = label
            lines.append(f"  {role}: {stack};\n")
    if not lines:
        return ""
    return (
        "\n/* The fonts' roles: each theme property, pointed at its self-hosted face. */\n"
        + f"{RAISED_ROOT} {{\n"
        + "".join(lines)
        + "}\n"
    )


# A theme declares its dark default on `html:root` (0,1,1), which outranks a plain `:root`
# (0,1,0) wherever it stands. The font roles and the site's tokens are written at the theme's
# own specificity, after it, so source order decides — the order theme.css's header promises.
RAISED_ROOT = "html:root"


def raise_roots(css: str) -> str:
    """A token sheet with each top-level `:root` prelude written as `html:root`. Comments and
    strings are copied as they are; `check_token_sheet` has already refused anything at the top
    level but `:root { }` blocks, so every `:root` outside a block is a prelude."""
    out: list[str] = []
    depth = i = 0
    while i < len(css):
        if css[i] == "\\":
            out.append(css[i : i + 2])
            i += 2
        elif css[i] in "\"'":
            end = _skip_string(css, i)
            out.append(css[i:end])
            i = end
        elif css.startswith("/*", i):
            close = css.find("*/", i + 2)
            end = len(css) if close < 0 else close + 2
            out.append(css[i:end])
            i = end
        elif depth == 0 and css.startswith(":root", i):
            out.append(RAISED_ROOT)
            i += len(":root")
        else:
            depth += {"{": 1, "}": -1}.get(css[i], 0)
            out.append(css[i])
            i += 1
    return "".join(out)


def plan_package(base: dict, config: dict, site: Path, app: Path, web: Path, problems: list[str]) -> bytes:
    """`package.json`: the skeleton's base with its `link:` paths rewritten for this app, the dev
    port, the analytics packages when `analytics` is set, and the site's extra npm dependencies
    and toolkit packages."""

    def link(package_dir: str) -> str:
        return "link:" + Path(os.path.relpath(site / SITE_TOOLKIT / package_dir, app)).as_posix()

    pkg = {"name": Path(config["output"]).name, **{k: v for k, v in base.items() if k != "//"}}
    pkg["scripts"] = {**pkg["scripts"], "dev": f"next dev -p {config['port']}"}
    deps = {
        name: link(spec[len("link:") :]) if spec.startswith("link:") else spec
        for name, spec in pkg["dependencies"].items()
    }
    if config.get("analytics", False):
        deps.update(ANALYTICS_DEPS)
    template_deps = set(deps) | set(pkg.get("devDependencies", {}))
    for name, spec in config.get("dependencies", {}).items():
        if name in template_deps:
            problems.append(f"site/site.json: dependencies: '{name}' is a template dependency, which the template pins")
        else:
            deps[name] = spec
    for package_dir in config.get("toolkitPackages", []):
        manifest = web / "packages" / package_dir / "package.json"
        if not manifest.is_file():
            problems.append(f"site/site.json: toolkitPackages: '{package_dir}' is not a package under {web / 'packages'}")
            continue
        name = json.loads(manifest.read_text())["name"]
        if name in deps or name in template_deps:
            problems.append(f"site/site.json: toolkitPackages: '{package_dir}' ({name}) is already a dependency")
            continue
        deps[name] = link(package_dir)
    pkg["dependencies"] = dict(sorted(deps.items()))
    return (json.dumps(pkg, indent=2) + "\n").encode()


def workspace_manifests(web: Path) -> dict[str, dict]:
    """Every toolkit package's manifest under `web/packages`, by package name."""
    manifests = {}
    for manifest in sorted((web / "packages").glob("*/package.json")):
        data = json.loads(manifest.read_text())
        manifests[data["name"]] = data
    return manifests


def toolkit_packages(package_json: bytes, web: Path) -> list[str]:
    """The toolkit packages an app reaches: its own `link:` dependencies — the template's, the
    site's `toolkitPackages` — and, transitively, every toolkit package one of those depends on
    (`workspace:`), which the app reaches only through that package's dist — the template's own,
    the landing kit's textlens. Sorted, so the generated file is stable."""
    app_deps = json.loads(package_json)["dependencies"]
    manifests = workspace_manifests(web)
    names: set[str] = set()
    pending = [name for name, spec in app_deps.items() if spec.startswith("link:")]
    pending.append(json.loads((PACKAGE / "package.json").read_text())["name"])
    while pending:
        name = pending.pop()
        if name in names:
            continue
        names.add(name)
        deps = manifests.get(name, {}).get("dependencies", {})
        pending.extend(dep for dep, spec in deps.items() if spec.startswith("workspace:"))
    return sorted(names)


def route_url(rel: str) -> str | None:
    """The URL an `app/**` page or route handler serves, or None for any other file. Route groups
    (`(frame)`) and parallel-route slots (`@x`) add no segment; a private folder (`_x`) is no route."""
    parts = rel.split("/")
    if parts[0] != "app" or not ROUTE_FILE.match(parts[-1]):
        return None
    segments = parts[1:-1]
    if any(segment.startswith("_") for segment in segments):
        return None
    kept = [s for s in segments if not (s.startswith("(") and s.endswith(")")) and not s.startswith("@")]
    return "/" + "/".join(kept)


DYNAMIC_SEGMENT = re.compile(r"^(\[\[\.\.\.|\[\.\.\.|\[)[^\]]*(\]\]|\])$")


def url_pattern(url: str) -> str:
    """`url` as Next matches it: a dynamic segment's name is the page's to choose and no part of
    the match, so `[slug]` and `[id]` are one segment, as are `[...path]` and `[...rest]`.
    Case-folded, since the file systems the sites build on are."""
    segments = [DYNAMIC_SEGMENT.sub(r"\1\2", segment) for segment in url.split("/")]
    return "/".join(segments).casefold()


def url_collisions(plan: AppPlan) -> list[str]:
    """Two files that serve one URL — the frame's `/` and a site's `app-routes/page.tsx`, or one
    route in both `routes` and `app-routes`. Each is a distinct path, so `AppPlan.add` lets it
    through; `next build` would refuse it, later and less plainly."""
    by_url: dict[str, list[str]] = {}
    for rel in sorted(plan.files):
        url = route_url(rel)
        if url is not None:
            by_url.setdefault(url_pattern(url), []).append(rel)
    problems = []
    for rels in by_url.values():
        if len(rels) > 1:
            owners = " and ".join(plan.owner[rel.casefold()] for rel in rels)
            problems.append(f"{owners} would both serve '{route_url(rels[0])}'")
    return problems


def plan_app(site: Path, web: Path) -> tuple[Path, AppPlan]:
    """Everything the assembler would write; `Refused`, with every problem found, if it cannot."""
    try:
        config = json.loads((site / "site" / "site.json").read_text())
    except FileNotFoundError:
        raise Refused([f"no site/site.json under {site}"]) from None
    except ValueError as error:
        raise Refused([f"site/site.json is not valid JSON: {error}"]) from None
    schema = json.loads(SCHEMA.read_text())
    problems: list[str] = []
    check_schema(config, schema, "", problems)
    # The schema's pattern says the same; this is the check the deletion logic relies on, so it
    # does not rest on a regex alone. The app is written, and pruned, only under websites/.
    output = config.get("output")
    parts = str(output).split("/")
    if not problems and (safe_rel(output) is None or parts[0] != "websites" or len(parts) < 2):
        problems.append(f"site/site.json: output: {output!r} must be a path under websites/, e.g. 'websites/main'")
    elif not problems and parts[1].casefold() == "external":
        problems.append(f"site/site.json: output: {output!r} is under websites/external, which holds the site's submodules")
    if problems:
        raise Refused(problems)

    defaults = {key: prop["default"] for key, prop in schema["properties"].items() if "default" in prop}
    app = site / config["output"]
    plan = AppPlan()

    # The skeleton, verbatim. Its package.json is the base of the generated one.
    for path in tree_files(SKELETON):
        rel = path.relative_to(SKELETON).as_posix()
        if rel != "package.json":
            plan.add(rel, path.read_bytes(), f"skeleton/{rel}")

    # The theme's stylesheet, the kit's and the frame's, then the site's token sheet.
    themes = json.loads(THEMES.read_text())
    theme_name = config.get("theme", defaults["theme"])
    theme = themes.get(theme_name)
    if theme is None:
        known = ", ".join(f"'{name}'" for name in sorted(themes))
        plan.problems.append(f"site/site.json: theme '{theme_name}' is not in themes.json; the themes are: {known}")
        theme = {"css": None, "fonts": []}
    # Theme font paths are relative to the toolkit's packages/web/, a site's to its site/.
    fonts = [(font, web, f"themes.json {theme_name}") for font in theme["fonts"]]
    fonts += [(font, site / "site", f"site/site.json: fonts[{i}]") for i, font in enumerate(config.get("fonts", []))]

    sheets = ([theme["css"]] if theme["css"] else []) + KIT_SHEETS + FRAME_SHEETS
    css = (
        "/* GENERATED by @agenticdevelopertoolkit/site-template's assembler — do not edit. The reset,\n"
        " * the theme, the landing kit's sheets and the frame's, the font roles, then the site's token\n"
        " * sheet. */\n"
        + RESET_IMPORT
        + "".join(f'@import "{sheet}";\n' for sheet in sheets)
        + plan_font_roles(fonts, plan.problems)
    )
    if "tokens" in config:
        tokens = site / "site" / config["tokens"]
        label = f"site/{config['tokens']}"
        if not inside(site / "site", config["tokens"]):
            plan.problems.append(f"site/site.json: tokens: {config['tokens']} is outside site/")
        elif not tokens.is_file():
            plan.problems.append(f"site/site.json: tokens: {label} does not exist")
        else:
            text = tokens.read_text()
            sheet_problems = check_token_sheet(text, label)
            plan.problems += sheet_problems
            if not sheet_problems:
                css += f"\n/* {label} */\n{raise_roots(text).rstrip()}\n"
    plan.add("app/theme.css", css.encode(), "generated")

    plan.add("src/site/fonts.ts", plan_fonts(plan, fonts).encode(), "generated")

    ids, slotted, landing_problems = section_ids(app)
    plan.problems += landing_problems
    slots_text, slot_problems = plan_slots(site, config.get("slots", {}), ids, slotted)
    plan.problems += slot_problems
    plan.add("src/site/slots.tsx", slots_text.encode(), "generated")

    plan.problems += drawer_problems(app, config.get("drawer", []))

    mark = config.get("mark", DEFAULT_MARK)
    frame = {
        "mark": mark,
        "themeColor": config.get("themeColor", defaults["themeColor"]),
        "ogImage": config.get("ogImage", mark["src"]),
        **({"ogImageSize": config["ogImageSize"]} if "ogImageSize" in config else {}),
        "drawerExtra": config.get("drawer", []),
        **({"jsonLd": config["jsonLd"]} if "jsonLd" in config else {}),
        "sitemap": config.get("sitemap", []),
        **({"bands": config["bands"]} if "bands" in config else {}),
    }
    # Refused here as the frame refuses it at render, but before a build: a look whose section
    # was renamed would otherwise wait for `next build` to say so.
    for band in config.get("bands", {}):
        if band not in ids:
            known = ", ".join(f"'{i}'" for i in ids) or "(none)"
            plan.problems.append(f"site/site.json: bands: '{band}' names no section; the sections are: {known}")
    # A literal origin, when the site states one, is frameSiteUrl's second choice — after the
    # deploy's SITE_URL and before Vercel's production hostname, which is a `*.vercel.app` name
    # whenever the project's production domain is not the custom one.
    site_url_args = ", ".join([str(config["port"]), *([ts(config["siteUrl"])] if "siteUrl" in config else [])])
    config_ts = (
        f"{HEADER}\n"
        "import { frameSiteUrl } from '@agenticdevelopertoolkit/site-template'\n"
        "import type { FrameConfig } from '@agenticdevelopertoolkit/site-template'\n\n"
        "export const config: FrameConfig = {\n"
        f"  siteUrl: frameSiteUrl({site_url_args}),\n"
        + "".join(f"  {key}: {ts(value)},\n" for key, value in frame.items())
        + "}\n"
    )
    plan.add("src/site/config.ts", config_ts.encode(), "generated")
    # The site's word for a screenshot not yet taken, bound once from its copy — the word the
    # skeleton's `/` hands LandingFrame — so a custom band's shots say what the frame's do.
    plan.add("src/site/shot.tsx", SHOT_TS.encode(), "generated")
    # What next.config.ts resolves against the build's environment (the `./next` export's
    # frameNext); the schema has already checked every `${…}` is well formed.
    analytics = ANALYTICS_ON if config.get("analytics", defaults["analytics"]) else ANALYTICS_OFF
    plan.add("src/site/analytics.tsx", analytics.encode(), "generated")

    base = json.loads((SKELETON / "package.json").read_text())
    package_json = plan_package(base, config, site, app, web, plan.problems)
    plan.add("package.json", package_json, "generated")
    next_ts = (
        f"{HEADER}\n"
        "import type { FrameNextSite } from '@agenticdevelopertoolkit/site-template/next'\n\n"
        "/** site.json's rewrites, public env and env defaults, which next.config.ts resolves at build. */\n"
        "export const nextSite: FrameNextSite = {\n"
        f"  rewrites: {ts(config.get('rewrites', []))},\n"
        f"  publicEnv: {ts(config.get('publicEnv', []))},\n"
        f"  envDefaults: {ts(config.get('envDefaults', {}))},\n"
        "}\n\n"
        "/** Every toolkit package the app reaches, which next.config.ts hands Next to compile. */\n"
        f"export const transpilePackages: readonly string[] = {ts(toolkit_packages(package_json, web))}\n"
    )
    plan.add("src/site/next.ts", next_ts.encode(), "generated")

    # The site's own files, after everything the template writes, so a collision names both.
    for folder, target_root in SITE_TREES:
        root = site / "site" / folder
        for path in tree_files(root):
            rel = path.relative_to(root).as_posix()
            label = f"site/{folder}/{rel}"
            if path.suffix == ".css" and folder in STYLED_TREES:
                plan.problems += check_site_css(path.read_text(), label)
            plan.add(f"{target_root}/{rel}" if target_root else rel, path.read_bytes(), label, from_site=True)
    plan.problems += url_collisions(plan)

    if plan.problems:
        raise Refused(plan.problems)
    return app, plan


# --- check and write --------------------------------------------------------------------------


def manifest_bytes(plan: AppPlan) -> bytes:
    version = json.loads((PACKAGE / "package.json").read_text())["version"]
    data = {"template": "@agenticdevelopertoolkit/site-template", "version": version, "files": sorted(plan.files)}
    return (json.dumps(data, indent=2) + "\n").encode()


def previous_files(app: Path) -> list[str]:
    """What the last run wrote, less anything it could never have owned. The manifest is on disk
    and may have been edited, so every entry is distrusted: it must be a plain relative path, not
    a content-buildr path in any spelling or case, and still inside the app once symlinks resolve.
    This is the only list `write` deletes from."""
    try:
        files = json.loads((app / MANIFEST).read_text())["files"]
    except (FileNotFoundError, ValueError, KeyError, TypeError):
        return []
    if not isinstance(files, list):
        return []
    kept = []
    for entry in files:
        rel = safe_rel(entry)
        if rel is None or is_protected(rel) or not inside(app, rel) or through_symlink(app, rel):
            continue
        # The path the entry really names, in case the filesystem folds it onto another.
        real = (app / rel).resolve().relative_to(app.resolve()).as_posix()
        if not is_protected(real):
            kept.append(rel)
    return kept


def through_symlink(app: Path, rel: str) -> bool:
    """Whether any component of `app/rel`, the last included, is a symlink. The template writes
    none, so an entry that reaches one is an alias for some other path, and is never followed."""
    path = app
    for part in rel.split("/"):
        path = path / part
        if path.is_symlink():
            return True
    return False


def stale_files(app: Path, plan: AppPlan) -> list[str]:
    """The manifest's entries this run no longer writes, compared case-folded: an entry that names
    a file this run writes (the manifest included) in some other case is never stale."""
    keep = {rel.casefold() for rel in wanted(plan)}
    return sorted(rel for rel in set(previous_files(app)) if rel.casefold() not in keep)


def wanted(plan: AppPlan) -> dict[str, bytes]:
    return {**plan.files, MANIFEST: manifest_bytes(plan)}


def differences(app: Path, plan: AppPlan) -> list[str]:
    found = []
    for rel, data in sorted(wanted(plan).items()):
        path = app / rel
        if not path.is_file():
            found.append(f"missing: {rel}")
        elif path.read_bytes() != data:
            found.append(f"changed: {rel}")
    for rel in stale_files(app, plan):
        if (app / rel).exists():
            found.append(f"stale: {rel}")
    return found


def write(app: Path, plan: AppPlan) -> tuple[int, int]:
    written = removed = 0
    stale = stale_files(app, plan)
    for rel, data in sorted(wanted(plan).items()):
        path = app / rel
        if path.is_file() and path.read_bytes() == data:
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        written += 1
    for rel in stale:
        path = app / rel
        if through_symlink(app, rel):
            continue
        if path.is_file():
            path.unlink()
            removed += 1
        # Prune the directories the deletion emptied, never the app itself, and never a symlink.
        parent = path.parent
        while parent != app and not parent.is_symlink() and parent.is_dir() and not any(parent.iterdir()):
            parent.rmdir()
            parent = parent.parent
    return written, removed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Assemble a content site's Next app from the site template.")
    parser.add_argument("--site", required=True, type=Path, help="the site repo's root, which holds site/site.json")
    parser.add_argument("--check", action="store_true", help="write nothing; exit 1 naming each path that is out of date")
    args = parser.parse_args(argv)
    site = args.site.resolve()
    try:
        app, plan = plan_app(site, find_toolkit_web())
    except Refused as refused:
        for problem in refused.problems:
            print(f"assemble: {problem}", file=sys.stderr)
        return 2
    except SchemaError as error:
        print(f"assemble: internal error: {error}", file=sys.stderr)
        return 3
    if args.check:
        found = differences(app, plan)
        for line in found:
            print(line)
        return 1 if found else 0
    written, removed = write(app, plan)
    total = len(wanted(plan))
    print(f"assemble: {app.relative_to(site).as_posix()}: {written} written, {removed} removed, {total - written} unchanged")
    return 0


if __name__ == "__main__":
    sys.exit(main())
