import { render } from '@testing-library/react'
import type { ReactElement } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { LandingPage, LandingSection } from '@agenticdevelopertoolkit/landing'
import { LandingFrame } from '../landing-frame'
import { FrameFooter } from '../footer'
import { SiteChrome } from '../chrome'
import { FrameMark } from '../frame-mark'
import { FrameBand } from '../frame-band'
import { frameShot } from '../frame-shot'
import { FrameZoomGuard } from '../frame-zoom'
import { FrameNotFound } from '../not-found'
import * as barrel from '../index'
import {
  frameMetadata,
  frameRobots,
  frameSiteUrl,
  frameSitemap,
  frameViewport,
} from '../frame-metadata'
import { frameNotFoundMetadata } from '../not-found'
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
  nav: { home: 'Home', extra: { downloads: 'Downloads' } },
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

  it('draws a hero Shot below the composition, in the hero frame', () => {
    const page: LandingPage = {
      hero: { ...hero, blocks: [...hero.blocks, { kind: 'Shot', title: 'App', caption: 'The main window' }] },
      sections: [],
    }
    const { container } = render(<LandingFrame page={page} slots={noSlots} mark={mark} />)
    const shot = container.querySelector('#top .lp-hero-shot .lp-shot')
    expect(shot).not.toBeNull()
    expect(shot!.textContent).toContain('The main window')
  })

  it('words every pending shot, hero and band alike, with the copy\'s label when it gives one', () => {
    const shot = { kind: 'Shot' as const, title: 'App', caption: 'Soon' }
    const page: LandingPage = {
      hero: { ...hero, blocks: [...hero.blocks, shot] },
      sections: [section('one', 'One', { blocks: [shot] })],
    }
    const labels = (node: ReactElement): string[] =>
      Array.from(render(node).container.querySelectorAll('.lp-shot__placeholder')).map((p) => p.textContent ?? '')
    expect(labels(<LandingFrame page={page} slots={noSlots} mark={mark} pendingLabel="Screenshot pending" />)).toEqual([
      'Screenshot pendingSoon',
      'Screenshot pendingSoon',
    ])
    expect(labels(<LandingFrame page={page} slots={noSlots} mark={mark} />)).toEqual([
      'Screenshot coming soonSoon',
      'Screenshot coming soonSoon',
    ])
  })

  it('gives a band the look the site configures, and the rest their alternation', () => {
    const three: LandingPage = { hero, sections: [...two.sections, section('three', 'Three')] }
    const { container } = render(
      <LandingFrame
        page={three}
        slots={noSlots}
        mark={mark}
        looks={{ two: { tone: 'paper' }, three: { seam: false } }}
      />,
    )
    const [one, second, third] = Array.from(container.querySelectorAll('.lp-band'))
    expect(one!.className).toContain('lp-band--soft')
    expect(one!.className).toContain('lp-band--seam')
    expect(second!.className).toContain('lp-band--paper')
    expect(second!.className).toContain('lp-band--seam')
    // A seam alone keeps the alternation's tone.
    expect(third!.className).toContain('lp-band--soft')
    expect(third!.className).not.toContain('lp-band--seam')
  })

  it('refuses a band look that names no section', () => {
    expect(() =>
      render(<LandingFrame page={two} slots={noSlots} mark={mark} looks={{ nope: { tone: 'paper' } }} />),
    ).toThrow(/looks names no section 'nope'/)
  })

  it('omits the Head of a section whose block carries its heading', () => {
    const page: LandingPage = {
      hero,
      sections: [section('one', 'One', { headingInBlock: true })],
    }
    const { container } = render(<LandingFrame page={page} slots={noSlots} mark={mark} />)
    expect(container.querySelector('#one .lp-head')).toBeNull()
  })

  it('heads a section with no title by its eyebrow, read once, as a visually hidden h2', () => {
    const page: LandingPage = { hero, sections: [section('one', 'One', { title: undefined })] }
    const { container } = render(<LandingFrame page={page} slots={noSlots} mark={mark} />)
    const head = container.querySelector('#one .lp-head')!
    const shown = head.querySelector('.lp-eyebrow > span[aria-hidden="true"]')
    expect(shown!.textContent).toBe('One')
    const h2 = head.querySelector('h2')!
    expect(h2.className).toBe('st-sr-only')
    expect(h2.textContent).toBe('One')
  })

  it('keeps a titled section\'s eyebrow plain and its title the visible h2', () => {
    const { container } = render(<LandingFrame page={two} slots={noSlots} mark={mark} />)
    const head = container.querySelector('#one .lp-head')!
    expect(head.querySelector('[aria-hidden]')).toBeNull()
    expect(head.querySelector('.st-sr-only')).toBeNull()
    expect(head.querySelector('h2')!.textContent).toBe('One title')
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

  it('refuses a {slot} section that no band slot fills', () => {
    const page: LandingPage = {
      hero,
      sections: [section('one', 'One'), section('two', 'Two', { slot: true, blocks: [] })],
    }
    expect(() => render(<LandingFrame page={page} slots={noSlots} mark={mark} />)).toThrow(
      /section 'two' is a \{slot\} band and slots\.bands has no 'two'/,
    )
  })

  it('fills a {slot} section from its band slot', () => {
    function Custom(): ReactElement {
      return <p className="custom">custom body</p>
    }
    const page: LandingPage = {
      hero,
      sections: [section('two', 'Two', { slot: true, blocks: [], title: undefined })],
    }
    const { container } = render(<LandingFrame page={page} slots={{ bands: { two: Custom } }} mark={mark} />)
    expect(container.querySelector('#two .custom')).not.toBeNull()
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
      <SiteChrome copy={copy} page={two} extra={[{ href: '/downloads', nav: 'downloads' }]} />,
    )
    const links = Array.from(container.querySelectorAll('nav a:not([href^="mailto:"])'))
    expect(links.map((a) => a.getAttribute('href'))).toEqual(['/#top', '/#one', '/#two', '/downloads'])
  })

  it('words an extra row from the copy\'s nav.extra, not the config', () => {
    const login: FrameCopy = { ...copy, nav: { home: 'Home', extra: { login: 'Sign in' } } }
    const { container } = render(<SiteChrome copy={login} page={empty} extra={[{ href: '/home', nav: 'login' }]} />)
    const links = Array.from(container.querySelectorAll('nav a:not([href^="mailto:"])'))
    expect(links.map((a) => [a.getAttribute('href'), a.textContent])).toEqual([
      ['/#top', 'Home'],
      ['/home', 'Sign in'],
    ])
  })

  it('refuses an extra row whose label the copy does not word', () => {
    expect(() =>
      render(<SiteChrome copy={copy} page={empty} extra={[{ href: '/home', nav: 'login' }]} />),
    ).toThrow(/'login'.*nav\.extra/s)
  })

  it('puts the hello, the mail address and the byline in the drawer foot', () => {
    const { container } = render(<SiteChrome copy={copy} page={empty} extra={[]} />)
    const mail = container.querySelector('a[href="mailto:hello@example.com"]')
    expect(mail).not.toBeNull()
    const foot = mail!.parentElement!
    expect(foot.textContent).toBe('Say hellohello@example.comby Mike')
    expect(foot.querySelector('b')!.textContent).toBe('Mike')
  })

  it('ends the drawer foot at the mail address when the copy words no byline', () => {
    const hello: FrameCopy = { ...copy, drawer: { hello: 'Say hello:' } }
    const { container } = render(<SiteChrome copy={hello} page={empty} extra={[]} />)
    const foot = container.querySelector('a[href="mailto:hello@example.com"]')!.parentElement!
    expect(foot.textContent).toBe('Say hello:hello@example.com')
    expect(foot.lastElementChild!.tagName).toBe('A')
  })

  it('takes the Home row\'s label from the copy, not the frame', () => {
    const start: FrameCopy = { ...copy, nav: { home: 'Start' } }
    const { container } = render(<SiteChrome copy={start} page={empty} extra={[]} />)
    const links = Array.from(container.querySelectorAll('nav a:not([href^="mailto:"])'))
    expect(links.map((a) => [a.getAttribute('href'), a.textContent])).toEqual([['/#top', 'Start']])
  })

  it('adds a contact row, mailing the copy\'s address, last, when the copy words one', () => {
    const withContact: FrameCopy = { ...copy, nav: { home: 'Home', contact: 'Contact', extra: { downloads: 'Downloads' } } }
    const { container } = render(
      <SiteChrome copy={withContact} page={two} extra={[{ href: '/downloads', nav: 'downloads' }]} />,
    )
    const rows = Array.from(container.querySelectorAll('nav a')).filter((a) => a.textContent !== 'hello@example.com')
    expect(rows.map((a) => [a.getAttribute('href'), a.textContent])).toEqual([
      ['/#top', 'Home'],
      ['/#one', 'One'],
      ['/#two', 'Two'],
      ['/downloads', 'Downloads'],
      ['mailto:hello@example.com', 'Contact'],
    ])
  })

  it('puts the copy\'s action in the bar as a ghost button', () => {
    const acting: FrameCopy = { ...copy, nav: { home: 'Home', action: { label: 'It’s free', href: '/#price' } } }
    const { container } = render(<SiteChrome copy={acting} page={empty} extra={[]} />)
    const action = container.querySelector('a.lp-btn.lp-btn--ghost')
    expect(action).not.toBeNull()
    expect(action!.getAttribute('href')).toBe('/#price')
    expect(action!.textContent).toBe('It’s free')
  })

  it('has no action when the copy words none', () => {
    const { container } = render(<SiteChrome copy={copy} page={empty} extra={[]} />)
    expect(container.querySelector('a.lp-btn')).toBeNull()
  })

  it('has no contact row when the copy words none', () => {
    const { container } = render(<SiteChrome copy={copy} page={empty} extra={[]} />)
    const mail = Array.from(container.querySelectorAll('a[href^="mailto:"]'))
    expect(mail.map((a) => a.textContent)).toEqual(['hello@example.com'])
  })
})

