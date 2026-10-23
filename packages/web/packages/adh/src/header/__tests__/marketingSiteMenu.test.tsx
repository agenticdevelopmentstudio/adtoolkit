/** MarketingSiteMenu's one decision: on the hub it shows the hub's own short tree and no
 *  settings gear (Mike, 2026-10-23); on every other host, the whole family with the gear. */
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

  it('on a satellite keeps the whole family and the gear', async () => {
    render(<MarketingSiteMenu currentSiteId="toolkit" authenticated onSettings={vi.fn()} />)
    await openMenu()
    expect(screen.getByRole('menuitem', { name: /^Products/ })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'User settings' })).toBeInTheDocument()
  })
})
