import { render } from '@testing-library/react'
import type { ReactElement } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { LandingPage, LandingSection } from '@agenticdevelopertoolkit/landing'
import { LandingFrame } from '../landing-frame'
import { FrameFooter } from '../footer'
import { SiteChrome } from '../chrome'
import { frameMetadata, frameRobots, frameSiteUrl, frameSitemap, frameViewport } from '../frame-metadata'
import type { FrameConfig, FrameCopy, SlotMap } from '../types'

const hero: LandingPage['hero'] = {
  headline: 'Cook the thing',
  tagline: 'One line under it.',
  blocks: [
    { kind: 'Cta', buttons: [{ href: '/downloads', label: 'Download' }] },
    { kind: 'Trust', items: ['macOS 15', 'Free'] },
  ],
}

function section(id: string, eyebrow: string, extra: Partial<LandingSection> = {}): LandingSection {
  return {
    id,
    eyebrow,
    title: `${eyebrow} title`,
    blocks: [{ kind: 'Lede', children: `${eyebrow} lede` }],
    ...extra,
  }
}

const empty: LandingPage = { hero, sections: [] }
const two: LandingPage = { hero, sections: [section('one', 'One'), section('two', 'Two')] }
const noSlots: SlotMap = { bands: {} }
const mark = <img src="/glyph.svg" alt="" />

const copy: FrameCopy = {
  name: 'Kitchen',
  description: 'A kitchen.',
  brand: 'Kitchen',
  markAlt: 'The Kitchen mark',
  ogImageAlt: 'Kitchen',
  people: { author: 'Mike', creator: 'Mike', publisher: 'Studio' },
  contact: { email: 'hello@example.com' },
  drawer: { hello: 'Say hello', byline: { html: 'by <b>Mike</b>' } },
  footer: { madeBy: 'Made by Mike', copyright: '© 2026', trademark: 'Mac is a trademark' },
}

const config: FrameConfig = {
  siteUrl: 'https://kitchen.example',
  mark: { src: '/glyph.svg', shape: 'glyph' },
  themeColor: '#0b0a09',
  ogImage: '/og.png',
  drawerExtra: [],
  sitemap: [],
}

