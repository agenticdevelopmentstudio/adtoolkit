// src/__tests__/BitbagMark.test.tsx
import { describe, expect, it } from 'vitest'
import { render } from '@testing-library/react'
import { BitbagMark } from '../mark'
import { EYE_BG, IRIS, STEM_LEFT, STEM_RIGHT } from '../avatar/geometry'

describe('BitbagMark', () => {
  it('draws his letterform from the rig geometry', () => {
    const { container } = render(<BitbagMark />)
    const svg = container.querySelector('svg')!
    expect(svg).toHaveClass('bb-mark')
    expect(svg).toHaveAttribute('aria-hidden')
    const paths = [...svg.querySelectorAll('path')].map((p) => p.getAttribute('d'))
    expect(paths).toEqual(expect.arrayContaining([STEM_LEFT, STEM_RIGHT]))
    const fills = [...svg.querySelectorAll('circle')].map((c) => c.getAttribute('fill'))
    expect(fills.filter((f) => f === EYE_BG)).toHaveLength(2)
    expect(fills.filter((f) => f === IRIS)).toHaveLength(2)
  })

  it('takes the host’s class in place of the default', () => {
    const { container } = render(<BitbagMark className="team-face" />)
    expect(container.querySelector('svg')).toHaveClass('team-face')
    expect(container.querySelector('svg')).not.toHaveClass('bb-mark')
  })
})
