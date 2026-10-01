// @vitest-environment node
// ^ Required, not a preference: this file drives config-time machinery (node fs,
// module resolution) rather than a component, and jsdom's globals interfere with
// tooling that assumes a plain Node process.
import { fileURLToPath } from "node:url";
import { beforeAll, describe, expect, it } from "vitest";

/**
 * `featureVitest()` resolves `dir: 'src'` and its setup files against the cwd, so it
 * asserts the cwd is a package before building anything from it.
 *
 * Loaded at runtime rather than by a static import for the same reason the other
 * config-shaped tests are: a static edge to a file outside `rootDir: './src'`
 * drags it into tsc's program and `pnpm run lint` fails with TS6059.
 */
const PACKAGE_DIR = fileURLToPath(new URL("../", import.meta.url)); // src/x -> the package
const NOT_A_PACKAGE = fileURLToPath(new URL("./no-such-directory-here/", import.meta.url));

let assertFeaturePackageDir: (packageDir: string) => string = () => "";

beforeAll(async () => {
  const loaded = (await import(new URL("../../vitest.preset.ts", import.meta.url).href)) as {
    assertFeaturePackageDir: (packageDir: string) => string;
  };
  assertFeaturePackageDir = loaded.assertFeaturePackageDir;
});

describe("featureVitest's package-directory guard", () => {
  it("accepts a feature package", () => {
    expect(assertFeaturePackageDir(PACKAGE_DIR)).toBe(PACKAGE_DIR);
  });

  it("rejects a directory with no manifest at all", () => {
    expect(() => assertFeaturePackageDir(NOT_A_PACKAGE)).toThrow(/has no package\.json/);
    expect(() => assertFeaturePackageDir(NOT_A_PACKAGE)).toThrow(NOT_A_PACKAGE);
  });
});
