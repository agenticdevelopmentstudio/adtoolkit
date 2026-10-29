import { readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import {
  BUNDLED_CHARACTER_DIR,
  CHARACTER_FILES,
  findCharacterDir,
} from "./character-dir";

/** The character directory this run is actually using — the same string the
 *  `@character` alias resolves to, handed over by `vitest.config.ts`. */
const IN_USE = process.env.CHARACTER_DIR!;
const USING_BUNDLED = IN_USE === BUNDLED_CHARACTER_DIR;

// The twin of `AvatarAnimationEngine/Tests/FixtureTests.swift`: if bundling
// ever breaks, exactly one test fails with a message that says so, instead of a
// hundred failing on a missing pose.
describe("the bundled character fixture", () => {
  it.each(CHARACTER_FILES)("bundles %s.json, declaring schemaVersion 1", (name) => {
    const blob = readFileSync(join(BUNDLED_CHARACTER_DIR, `${name}.json`), "utf8");
    expect(JSON.parse(blob).schemaVersion).toBe(1);
  });

  // The fixture is a COPY, and a copy nothing compares is a fork. Every run
  // that can see the real character — which is every run inside
  // whatsnow-toolkit, including CI's root workspace run — diffs the two, so a
  // change to olylo's config that forgets the copy fails here and not months
  // later as an unexplained difference between this repo's CI and the
  // superproject's.
  it.skipIf(USING_BUNDLED).each(CHARACTER_FILES)(
    "%s.json is byte-identical to the character in use",
    (name) => {
      const bundled = readFileSync(join(BUNDLED_CHARACTER_DIR, `${name}.json`), "utf8");
      const real = readFileSync(join(IN_USE, `${name}.json`), "utf8");
      if (bundled === real) return;
      expect.fail(
        `src/__fixtures__/olylo/${name}.json has drifted from ${IN_USE}/${name}.json. ` +
          `Copy the real one over it — the bundled fixture is not edited by hand.`,
      );
    },
  );
});

describe("findCharacterDir", () => {
  // The regression this whole fixture exists for. `deployment/run-ci` checks this
  // repo out ALONE — whatsnow-toolkit is a parent of it, never a submodule — so
  // the upward search reaches `/` and finds nothing. It used to throw there,
  // which meant the workspace's own CI could not collect a single one of these
  // tests.
  it("falls back to the bundled fixture when no ancestor has a character", () => {
    expect(findCharacterDir(tmpdir(), {})).toBe(BUNDLED_CHARACTER_DIR);
  });

  it("prefers an explicit CHARACTER_DIR over anything it could find", () => {
    const dir = join(tmpdir(), "some-other-character");
    expect(findCharacterDir(undefined, { CHARACTER_DIR: dir })).toBe(dir);
  });

  // Priority matters as much as the fallback: a bundled copy that shadowed the
  // real character would quietly test the wrong config, and the goldens beside
  // the real one would stop being checked against anything.
  it.skipIf(USING_BUNDLED)("prefers a character found in an ancestor over the bundle", () => {
    expect(findCharacterDir(undefined, {})).toBe(IN_USE);
  });
});

// `vitest.config.ts` reaches the bundled fixture by running code; `tsconfig.json`
// cannot, so it lists the candidate paths instead and the two have to agree. When
// they did not, the suite ran green in a standalone checkout while `pnpm lint`
// failed TS2307 on all six `@character/*` imports -- a split nothing caught,
// because the two are checked by different commands.
describe("the @character alias in tsconfig", () => {
  const paths = JSON.parse(
    readFileSync(join(import.meta.dirname, "tsconfig.json"), "utf8")
      .replace(/^\s*\/\/.*$/gm, ""),
  ).compilerOptions.paths["@character/*"] as string[];

  it("falls back to the bundled fixture, so a standalone checkout typechecks", () => {
    expect(paths).toContain("src/__fixtures__/olylo/*");
  });

  // Order is the whole guarantee: a fallback listed first would shadow the real
  // character, and TypeScript would silently typecheck against a copy while the
  // suite ran against the original.
  it("lists the fallback last, so a reachable character always wins", () => {
    expect(paths.indexOf("src/__fixtures__/olylo/*")).toBe(paths.length - 1);
  });
});
