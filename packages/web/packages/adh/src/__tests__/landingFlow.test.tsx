import { describe, it, expect } from 'vitest'
import '@testing-library/jest-dom/vitest'
import { render, screen } from '@testing-library/react'
import { LandingFlow, LandingFlowTour } from '../landing'
import type { LandingContent } from '../landing'

// The flow is the deck's content in a different frame, so the properties are the deck's:
// one band per section, an index that reaches every one, the same `headingInBlock` rule —
// plus the one the flow adds, that a hero block with no slot fails instead of vanishing.
const CONTENT: LandingContent = {
  hero: {
    headline: <>Ecosystems</>,
    tagline: <>The wiring that turns parts into a product.</>,
    blocks: [
      { kind: 'Cta', buttons: [{ href: '/start', label: 'Get started', variant: 'primary' }] },
      { kind: 'Trust', items: [<>MIT licensed</>, <>Free</>] },
    ],
  },
  sections: [
    {
      id: 'what-it-is',
      eyebrow: 'What it is',
      title: <>An ecosystem is where the pieces meet.</>,
      blocks: [{ kind: 'Lede', children: <>Pick the features you use.</> }],
    },
    {
      id: 'what-it-does',
      eyebrow: 'What it does',
      blocks: [
        {
          kind: 'Cards',
          items: [{ title: <>Group features</>, body: [<>One.</>, <>Two.</>] }],
        },
      ],
    },
    {
      id: 'the-shape',
      eyebrow: 'The shape',
      headingInBlock: true,
      blocks: [{ kind: 'Roadmap', eyebrow: <>In flight</>, children: [] }],
    },
  ],
  tour: {
    eyebrow: 'The agentic developer story',
    promise: <>Everything your agents need.</>,
    position: { step: 3, total: 12 },
    back: { site: 'personas', label: 'Personas' },
    next: { site: 'hub', label: 'Hub', note: 'The platform' },
  },
}

function bands(container: HTMLElement): HTMLElement[] {
  return Array.from(container.querySelectorAll<HTMLElement>('.lp-band'))
}

function indexRows(container: HTMLElement): [string, string][] {
  return Array.from(container.querySelectorAll('a.lp-nav')).map((a) => [
    a.getAttribute('href') ?? '',
    a.textContent ?? '',
  ])
}

describe('LandingFlow', () => {
  it('renders one band per section and no deck screens', () => {
    // No `.lp-screen`, no `.lp-deck`: base.css arms snapping only under `.lp-deck`, so the
    // absence of that class is what keeps a flow page from snapping at all.
    const { container } = render(<LandingFlow content={CONTENT} />)
    expect(bands(container).map((b) => b.id)).toEqual(['what-it-is', 'what-it-does', 'the-shape'])
    expect(container.querySelector('.lp-screen')).toBeNull()
    expect(container.querySelector('.lp-deck')).toBeNull()
    expect(container.querySelector('.lp-flow')).not.toBeNull()
  })

  it('alternates band tones, soft first', () => {
    const { container } = render(<LandingFlow content={CONTENT} />)
    expect(bands(container).map((b) => b.className)).toEqual([
      expect.stringContaining('soft'),
      expect.stringContaining('dark'),
      expect.stringContaining('soft'),
    ])
  })

  it('puts the hero CTA buttons in the action row and the trust claims on the meta line', () => {
    const { container } = render(<LandingFlow content={CONTENT} />)
    expect(screen.getByText('Ecosystems')).toBeInTheDocument()
    expect(container.querySelector('.lp-hero-actions a')).toHaveAttribute('href', '/start')
    expect(container.querySelector('.lp-hero-actions a')).toHaveTextContent('Get started')
    expect(container.querySelector('.lp-hero-meta')).toHaveTextContent('MIT licensed · Free')
  })

  it('gives every band a row in the index, labelled with its eyebrow', () => {
    const { container } = render(<LandingFlow content={CONTENT} />)
    expect(indexRows(container)).toEqual([
      ['#what-it-is', 'What it is'],
      ['#what-it-does', 'What it does'],
      ['#the-shape', 'The shape'],
    ])
  })

  it('draws no Head over a section whose heading is in its block', () => {
    // The Roadmap draws its own eyebrow ("In flight"); the section's ("The shape") must not
    // appear over it.
    const { container } = render(<LandingFlow content={CONTENT} />)
    const eyebrows = (band: HTMLElement | undefined): string[] =>
      Array.from(band?.querySelectorAll('.lp-eyebrow') ?? []).map((e) => e.textContent ?? '')
    expect(eyebrows(bands(container)[2])).toEqual(['In flight'])
    expect(eyebrows(bands(container)[0])).toEqual(['What it is'])
  })

  it('refuses a hero block the flow hero has no slot for', () => {
    const content: LandingContent = {
      ...CONTENT,
      hero: { ...CONTENT.hero, blocks: [{ kind: 'Lede', children: <>Lost?</> }] },
    }
    expect(() => render(<LandingFlow content={content} />)).toThrow(/'Lede' block has no slot/)
  })

  it('keeps the short hero unless the site asks for one the height of the window', () => {
    const { container, rerender } = render(<LandingFlow content={CONTENT} />)
    expect(container.querySelector('.lp-hero-flow--fill')).toBeNull()
    rerender(<LandingFlow content={CONTENT} heroFillsWindow />)
    expect(container.querySelector('.lp-hero-flow--fill')).not.toBeNull()
  })
})

describe('LandingFlowTour', () => {
  it('leads with the tour strip and indexes it first', () => {
    const { container } = render(<LandingFlowTour content={CONTENT} />)
    expect(screen.getByText('Everything your agents need.')).toBeInTheDocument()
    expect(indexRows(container)[0]).toEqual(['#tour', 'The agentic developer story'])
    expect(indexRows(container)).toHaveLength(4)
  })
})
