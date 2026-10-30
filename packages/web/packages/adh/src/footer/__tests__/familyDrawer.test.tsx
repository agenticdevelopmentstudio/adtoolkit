import { cleanup, fireEvent, render, screen, within } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { siteProdUrl } from '@agentic-toolkit/adh-registry'
import { FamilyDrawerSection, MoreInfoDrawerFoot } from '../FamilyDrawer'
import { CONTACT_POPOVER_ID } from '../identity'
import { TERMS_DIALOG_ID } from '../LegalModals'

afterEach(cleanup)

const names = (links: HTMLElement[]) => links.map((a) => a.textContent)

describe('FamilyDrawerSection', () => {
  it("lists the site menu's family, in its order, as drawer rows at each site's home", () => {
    render(<FamilyDrawerSection />)
    const section = screen.getByRole('region', { name: 'Family' })
    const links = within(section).getAllByRole('link')
    expect(names(links)).toEqual(['Bitbag', 'Hub', 'Dev Team', 'Cookbook', 'Toolkit', 'Persona Registry'])
    expect(links.every((a) => a.classList.contains('lp-nav'))).toBe(true)
    expect(links[1]!.getAttribute('href')).toBe(siteProdUrl('hub', '/'))
  })
})

describe('MoreInfoDrawerFoot', () => {
  it('lists Help, Contact, Terms and Privacy', () => {
    render(<MoreInfoDrawerFoot />)
    const section = screen.getByRole('region', { name: 'More Info' })
    const links = within(section).getAllByRole('link')
    expect(names(links)).toEqual(['Help', 'Contact', 'Terms of Use', 'Privacy Policy'])
    expect(links[0]!.getAttribute('href')).toBe(siteProdUrl('hub-help', '/'))
  })

  it.each([
    ['Contact', CONTACT_POPOVER_ID],
    ['Terms of Use', TERMS_DIALOG_ID],
  ])('%s opens its dialog in place of navigating', (label, id) => {
    const showPopover = vi.fn()
    const dialog = document.createElement('div')
    dialog.id = id
    Object.assign(dialog, { showPopover })
    document.body.append(dialog)
    render(<MoreInfoDrawerFoot />)
    const notPrevented = fireEvent.click(screen.getByRole('link', { name: label }))
    expect(notPrevented).toBe(false)
    expect(showPopover).toHaveBeenCalledOnce()
    dialog.remove()
  })
})
