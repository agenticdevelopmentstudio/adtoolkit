// src/__tests__/BitbagStandalone.test.tsx
import { describe, expect, it, vi } from 'vitest'
import { render } from '@testing-library/react'
import type { BitbagDockProps } from '../BitbagDock'

// The dock itself is BitbagDock.test.tsx's to exercise. This file is about the mount: which
// class it rides in on. That the class lands him where the footer does is a fact about two
// stylesheets, bitbag's and adh's, and is pinned where both are readable: adh's
// footerDock and hostCascade tests.
const dock = vi.hoisted(() => ({ props: {} as BitbagDockProps }))
vi.mock('../BitbagDock', () => ({
  BitbagDock: (props: BitbagDockProps) => {
    dock.props = props
    return <div className={props.className} data-testid="dock" />
  },
}))

import { BitbagStandalone, STANDALONE_CLASS } from '../BitbagStandalone'

describe('BitbagStandalone', () => {
  it('is the dock, wearing the standalone class', () => {
    const { getByTestId } = render(<BitbagStandalone />)
    expect(getByTestId('dock')).toHaveClass(STANDALONE_CLASS)
  })

  it("keeps the host's own class beside it, and hands the rest of the props straight through", () => {
    const backend = {} as NonNullable<BitbagDockProps['backend']>
    render(<BitbagStandalone className="site-chat" theme="old-school-terminal" backend={backend} size={96} rest="entry" />)
    expect(dock.props.className).toBe(`${STANDALONE_CLASS} site-chat`)
    expect(dock.props).toMatchObject({ theme: 'old-school-terminal', backend, size: 96, rest: 'entry' })
  })
})
