import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { DateRangePicker } from '../components/date-range-picker'

const value = { from: '2026-09-01', to: '2026-09-30' }

describe('DateRangePicker', () => {
  it('shows both ends, each bounding the other', () => {
    render(<DateRangePicker value={value} onChange={() => {}} min="2026-01-01" max="2026-12-31" />)
    const from = screen.getByLabelText('From')
    const to = screen.getByLabelText('To')
    expect(from).toHaveValue('2026-09-01')
    expect(to).toHaveValue('2026-09-30')
    expect(from).toHaveAttribute('min', '2026-01-01')
    expect(from).toHaveAttribute('max', '2026-09-30')
    expect(to).toHaveAttribute('min', '2026-09-01')
    expect(to).toHaveAttribute('max', '2026-12-31')
  })

  it('reports a changed end with the other kept', () => {
    const onChange = vi.fn()
    render(<DateRangePicker value={value} onChange={onChange} />)
    fireEvent.change(screen.getByLabelText('From'), { target: { value: '2026-09-10' } })
    expect(onChange).toHaveBeenCalledWith({ from: '2026-09-10', to: '2026-09-30' })
    fireEvent.change(screen.getByLabelText('To'), { target: { value: '2026-09-20' } })
    expect(onChange).toHaveBeenLastCalledWith({ from: '2026-09-01', to: '2026-09-20' })
  })

  it('ignores a cleared field', () => {
    const onChange = vi.fn()
    render(<DateRangePicker value={value} onChange={onChange} />)
    fireEvent.change(screen.getByLabelText('To'), { target: { value: '' } })
    expect(onChange).not.toHaveBeenCalled()
  })
})
