// src/__tests__/Bitbag.test.tsx
import { afterEach, describe, expect, it, vi } from 'vitest'
import { createRef } from 'react'
import { act, fireEvent, render, screen } from '@testing-library/react'
import type { BitbagHandle } from '../avatar'
import { EXPRESSIONS } from '../avatar/expressions'

// The engine is where his motion runs, and jsdom can't watch gsap move anything —
// so this file captures what bitbag ASKS the engine for, and the poke it hands back,
// which is all the reduced-motion stilling is: his ordinary configuration, turned
// down. (The engine itself is tested in @agenticdevelopertoolkit/avatar.)
type EngineArgs = {
  expression?: string
  gaze?: unknown
  mute?: boolean
  tuning: Record<string, unknown>
  perExpressionEffects: Record<string, unknown>
  blinkSuppressed: readonly string[]
}
const engine = vi.hoisted(() => ({ args: null as EngineArgs | null, poke: vi.fn() }))
vi.mock('@agenticdevelopertoolkit/avatar', () => ({
  useAvatarEngine: (args: EngineArgs) => {
    engine.args = args
    return { effective: args.expression ?? 'idle', speech: null, poke: engine.poke }
  },
}))
vi.mock('gsap', () => ({ default: { to: () => ({ kill: () => {} }) } }))

import { Bitbag } from '../avatar'

/** A matchMedia whose reduced-motion answer the test sets. */
function preferReducedMotion(reduce: boolean): void {
  window.matchMedia = ((query: string) => ({
    matches: reduce && query === '(prefers-reduced-motion: reduce)',
    media: query,
    addEventListener: () => {},
    removeEventListener: () => {},
  })) as unknown as typeof window.matchMedia
}

afterEach(() => {
  engine.args = null
  engine.poke.mockReset()
})

describe('Bitbag', () => {
  it('moves as asked when the reader has not asked for reduced motion', () => {
    preferReducedMotion(false)
    render(<Bitbag expression="excited" gaze={{ x: 0, y: 1 }} />)
    expect(engine.args?.expression).toBe('excited')
    expect(engine.args?.gaze).toEqual({ x: 0, y: 1 })
    expect(engine.args?.mute).toBe(false)
    expect(engine.args?.tuning.gazeMax).toBeUndefined()
    expect(Object.keys(engine.args?.perExpressionEffects ?? {})).not.toHaveLength(0)
    fireEvent.click(screen.getByLabelText('bitbag'))
    expect(engine.poke).toHaveBeenCalledTimes(1)
  })

  it('holds one quiet face when the reader asks for reduced motion', () => {
    preferReducedMotion(true)
    const handle = createRef<BitbagHandle>()
    render(<Bitbag expression="excited" gaze={{ x: 0, y: 1 }} handleRef={handle} />)
    expect(engine.args?.expression).toBe('inquisitive')
    expect(engine.args?.gaze).toBeNull()
    expect(engine.args?.mute).toBe(true)
    expect(engine.args?.tuning).toMatchObject({ gazeMax: 0, tiltMax: 0, leanMax: 0 })
    expect(engine.args?.perExpressionEffects).toEqual({})
    expect(engine.args?.blinkSuppressed).toEqual(EXPRESSIONS)
    // No poke, by click or by his host: the giggle is a looping animation.
    const svg = screen.getByLabelText('bitbag')
    fireEvent.click(svg)
    act(() => handle.current?.poke())
    expect(engine.poke).not.toHaveBeenCalled()
    expect(svg.style.cursor).not.toBe('pointer')
  })
})
