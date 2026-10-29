// A site that wears the appearance preferences on only some of its routes mounts a scope there
// (the hub's route group does; `/` is the site template's frame and wears none of them). The
// store outlives the scope: its OS colour-scheme listener is attached once for the app's
// lifetime, and adopt/reset can resolve after the reader has left. Either one painting <html>
// with no scope mounted would carry the hub's palette onto the frame, so both must hold off
// until a scope is mounted again, and a site that never mounts a scope must keep painting.
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { APPEARANCE_DEFAULTS, APPEARANCE_STORAGE_KEY, type AppearancePrefs } from '../appearance'

type Store = typeof import('../appearance-store')

interface FakeSchemeQuery {
  flip: (dark: boolean) => void
}

function installSchemeQuery(dark: boolean): FakeSchemeQuery {
  const listeners = new Set<() => void>()
  const mq = {
    matches: dark,
    media: '(prefers-color-scheme: dark)',
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: (_type: string, l: () => void) => listeners.add(l),
    removeEventListener: (_type: string, l: () => void) => listeners.delete(l),
    dispatchEvent: () => false,
  }
  window.matchMedia = vi.fn(() => mq as unknown as MediaQueryList)
  return {
    flip(next: boolean): void {
      mq.matches = next
      for (const l of listeners) l()
    },
  }
}

const AUTO_HIGH_CONTRAST: AppearancePrefs = { ...APPEARANCE_DEFAULTS, colorMode: 'auto', contrast: 'high' }
const DARK: AppearancePrefs = { ...APPEARANCE_DEFAULTS, colorMode: 'dark' }

function painted(): boolean {
  const el = document.documentElement
  return el.hasAttribute('data-color-mode') || el.classList.contains('dark') || el.hasAttribute('data-contrast')
}

async function freshStore(): Promise<Store> {
  vi.resetModules()
  return import('../appearance-store')
}

let originalMatchMedia: typeof window.matchMedia

beforeEach(() => {
  originalMatchMedia = window.matchMedia
  document.documentElement.removeAttribute('class')
  for (const a of [...document.documentElement.attributes]) document.documentElement.removeAttribute(a.name)
  window.localStorage.clear()
})

afterEach(() => {
  window.matchMedia = originalMatchMedia
})

describe('appearance scope', () => {
  it('an OS scheme change after the scope unmounts leaves <html> alone', async () => {
    const os = installSchemeQuery(false)
    const store = await freshStore()

    const release = store.mountAppearanceScope()
    store.adoptAppearance(AUTO_HIGH_CONTRAST)
    expect(document.documentElement.dataset.contrast).toBe('high')

    release()
    expect(painted()).toBe(false)

    os.flip(true)
    expect(painted()).toBe(false)
  })

  it('a commit that resolves after the scope unmounts is cached but not painted', async () => {
    installSchemeQuery(false)
    const store = await freshStore()

    const release = store.mountAppearanceScope()
    release()

    store.adoptAppearance(DARK)
    expect(painted()).toBe(false)
    expect(JSON.parse(window.localStorage.getItem(APPEARANCE_STORAGE_KEY) ?? '{}').colorMode).toBe('dark')

    store.resetAppearance()
    expect(painted()).toBe(false)
  })

  it('mounting the scope again paints what the store holds now', async () => {
    installSchemeQuery(false)
    const store = await freshStore()

    store.mountAppearanceScope()()
    store.adoptAppearance(DARK)

    store.mountAppearanceScope()
    expect(document.documentElement.classList.contains('dark')).toBe(true)
    expect(document.documentElement.dataset.colorMode).toBe('dark')
  })

  it('keeps painting until the last of two scopes unmounts, and a release runs once', async () => {
    installSchemeQuery(false)
    const store = await freshStore()

    const first = store.mountAppearanceScope()
    const second = store.mountAppearanceScope()
    store.adoptAppearance(DARK)

    first()
    first()
    expect(document.documentElement.classList.contains('dark')).toBe(true)

    second()
    expect(painted()).toBe(false)
  })

  it('a site that never mounts a scope keeps painting on commit and on an OS change', async () => {
    const os = installSchemeQuery(false)
    const store = await freshStore()

    store.adoptAppearance(AUTO_HIGH_CONTRAST)
    expect(document.documentElement.dataset.contrast).toBe('high')
    expect(document.documentElement.classList.contains('dark')).toBe(false)

    os.flip(true)
    expect(document.documentElement.classList.contains('dark')).toBe(true)
  })
})
