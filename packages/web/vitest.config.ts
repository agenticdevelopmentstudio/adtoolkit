import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { join, relative, resolve } from 'node:path'
import { defineConfig } from 'vitest/config'

const VIRTUAL_ID = 'virtual:reference-site-content'
const RESOLVED_ID = '\0' + VIRTUAL_ID

const PACKAGES_DIR = resolve(__dirname, 'packages')
const OWN_CONFIG_FILES = ['vitest.config.ts', 'vitest.config.mts', 'vitest.config.js', 'vitest.config.mjs']

/**
 * Package directories (relative to `packagesDir`) for which `owns` holds.
 *
 * Packages live at two depths — `packages/<name>` and `packages/features/<name>` — and a
 * directory that is not itself a package (no package.json, like `features/`) is searched
 * one level further. Derived from the filesystem so the set can't go stale as a package
 * adds or drops its own config.
 */
function findPackages(packagesDir: string, owns: (packageDir: string) => boolean): string[] {
  if (!existsSync(packagesDir)) return []
  const found: string[] = []
  const visit = (dir: string, depth: number): void => {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      if (!entry.isDirectory() || entry.name === 'node_modules') continue
      const full = join(dir, entry.name)
      if (existsSync(join(full, 'package.json'))) {
        if (owns(full)) found.push(relative(packagesDir, full))
      } else if (depth === 0) {
        visit(full, depth + 1)
      }
    }
  }
  visit(packagesDir, 0)
  return found.sort()
}

/** Package directories (relative to `packagesDir`) that own their own vitest.config.ts. */
export function packagesWithOwnConfig(packagesDir: string = PACKAGES_DIR): string[] {
  return findPackages(packagesDir, (full) => OWN_CONFIG_FILES.some((f) => existsSync(join(full, f))))
}

/**
 * Package directories whose own `test` script runs something other than vitest
 * (`node --test`, for one). Vitest's glob finds such a package's `*.test.ts` files all
 * the same and reports "No test suite found" for each, because they import `node:test`
 * and never register with vitest — so they belong to the `pnpm -r run test` lane, which
 * runs them with their own runner, and not to this one. A script that also invokes vitest
 * (`python3 … && vitest run`) stays in both lanes, as it always did.
 */
export function packagesWithOwnRunner(packagesDir: string = PACKAGES_DIR): string[] {
  return findPackages(packagesDir, (full) => {
    try {
      const pkg = JSON.parse(readFileSync(join(full, 'package.json'), 'utf8')) as {
        scripts?: { test?: string }
      }
      const script = pkg.scripts?.test
      return script !== undefined && !script.includes('vitest')
    } catch {
      return false
    }
  })
}

function packageNameFor(packagesDir: string, dir: string): string {
  try {
    const pkg = JSON.parse(readFileSync(join(packagesDir, dir, 'package.json'), 'utf8')) as {
      name?: string
    }
    return pkg.name ?? dir
  } catch {
    return dir
  }
}

/**
 * Vitest loads exactly one config per run, chosen by where the process starts, never by
 * what `--dir` narrows it to scan. `pnpm vitest run --dir packages/<name>` run from this
 * workspace root therefore loads THIS file for every `<name>`, including one that owns its
 * own vitest.config.ts — `--dir` only picks which test files run under it, not which config
 * runs them. For `adh-ui` that meant no package-local setup and `Cannot read properties of
 * null (reading 'useId')`: a wrong command whose output reads exactly like a product
 * regression, not a command mistake. Fail here instead, before any test runs, and name the
 * command that actually loads the right config.
 */
export function checkDirTarget(argv: string[], cwd: string, packagesDir: string = PACKAGES_DIR): void {
  const flagIndex = argv.findIndex((arg) => arg === '--dir' || arg.startsWith('--dir='))
  if (flagIndex === -1) return
  const flag = argv[flagIndex]
  const value = flag.startsWith('--dir=') ? flag.slice('--dir='.length) : argv[flagIndex + 1]
  if (!value) return

  const target = resolve(cwd, value)
  for (const dir of packagesWithOwnConfig(packagesDir)) {
    const pkgRoot = join(packagesDir, dir)
    if (target === pkgRoot || target.startsWith(pkgRoot + '/')) {
      const name = packageNameFor(packagesDir, dir)
      throw new Error(
        `vitest.config.ts (workspace root): "--dir ${value}" targets "${dir}", which owns its ` +
          `own vitest.config.ts. Loading this root config there skips that package's aliases, ` +
          `environment, and setup files, and its failures will read like a product regression ` +
          `rather than a wrong command. Run \`pnpm --filter ${name} run test\` instead.`,
      )
    }
  }
}

checkDirTarget(process.argv, process.cwd())

// Two lanes, split by one rule, so every test runs exactly once and under the config its
// author chose.
//
// A package that owns a vitest.config.ts runs under it, through its own `test` script —
// the root `test` script's `pnpm -r --if-present run test`. Its config is the one its
// consumers build against and can differ from this one in ways that break its tests here:
// `avatar-engine` needs `environment: "node"` and its `@character` alias, and replays 43MB
// scenarios that blow the 5s default timeout under jsdom; `adh-ui` needs its own
// @base-ui Dialog setup file. Running such a package in this lane as well would at best
// run it twice and at worst run it wrong.
//
// Every other package — the ones that declare no config, most of them no `test` script
// either (`chat`, `viewport`, `popover`, …) — is discovered here, by this one jsdom run.
// A package whose own `test` script uses another runner (`releases`: node --test) is
// left out of this lane for the same reason. The exclusion list is derived, never written out, so a package that gains or drops its
// own config moves lanes without anyone editing this file.
export default defineConfig({
  plugins: [
    {
      name: 'stub-reference-site-content',
      resolveId(id: string) {
        if (id === VIRTUAL_ID) return RESOLVED_ID
      },
      load(id: string) {
        if (id === RESOLVED_ID) return 'export default []'
      },
    },
  ],
  server: {
    fs: {
      allow: ['..'],
    },
  },
  test: {
    name: 'web',
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./vitest.setup.ts'],
    dir: './packages',
    // Vitest's own defaults, which naming `exclude` at all would drop, plus every package
    // that runs in its own lane. Relative to `dir` above, not to the workspace root.
    exclude: [
      '**/node_modules/**',
      '**/dist/**',
      '**/cypress/**',
      '**/.{idea,git,cache,output,temp}/**',
      '**/{karma,rollup,webpack,vite,vitest,jest,ava,babel,nyc,cypress,tsup,build,eslint,prettier}.config.*',
      ...[...new Set([...packagesWithOwnConfig(), ...packagesWithOwnRunner()])].map((dir) => `${dir}/**`),
    ],
  },
})
