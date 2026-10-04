'use client'

import { useCallback, useSyncExternalStore } from 'react'
import { themeIds, type ThemeKey } from '@agenticdevelopertoolkit/themes'

/**
 * Single source for the demo's selected theme. The theme is persisted in
 * localStorage and broadcast via a custom event so every part of the demo —
 * the Shell (which applies the `ThemeStyle`), the chat options popup, and the
 * theme showcase — stays in sync without prop-drilling.
 */
export const STORAGE_THEME = 'apt-demo:theme'
export const DEFAULT_THEME: ThemeKey = 'agenticdevelopmentstudioweb'

export function readStoredTheme(): ThemeKey {
  if (typeof window === 'undefined') return DEFAULT_THEME
  try {
    const v = window.localStorage.getItem(STORAGE_THEME)
    if (v && (themeIds as readonly string[]).includes(v)) return v as ThemeKey
  } catch {
    // best-effort
  }
  return DEFAULT_THEME
}

export function writeTheme(next: ThemeKey): void {
  if (typeof window === 'undefined') return
  try {
    window.localStorage.setItem(STORAGE_THEME, next)
  } catch {
    // best-effort
  }
  window.dispatchEvent(new CustomEvent(STORAGE_THEME, { detail: next }))
}

export function subscribeTheme(callback: () => void): () => void {
  if (typeof window === 'undefined') return () => {}
  window.addEventListener(STORAGE_THEME, callback)
  window.addEventListener('storage', callback)
  return () => {
    window.removeEventListener(STORAGE_THEME, callback)
    window.removeEventListener('storage', callback)
  }
}

/** The active demo theme and a setter, synced across the demo. */
export function useDemoTheme(): [ThemeKey, (next: ThemeKey) => void] {
  const theme = useSyncExternalStore(subscribeTheme, readStoredTheme, () => DEFAULT_THEME)
  const setTheme = useCallback((next: ThemeKey) => writeTheme(next), [])
  return [theme, setTheme]
}
