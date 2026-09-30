import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { TimeSeriesChart, type TimeSeriesPoint } from '../components/time-series-chart'

// jsdom lays nothing out, so ResponsiveContainer measures 0×0 and draws no chart.
// Give the container a real box so the plot renders — and the legend a one-line one,
// since recharts subtracts the legend's measured height from the plot's.
function box(width: number, height: number): DOMRect {
  return { width, height, top: 0, left: 0, right: width, bottom: height, x: 0, y: 0, toJSON: () => ({}) } as DOMRect
}

beforeEach(() => {
  vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect').mockImplementation(function (this: HTMLElement) {
    return this.classList.contains('recharts-legend-wrapper') ? box(600, 20) : box(600, 240)
  })
  vi.spyOn(HTMLElement.prototype, 'clientWidth', 'get').mockReturnValue(600)
  vi.spyOn(HTMLElement.prototype, 'clientHeight', 'get').mockReturnValue(240)
  vi.spyOn(HTMLElement.prototype, 'offsetWidth', 'get').mockReturnValue(600)
  vi.spyOn(HTMLElement.prototype, 'offsetHeight', 'get').mockReturnValue(240)
})

afterEach(() => {
  vi.restoreAllMocks()
})

const points: TimeSeriesPoint[] = [
  { x: '2026-09-01', direct: 1_000_000, fixed: 500_000 },
  { x: '2026-09-02', direct: null, fixed: 500_000 },
  { x: '2026-09-03', direct: 3_000_000, fixed: 500_000 },
]

// Recharts draws its lines a commit after the first render (once the legend has been
// measured), so read them after that settles.
async function linePaths(container: HTMLElement, expected: number) {
  await waitFor(() => expect(container.querySelectorAll('path.recharts-line-curve')).toHaveLength(expected))
  return [...container.querySelectorAll('path.recharts-line-curve')]
}

describe('TimeSeriesChart', () => {
  it('draws one line per series with a legend naming each', async () => {
    const { container } = render(
      <TimeSeriesChart
        points={points}
        series={[
          { key: 'direct', label: 'Direct' },
          { key: 'fixed', label: 'Fixed' },
        ]}
      />,
    )
    await linePaths(container, 2)
    expect(screen.getByText('Direct')).toBeInTheDocument()
    expect(screen.getByText('Fixed')).toBeInTheDocument()
  })

  it('colours series by position in the fixed order', async () => {
    const { container } = render(
      <TimeSeriesChart
        points={points}
        series={[
          { key: 'direct', label: 'Direct' },
          { key: 'fixed', label: 'Fixed' },
        ]}
      />,
    )
    const strokes = (await linePaths(container, 2)).map((p) => p.getAttribute('stroke'))
    expect(strokes).toEqual([
      'var(--color-apt-cat-blue, #2f80ff)',
      'var(--color-apt-cat-orange, #f6821f)',
    ])
  })

  it('shows no legend for a single series', async () => {
    const { container } = render(
      <TimeSeriesChart points={points} series={[{ key: 'direct', label: 'Direct' }]} />,
    )
    await linePaths(container, 1)
    expect(container.querySelector('.recharts-legend-wrapper')).toBeNull()
  })

  it('formats y-axis ticks with the given formatter', () => {
    render(
      <TimeSeriesChart
        points={points}
        series={[{ key: 'direct', label: 'Direct' }]}
        format={(v) => `v${v}`}
      />,
    )
    expect(screen.getAllByText(/^v\d+$/).length).toBeGreaterThan(0)
  })

  it('refuses more series than it has colours', () => {
    const series = ['a', 'b', 'c', 'd', 'e'].map((k) => ({ key: k, label: k }))
    vi.spyOn(console, 'error').mockImplementation(() => {})
    expect(() => render(<TimeSeriesChart points={points} series={series} />)).toThrow(RangeError)
  })
})
