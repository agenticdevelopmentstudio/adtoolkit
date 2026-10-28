import { dirname } from "node:path";
import { describe, expect, it } from "vitest";
import { adhStylesheet, cascadeOrder, styleRules } from "./stylesheetRules";
import { FAMILY_ROOT_CLASS } from "../marketing/MarketingShell";

/**
 * The family sheets apply only while a family shell is on the page.
 *
 * A site built on the site template keeps its family routes (privacy, terms, the signed-in
 * pages) in a route group whose layout imports `family.css`, and its `/` is the template's.
 * Next keeps a layout's stylesheet in the document after a client-side navigation away from
 * that layout, so an unscoped `html`, `body` or `:root` rule here, or a `.lp-*` rule, went on
 * styling the template's own landing page — the bridge's `:root { --lp-* }` re-pointed every
 * token the template's landing reads. Each rule therefore names the class `MarketingShell`
 * renders on its root element, so it stops applying the moment the shell unmounts.
 *
 * What is checked: every rule in adh's OWN sheets that `adh-family.css` brings in, itself
 * included. The landing package's sheets are gated on their own classes (`:has(.lp-deck)`,
 * `.lp-band`) and the themes and ui sheets are not this package's to scope.
 */
const ADH_STYLES = dirname(adhStylesheet("adh-family.css"));
const OWN_SHEETS = [
  ...new Set(cascadeOrder(adhStylesheet("adh-family.css"))),
].filter((sheet) => dirname(sheet) === ADH_STYLES);
const FAMILY_SHEET_NAMES = ["adh-family.css", "adh-landing-bridge.css"];
const FAMILY_SHEETS = FAMILY_SHEET_NAMES.map(adhStylesheet);
/** The selectors that reach the document or the landing kit's elements. */
const DOCUMENT_OR_LANDING = /(^|[\s>+~(,])(html|body)\b|:root\b|\.lp-/;

describe("the family sheets are scoped to the family shell", () => {
  it("reads adh-family.css, the bridge and the sheets they import", () => {
    const names = OWN_SHEETS.map((sheet) => sheet.slice(ADH_STYLES.length + 1));
    expect(names).toEqual(
      expect.arrayContaining([
        "adh-family.css",
        "adh-landing-bridge.css",
        "adh-site.css",
      ]),
    );
  });

  it.each(FAMILY_SHEET_NAMES)(
    "scopes every rule of %s under the shell",
    (name) => {
      const rules = styleRules(adhStylesheet(name));
      expect(rules.length).toBeGreaterThan(0);
      const unscoped = rules
        .flatMap((rule) => rule.selectors)
        .filter((s) => !s.includes(`.${FAMILY_ROOT_CLASS}`));
      expect(unscoped).toEqual([]);
    },
  );

  it("lets the other adh sheets reach the document only through adh-owned hooks", () => {
    // The sheets adh-family.css imports are also a site's own `styles.css` (fishlamp mounts the
    // header without the shell), so they cannot all be put under the shell's class. What they
    // may do to the document is what cannot collide with a page that is not the family's: a
    // `:root` that assigns only `--adh-*` tokens, or one gated on an adh attribute
    // (`:root[data-adh-slide]`, which the family chrome sets). An html, body or `.lp-*` rule, or
    // a `:root` that assigns anything else, has to be in the family sheets, under the shell.
    const reaching = OWN_SHEETS.filter(
      (sheet) => !FAMILY_SHEETS.includes(sheet),
    ).flatMap((sheet) =>
      styleRules(sheet).flatMap((rule) =>
        rule.selectors
          .filter(
            (s) =>
              DOCUMENT_OR_LANDING.test(s) &&
              !s.includes(`.${FAMILY_ROOT_CLASS}`),
          )
          .filter((s) => !/^:root\[data-adh-/.test(s))
          .filter(
            (s) =>
              !(
                s === ":root" &&
                rule.properties.every((p) => p.startsWith("--adh-"))
              ),
          )
          .map((s) => `${sheet.slice(ADH_STYLES.length + 1)}: ${s}`),
      ),
    );
    expect(reaching).toEqual([]);
  });
});
