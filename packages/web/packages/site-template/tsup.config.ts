import { defineConfig } from 'tsup'
import { preserveDirectivesPlugin } from 'esbuild-plugin-preserve-directives'

const shared = {
  outDir: 'dist',
  format: ['esm'] as const,
  target: 'es2022' as const,
  platform: 'browser' as const,
  sourcemap: true,
  dts: false,
  bundle: true,
  splitting: true,
  outExtension: () => ({ js: '.js' }),
  // Dependencies and peers (the landing kit, bitbag, next) are external already — tsup
  // reads them from package.json — so a `'use client'` module of theirs is imported by
  // package path and cannot hoist its directive into this package's server barrel.
  external: ['react', 'react-dom', 'react/jsx-runtime'],
  esbuildPlugins: [
    preserveDirectivesPlugin({
      directives: ['use client', 'use server'],
      include: /\.(js|ts|jsx|tsx)$/,
      exclude: /node_modules/,
    }),
  ],
}

// Independent builds, for the reason landing's tsup.config.ts gives in full: one chunk
// graph would carry SiteChrome's `'use client'` onto dist/index.js and turn LandingFrame —
// every band of a site's copy — into a Client Component. tools/check_template_directives.py
// asserts the outcome.
//
// The client entry's source is `client-barrel.ts`, not `client.ts`: the repo's abstractr
// hook refuses a new file whose stem another shared tier already exports. The built file
// and the `./client` subpath keep the conventional name.
export default defineConfig([
  {
    ...shared,
    entry: { index: 'src/index.ts' },
    clean: true,
  },
  {
    ...shared,
    // clean:false so it adds to, rather than wipes, the build above.
    entry: { client: 'src/client-barrel.ts' },
    clean: false,
  },
  {
    ...shared,
    // `./next`: what the skeleton's next.config.ts imports. Node runs it when Next loads the
    // config, so it is built for node and shares no chunk with the page entries above.
    // `@agentic-toolkit/next-env` is a devDependency, so it is bundled in: the config loads
    // nothing at build that the site's install has to have hoisted. The themes package stays
    // external — its font copier finds its faces by its own `import.meta.url`.
    entry: { next: 'src/frame-next.ts' },
    platform: 'node' as const,
    clean: false,
  },
])