describe('FrameZoomGuard', () => {
  function script(element: ReactElement): string {
    const { container } = render(element)
    return Array.from(container.querySelectorAll('script'))
      .map((s) => s.innerHTML)
      .join('\n')
  }

  it('strips maximum-scale off iOS and does nothing else', () => {
    const body = script(<FrameZoomGuard />)
    expect(body).toContain('maximum-scale')
    expect(body).not.toContain('data-smooth')
    expect(body).not.toContain('data-snap')
  })

  it('ships from the server barrel', () => {
    expect(barrel.FrameZoomGuard).toBe(FrameZoomGuard)
  })

  it('is the only zoom restore: LandingFrame leaves it to the root layout', () => {
    expect(script(<LandingFrame page={empty} slots={noSlots} mark={mark} />)).not.toContain('maximum-scale')
  })
})

describe('FrameMark', () => {
  it('renders the configured mark in the frame\'s classes', () => {
    const { container } = render(<FrameMark config={config} alt="The Kitchen mark" />)
    const img = container.querySelector('img')!
    expect(img.className).toBe('st-mark st-mark--glyph')
    expect(img.getAttribute('src')).toBe('/glyph.svg')
    expect(img.getAttribute('alt')).toBe('The Kitchen mark')
  })

  it('follows the config\'s shape', () => {
    const icon: FrameConfig = { ...config, mark: { src: '/app-icon.png', shape: 'app-icon' } }
    const { container } = render(<FrameMark config={icon} alt="" />)
    expect(container.querySelector('img')!.className).toBe('st-mark st-mark--app-icon')
  })

  it('ships from the server barrel', () => {
    expect(barrel.FrameMark).toBe(FrameMark)
  })
})

