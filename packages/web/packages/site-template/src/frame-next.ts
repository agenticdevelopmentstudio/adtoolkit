// The build-time half of `site.json`: its `rewrites`, `publicEnv` and `envDefaults`, resolved
// against the environment `next build` runs in. Published as `@agenticdevelopertoolkit/site-template/next`
// and imported by the skeleton's `next.config.ts` — never by a page, so nothing here reaches a
// bundle. The assembler has already checked every `${…}` is well formed; what it cannot know is
// the environment, so an unset variable with no default fails the build here, by name.

/** One `site.json` rewrite: Next's `{ source, destination }`, the destination substituted. */
export interface FrameRewrite {
  source: string
  destination: string
}

/**
 * A variable's fallback when the environment leaves it unset or empty: a string (itself
 * substituted), or a value chosen by another variable — `values[env[by]]` — with `local` for a
 * build off Vercel whose selector names no value. On Vercel a selector naming no value fails the
 * build, so a misspelt tier is never quietly served `local`'s backend.
 */
export type FrameEnvDefault = string | { by: string; values: Readonly<Record<string, string>>; local?: string }

/** What the assembler writes to `src/site/next.ts` from `site.json`. */
export interface FrameNextSite {
  rewrites: readonly FrameRewrite[]
  /** `NAME`, which must resolve, or `${NAME:-}`, which is left out when it does not. */
  publicEnv: readonly string[]
  envDefaults: Readonly<Record<string, FrameEnvDefault>>
}

/** The resolved pieces `next.config.ts` merges into its config. */
export interface FrameNextResult {
  env: Record<string, string>
  rewrites: FrameRewrite[]
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
    const selector = lookup(fallback.by)
    const chosen = selector === undefined ? undefined : fallback.values[selector]
    if (chosen !== undefined) return substitute(chosen, where)
    if (fallback.local !== undefined && !env.VERCEL) return substitute(fallback.local, where)
    const known = Object.keys(fallback.values).join(', ')
    const found = selector === undefined ? 'is unset' : `is '${selector}'`
    throw new Error(
      `site.json: ${where}: ${fallback.by} ${found}, which names none of its values (${known})` +
        (fallback.local === undefined ? '' : '; `local` applies only off Vercel'),
    )
  }

  function substitute(text: string, where: string): string {
    return text.replace(REFERENCE, (_whole, name: string, inline: string | undefined) => {
      const value = lookup(name)
      if (value !== undefined) return value
      if (inline !== undefined) return inline
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
  return { env: publicEnv, rewrites }
}
