import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));

/** The character config bundled with the engine, used when no other is reachable.
 *
 *  A byte-for-byte copy of `whatsnow-toolkit/characters/olylo`'s six JSON files
 *  — everything except the `goldens/` beside them, which run to 93MB of
 *  recorded frames and belong with the tool that records them. The copy is not
 *  allowed to drift: `character-dir.test.ts` beside it diffs it against the
 *  real directory on every run that can see one, which is every run inside
 *  whatsnow-toolkit.
 *
 *  A synthetic character would be the tidier fixture, and it is what the Swift
 *  half bundles (`AvatarAnimationEngine/Tests/Fixtures/dot`). It cannot be used
 *  here: the TypeScript tests were written against olylo and assert its
 *  numbers, its pose names and its exact path strings — 104 of 249 fail against
 *  `dot`. Porting them to a synthetic rig is a change to twelve test files this
 *  copy deliberately does not make. */
export const BUNDLED_CHARACTER_DIR = resolve(HERE, "src/__fixtures__/olylo");

/** Where the character config the tests load lives.
 *
 *  Three sources, in priority order:
 *
 *  1. `CHARACTER_DIR` in the environment — an explicit override, for pointing
 *     the suite at a character that is neither bundled nor an ancestor.
 *  2. `characters/olylo` in an ancestor directory. This repo is checked out
 *     inside `whatsnow-toolkit`, and in the olylo superproject it is checked out
 *     TWICE at two different depths: once for the web app (nested under
 *     `whatsnow-toolkit/packages/web/external/`) and once for the Apple app (a
 *     sibling at the superproject root). A fixed run of `..` segments is
 *     therefore correct in exactly one of the two and resolves to a directory
 *     that does not exist in the other — which fails twelve test files with
 *     nothing but "Cannot find package '@character/character.json'", and looks
 *     for all the world like a broken source tree. Searching upward is correct
 *     in both, and finds the REAL directory — goldens included — wherever one
 *     exists, so the parity run inside whatsnow-toolkit is unaffected by the
 *     bundled copy.
 *  3. The bundled fixture. This used to THROW instead, which made the suite
 *     unrunnable in this repo's own CI: `deployment/run-ci` checks out
 *     agenticdevelopertoolkit alone, and whatsnow-toolkit is a *parent* of it,
 *     never a submodule, so there is no ancestor to find and not one test was
 *     ever collected. A library whose tests only run inside one particular
 *     superproject is a library nobody outside that superproject can change. */
export function findCharacterDir(
  // Both parameters exist so the search itself is testable: the interesting
  // case is what happens with no `characters/olylo` in ANY ancestor, which is
  // the one case a test running inside whatsnow-toolkit cannot reach by
  // default. See `character-dir.test.ts` beside this file.
  from: string = HERE,
  env: Record<string, string | undefined> = process.env,
): string {
  const fromEnv = env.CHARACTER_DIR;
  if (fromEnv) return resolve(fromEnv);

  // Either this IS the toolkit repo's own tree, or the toolkit is a submodule
  // of the superproject we are somewhere underneath.
  const candidates = ["characters/olylo", "external/whatsnow-toolkit/characters/olylo"];
  let dir = from;
  for (;;) {
    for (const rel of candidates) {
      const found = resolve(dir, rel);
      // Probe a FILE, not the directory: an empty or half-initialised submodule
      // checkout still has the directory, and would resolve the alias to a tree
      // with no JSON in it — a later, much more confusing failure.
      if (existsSync(join(found, "character.json"))) return found;
    }
    const up = dirname(dir);
    if (up === dir) return BUNDLED_CHARACTER_DIR;
    dir = up;
  }
}

/** The six files a character is made of, in the order the loader takes them. */
export const CHARACTER_FILES = [
  "character",
  "rig",
  "poses",
  "timelines",
  "behavior",
  "sayings",
] as const;
