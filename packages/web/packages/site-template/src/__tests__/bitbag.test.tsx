import { render } from '@testing-library/react'
import type { ComponentType } from 'react'
import { describe, expect, it, vi } from 'vitest'
import { DEFAULT_VOICE } from '@agentic-toolkit/bitbag'

// `next/dynamic` stood in for by a component that records what it is handed: jsdom can run
// neither the client-only loader nor bitbag's gsap, and what `SiteBitbag` owes a site is only
// that the props it is given reach him.
const seen = vi.hoisted(() => ({ props: null as Record<string, unknown> | null }))
vi.mock('next/dynamic', () => ({
  default: (): ComponentType<Record<string, unknown>> =>
    function Recorded(props: Record<string, unknown>) {
      seen.props = props
      return null
    },
}))
vi.mock('@agentic-toolkit/bitbag/css/bitbag-dock.css', () => ({}))

import { SiteBitbag } from '../bitbag'

describe('SiteBitbag', () => {
  it('mounts him with no props by default', () => {
    render(<SiteBitbag />)
    expect(seen.props).toEqual({})
  })

  it('hands a site\'s voice and resting place to him', () => {
    const voice = { ...DEFAULT_VOICE, welcome: 'Hello from the site' }
    render(<SiteBitbag voice={voice} rest="entry" />)
    expect(seen.props).toEqual({ voice, rest: 'entry' })
  })
})
