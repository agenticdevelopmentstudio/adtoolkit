/** MarketingSiteMenu's one decision: on the hub it shows the hub's own short tree and no
 *  settings gear (Mike, 2026-10-23) and no Admin block (2026-10-24); on every other host, the
 *  whole family with the gear and, for an admin, the consoles. */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { describe, it, expect, afterEach, vi } from 'vitest'

vi.mock('next/navigation', () => ({
  usePathname: () => '/',
  useRouter: () => ({ push: vi.fn() }),
}))

import { MarketingSiteMenu } from '../MarketingSiteMenu'

afterEach(cleanup)

// jsdom has no layout, so no scrollIntoView; the popover calls it on a keyboard highlight.
Element.prototype.scrollIntoView = vi.fn()

async function openMenu(): Promise<void> {
  fireEvent.click(screen.getByRole('button', { name: /switch site$/ }))
  await waitFor(() => expect(screen.getByRole('menu')).toBeInTheDocument())
}

describe('MarketingSiteMenu', () => {
  it('on the hub, signed in, shows the short tree and no settings gear', async () => {
    render(<MarketingSiteMenu currentSiteId="hub" authenticated onSettings={vi.fn()} />)
    await openMenu()
    expect(screen.getByRole('menuitem', { name: /^Bitbag/ })).toBeInTheDocument()
    expect(screen.getByRole('menuitem', { name: /^Persona Registry/ })).toBeInTheDocument()
    for (const gone of [
      /^Messages/,
      /^Organizations/,
      /^Learn/,
      /^Plan/,
      /^Personas/,
      /^Products/,
      /^Hire/,
    ])
      expect(screen.queryByRole('menuitem', { name: gone })).toBeNull()
    expect(screen.queryByRole('button', { name: 'User settings' })).toBeNull()
    // The search row keeps a trailing control: the sites overview, as it has signed out.
    expect(
      screen.getByRole('button', { name: 'About the Agentic Developer family' }),
    ).toBeInTheDocument()
  })

  it('on the hub shows an admin no Admin block', async () => {
    render(<MarketingSiteMenu currentSiteId="hub" authenticated userIsAdmin />)
    await openMenu()
    expect(screen.getByRole('menuitem', { name: /^Bitbag/ })).toBeInTheDocument()
    expect(screen.queryByRole('menuitem', { name: /^Admin/ })).toBeNull()
  })

  it('on a satellite keeps the whole family, the gear and the Admin block', async () => {
    render(
      <MarketingSiteMenu currentSiteId="toolkit" authenticated userIsAdmin onSettings={vi.fn()} />,
    )
    await openMenu()
    expect(screen.getByRole('menuitem', { name: /^Products/ })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'User settings' })).toBeInTheDocument()
    // Non-vacuity for the hub case above: the same props DO produce the row elsewhere.
    expect(screen.getByRole('menuitem', { name: /^Admin/ })).toBeInTheDocument()
  })
})
