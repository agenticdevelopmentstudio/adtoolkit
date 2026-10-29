// The build-time half of `site.json`: its `rewrites`, `headers`, `redirects`, `publicEnv` and `envDefaults`,
// resolved against the environment `next build` runs in, and what the build does besides Next's
// config (the theme's font files, the build's identity). Published as `@agenticdevelopertoolkit/site-template/next`
// and imported by the skeleton's `next.config.ts` — never by a page, so nothing here reaches a
// bundle. The assembler has already checked every `${…}` is well formed; what it cannot know is
// the environment, so an unset variable with no default fails the build here, by name.

import { commitSha, readSiteVersion } from '@agentic-toolkit/next-env'
import { materializeThemeFonts } from '@agenticdevelopertoolkit/themes/materialize-fonts'

/** One `site.json` rewrite: Next's `{ source, destination }`, the destination substituted. */
export interface FrameRewrite {
  source: string
  destination: string
}

/** One `site.json` header rule: Next's `{ source, headers }`, passed through as written. */
export interface FrameHeader {
  source: string
  headers: readonly { key: string; value: string }[]
}

/** One `site.json` redirect: Next's `{ source, destination, permanent }`, passed through as written. */
export interface FrameRedirect {
  source: string
  destination: string
  permanent: boolean
}

/**
 * A value chosen by a variable: `values[env[by]]`, with `local` for a build off Vercel whose
 * selector names no value. On Vercel a selector naming no value fails the build, so a misspelt
 * tier is never quietly served `local`'s backend.
 */
export interface FrameEnvChoice<Local> {
  by: string
  values: Readonly<Record<string, string>>
  local?: Local
}

/**
 * A variable's fallback when the environment leaves it unset or empty: a string (itself
 * substituted), or a value chosen by another variable (`FrameEnvChoice`). That choice's `local`
 * may itself be chosen by a second variable, one level deep: a site whose deploys pick a backend
 * by tier (`DEPLOYMENT_ENV`) and whose local builds pick one by build mode (`NODE_ENV`) says both
 * in one entry, rather than through a variable that exists only to be switched on.
 */
export type FrameEnvDefault = string | FrameEnvChoice<string | FrameEnvChoice<string>>

/** What the assembler writes to `src/site/next.ts` from `site.json`. */
export interface FrameNextSite {
  rewrites: readonly FrameRewrite[]
  /** Literal response headers; absent from a `next.ts` assembled before the key existed. */
  headers?: readonly FrameHeader[]
  /** Literal redirects, in Next's matching order; absent when the site has none. */
  redirects?: readonly FrameRedirect[]
  /** `NAME`, which must resolve, or `${NAME:-}`, which is left out when it does not. */
  publicEnv: readonly string[]
  envDefaults: Readonly<Record<string, FrameEnvDefault>>
  /** Copy the theme's font files into the app's `public/` (`frameThemeFonts`). */
  themeFonts?: boolean
  /** Name the build in the client env by its VERSION file and commit (`frameBuildIdentity`). */
  buildIdentity?: boolean
  /** Next's client router cache lifetimes, in seconds: `experimental.staleTimes`. */
  staleTimes?: { dynamic?: number; static?: number }
}

/**
 * A header rule as Next takes it: the same shape as `FrameHeader`, but with a mutable list, since
 * Next's `Header` type will not accept a readonly one.
 */
export interface FrameNextHeader {
  source: string
  headers: { key: string; value: string }[]
}

/** The resolved pieces `next.config.ts` merges into its config. */
export interface FrameNextResult {
  env: Record<string, string>
  rewrites: FrameRewrite[]
  headers: FrameNextHeader[]
  redirects: FrameRedirect[]
}

type Env = Readonly<Record<string, string | undefined>>

// The assembler validates the same grammar: `${NAME}` or `${NAME:-default}`.
const REFERENCE = /\$\{([A-Z_][A-Z0-9_]*)(?::-([^}]*))?\}/g

// A `publicEnv` entry the site may go without: `${NAME:-}`, the empty-default reference.
const OPTIONAL = /^\$\{([A-Z_][A-Z0-9_]*):-\}$/

/**
 * Resolve a site's rewrites and public env against `env` (`process.env` in `next.config.ts`).
 * A variable is the environment's value when it is set and non-empty, else its `envDefaults`
 * entry, else the reference's inline `:-default`; with none of them, it throws, naming the
 * variable and where it was used. A `publicEnv` name with no value anywhere throws the same
 * way — a client bundle inlining `undefined` is the failure it would otherwise be — unless the
 * site wrote it `${NAME:-}`, which is how it says the variable is optional; that one is left out.
 */
