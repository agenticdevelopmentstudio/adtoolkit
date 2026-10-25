import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { ProfileInfoButton } from './ProfileInfoButton'

const PROFILE = 'https://registry.example/olylo'

describe('ProfileInfoButton', () => {
  it('links to the profile in a new tab with the accessible label', () => {
    render(<ProfileInfoButton profileUrl={PROFILE} label="olylo's profile" />)
    const link = screen.getByRole('link', { name: "olylo's profile" })
    expect(link).toHaveAttribute('href', PROFILE)
    expect(link).toHaveAttribute('target', '_blank')
    expect(link).toHaveAttribute('rel', 'noopener noreferrer')
    expect(link).toHaveAttribute('title', "olylo's profile")
    expect(link).toHaveClass('pc-profile-info')
    expect(link).toHaveTextContent('i')
  })
})
