"use client";

import { useState } from "react";
import { Label } from "@agenticdevelopertoolkit/ui/components/label";
import { Select } from "@agenticdevelopertoolkit/ui/components/select";
import { Pagination } from "@agenticdevelopertoolkit/ui/components/pagination";
import { Alert, AlertTitle, AlertDescription } from "@agenticdevelopertoolkit/ui/components/alert";
import { errorMessage } from "@agenticdevelopertoolkit/ui/lib/errors";
import { formatMicros } from "@agentic-toolkit/adh-ui/money";
import {
  DateRangePicker,
  type DateRange,
} from "@agentic-toolkit/adh-ui/components/date-range-picker";
import { useBreakdown, type BreakdownBy, type BreakdownSort } from "../api/insight";
import { BreakdownTable, ESTIMATE_HINT, unattributedLast } from "../breakdown/BreakdownTable";
import { BreakdownDetail } from "../breakdown/BreakdownDetail";
import { lastDays, todayUtc } from "../costs/days";

// Who drives the platform's usage and cost: one row per organization, ecosystem, user or persona,
// ranked and paged by the server. Direct cost is the measured figure; the estimated total adds a
// share of the fixed hosting cost, split by server + DB time, and is labelled an estimate.

const PAGE_SIZE = 50;

const DIMENSIONS: { value: BreakdownBy; label: string }[] = [
  { value: "organization", label: "Organization" },
  { value: "ecosystem", label: "Ecosystem" },
  { value: "user", label: "User" },
  { value: "persona", label: "Persona" },
];

export function BreakdownPane() {
  const today = todayUtc();
  const [by, setBy] = useState<BreakdownBy>("organization");
  const [range, setRange] = useState<DateRange>(() => lastDays(30, today));
  const [sort, setSort] = useState<BreakdownSort>("direct");
  const [page, setPage] = useState(1);
  const [openKey, setOpenKey] = useState<string>();

  const breakdown = useBreakdown({
    by,
    ...range,
    sort,
    limit: PAGE_SIZE,
    offset: (page - 1) * PAGE_SIZE,
  });
  const data = breakdown.data;

  // A new grouping or ranking starts again from its first page; a new grouping also closes the
  // open row, whose key belongs to the old dimension.
  const chooseBy = (next: BreakdownBy) => {
    setBy(next);
    setPage(1);
    setOpenKey(undefined);
  };
  const chooseRange = (next: DateRange) => {
    setRange(next);
    setPage(1);
  };
  const chooseSort = (next: BreakdownSort) => {
    setSort(next);
    setPage(1);
  };

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-apt-text">Breakdown</h1>

      <div className="mb-6 flex flex-wrap items-end gap-6">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="breakdown-by">Group by</Label>
          <Select
            id="breakdown-by"
            value={by}
            onChange={(e) => chooseBy(e.target.value as BreakdownBy)}
          >
            {DIMENSIONS.map((d) => (
              <option key={d.value} value={d.value}>
                {d.label}
              </option>
            ))}
          </Select>
        </div>
        <DateRangePicker value={range} onChange={chooseRange} max={today} />
      </div>

      {breakdown.error != null && (
        <Alert variant="error" className="mb-6">
          <AlertTitle>Couldn't load the breakdown</AlertTitle>
          <AlertDescription>{errorMessage(breakdown.error)}</AlertDescription>
        </Alert>
      )}

      <BreakdownTable
        by={by}
        rows={unattributedLast(data?.rows ?? [])}
        loading={breakdown.isLoading}
        sort={sort}
        onSortChange={chooseSort}
        openKey={openKey}
        onOpen={setOpenKey}
      />

      {data && (
        <p className="mt-2 px-2 text-sm text-apt-text-muted">
          Estimated total, an estimate: {ESTIMATE_HINT}. Fixed hosting over this range:{" "}
          {formatMicros(data.fixedMicros)}.
        </p>
      )}

      <Pagination
        className="mt-4"
        page={page}
        totalPages={Math.ceil((data?.total ?? 0) / PAGE_SIZE)}
        onPageChange={setPage}
      />

      {openKey !== undefined && (
        <BreakdownDetail
          by={by}
          itemKey={openKey}
          range={range}
          onClose={() => setOpenKey(undefined)}
        />
      )}
    </div>
  );
}
