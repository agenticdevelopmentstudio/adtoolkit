import type { ReactNode } from 'react'
import { describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { AppShell } from '../AppShell'

// AdhAppShell mounts SlideTransitions, which takes the app router's push; there is no app
// router under vitest, so stand one in.
vi.mock('next/navigation', () => ({ usePathname: () => '/', useRouter: () => ({ push: () => {} }) }))

// Stubbed to a marker for the reason appShellSettings.test.tsx gives (the real footer barrel
// reaches a sibling submodule with no built dist here) — and because a marker is exactly what
// this file needs: proof the footer slot rendered, or did not.
vi.mock('@agentic-toolkit/adh/footer', () => ({
  SiteFooter: () => <footer>FOOTER</footer>,
}))

const Closed = (_: { children: ReactNode }) => null
const Open = ({ children }: { children: ReactNode }) => <>{children}</>

// The gate wraps the chrome and NEVER the page: a gate that closes must take the header and
// the footer with it and leave the route's own content standing.
describe('AppShell chromeGate', () => {
  it('renders the header and footer when no gate is given', () => {
    render(<AppShell header={<header>HEADER</header>}>PAGE</AppShell>)
    expect(screen.getByText('HEADER')).toBeInTheDocument()
    expect(screen.getByText('FOOTER')).toBeInTheDocument()
    expect(screen.getByText('PAGE')).toBeInTheDocument()
  })

  it('renders both when the gate passes its children through', () => {
    render(
      <AppShell header={<header>HEADER</header>} chromeGate={Open}>
        PAGE
      </AppShell>,
    )
    expect(screen.getByText('HEADER')).toBeInTheDocument()
    expect(screen.getByText('FOOTER')).toBeInTheDocument()
  })

  it('drops the header and footer, and keeps the page, when the gate closes', () => {
    render(
      <AppShell header={<header>HEADER</header>} chromeGate={Closed}>
        PAGE
      </AppShell>,
    )
    expect(screen.queryByText('HEADER')).not.toBeInTheDocument()
    expect(screen.queryByText('FOOTER')).not.toBeInTheDocument()
    expect(screen.getByText('PAGE')).toBeInTheDocument()
  })
})
