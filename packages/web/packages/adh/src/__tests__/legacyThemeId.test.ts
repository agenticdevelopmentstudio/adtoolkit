// A theme key persisted before the theme was renamed to agenticdevelopmentstudioweb
// must keep resolving to the same theme, not silently to the site default.
import { afterEach, describe, expect, it } from 'vitest'
import { LEGACY_THEME_ID, RENAMED_THEME_ID, normalizeThemeKey, FULL_PALETTE_THEMES } from '../themes/adh-themes'
import { isSwitcherSeed } from '../themes/resolve'
import { readStoredTheme, themePrePaintScript, THEME_STORAGE_KEY } from '../themes/theme-preview'

afterEach(() => {
  localStorage.clear()
  document.cookie = 'adh-theme=; max-age=0; path=/'
  document.head.innerHTML = ''
})

describe('legacy theme id', () => {
  it('maps to the renamed theme, and only that one', () => {
    expect(normalizeThemeKey(LEGACY_THEME_ID)).toBe(RENAMED_THEME_ID)
    expect(normalizeThemeKey('charcoal')).toBe('charcoal')
    expect(normalizeThemeKey(null)).toBeNull()
    expect(FULL_PALETTE_THEMES).toContain(RENAMED_THEME_ID)
  })

  it('is accepted as a switcher seed (a DB theme basedOn it still resolves)', () => {
    expect(isSwitcherSeed(LEGACY_THEME_ID)).toBe(true)
    expect(isSwitcherSeed(RENAMED_THEME_ID)).toBe(true)
  })

  it('a stored legacy key reads back as the new theme (localStorage and cookie)', () => {
    localStorage.setItem(THEME_STORAGE_KEY, LEGACY_THEME_ID)
    expect(readStoredTheme()).toBe(RENAMED_THEME_ID)
    document.cookie = `adh-theme=${LEGACY_THEME_ID}; path=/`
    expect(readStoredTheme()).toBe(RENAMED_THEME_ID)
  })

  it('the pre-paint script activates the renamed alt block for a stored legacy key', () => {
    document.head.innerHTML =
      `<style data-adh-theme-alt="${RENAMED_THEME_ID}" media="not all"></style>` +
      '<style data-adh-theme-alt="charcoal" media="not all"></style>'
    localStorage.setItem(THEME_STORAGE_KEY, LEGACY_THEME_ID)
    new Function(themePrePaintScript())()
    const active = document.querySelector('style[media="all"]')
    expect(active?.getAttribute('data-adh-theme-alt')).toBe(RENAMED_THEME_ID)
  })
})
