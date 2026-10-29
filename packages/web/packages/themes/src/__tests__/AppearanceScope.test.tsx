// <AppearanceScope/> is mountAppearanceScope as a component, so every site that wears the prefs on
// only some of its routes renders the same scope rather than writing its own. One test, in a file
// of its own: the store's scope count is module state, and this file must not reset modules (a
// re-imported store would bring a second React that the renderer below does not drive).
import { render } from '@testing-library/react'
import { describe, expect, it } from 'vitest'

import { APPEARANCE_DEFAULTS } from '../appearance'
import { AppearanceScope, adoptAppearance } from '../appearance-store'

describe('<AppearanceScope/>', () => {
  it('paints <html> while mounted and takes the prefs off when it unmounts', () => {
    const html = document.documentElement
    const view = render(<AppearanceScope />)
    adoptAppearance({ ...APPEARANCE_DEFAULTS, colorMode: 'dark', contrast: 'high' })
    expect(html.classList.contains('dark')).toBe(true)
    expect(html.dataset.contrast).toBe('high')

    view.unmount()
    expect(html.classList.contains('dark')).toBe(false)
    expect(html.hasAttribute('data-color-mode')).toBe(false)
    expect(html.hasAttribute('data-contrast')).toBe(false)

    adoptAppearance({ ...APPEARANCE_DEFAULTS, colorMode: 'dark' })
    expect(html.classList.contains('dark')).toBe(false)
  })
})
