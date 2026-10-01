import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitest/config'

// Self-contained config so `pnpm --filter @agentic-toolkit/adh run test`
// (cwd = this package) discovers src/__tests__/*. The workspace-root
// config excludes every package that owns a config, so this is the only one that runs
// these tests.
// We reuse the root setup file for its deterministic localStorage shim (Node 24's
// built-in localStorage otherwise interferes with jsdom).
export default defineConfig({
  resolve: {
    alias: [
      // ONE `next` in the test process, forced by
      // Task 7 (the User Settings overlay): its render tree now crosses into
      // @agentic-toolkit/account and @agentic-toolkit/resource, both pinned to next ^15.1.0,
      // while this package's own devDependency is next ^16.2.9 — two genuinely different
      // installed copies (confirmed: 15.5.18 vs 16.2.10, resolving to different files under
      // node_modules/.pnpm). Unlike react, that mismatch is silent up to this task: nothing
      // under src/ rendered an account/resource component before. Without this alias,
      // `vi.mock('next/navigation', …)` in a test here (see settings/__tests__/
      // userSettingsOverlay.test.tsx) only intercepts THIS package's next@16 copy — a
      // component resolved from account/resource's own src (the `development` condition)
      // still imports the bare specifier, which Node resolution walks up to THEIR next@15
      // copy, unmocked. The result is the real Next.js useRouter() throwing "invariant
      // expected app router to be mounted" instead of returning the mock, since jsdom has no
      // App Router.
      //
      // The pin covers exactly the `next/*` subpaths those siblings import, which today is
      // `next/link` and `next/navigation`. It is EIGHT siblings, not two, that carry their own
      // next (account, auth, authentication, data, ecosystem-config, personas, profile,
      // resource) — so do not reason about this list from the two package names above.
      // `src/__tests__/nextAliasCoverage.test.ts` derives the required set from their source
      // and fails by name when a panel reaches for a subpath that is missing here; adding the
      // alias is the fix, and that test is what tells you to.
      {
        find: 'next/navigation',
        replacement: fileURLToPath(new URL('./node_modules/next/navigation.js', import.meta.url)),
      },
      {
        find: 'next/link',
        replacement: fileURLToPath(new URL('./node_modules/next/link.js', import.meta.url)),
      },
    ],
  },
  test: {
    environment: 'jsdom',
    globals: true,
    // The gate runs `pnpm -r --if-present test`, which starts a vitest worker POOL PER PACKAGE
    // across the whole workspace at once, so a worker here can be starved of CPU for seconds at a
    // stretch. That is not a slow test, it is a descheduled one, and the default 5 s budget is
    // narrow enough to lose the race: `siteHomeShell.test.tsx`'s "selecting a workspace pushes the
    // URL, and the settled effect writes the cache and the server" measures 61 ms run on its own
    // and timed out at 5 000 ms under the full run — an 80x blowup with the package's code
    // unchanged, having passed the identical step 40 minutes earlier. A ceiling costs nothing when
    // it is not hit, so raise it for the package rather than for the one test that happened to be
    // descheduled this time; the next one would otherwise be a fresh flake with the same cause.
    // Same reason and same number as packages/markdown.
    testTimeout: 30_000,
    // Two setups. The root one for its deterministic localStorage shim (above); the data
    // package's for the toolkit query cache, which lives at MODULE scope — one per browser tab
    // by design — and therefore outlives `cleanup()`. Any test here that exercises a real
    // resource hook would otherwise read the PREVIOUS test's rows and fail as "my fixture never
    // appeared". Added by path because that file sits inside `packages/`, where the root setup
    // cannot reach it.
    setupFiles: ['../../vitest.setup.ts', '../data/vitest-setup.ts'],
    dir: 'src',
  },
})