export function frameNext(site: FrameNextSite, env: Env): FrameNextResult {
  const resolving: string[] = []

  function lookup(name: string): string | undefined {
    const own = env[name]
    if (own !== undefined && own !== '') return own
    const fallback = site.envDefaults[name]
    if (fallback === undefined) return undefined
    if (resolving.includes(name)) {
      throw new Error(`site.json: envDefaults has a cycle: ${[...resolving, name].join(' -> ')}`)
    }
    resolving.push(name)
    try {
      return fromDefault(name, fallback)
    } finally {
      resolving.pop()
    }
  }

  function fromDefault(name: string, fallback: FrameEnvDefault): string | undefined {
    const where = `envDefaults.${name}`
    if (typeof fallback === 'string') return substitute(fallback, where)
    return choose(fallback, where)
  }

  function choose(fallback: FrameEnvChoice<string | FrameEnvChoice<string>>, where: string): string {
    const selector = lookup(fallback.by)
    const chosen = selector === undefined ? undefined : fallback.values[selector]
    if (chosen !== undefined) return substitute(chosen, where)
    if (fallback.local !== undefined && !env.VERCEL) {
      return typeof fallback.local === 'string'
        ? substitute(fallback.local, where)
        : choose(fallback.local, `${where}.local`)
    }
    const known = Object.keys(fallback.values).join(', ')
    const found = selector === undefined ? 'is unset' : `is '${selector}'`
    throw new Error(
      `site.json: ${where}: ${fallback.by} ${found}, which names none of its values (${known})` +
        (fallback.local === undefined ? '' : '; `local` applies only off Vercel'),
    )
  }

  // A value joined to a path (`${API}/auth`) loses its trailing slashes, so `API=https://x/`
  // gives `https://x/auth`, not `https://x//auth`. A value with no path after it is left whole.
  function substitute(text: string, where: string): string {
    return text.replace(REFERENCE, (whole, name: string, inline: string | undefined, at: number) => {
      const joined = text.charAt(at + whole.length) === '/'
      const trim = (value: string): string => (joined ? value.replace(/\/+$/, '') : value)
      const value = lookup(name)
      if (value !== undefined) return trim(value)
      if (inline !== undefined) return trim(inline)
      throw new Error(
        `site.json: \${${name}} in ${where} is unset, with no envDefaults entry and no inline default (\${${name}:-…})`,
      )
    })
  }

  const rewrites = site.rewrites.map((rewrite, i) => ({
    source: rewrite.source,
    destination: substitute(rewrite.destination, `rewrites[${i}].destination`),
  }))
  const publicEnv: Record<string, string> = {}
  site.publicEnv.forEach((entry, i) => {
    const optional = OPTIONAL.exec(entry)
    const name = optional?.[1] ?? entry
    const value = lookup(name)
    if (value !== undefined) {
      publicEnv[name] = value
    } else if (optional === null) {
      throw new Error(
        `site.json: ${name} in publicEnv[${i}] is unset, with no envDefaults entry; ` +
          `write it \${${name}:-} if the site can go without it`,
      )
    }
  })
  // Copied rule by rule: the site's lists are readonly and Next's are not.
  const headers = (site.headers ?? []).map((rule) => ({
    source: rule.source,
    headers: rule.headers.map((header) => ({ key: header.key, value: header.value })),
  }))
  const redirects = (site.redirects ?? []).map((rule) => ({ ...rule }))
  return { env: publicEnv, rewrites, headers, redirects }
}

/**
 * Put the theme's self-hosted faces under `<appDir>/public/fonts/`, when the site asks
 * (`themeFonts`). A site that inlines the theme's css itself — `AdhThemeStyle` does — names those
 * faces by absolute path, so the bytes must be on disk before Next collects `public/`, in every
 * mode; the config load is the one hook `next dev` and `next build` share. Fails the build when it
 * cannot copy them, as the themes package's copier does.
 */
export function frameThemeFonts(site: FrameNextSite, appDir: string): void {
  if (site.themeFonts === true) materializeThemeFonts(appDir)
}

/**
 * The build's identity for the client, when the site asks (`buildIdentity`): the app's `VERSION`
 * file as `NEXT_PUBLIC_ADH_SITE_VERSION` and the commit (Vercel's, Railway's, else `git rev-parse
 * HEAD`) as `NEXT_PUBLIC_ADH_RELEASE` — what the fleet footer shows and error reports carry. Either
 * may be `''`: a missing VERSION file, or no commit to be had.
 */
export function frameBuildIdentity(site: FrameNextSite, appDir: string): Record<string, string> {
  if (site.buildIdentity !== true) return {}
  return { NEXT_PUBLIC_ADH_SITE_VERSION: readSiteVersion(appDir), NEXT_PUBLIC_ADH_RELEASE: commitSha() }
}
