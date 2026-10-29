// A site that mounts the appearance preferences on only some of its routes (the hub keeps them
// in a route group, and `/` is the site template's frame, which wears none of them) has to take
// them off the document again when the reader leaves: a client navigation keeps the same
// <html>, so whatever applyAppearance wrote would follow the reader onto a page that never
// asked for it. clearAppearance is that undo, and it must undo exactly what apply did.
import { describe, expect, it } from 'vitest'
import { applyAppearance, clearAppearance, type AppearancePrefs } from '../appearance'

const EVERY_ATTRIBUTE_SET: AppearancePrefs = {
  colorMode: 'dark',
  reduceMotion: 'on',
  contrast: 'high',
  textSize: 'large',
  spacing: 'spacious',
  focusOutlines: true,
  underlineLinks: true,
}

describe('clearAppearance', () => {
  it('leaves the element as it was before applyAppearance', () => {
    const el = document.createElement('html')
    el.className = 'font-a font-b'
    el.setAttribute('lang', 'en')
    const before = el.outerHTML

    applyAppearance(el, EVERY_ATTRIBUTE_SET, true)
    expect(el.outerHTML).not.toBe(before)

    clearAppearance(el)
    expect(el.outerHTML).toBe(before)
  })

  it('removes the attributes the pre-paint script writes for the defaults too', () => {
    const el = document.createElement('html')
    el.dataset.colorMode = 'auto'
    el.classList.add('dark')

    clearAppearance(el)
    expect(el.hasAttribute('data-color-mode')).toBe(false)
    expect(el.classList.contains('dark')).toBe(false)
  })
})
