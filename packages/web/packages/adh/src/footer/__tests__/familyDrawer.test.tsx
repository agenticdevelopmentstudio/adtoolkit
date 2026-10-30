import { cleanup, render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it } from 'vitest'
import { FamilyDrawerRow, MoreInfoDrawerFoot } from '../FamilyDrawer'
import { FamilyFooter } from '../FamilyFooter'

afterEach(cleanup)

describe('the drawer rows', () => {
  it('Hub Websites is one drawer row, to the family band', () => {
    render(<FamilyDrawerRow />)
    const row = screen.getByRole('link', { name: 'Hub Websites' })
    expect(row.classList.contains('lp-nav')).toBe(true)
    expect(row.getAttribute('href')).toBe('/#family')
  })

  it('More Info is one drawer row, to the landing footer it anchors', () => {
    const { container } = render(
      <>
        <MoreInfoDrawerFoot />
        <FamilyFooter version={null} anchored />
      </>
    )
    const row = screen.getByRole('link', { name: 'More Info' })
    expect(row.classList.contains('lp-nav')).toBe(true)
    expect(row.getAttribute('href')).toBe('/#more-info')
    expect(container.querySelector('#more-info')!.className).toBe('adh-landing-footer')
  })

  it('the footer carries no id unless anchored, so the dialog copy cannot repeat it', () => {
    const { container } = render(<FamilyFooter version={null} />)
    expect(container.querySelector('#more-info')).toBeNull()
  })
})
