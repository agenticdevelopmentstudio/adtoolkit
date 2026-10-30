import { describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { AppShell } from '../AppShell'

// The route each test is on; AdhAppShell's SlideTransitions also takes the router's push.
let pathname = '/'
vi.mock('next/navigation', () => ({
  usePathname: () => pathname,
  useRouter: () => ({ push: () => {} }),
}))

// Markers for the bar and bitbag, for the reason appShellChromeGate.test.tsx gives; the route
// switch is the real one, since which footer it picks is what this file is about.
vi.mock('@agentic-toolkit/adh/footer', async () => {
  const { FooterForRoute } = await import('../../footer/FooterForRoute')
  return {
    FooterForRoute,
    SiteFooter: () => <footer>BAR</footer>,
    FooterChat: () => <div>BITBAG</div>,
    SitesPopover: () => null,
    // The landing footer's body and the dialogs it brings, reduced to the one class the test
    // looks for: what they render is footer.test's.
    FamilyFooter: () => <div className="adh-landing-footer" />,
    TermsModal: () => null,
    PrivacyModal: () => null,
  }
})

function renderOn(route: string, landingFooter?: boolean) {
  pathname = route
  return render(
    <AppShell header={<header>HEADER</header>} landingFooter={landingFooter}>
      PAGE
    </AppShell>,
  )
}

describe('AppShell landingFooter', () => {
  it('ends `/` with the landing footer and bitbag, and no bar', () => {
    const { container } = renderOn('/', true)
    expect(container.querySelector('.adh-landing-footer-band .adh-landing-footer')).not.toBeNull()
    expect(screen.getByText('BITBAG')).toBeInTheDocument()
    expect(screen.queryByText('BAR')).not.toBeInTheDocument()
    expect(screen.getByText('PAGE')).toBeInTheDocument()
  })

  it('keeps the bar on every other route', () => {
    const { container } = renderOn('/docs/getting-started', true)
    expect(screen.getByText('BAR')).toBeInTheDocument()
    expect(container.querySelector('.adh-landing-footer')).toBeNull()
  })

  it('keeps the bar on `/` too when the site has not opted in', () => {
    const { container } = renderOn('/')
    expect(screen.getByText('BAR')).toBeInTheDocument()
    expect(container.querySelector('.adh-landing-footer')).toBeNull()
  })
})
