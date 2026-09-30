import { describe, expect, it } from 'vitest'
import { deepestSelectedLevel, pinAll, pinKeyFor } from '../blocks/stack-frontier'

const lvl = (selectedId: string | null) => ({ selectedId })

describe('deepestSelectedLevel', () => {
  it('is -1 for an empty stack', () => {
    expect(deepestSelectedLevel([])).toBe(-1)
  })

  it('is -1 when nothing is selected anywhere', () => {
    expect(deepestSelectedLevel([lvl(null), lvl(null)])).toBe(-1)
  })

  it('is the last level when every level is selected', () => {
    expect(deepestSelectedLevel([lvl('a'), lvl('b'), lvl('c')])).toBe(2)
  })

  it('is the level above the first unselected one', () => {
    expect(deepestSelectedLevel([lvl('a'), lvl('b'), lvl(null)])).toBe(1)
  })

  // THE GAP CASE. A deeper level can carry a selection while a shallower one does not (a level
  // that publishes a default, or one whose selection survived its parent being cleared). The
  // frontier stops at the FIRST hole — the stack below it is not reachable, so the leaf the user
  // can actually back out of is the level above the hole, not the deepest non-null one.
  it('stops at the FIRST unselected level, not the deepest selected one', () => {
    expect(deepestSelectedLevel([lvl('a'), lvl(null), lvl('c')])).toBe(0)
  })

  it('is -1 when the hole is the very first level', () => {
    expect(deepestSelectedLevel([lvl(null), lvl('b')])).toBe(-1)
  })
})

// The one rule behind every "all" gesture (⌘-click on a «/», and <<< / >>>). Stack [a, b, c] with c
// the choosing frontier: coverableCount = 2.
describe('pinAll', () => {
  const ids = ['a', 'b', 'c']
  const cFrontier = pinKeyFor('c', 2, 2)

  it('keeps a cover already on the frontier when a PARENT is ⌘-clicked shut', () => {
    // The detail's « covered c; a ⌘-click on a's toggle must not spring it back open.
    const next = pinAll({ [cFrontier]: true }, ids, 2, true, false)
    expect(next).toEqual({ a: true, b: true, [cFrontier]: true })
  })

  it('never covers the frontier from a parent, and stores no pin that would spring later', () => {
    const next = pinAll({}, ids, 2, true, false)
    expect(next).toEqual({ a: true, b: true })
  })

  it('pins the frontier under BOTH keys from its own toggle (<<<), so it stays covered once chosen in', () => {
    const next = pinAll({}, ids, 2, true, true)
    expect(next).toEqual({ a: true, b: true, c: true, [cFrontier]: true })
  })

  it('opens the frontier from anywhere', () => {
    const next = pinAll({ c: true, [cFrontier]: true }, ids, 2, false, false)
    expect(next).toEqual({ a: false, b: false, c: false, [cFrontier]: false })
  })

  it('keeps the pins of lists not rendered now', () => {
    expect(pinAll({ gone: true }, ids, 3, true, false)).toMatchObject({ gone: true })
  })
})
