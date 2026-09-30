"use client";

import { useState } from "react";
import { Label } from "@agenticdevelopertoolkit/ui/components/label";
import { Select } from "@agenticdevelopertoolkit/ui/components/select";
import { Stat } from "@agenticdevelopertoolkit/ui/components/stat";
import { Alert, AlertTitle, AlertDescription } from "@agenticdevelopertoolkit/ui/components/alert";
import { errorMessage } from "@agenticdevelopertoolkit/ui/lib/errors";
import { formatMicros } from "@agentic-toolkit/adh-ui/money";
import {
  formatBytes,
  formatCompact,
  formatCount,
  formatDuration,
} from "@agenticdevelopertoolkit/ui/lib/quantities";
import { DateRangePicker } from "@agentic-toolkit/adh-ui/components/date-range-picker";
import {
  TimeSeriesChart,
  type TimeSeriesPoint,
  type TimeSeriesSeries,
} from "@agentic-toolkit/adh-ui/components/time-series-chart";
import {
  useInsightOverview,
  type InsightInterval,
  type InsightOverview,
} from "../api/insight";
import { lastDays, todayUtc } from "../costs/days";

// The platform's metered usage over time: traffic, the time spent serving it, LLM tokens,
// messaging, and the direct cost it priced out to. The enforcement/tiers console is the separate
// Usage Limits pane; this one only reads.

type OverviewPoint = InsightOverview["points"][number];

const INTERVALS: { value: InsightInterval; label: string }[] = [
  { value: "day", label: "Day" },
  { value: "week", label: "Week" },
  { value: "month", label: "Month" },
];

/** One chart: which point fields it draws, and how its values read. */
interface ChartSpec {
  title: string;
  series: TimeSeriesSeries[];
  format: (n: number) => string;
  value: (p: OverviewPoint) => Record<string, number | null>;
}

// Each chart holds measures on ONE scale — two scales are two charts. Reasoning tokens are
// already inside `output`, so they are not drawn as a kind of their own.
const CHARTS: ChartSpec[] = [
  {
    title: "Requests",
    series: [{ key: "requests", label: "Requests" }],
    format: formatCompact,
    value: (p) => ({ requests: p.requests }),
  },
  {
    title: "Data",
    series: [
      { key: "bytesIn", label: "In" },
      { key: "bytesOut", label: "Out" },
    ],
    format: formatBytes,
    value: (p) => ({ bytesIn: p.bytesIn, bytesOut: p.bytesOut }),
  },
  {
    title: "Server & DB time",
    series: [
      { key: "serverMs", label: "Server" },
      { key: "dbMs", label: "Database" },
    ],
    format: formatDuration,
    value: (p) => ({ serverMs: p.serverMs, dbMs: p.dbMs }),
  },
  {
    title: "LLM tokens",
    series: [
      { key: "input", label: "Input" },
      { key: "output", label: "Output" },
      { key: "cacheRead", label: "Cache read" },
      { key: "cacheWrite", label: "Cache write" },
    ],
    format: formatCompact,
    value: ({ llmTokens: t }) => ({
      input: t.input,
      output: t.output,
      cacheRead: t.cacheRead,
      cacheWrite: t.cacheWrite,
    }),
  },
  {
    title: "Messaging",
    series: [
      { key: "emails", label: "Emails" },
      { key: "smsSegments", label: "SMS" },
    ],
    format: formatCompact,
    value: (p) => ({ emails: p.emails, smsSegments: p.smsSegments }),
  },
  {
    title: "Direct cost",
    series: [{ key: "directMicros", label: "Direct cost" }],
    // An unpriced bucket is `null`: a gap in the line, never a drop to $0.00.
    format: (n) => formatMicros(Math.round(n)),
    value: (p) => ({ directMicros: p.directMicros }),
  },
];

export interface OverviewTotals {
  requests: number;
  bytesIn: number;
  bytesOut: number;
  serverMs: number;
  dbMs: number;
  llmTokens: number;
  emails: number;
  smsSegments: number;
  /** `null` when every bucket is unpriced. */
  directMicros: number | null;
  /** Some bucket is unpriced, so the direct figure is a floor. */
  directIsFloor: boolean;
}

