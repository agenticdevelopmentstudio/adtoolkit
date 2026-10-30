import { render, screen, within } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { SiteFooter } from '../footer/SiteFooter'

describe('adh SiteFooter', () => {
  it('is a floating box whose copyright opens the family footer, and names the studio', () => {
    const { container } = render(<SiteFooter />)
    const footer = container.querySelector('footer')!
    expect(footer).toHaveClass('adh-footer', 'adh-footer--floating')
    const trigger = within(footer).getByRole('button', { name: /© 2026 Agentic Development Studio/ })
    expect(trigger.closest('.adh-footer__copyright')).not.toBeNull()
    expect(trigger.getAttribute('popovertarget')).toBe('adh-family-footer')
  })

  it('opens the whole family footer in a dialog, with the site\'s own links first', () => {
    render(<SiteFooter links={[{ label: 'GitHub', href: 'https://example.com' }]} />)
    const dialog = document.getElementById('adh-family-footer')!
    expect(dialog).toHaveClass('adh-modal', 'adh-modal--wide')
    expect(dialog.getAttribute('popover')).toBe('auto')
    const headings = Array.from(dialog.querySelectorAll('.adh-landing-footer__heading')).map((h) => h.textContent)
    expect(headings[0]).toBe('This site')
    expect(headings.slice(-2)).toEqual(['About', 'Legal'])
    expect(within(dialog).getByRole('link', { name: 'GitHub', hidden: true })).toHaveAttribute('href', 'https://example.com')
  })

  it('renders each dialog the family footer opens once, beside it rather than inside it', () => {
    render(<SiteFooter />)
    const family = document.getElementById('adh-family-footer')!
    for (const id of ['adh-contact', 'adh-sites-overview', 'adh-terms-dialog', 'adh-privacy-dialog']) {
      expect(document.querySelectorAll(`#${id}`)).toHaveLength(1)
      expect(family.contains(document.getElementById(id))).toBe(false)
    }
  })

  it('writes to the hub by default, and to a site\'s own address when it passes one', () => {
    const { unmount } = render(<SiteFooter />)
    expect(document.querySelector('#adh-contact a')).toHaveAttribute('href', 'mailto:hello@agenticdeveloperhub.com')
    unmount()
    render(<SiteFooter contact={{ name: 'FishLamp Design', email: 'hello@fishlamp.com' }} />)
    const contact = document.getElementById('adh-contact')!
    expect(contact.textContent).toContain('Contact FishLamp Design')
    expect(contact.querySelector('a')).toHaveAttribute('href', 'mailto:hello@fishlamp.com')
  })

  it('keeps the studio\'s link and the build on screen without the Popover API', () => {
    vi.stubEnv('NEXT_PUBLIC_ADH_SITE_VERSION', '1.0.155')
    vi.stubEnv('NEXT_PUBLIC_ADH_RELEASE', 'a73e79b7c0ffee00deadbeef1234567890abcdef')
    try {
      const { container } = render(<SiteFooter />)
      const fallback = container.querySelector('.adh-footer__copyright-fallback')!
      expect(fallback.querySelector('a')).toHaveAttribute('href', 'https://agenticdevelopmentstudio.com/')
      expect(fallback.textContent).toContain('v1.0.155 · a73e79b7')
    } finally {
      vi.unstubAllEnvs()
    }
  })

  it('renders no dialogs as a specimen', () => {
    render(<SiteFooter specimen />)
    expect(screen.getByRole('button', { name: /Agentic Development Studio/ })).toBeInTheDocument()
    expect(document.querySelectorAll('[popover]')).toHaveLength(0)
  })
})
