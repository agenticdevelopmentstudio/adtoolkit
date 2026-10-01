import { defineConfig } from 'vitest/config'

// Self-contained config so `pnpm --filter @agentic-toolkit/crud run test`
// (cwd = this package) discovers src/__tests__/*. The workspace-root
// config excludes every package that owns a config, so this is the only one that runs
// these tests. We reuse the root setup file for its deterministic jest-dom/
// localStorage/ResizeObserver/matchMedia shims.
export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../../vitest.setup.ts'],
    dir: 'src',
  },
})
