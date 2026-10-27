// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit. Change the
// skeleton in the toolkit and re-assemble.
import { fileURLToPath } from 'node:url'
import type { NextConfig } from 'next'

/** The pnpm workspace root: the app's parent (`websites/`), where the site's lockfile lives. */
const WORKSPACE_ROOT = fileURLToPath(new URL('..', import.meta.url))

/**
 * Two cross-cutting concerns, carried over from the fleet's `with<Site>Config` wrappers.
 *
 * 1. Promote the server-only `DEPLOYMENT_ENV` to the client-inlined `NEXT_PUBLIC_DEPLOYMENT_ENV`.
 *    Every tier's Vercel project makes `VERCEL_ENV=production` deployments of its branch, so
 *    Vercel's own label cannot tell production from staging; `DEPLOYMENT_ENV` can.
 *
 * 2. Pin Turbopack's workspace root, but only off Vercel. Next picks the OUTERMOST lockfile it
 *    finds walking up from the app, so a stray lockfile above the repo makes it watch the whole
 *    tree. On Vercel the checkout is the repo alone, and pinning `outputFileTracingRoot` to an
 *    ancestor of the project's Root Directory makes the builder look for `.next` one level too
 *    shallow and fail the deploy — hence the `VERCEL` early return.
 */
function frameConfig(config: NextConfig): NextConfig {
  const withEnv: NextConfig = {
    ...config,
    env: {
      NEXT_PUBLIC_DEPLOYMENT_ENV: process.env.DEPLOYMENT_ENV ?? process.env.NEXT_PUBLIC_DEPLOYMENT_ENV,
      ...config.env,
    },
  }
  if (process.env.VERCEL) return withEnv
  return {
    ...withEnv,
    turbopack: { ...config.turbopack, root: WORKSPACE_ROOT },
    outputFileTracingRoot: config.outputFileTracingRoot ?? WORKSPACE_ROOT,
  }
}

export default frameConfig({
  // Hide the floating Next.js dev-tools indicator in `next dev`.
  devIndicators: false,
  // No transpilePackages: every toolkit package builds a dist with its `'use client'`
  // directives preserved, precisely so a Next consumer does not need it.
})
