import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { defineConfig } from 'vitest/config'

// Single source of the feature-package vitest config (DRY). Self-contained so
// `pnpm --filter @agentic-toolkit/<pkg> run test` (cwd = the package) discovers
// src/**/*.test.tsx — the workspace-root config excludes every package that owns a
// config, so this is the only one that runs these tests. Reuses the root setup file
// for its ResizeObserver / localStorage / matchMedia shims (jsdom doesn't provide them).
//
// A per-package vitest.config.ts is one line: the default export of
// `featureVitest()`. Packages that ship no unit tests yet pass `{ passWithNoTests:
// true }` so an empty suite doesn't fail the per-package lane.
//
// `setupFiles` adds a package's OWN setup after the shared one. It exists because the
// root file can only reach dependency-free shims: it lives at the workspace root,
// which has no `@agentic-toolkit/*` in scope, so anything that must reset a toolkit
// package's module-scope state (the query cache — see `vitest.setup.ts` next to any
// config that passes this) has to be imported from inside the package that depends on it.

/**
 * The directory `featureVitest()` runs from, checked.
 *
 * Exported for its own test: the check has to be callable with a directory that
 * is NOT this process's cwd, and a vitest worker cannot `process.chdir()`.
 *
 * Every path below — `dir: 'src'`, the `../../../vitest.setup.ts` setup file — is
 * relative to the cwd, so a run started anywhere but a feature package resolves them
 * against the wrong directory and finds no tests or the wrong setup. Fail here,
 * naming the command that starts in the right place.
 */
export function assertFeaturePackageDir(packageDir: string): string {
  if (!existsSync(join(packageDir, 'package.json'))) {
    throw new Error(
      `featureVitest: expected the cwd to be the package being tested, but ` +
        `${packageDir} has no package.json. Run this through the package's own ` +
        `\`test\` script (pnpm --filter <pkg> run test).`,
    )
  }
  return packageDir
}

export function featureVitest(
  opts: { passWithNoTests?: boolean; setupFiles?: string[] } = {},
) {
  // A per-package config is only ever loaded by that package's own `test` script, so
  // cwd IS the package; assert it rather than let a wrong cwd scan the wrong `src`.
  assertFeaturePackageDir(process.cwd())

  return defineConfig({
    test: {
      environment: 'jsdom',
      globals: true,
      setupFiles: ['../../../vitest.setup.ts', ...(opts.setupFiles ?? [])],
      dir: 'src',
      passWithNoTests: opts.passWithNoTests ?? false,
    },
  })
}
