// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit. Change the
// skeleton in the toolkit and re-assemble.
import { fileURLToPath } from 'node:url'
import type { NextConfig } from 'next'
import { frameNext } from '@agenticdevelopertoolkit/site-template/next'
import { nextSite, transpilePackages } from './src/site/next'

/** The pnpm workspace root: the app's parent (`websites/`), where the site's lockfile lives. */
const WORKSPACE_ROOT = fileURLToPath(new URL('..', import.meta.url))

/**
 * `site.json`'s `rewrites` and `publicEnv`, resolved now, as the config loads, so a variable the
 * build needs and cannot find fails `next build` by name rather than a request at runtime.
 */
const site = frameNext(nextSite, process.env)

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
  env: site.env,
  ...(site.rewrites.length === 0 ? {} : { rewrites: async () => site.rewrites }),
  // The suite serves `next dev` at `https://<id>.<name>.dev.local` behind Caddy, and a walk may
  // reach it at 127.0.0.1; Next refuses its dev assets (HMR, the RSC fetches) to any origin not
  // listed, which leaves the page hydrating against nothing.
  allowedDevOrigins: ['*.dev.local', 'dev.local', '127.0.0.1'],
  // Every toolkit package the app reaches, as the assembler lists them in `src/site/next.ts`.
  // Each ships a dist that keeps its `'use client'` directives, but a site's linked package may
  // serve source under a `development` condition, which Next must compile; a dist compiled
  // again costs the build little.
  transpilePackages: [...transpilePackages],
})