/** The range's totals over every bucket. Tokens total input + output + cache (reasoning is in output). */
export function overviewTotals(points: readonly OverviewPoint[]): OverviewTotals {
  const sum = (f: (p: OverviewPoint) => number) => points.reduce((n, p) => n + f(p), 0);
  const priced = points.filter((p) => p.directMicros !== null);
  return {
    requests: sum((p) => p.requests),
    bytesIn: sum((p) => p.bytesIn),
    bytesOut: sum((p) => p.bytesOut),
    serverMs: sum((p) => p.serverMs),
    dbMs: sum((p) => p.dbMs),
    llmTokens: sum(
      ({ llmTokens: t }) => t.input + t.output + t.cacheRead + t.cacheWrite,
    ),
    emails: sum((p) => p.emails),
    smsSegments: sum((p) => p.smsSegments),
    directMicros:
      priced.length === 0 && points.length > 0
        ? null
        : priced.reduce((n, p) => n + p.directMicros!, 0),
    directIsFloor: priced.length > 0 && priced.length < points.length,
  };
}

function Totals({ totals }: { totals: OverviewTotals }) {
  const direct =
    totals.directMicros === null
      ? "Unpriced"
      : `${totals.directIsFloor ? "≥ " : ""}${formatMicros(totals.directMicros)}`;
  const stats: [string, string][] = [
    ["Requests", formatCount(totals.requests)],
    ["Data in", formatBytes(totals.bytesIn)],
    ["Data out", formatBytes(totals.bytesOut)],
    ["Server time", formatDuration(totals.serverMs)],
    ["DB time", formatDuration(totals.dbMs)],
    ["LLM tokens", formatCount(totals.llmTokens)],
    ["Emails", formatCount(totals.emails)],
    ["SMS", formatCount(totals.smsSegments)],
    ["Direct cost", direct],
  ];
  return (
    <section
      aria-label="Totals"
      className="mb-6 flex flex-wrap gap-6 rounded-lg border border-apt-border bg-apt-surface p-4"
    >
      {stats.map(([label, value]) => (
        <Stat key={label} label={label} value={value} className="items-start" />
      ))}
    </section>
  );
}

export function UsageOverviewPane() {
  const today = todayUtc();
  const [range, setRange] = useState(() => lastDays(30, today));
  const [interval, chooseInterval] = useState<InsightInterval>("day");
  const overview = useInsightOverview(range, interval);
  const points = overview.data?.points ?? [];
  const chartPoints = (spec: ChartSpec): TimeSeriesPoint[] =>
    points.map((p) => ({ x: p.start, ...spec.value(p) }));

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-apt-text">Usage overview</h1>

      <div className="mb-6 flex flex-wrap items-end gap-6">
        <DateRangePicker value={range} onChange={setRange} max={today} />
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="usage-overview-interval">Interval</Label>
          <Select
            id="usage-overview-interval"
            value={interval}
            onChange={(e) => chooseInterval(e.target.value as InsightInterval)}
          >
            {INTERVALS.map((i) => (
              <option key={i.value} value={i.value}>
                {i.label}
              </option>
            ))}
          </Select>
        </div>
      </div>

      {overview.error != null && (
        <Alert variant="error" className="mb-6">
          <AlertTitle>Couldn't load the usage overview</AlertTitle>
          <AlertDescription>{errorMessage(overview.error)}</AlertDescription>
        </Alert>
      )}

      {overview.isLoading && <p className="text-sm text-apt-text-muted">Loading…</p>}

      {overview.data && (
        <>
          <Totals totals={overviewTotals(points)} />
          <div className="grid gap-6 lg:grid-cols-2">
            {CHARTS.map((spec) => (
              <section
                key={spec.title}
                aria-label={spec.title}
                className="rounded-lg border border-apt-border bg-apt-surface p-4"
              >
                <h2 className="mb-2 text-lg font-semibold text-apt-text">{spec.title}</h2>
                <TimeSeriesChart
                  points={chartPoints(spec)}
                  series={spec.series}
                  format={spec.format}
                />
              </section>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