describe('LandingFrame', () => {
  it('renders the hero alone when the page has no sections', () => {
    const { container } = render(<LandingFrame page={empty} slots={noSlots} mark={mark} />)
    const main = container.querySelector('main.lp-flow')
    expect(main).not.toBeNull()
    expect(main!.querySelector('#top.lp-hero-flow.lp-hero-flow--fill')).not.toBeNull()
    expect(main!.querySelectorAll('.lp-band')).toHaveLength(0)
    expect(main!.querySelector('h1')!.textContent).toBe('Cook the thing')
  })

  it('wraps the hero meta in .st-hero-meta', () => {
    const { container } = render(<LandingFrame page={empty} slots={noSlots} mark={mark} />)
    const meta = container.querySelector('.lp-hero-meta .st-hero-meta')
    expect(meta).not.toBeNull()
    expect(meta!.textContent).toBe('macOS 15 · Free')
  })

  it('draws a hero status pill in the actions row, before the buttons', () => {
    const page: LandingPage = {
      hero: { ...hero, blocks: [...hero.blocks, { kind: 'StatusPill', children: 'Coming soon' }] },
      sections: [],
    }
    const { container } = render(<LandingFrame page={page} slots={noSlots} mark={mark} />)
    const row = container.querySelector('.lp-hero-actions')!
    expect(row.firstElementChild!.className).toContain('lp-status')
    expect(row.firstElementChild!.textContent).toBe('Coming soon')
    expect(row.querySelector('.lp-btn--ghost')).not.toBeNull()
  })

  it('alternates band tones soft, dark, with the Reveal inside each band', () => {
    const { container } = render(<LandingFrame page={two} slots={noSlots} mark={mark} />)
    const bands = Array.from(container.querySelectorAll('.lp-band'))
    expect(bands.map((b) => b.id)).toEqual(['one', 'two'])
    expect(bands[0]!.className).toContain('lp-band--soft')
    expect(bands[1]!.className).toContain('lp-band--dark')
    for (const band of bands) {
      const reveal = band.querySelector('.lp-reveal')
      expect(reveal).not.toBeNull()
      expect(reveal!.closest('.lp-band')).toBe(band)
      expect(reveal!.querySelector('.lp-head')).not.toBeNull()
    }
  })

  it('omits the Head of a section whose block carries its heading', () => {
    const page: LandingPage = {
      hero,
      sections: [section('one', 'One', { headingInBlock: true })],
    }
    const { container } = render(<LandingFrame page={page} slots={noSlots} mark={mark} />)
    expect(container.querySelector('#one .lp-head')).toBeNull()
  })

  it('lets a band slot replace only that band’s blocks, keeping its Head', () => {
    function Custom(): ReactElement {
      return <p className="custom">custom body</p>
    }
    const { container } = render(
      <LandingFrame page={two} slots={{ bands: { two: Custom } }} mark={mark} />,
    )
    const one = container.querySelector('#one')!
    const second = container.querySelector('#two')!
    expect(one.textContent).toContain('One lede')
    expect(one.querySelector('.custom')).toBeNull()
    expect(second.querySelector('.custom')).not.toBeNull()
    expect(second.textContent).not.toContain('Two lede')
    expect(second.querySelector('.lp-head')!.textContent).toContain('Two')
  })

  it('refuses a band slot that names no section', () => {
    function Custom(): ReactElement {
      return <p>x</p>
    }
    expect(() =>
      render(<LandingFrame page={two} slots={{ bands: { nope: Custom } }} mark={mark} />),
    ).toThrow(/no section 'nope'/)
  })

  it('keeps the #top hero frame around a hero slot', () => {
    function Hero(): ReactElement {
      return <div className="my-hero">mine</div>
    }
    const { container } = render(<LandingFrame page={empty} slots={{ hero: Hero, bands: {} }} mark={mark} />)
    const top = container.querySelector('#top')!
    expect(top.className).toContain('lp-hero-flow')
    expect(top.className).toContain('lp-hero-flow--fill')
    expect(top.querySelector('.my-hero')).not.toBeNull()
    expect(top.querySelector('h1')).toBeNull()
  })

  it('renders afterHero between the hero and the first band', () => {
    function After(): ReactElement {
      return <div className="after">after</div>
    }
    const { container } = render(
      <LandingFrame page={two} slots={{ afterHero: After, bands: {} }} mark={mark} />,
    )
    const kids = Array.from(container.querySelector('main')!.children)
    expect(kids.map((k) => k.id || k.className)).toEqual([
      'top',
      'after',
      'one',
      'two',
    ])
  })
})

describe('SiteChrome', () => {
  it('lists only Home when the page has no sections', () => {
    const { container } = render(<SiteChrome copy={copy} page={empty} extra={[]} />)
    const links = Array.from(container.querySelectorAll('nav a:not([href^="mailto:"])'))
    expect(links.map((a) => [a.getAttribute('href'), a.textContent])).toEqual([['/#top', 'Home']])
  })

  it('lists Home, each section and the extra links, in that order', () => {
    const { container } = render(
      <SiteChrome copy={copy} page={two} extra={[{ href: '/downloads', label: 'Downloads' }]} />,
    )
    const links = Array.from(container.querySelectorAll('nav a:not([href^="mailto:"])'))
    expect(links.map((a) => a.getAttribute('href'))).toEqual(['/#top', '/#one', '/#two', '/downloads'])
  })

  it('puts the hello, the mail address and the byline in the drawer foot', () => {
    const { container } = render(<SiteChrome copy={copy} page={empty} extra={[]} />)
    const mail = container.querySelector('a[href="mailto:hello@example.com"]')
    expect(mail).not.toBeNull()
    const foot = mail!.parentElement!
    expect(foot.textContent).toBe('Say hellohello@example.comby Mike')
    expect(foot.querySelector('b')!.textContent).toBe('Mike')
  })
})

