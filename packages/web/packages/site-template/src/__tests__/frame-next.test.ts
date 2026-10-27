import { describe, expect, it } from 'vitest'
import { frameNext } from '../frame-next'
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
    expect(frameNext(none, {})).toEqual({ env: {}, rewrites: [] })
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

  it('passes a public variable through from the environment, and leaves an unset one out', () => {
    const site: FrameNextSite = { ...none, publicEnv: ['NEXT_PUBLIC_A', 'NEXT_PUBLIC_B'] }
    expect(frameNext(site, { NEXT_PUBLIC_A: 'a' }).env).toEqual({ NEXT_PUBLIC_A: 'a' })
  })

  it('refuses an envDefaults cycle rather than recursing', () => {
    const site: FrameNextSite = { ...none, publicEnv: ['A'], envDefaults: { A: '${B}', B: '${A}' } }
    expect(() => frameNext(site, {})).toThrow(/cycle.*A.*B/s)
  })
})
