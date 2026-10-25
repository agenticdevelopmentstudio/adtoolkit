/** MarketingSiteMenu shows ONE menu on every site (Mike, 2026-10-25): the short tree, no
 *  settings gear (2026-10-23), no Admin block and no chrome rows (2026-10-24). The hub and a
 *  satellite are asserted alike, so a per-site branch that creeps back in fails here. */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { describe, it, expect, afterEach, vi } from 'vitest'

vi.mock('next/navigation', () => ({
  usePathname: () => '/',
  useRouter: () => ({ push: vi.fn() }),
}))

import type { SiteId } from '@agentic-toolkit/adh-registry'
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
    // Nor the "?" that used to stand in for it (Mike, 2026-10-24).
    expect(screen.queryByRole('button', { name: 'About the Agentic Developer family' })).toBeNull()
    // Nor SiteMenu's own chrome rows: Home and the Help modal row (the one menuitem that
    // is not a link).
    expect(screen.queryByRole('menuitem', { name: /^Home/ })).toBeNull()
    for (const help of screen.getAllByRole('menuitem', { name: /^Help/ }))
      expect(help).toHaveAttribute('href')
    // Help is still in the menu, as the help site's row in the foot block, beside Contact.
    expect(screen.getAllByRole('menuitem', { name: /^Help/ })).toHaveLength(1)
    expect(screen.getByRole('menuitem', { name: /^Contact/ })).toBeInTheDocument()
  })

  it('on the hub shows an admin no Admin block', async () => {
    render(<MarketingSiteMenu currentSiteId="hub" authenticated userIsAdmin />)
    await openMenu()
    expect(screen.getByRole('menuitem', { name: /^Bitbag/ })).toBeInTheDocument()
    expect(screen.queryByRole('menuitem', { name: /^Admin/ })).toBeNull()
  })

  // The menu is shared code, so a satellite shows exactly what the hub does (Mike, 2026-10-25).
  it.each<SiteId>(['hub', 'toolkit', 'cookbook', 'hub-help'])(
    'on %s, signed in as an admin, shows the same short menu',
    async (site) => {
      render(
        <MarketingSiteMenu currentSiteId={site} authenticated userIsAdmin onSettings={vi.fn()} />,
      )
      await openMenu()
      const labels = screen
        .getAllByRole('menuitem')
        .map((el) => el.textContent ?? '')
      for (const want of [
        /^Bitbag/,
        /^Hub/,
        /^Dev Team/,
        /^Cookbook/,
        /^Toolkit/,
        /^Persona Registry/,
        /^Help/,
        /^Contact/,
      ])
        expect(labels.filter((l) => want.test(l)), `${want} on ${site}`).toHaveLength(1)
      expect(screen.queryByRole('menuitem', { name: /^Products/ })).toBeNull()
      expect(screen.queryByRole('menuitem', { name: /^Home/ })).toBeNull()
      expect(screen.queryByRole('menuitem', { name: /^Admin/ })).toBeNull()
      expect(screen.queryByRole('button', { name: 'User settings' })).toBeNull()
      expect(
        screen.queryByRole('button', { name: 'About the Agentic Developer family' }),
      ).toBeNull()
    },
  )
})