describe('FrameFooter', () => {
  it('renders the first line plain and the rest in <small>', () => {
    const { container } = render(<FrameFooter copy={copy} />)
    const foot = container.querySelector('footer.lp-site-foot')!
    const smalls = Array.from(foot.querySelectorAll('small')).map((s) => s.textContent)
    expect(smalls).toEqual(['© 2026', 'Mac is a trademark'])
    expect(foot.textContent!.startsWith('Made by Mike')).toBe(true)
    expect(foot.textContent).not.toMatch(/^<small>/)
  })

  it('renders nothing when the copy has no footer', () => {
    const { footer: _omit, ...bare } = copy
    const { container } = render(<FrameFooter copy={bare} />)
    expect(container.innerHTML).toBe('')
  })

  it('renders a footer slot inside the footer frame', () => {
    function Mine(): ReactElement {
      return <span className="mine">mine</span>
    }
    const { container } = render(<FrameFooter copy={copy} slot={Mine} />)
    expect(container.querySelector('footer.lp-site-foot .mine')).not.toBeNull()
    expect(container.querySelector('small')).toBeNull()
  })
})

describe('frame metadata helpers', () => {
  afterEach(() => {
    vi.unstubAllEnvs()
  })

  it('frameSiteUrl falls back to localhost on the given port when the env is empty', () => {
    vi.stubEnv('SITE_URL', '')
    vi.stubEnv('VERCEL_PROJECT_PRODUCTION_URL', '')
    expect(frameSiteUrl(5210)).toBe('http://localhost:5210')
  })

  it('frameSiteUrl falls back to localhost when the env is genuinely unset', () => {
    vi.stubEnv('SITE_URL', undefined)
    vi.stubEnv('VERCEL_PROJECT_PRODUCTION_URL', undefined)
    expect('SITE_URL' in process.env).toBe(false)
    expect('VERCEL_PROJECT_PRODUCTION_URL' in process.env).toBe(false)
    expect(frameSiteUrl(5210)).toBe('http://localhost:5210')
  })

  it('frameSiteUrl prefers SITE_URL, then the Vercel production host', () => {
    vi.stubEnv('VERCEL_PROJECT_PRODUCTION_URL', 'kitchen.vercel.app')
    vi.stubEnv('SITE_URL', '')
    expect(frameSiteUrl(5210)).toBe('https://kitchen.vercel.app')
    vi.stubEnv('SITE_URL', 'https://kitchen.example')
    expect(frameSiteUrl(5210)).toBe('https://kitchen.example')
  })

  it('robots allows crawling only in production', () => {
    vi.stubEnv('DEPLOYMENT_ENV', 'staging')
    expect(frameRobots(config).rules).toEqual([{ userAgent: '*', disallow: '/' }])
    vi.stubEnv('DEPLOYMENT_ENV', 'production')
    const robots = frameRobots(config)
    expect(robots.rules).toEqual([{ userAgent: '*', allow: '/' }])
    expect(robots.sitemap).toBe('https://kitchen.example/sitemap.xml')
  })

  const slashed: FrameConfig = { ...config, siteUrl: 'https://kitchen.example/', sitemap: ['/downloads'] }

  it('robots builds single-slash URLs from a siteUrl ending in /', () => {
    vi.stubEnv('DEPLOYMENT_ENV', 'production')
    const robots = frameRobots(slashed)
    expect(robots.sitemap).toBe('https://kitchen.example/sitemap.xml')
    expect(robots.host).toBe('https://kitchen.example')
  })

  it('sitemap builds single-slash URLs from a siteUrl ending in /', () => {
    expect(frameSitemap(slashed).map((entry) => entry.url)).toEqual([
      'https://kitchen.example',
      'https://kitchen.example/downloads',
    ])
  })

  it('frameMetadata takes its base and title from the config and copy', () => {
    const meta = frameMetadata({ ...copy, title: 'Kitchen — cook the thing' }, config)
    expect(meta.metadataBase?.href).toBe('https://kitchen.example/')
    expect(meta.title).toBe('Kitchen — cook the thing')
    expect(frameMetadata(copy, config).title).toBe('Kitchen')
  })

  it('frameViewport carries the theme color', () => {
    expect(frameViewport(config).themeColor).toBe('#0b0a09')
  })
})
