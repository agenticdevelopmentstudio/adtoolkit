"use client";

import { Input } from "@agenticdevelopertoolkit/ui/components/input";
import { Label } from "@agenticdevelopertoolkit/ui/components/label";
import { Button } from "@agenticdevelopertoolkit/ui/components/button";
import { Alert, AlertTitle, AlertDescription } from "@agenticdevelopertoolkit/ui/components/alert";
import { errorMessage } from "@agenticdevelopertoolkit/ui/lib/errors";
import { formatMicros } from "@agentic-toolkit/adh-ui/money";
import type { RunRate } from "../api/insight";

function Stat({ label, value, title }: { label: string; value: string; title?: string }) {
  return (
    <div className="flex flex-col gap-1" title={title}>
      <span className="text-xs uppercase tracking-wide text-apt-text-dim">{label}</span>
      <span className="text-xl font-semibold tabular-nums text-apt-text">{value}</span>
    </div>
  );
}

/**
 * The month's headline numbers: a month picker, month to date, projected month end, fixed cost,
 * and how many items have no price. Unpriced items add nothing to the direct figures, so a
 * non-zero count says they are a floor; the count is a button that scrolls to those items.
 */
export function RunRateHeader({
  month,
  onMonthChange,
  maxMonth,
  runRate,
  error,
  onShowUnpriced,
}: {
  month: string;
  onMonthChange: (month: string) => void;
  /** The latest month the backend accepts (the current one). */
  maxMonth: string;
  runRate: RunRate | undefined;
  /** The run-rate read's failure, shown here rather than under the items. */
  error?: unknown;
  onShowUnpriced: () => void;
}) {
  const unpriced = runRate?.unpricedItems ?? 0;
  // Unpriced items add nothing to the direct figures, so with any of them the figure is a floor
  // and says so (same `≥` as the items table) rather than headlining a bare $0.00.
  const floor = unpriced > 0 ? "≥ " : "";
  const money = (micros: number | undefined, floored = false) =>
    micros === undefined ? "—" : `${floored ? floor : ""}${formatMicros(micros)}`;
  return (
    <section
      aria-label="Run rate"
      className="mb-6 rounded-lg border border-apt-border bg-apt-surface p-4"
    >
      {error != null && (
        <Alert variant="error" className="mb-4">
          <AlertTitle>Couldn't load the run rate</AlertTitle>
          <AlertDescription>{errorMessage(error)}</AlertDescription>
        </Alert>
      )}
      <div className="flex flex-wrap items-end gap-6">
        <div className="flex flex-col gap-1">
          <Label htmlFor="costs-month">Month</Label>
          <Input
            id="costs-month"
            type="month"
            value={month}
            max={maxMonth}
            onChange={(e) => e.target.value && onMonthChange(e.target.value)}
          />
        </div>
        <Stat
          label="Month to date"
          value={money(runRate?.directToDateMicros, true)}
          title={runRate ? `Direct cost over ${runRate.elapsedDays} complete days` : undefined}
        />
        <Stat
          label="Projected month end"
          value={money(runRate?.projectedMonthMicros, true)}
          title="Direct to date ÷ elapsed days × days in month, plus fixed"
        />
        <Stat label="Fixed" value={money(runRate?.fixedMonthMicros)} />
        {unpriced > 0 && (
          <Button variant="ghost" size="sm" onClick={onShowUnpriced}>
            {unpriced === 1 ? "1 unpriced item" : `${unpriced} unpriced items`}
          </Button>
        )}
      </div>
      {unpriced > 0 && (
        <p className="mt-3 text-sm text-apt-text-muted">
          Unpriced items add nothing to these figures, so they are a floor until each has a price.
        </p>
      )}
    </section>
  );
}
