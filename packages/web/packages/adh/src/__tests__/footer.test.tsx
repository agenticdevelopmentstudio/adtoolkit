import { render, screen, within } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { SiteFooter } from '../footer/SiteFooter'

describe('adh SiteFooter', () => {
  it('is a floating `i` that opens the family footer, which names the studio', () => {
    const { container } = render(<SiteFooter />)
    const footer = container.querySelector('footer')!
    expect(footer).toHaveClass('adh-footer', 'adh-footer--floating')
    const trigger = within(footer).getByRole('button', { name: 'About the Agentic Developer family' })
    expect(trigger.closest('.adh-footer__copyright')).not.toBeNull()
    expect(trigger.textContent).toBe('i')
    expect(trigger.getAttribute('popovertarget')).toBe('adh-family-footer')
    const dialog = document.getElementById('adh-family-footer')!
    expect(dialog.textContent).toContain('© 2026 Agentic Development Studio')
  })

  it('opens the whole family footer in a dialog, with the site\'s own links first', () => {
    render(<SiteFooter links={[{ label: 'GitHub', href: 'https://example.com' }]} />)
    const dialog = document.getElementById('adh-family-footer')!
    expect(dialog).toHaveClass('adh-modal', 'adh-modal--wide')
    expect(dialog.getAttribute('popover')).toBe('auto')
    const headings = Array.from(dialog.querySelectorAll('.adh-landing-footer__heading')).map((h) => h.textContent)
    expect(headings[0]).toBe('This site')
    expect(headings.slice(-3)).toEqual(['About', 'Legal', 'Contact'])
    expect(within(dialog).getByRole('link', { name: 'GitHub', hidden: true })).toHaveAttribute('href', 'https://example.com')
  })

  it('renders each dialog the family footer opens once, beside it rather than inside it', () => {
    render(<SiteFooter />)
    const family = document.getElementById('adh-family-footer')!
    for (const id of ['adh-sites-overview', 'adh-terms-dialog', 'adh-privacy-dialog']) {
      expect(document.querySelectorAll(`#${id}`)).toHaveLength(1)
      expect(family.contains(document.getElementById(id))).toBe(false)
    }
  })

  it('ends the directory with a Contact column of the hub\'s address, or a site\'s own', () => {
    const contactLink = () =>
      document.querySelector('#adh-family-footer nav[aria-label="Contact"] a')
    const { unmount } = render(<SiteFooter />)
    expect(contactLink()).toHaveAttribute('href', 'mailto:hello@agenticdeveloperhub.com')
    expect(contactLink()?.textContent).toBe('hello@agenticdeveloperhub.com')
    unmount()
    render(<SiteFooter contact={{ name: 'FishLamp Design', email: 'hello@fishlamp.com' }} />)
    expect(contactLink()).toHaveAttribute('href', 'mailto:hello@fishlamp.com')
    expect(document.querySelector('#adh-contact')).toBeNull()
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
    expect(screen.getByRole('button', { name: 'About the Agentic Developer family' })).toBeInTheDocument()
    expect(document.querySelectorAll('[popover]')).toHaveLength(0)
  })
})
