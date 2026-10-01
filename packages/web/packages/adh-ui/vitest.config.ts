import { defineConfig } from 'vitest/config'

// Self-contained config so `pnpm --filter @agentic-toolkit/adh-ui run test`
// (cwd = this package) discovers src/__tests__/*. The workspace-root
// config excludes every package that owns a config, so this is the only one that runs
// these tests.
// We reuse the root setup file for its deterministic jest-dom/localStorage/
// ResizeObserver/matchMedia shims (see packages/web/vitest.setup.ts, and the
// @agenticdevelopertoolkit/ui package for the same pattern), plus a package-local
// setup for the @base-ui/react Dialog getComputedStyle patch this package's
// dialog-based blocks (SendInvitationModal, AdminNotesModal,
// TransferOwnershipSection, ...) need.
export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../../vitest.setup.ts', './vitest.setup.ts'],
    dir: 'src',
  },
})
