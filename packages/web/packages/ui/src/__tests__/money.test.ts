import { describe, it, expect } from 'vitest'
import { formatMicros, formatMicrosFloor } from '../lib/money'

describe('formatMicros', () => {
  it('shows an unpriced amount as a dash, never a zero', () => {
    expect(formatMicros(null)).toBe('—')
  })

  it('shows zero as $0.00', () => {
    expect(formatMicros(0)).toBe('$0.00')
  })

  it('formats cents with thousands grouping', () => {
    expect(formatMicros(1_234_560_000)).toBe('$1,234.56')
    expect(formatMicros(10_000)).toBe('$0.01')
    expect(formatMicros(1_000_000)).toBe('$1.00')
    expect(formatMicros(1_234_567_890_000)).toBe('$1,234,567.89')
  })

  it('rounds to the cent half away from zero, on the integer', () => {
    expect(formatMicros(15_000)).toBe('$0.02')
    expect(formatMicros(14_999)).toBe('$0.01')
    // 1.005 dollars: the float path (1.005).toFixed(2) gives "1.00".
    expect(formatMicros(1_005_000)).toBe('$1.01')
    expect(formatMicros(-15_000)).toBe('-$0.02')
    expect(formatMicros(-1_005_000)).toBe('-$1.01')
  })

  it('shows sub-cent amounts to four decimals', () => {
    expect(formatMicros(1_200)).toBe('$0.0012')
    expect(formatMicros(9_949)).toBe('$0.0099')
    expect(formatMicros(9_999)).toBe('$0.0100')
    expect(formatMicros(50)).toBe('$0.0001')
    expect(formatMicros(-1_200)).toBe('-$0.0012')
  })

  it('shows an amount that rounds to zero unsigned', () => {
    expect(formatMicros(49)).toBe('$0.0000')
    expect(formatMicros(-49)).toBe('$0.0000')
  })

  it('keeps the sign on large negatives', () => {
    expect(formatMicros(-1_234_560_000)).toBe('-$1,234.56')
  })

  it('throws on a non-integer input', () => {
    expect(() => formatMicros(1.5)).toThrow(RangeError)
    expect(() => formatMicros(Number.NaN)).toThrow(RangeError)
  })
})

describe('formatMicrosFloor', () => {
  it('marks a floor with a leading ≥', () => {
    expect(formatMicrosFloor(1_005_000, true)).toBe('≥ $1.01')
    expect(formatMicrosFloor(0, true)).toBe('≥ $0.00')
  })

  it('reads exactly like formatMicros when not a floor', () => {
    expect(formatMicrosFloor(1_005_000, false)).toBe('$1.01')
  })

  it('keeps an unpriced amount a dash, floor or not', () => {
    expect(formatMicrosFloor(null, true)).toBe('—')
    expect(formatMicrosFloor(null, false)).toBe('—')
  })
})
