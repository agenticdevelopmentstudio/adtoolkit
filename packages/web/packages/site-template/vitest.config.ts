import { defineConfig } from 'vitest/config'

// Self-contained, like landing's: `pnpm --filter @agenticdevelopertoolkit/site-template run test`
// runs with this package as its cwd, and the workspace-root setup file supplies the jsdom shims.
export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../../vitest.setup.ts'],
    dir: 'src',
  },
})
