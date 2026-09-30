"use client"

import * as React from "react"
import {
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"

/**
 * One x position: `x` is its label (a day, a week's first day, a month), and every
 * other key is a series value. `null` is a gap — "no value", drawn as a break in the
 * line, never as a zero.
 */
export type TimeSeriesPoint = { x: string } & { [key: string]: string | number | null }

export interface TimeSeriesSeries {
  /** The point key this series reads. */
  key: string
  label: string
}

export interface TimeSeriesChartProps {
  points: readonly TimeSeriesPoint[]
  series: readonly TimeSeriesSeries[]
  /** Formats a value for the y axis and the tooltip. Default: the number as-is. */
  format?: (value: number) => string
  /** Plot height in px; the width follows the container. */
  height?: number
}

/**
 * The categorical series colours, in their fixed assignment order — the toolkit's own
 * tagging hues, hue-stable across themes (`--color-apt-cat-*`, which sit outside the status
 * spectrum), ordered so adjacent series stay apart for colour-blind readers. A series
 * keeps its slot by position in `series`, never by rank in the data.
 */
const SERIES_COLORS = [
  "var(--color-apt-cat-blue, #2f80ff)",
  "var(--color-apt-cat-orange, #f6821f)",
  "var(--color-apt-cat-violet, #a855f7)",
  "var(--color-apt-cat-pink, #ff4d9e)",
] as const

const AXIS_TICK = { fill: "var(--color-apt-text-dim)", fontSize: 12 }
const GRID_STROKE = "var(--color-apt-border)"

/**
 * A thin line chart over time, for a handful of series on ONE y scale (two measures
 * of different scale belong in two charts, not a second axis). A crosshair tooltip
 * reads every series at the hovered x; a legend names them once there are two or
 * more, so identity is never colour alone.
 *
 * At most four series: a fifth would need a generated hue, which is exactly the
 * colour a reader can no longer tell apart — fold the tail into "Other" instead.
 */
export function TimeSeriesChart({
  points,
  series,
  format = String,
  height = 240,
}: TimeSeriesChartProps) {
  if (series.length > SERIES_COLORS.length) {
    throw new RangeError(
      `TimeSeriesChart draws at most ${SERIES_COLORS.length} series, got ${series.length}`,
    )
  }
  return (
    <ResponsiveContainer width="100%" height={height}>
      <LineChart data={points as TimeSeriesPoint[]} margin={{ top: 8, right: 16, bottom: 0, left: 8 }}>
        <CartesianGrid vertical={false} stroke={GRID_STROKE} strokeOpacity={0.5} />
        <XAxis
          dataKey="x"
          tick={AXIS_TICK}
          tickLine={false}
          axisLine={{ stroke: GRID_STROKE }}
          minTickGap={24}
        />
        <YAxis
          tick={AXIS_TICK}
          tickLine={false}
          axisLine={false}
          tickFormatter={(v: number) => format(v)}
          width={72}
        />
        <Tooltip
          cursor={{ stroke: GRID_STROKE }}
          contentStyle={{
            background: "var(--color-apt-surface-2)",
            border: "1px solid var(--color-apt-border)",
            borderRadius: 8,
            color: "var(--color-apt-text)",
          }}
          labelStyle={{ color: "var(--color-apt-text-muted)" }}
          itemStyle={{ color: "var(--color-apt-text)" }}
          formatter={(value) => (typeof value === "number" ? format(value) : "—")}
        />
        {series.length >= 2 && (
          <Legend
            iconType="plainline"
            wrapperStyle={{ color: "var(--color-apt-text-muted)", fontSize: 12 }}
          />
        )}
        {series.map((s, i) => (
          <Line
            key={s.key}
            type="monotone"
            dataKey={s.key}
            name={s.label}
            stroke={SERIES_COLORS[i]}
            strokeWidth={2}
            dot={false}
            activeDot={{ r: 4, strokeWidth: 2, stroke: "var(--color-apt-bg)" }}
            connectNulls={false}
            isAnimationActive={false}
          />
        ))}
      </LineChart>
    </ResponsiveContainer>
  )
}