describe('frameShot', () => {
  const placeholder = (node: ReactElement): string =>
    render(node).container.querySelector('.lp-shot__placeholder')?.textContent ?? '(none)'

  it("words a slot's pending shot with the site's word, given once", () => {
    const SiteShot = frameShot('Screenshot pending')
    expect(placeholder(<SiteShot title="App" caption="Soon" />)).toBe('Screenshot pendingSoon')
  })

  it("words it as the frame's own bands do when the site has no word", () => {
    const SiteShot = frameShot(undefined)
    const shot = { kind: 'Shot' as const, title: 'App', caption: 'Soon' }
    const page: LandingPage = { hero, sections: [section('one', 'One', { blocks: [shot] })] }
    expect(placeholder(<SiteShot title="App" caption="Soon" />)).toBe(
      placeholder(<LandingFrame page={page} slots={noSlots} mark={mark} />),
    )
  })

  it('lets one shot word itself, and draws media as given', () => {
    const SiteShot = frameShot('Screenshot pending')
    expect(placeholder(<SiteShot title="App" caption="Soon" pendingLabel="Later" />)).toBe('LaterSoon')
    const { container } = render(<SiteShot title="App" caption="Soon" media={<img alt="The app" />} />)
    expect(container.querySelector('.lp-shot img')!.getAttribute('alt')).toBe('The app')
    expect(container.querySelector('.lp-shot__placeholder')).toBeNull()
    expect(container.querySelector('.lp-shot__name')!.textContent).toBe('App')
  })

  it('ships from the server barrel', () => {
    expect(barrel.frameShot).toBe(frameShot)
  })
})

