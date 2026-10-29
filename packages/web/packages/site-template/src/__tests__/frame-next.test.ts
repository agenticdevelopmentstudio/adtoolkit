import { mkdtempSync, readdirSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { frameBuildIdentity, frameNext, frameThemeFonts } from '../frame-next'
import type { FrameNextSite } from '../frame-next'

const none: FrameNextSite = { rewrites: [], publicEnv: [], envDefaults: {} }

const tiers: FrameNextSite = {
  rewrites: [{ source: '/api/:path*', destination: '${API_BACKEND_URL}/:path*' }],
  publicEnv: ['NEXT_PUBLIC_AUTH_API_URL'],
  envDefaults: {
    API_BACKEND_URL: {
      by: 'DEPLOYMENT_ENV',
      values: { production: 'https://api.example', staging: 'https://staging.api.example' },
      local: 'https://staging.api.example',
    },
    NEXT_PUBLIC_AUTH_API_URL: '${API_BACKEND_URL}',
  },
}

describe('frameNext', () => {
  it('adds nothing for a site that declares nothing', () => {
    expect(frameNext(none, {})).toEqual({ env: {}, rewrites: [], headers: [], redirects: [] })
  })

  it('passes headers through literally, and treats a site that omits them as having none', () => {
    const headers = [
      {
        source: '/(.*)',
        headers: [
          { key: 'X-Frame-Options', value: 'SAMEORIGIN' },
          { key: 'X-Literal', value: '${NOT_A_REFERENCE}' },
        ],
      },
    ]
    expect(frameNext({ ...none, headers }, {}).headers).toEqual(headers)
    const { headers: _omitted, ...older } = { ...none, headers }
    expect(frameNext(older, {}).headers).toEqual([])
  })

  it("hands Next its own mutable header lists, not the site's readonly ones", () => {
    // `next.config.ts` passes the result straight to Next, whose `Header` type takes a mutable
    // `headers` array; the site's readonly lists are copied, rule by rule, so a rule's list can
    // be returned as Next's type and no edit to it reaches the site's config.
    const rule = { source: '/(.*)', headers: [{ key: 'X-Frame-Options', value: 'SAMEORIGIN' }] }
    const out = frameNext({ ...none, headers: [rule] }, {}).headers
    expect(out[0]).not.toBe(rule)
    expect(out[0].headers).not.toBe(rule.headers)
    expect(out[0].headers[0]).not.toBe(rule.headers[0])
  })

  it('passes redirects through literally, as Next lists, and treats a site that omits them as having none', () => {
    const redirects = [
      { source: '/old/:rest*', destination: '/new', permanent: false },
      { source: '/a', destination: '/${NOT_A_REFERENCE}', permanent: true },
    ]
    const out = frameNext({ ...none, redirects }, {}).redirects
    expect(out).toEqual(redirects)
    expect(out[0]).not.toBe(redirects[0])
    expect(frameNext(none, {}).redirects).toEqual([])
  })

  it('substitutes a variable from the environment into a destination', () => {
    const site: FrameNextSite = { ...none, rewrites: [{ source: '/api/:path*', destination: '${BACKEND}/:path*' }] }
    expect(frameNext(site, { BACKEND: 'https://b.example' }).rewrites).toEqual([
      { source: '/api/:path*', destination: 'https://b.example/:path*' },
    ])
  })

  it('takes the inline default when the variable is unset or empty', () => {
    const site: FrameNextSite = { ...none, rewrites: [{ source: '/a', destination: '${BACKEND:-https://d.example}/a' }] }
    expect(frameNext(site, {}).rewrites[0]?.destination).toBe('https://d.example/a')
    expect(frameNext(site, { BACKEND: '' }).rewrites[0]?.destination).toBe('https://d.example/a')
  })

  it('fails loudly, naming the variable and the rewrite, when a variable is unset with no default', () => {
    const site: FrameNextSite = { ...none, rewrites: [{ source: '/api/:path*', destination: '${BACKEND}/:path*' }] }
    expect(() => frameNext(site, {})).toThrow(/BACKEND.*rewrites\[0\]/s)
  })

  it('picks an envDefaults value by another variable', () => {
    const result = frameNext(tiers, { DEPLOYMENT_ENV: 'production', VERCEL: '1' })
    expect(result.rewrites[0]?.destination).toBe('https://api.example/:path*')
    expect(result.env).toEqual({ NEXT_PUBLIC_AUTH_API_URL: 'https://api.example' })
  })

  it('lets the environment override an envDefaults entry', () => {
    const result = frameNext(tiers, {
      DEPLOYMENT_ENV: 'production',
      API_BACKEND_URL: 'http://127.0.0.1:9',
      NEXT_PUBLIC_AUTH_API_URL: 'https://as.example',
    })
    expect(result.rewrites[0]?.destination).toBe('http://127.0.0.1:9/:path*')
    expect(result.env.NEXT_PUBLIC_AUTH_API_URL).toBe('https://as.example')
  })

  it('falls back to `local` off Vercel when the selector names no value', () => {
    expect(frameNext(tiers, {}).rewrites[0]?.destination).toBe('https://staging.api.example/:path*')
    expect(frameNext(tiers, { DEPLOYMENT_ENV: 'nope' }).env.NEXT_PUBLIC_AUTH_API_URL).toBe(
      'https://staging.api.example',
    )
  })

  it('never uses `local` on Vercel: an unknown selector there fails the build', () => {
    expect(() => frameNext(tiers, { VERCEL: '1', DEPLOYMENT_ENV: 'qa' })).toThrow(/DEPLOYMENT_ENV.*'qa'/s)
    expect(() => frameNext(tiers, { VERCEL: '1' })).toThrow(/API_BACKEND_URL/)
  })

  it('passes a public variable through from the environment', () => {
    const site: FrameNextSite = { ...none, publicEnv: ['NEXT_PUBLIC_A'] }
    expect(frameNext(site, { NEXT_PUBLIC_A: 'a' }).env).toEqual({ NEXT_PUBLIC_A: 'a' })
  })

  it('fails loudly, naming the variable, when a public variable resolves to nothing', () => {
    const site: FrameNextSite = { ...none, publicEnv: ['NEXT_PUBLIC_A', 'NEXT_PUBLIC_B'] }
    expect(() => frameNext(site, { NEXT_PUBLIC_A: 'a' })).toThrow(/NEXT_PUBLIC_B.*publicEnv\[1\]/s)
  })

  it('leaves out an optional public variable, written `${NAME:-}`, when it resolves to nothing', () => {
    const site: FrameNextSite = { ...none, publicEnv: ['NEXT_PUBLIC_A', '${NEXT_PUBLIC_B:-}'] }
    expect(frameNext(site, { NEXT_PUBLIC_A: 'a' }).env).toEqual({ NEXT_PUBLIC_A: 'a' })
    expect(frameNext(site, { NEXT_PUBLIC_A: 'a', NEXT_PUBLIC_B: 'b' }).env).toEqual({
      NEXT_PUBLIC_A: 'a',
      NEXT_PUBLIC_B: 'b',
    })
  })

  it('drops a trailing slash from a value joined to a path, so the join has one slash', () => {
    const site: FrameNextSite = {
      ...none,
      rewrites: [{ source: '/api/:path*', destination: '${BACKEND}/auth/:path*' }],
    }
    expect(frameNext(site, { BACKEND: 'https://b.example/' }).rewrites[0]?.destination).toBe(
      'https://b.example/auth/:path*',
    )
    expect(frameNext(site, { BACKEND: 'https://b.example//' }).rewrites[0]?.destination).toBe(
      'https://b.example/auth/:path*',
    )
  })

  it('keeps a value whole where no path follows it', () => {
    const site: FrameNextSite = { ...none, publicEnv: ['NEXT_PUBLIC_A'], envDefaults: { NEXT_PUBLIC_A: '${B}' } }
    expect(frameNext(site, { B: 'https://b.example/' }).env.NEXT_PUBLIC_A).toBe('https://b.example/')
  })

  it('chooses `local` by a second variable: the deploy tier on Vercel, the build mode off it', () => {
    const twoAxis: FrameNextSite = {
      rewrites: [{ source: '/api/:path*', destination: '${API_BACKEND_URL}/:path*' }],
      publicEnv: [],
      envDefaults: {
        API_BACKEND_URL: {
          by: 'DEPLOYMENT_ENV',
          values: { production: 'https://api.example' },
          local: { by: 'NODE_ENV', values: { production: 'https://api.example' }, local: 'http://localhost:3000' },
        },
      },
    }
    const dest = (env: Record<string, string>): string | undefined => frameNext(twoAxis, env).rewrites[0]?.destination
    expect(dest({ VERCEL: '1', DEPLOYMENT_ENV: 'production' })).toBe('https://api.example/:path*')
    expect(dest({ NODE_ENV: 'production' })).toBe('https://api.example/:path*')
    expect(dest({ NODE_ENV: 'development' })).toBe('http://localhost:3000/:path*')
    expect(dest({})).toBe('http://localhost:3000/:path*')
    expect(() => dest({ VERCEL: '1', DEPLOYMENT_ENV: 'qa' })).toThrow(/DEPLOYMENT_ENV.*'qa'/s)
  })

  it('refuses an envDefaults cycle rather than recursing', () => {
    const site: FrameNextSite = { ...none, publicEnv: ['A'], envDefaults: { A: '${B}', B: '${A}' } }
    expect(() => frameNext(site, {})).toThrow(/cycle.*A.*B/s)
  })
})

describe('frameThemeFonts', () => {
  const dirs: string[] = []
  function appDir(): string {
    const dir = mkdtempSync(path.join(tmpdir(), 'frame-fonts-'))
    dirs.push(dir)
    return dir
  }
  afterEach(() => {
    for (const dir of dirs.splice(0)) rmSync(dir, { recursive: true, force: true })
  })

  it("copies the theme's faces under the app's public/fonts when the site asks", () => {
    const app = appDir()
    frameThemeFonts({ ...none, themeFonts: true }, app)
    const [revision] = readdirSync(path.join(app, 'public', 'fonts'))
    expect(revision).toBeDefined()
    const faces = readdirSync(path.join(app, 'public', 'fonts', revision ?? ''))
    expect(faces.some((face) => face.endsWith('.woff2'))).toBe(true)
  })

  it('writes nothing for a site that does not', () => {
    const app = appDir()
    frameThemeFonts(none, app)
    expect(readdirSync(app)).toEqual([])
  })
})

describe('frameBuildIdentity', () => {
  const dirs: string[] = []
  afterEach(() => {
    vi.unstubAllEnvs()
    for (const dir of dirs.splice(0)) rmSync(dir, { recursive: true, force: true })
  })

  it("names the build by the app's VERSION file and the commit, when the site asks", () => {
    const app = mkdtempSync(path.join(tmpdir(), 'frame-identity-'))
    dirs.push(app)
    writeFileSync(path.join(app, 'VERSION'), '1.0.157\n')
    vi.stubEnv('VERCEL_GIT_COMMIT_SHA', 'abc123')
    expect(frameBuildIdentity({ ...none, buildIdentity: true }, app)).toEqual({
      NEXT_PUBLIC_ADH_SITE_VERSION: '1.0.157',
      NEXT_PUBLIC_ADH_RELEASE: 'abc123',
    })
  })

  it('adds nothing for a site that does not', () => {
    expect(frameBuildIdentity(none, tmpdir())).toEqual({})
  })
})
