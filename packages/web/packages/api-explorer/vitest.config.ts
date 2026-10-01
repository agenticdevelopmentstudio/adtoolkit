import { defineConfig } from 'vitest/config'

// Self-contained config so `pnpm --filter @agentic-toolkit/api-explorer run test`
// (cwd = this package) discovers src/__tests__/*. The workspace-root
// config excludes every package that owns a config, so this is the only one that runs
// these tests. No test files exist here yet — the one test this package had
// (the openapi.json drift gate) stays monorepo-side since it needs the spec
// file, which only exists in the websites/ checkout — so `passWithNoTests`
// keeps `test` green rather than failing on an empty suite.
export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../../vitest.setup.ts'],
    dir: 'src',
    passWithNoTests: true,
  },
})