describe('FrameBand', () => {
  it('is a band with its Reveal inside, as every band of / is', () => {
    const { container } = render(
      <FrameBand id="install" tone="soft">
        <p>Body</p>
      </FrameBand>,
    )
    const band = container.querySelector('section.lp-band')!
    expect(band.id).toBe('install')
    expect(band.className).toContain('lp-band--soft')
    expect(band.className).toContain('lp-band--seam')
    // Inside, not around: a transformed wrapper outside the band breaks the seam's stacking.
    const reveal = band.querySelector('.lp-reveal')!
    expect(reveal.closest('.lp-band')).toBe(band)
    expect(reveal.querySelector('p')!.textContent).toBe('Body')
  })

  it('passes a dropped seam through', () => {
    const { container } = render(
      <FrameBand id="x" tone="paper" seam={false}>
        <p />
      </FrameBand>,
    )
    expect(container.querySelector('.lp-band')!.className).not.toContain('lp-band--seam')
  })

  it('is what the frame draws each band with, and ships from the server barrel', () => {
    const { container } = render(<LandingFrame page={two} slots={noSlots} mark={mark} />)
    const ours = render(
      <FrameBand id="one" tone="soft">
        <span />
      </FrameBand>,
    ).container.querySelector('.lp-band')!
    expect(container.querySelector('#one')!.className).toBe(ours.className)
    expect(barrel.FrameBand).toBe(FrameBand)
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

const worded404: FrameCopy = {
  ...copy,
  notFound: {
    title: 'Not found — Kitchen',
    code: '404',
    heading: 'There is nothing here.',
    body: { html: 'It is <b>gone</b>.' },
    back: 'Back to Kitchen',
  },
}

describe('FrameNotFound', () => {
  it('says what Next\'s own 404 page says when the copy words no 404', () => {
    const { container } = render(<FrameNotFound copy={copy} />)
    const hero = container.querySelector('#top.lp-hero-flow.lp-hero-flow--fill')
    expect(hero?.querySelector('h1')?.textContent).toBe('404')
    expect(hero?.querySelector('.lp-hero-sub')?.textContent).toBe('This page could not be found.')
    expect(container.querySelector('.st-404-code')).toBeNull()
    expect(container.querySelector('a')).toBeNull()
  })

  it('says the copy\'s words when it words a 404: the code, the heading, the body and a way home', () => {
    const { container } = render(<FrameNotFound copy={worded404} />)
    const hero = container.querySelector('#top.lp-hero-flow.lp-hero-flow--fill')
    expect(hero?.querySelector('.st-404-code')?.textContent).toBe('404')
    expect(hero?.querySelector('h1')?.textContent).toBe('There is nothing here.')
    expect(hero?.querySelector('.lp-hero-sub')?.innerHTML).toContain('It is <b>gone</b>.')
    const back = hero?.querySelector('a.st-404-back')
    expect(back?.getAttribute('href')).toBe('/')
    expect(back?.textContent).toBe('Back to Kitchen')
  })

  it('titles the 404 as Next\'s own 404 page does when the copy words none', () => {
    expect(frameNotFoundMetadata(copy).title).toBe('404: This page could not be found.')
  })

  it('titles the 404 with the copy\'s title when it words one', () => {
    expect(frameNotFoundMetadata(worded404).title).toBe('Not found — Kitchen')
  })

  it('ships from the server barrel', () => {
    expect(barrel.FrameNotFound).toBe(FrameNotFound)
    expect(barrel.frameNotFoundMetadata).toBe(frameNotFoundMetadata)
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

  it("frameSiteUrl takes SITE_URL, then site.json's siteUrl, then Vercel, then localhost", () => {
    vi.stubEnv('SITE_URL', 'https://staging.example')
    vi.stubEnv('VERCEL_PROJECT_PRODUCTION_URL', 'kitchen.vercel.app')
    expect(frameSiteUrl(5210, 'https://kitchen.example')).toBe('https://staging.example')
    vi.stubEnv('SITE_URL', '')
    expect(frameSiteUrl(5210, 'https://kitchen.example')).toBe('https://kitchen.example')
    expect(frameSiteUrl(5210, '')).toBe('https://kitchen.vercel.app')
    vi.stubEnv('VERCEL_PROJECT_PRODUCTION_URL', undefined)
    expect(frameSiteUrl(5210, 'https://kitchen.example')).toBe('https://kitchen.example')
    expect(frameSiteUrl(5210, undefined)).toBe('http://localhost:5210')
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

  it('frameMetadata asks for the small card when the OG image is the mark', () => {
    const icon: FrameConfig = { ...config, ogImage: config.mark.src }
    expect(frameMetadata(copy, icon).twitter).toMatchObject({ card: 'summary' })
    expect(frameMetadata(copy, config).twitter).toMatchObject({ card: 'summary_large_image' })
  })

  it('frameMetadata gives the OG image its size when the config has one', () => {
    const sized: FrameConfig = { ...config, ogImageSize: { width: 512, height: 512 } }
    expect(frameMetadata(copy, sized).openGraph?.images).toEqual([
      { url: '/og.png', width: 512, height: 512, alt: 'Kitchen' },
    ])
    expect(frameMetadata(copy, config).openGraph?.images).toEqual([{ url: '/og.png', alt: 'Kitchen' }])
  })

  it('frameMetadata carries the copy\'s keywords when it words them, and none when it does not', () => {
    const worded: FrameCopy = { ...copy, keywords: ['kitchen', 'recipes'] }
    expect(frameMetadata(worded, config).keywords).toEqual(['kitchen', 'recipes'])
    expect('keywords' in frameMetadata(copy, config)).toBe(false)
  })


  it('frameViewport carries the theme color', () => {
    expect(frameViewport(config).themeColor).toBe('#0b0a09')
  })

  it('frameViewport carries the iOS focus-zoom guard and the Android keyboard resize', () => {
    const viewport = frameViewport(config)
    expect(viewport.maximumScale).toBe(1)
    expect(viewport.interactiveWidget).toBe('resizes-content')
  })
})
