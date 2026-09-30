"use client";

import { useMemo } from "react";
import { Bot, Boxes, Building2, Info, User, type LucideIcon } from "lucide-react";
import { DataTable, type DataTableColumn } from "@agenticdevelopertoolkit/ui/components/data-table";
import { formatMicros } from "@agentic-toolkit/adh-ui/money";
import { formatCompact, formatCount, formatDuration } from "@agentic-toolkit/profile/usage-format";
import type { Breakdown, BreakdownBy, BreakdownSort } from "../api/insight";

export type BreakdownRow = Breakdown["rows"][number];

/** The nil uuid: usage no organization/ecosystem/user/persona could be attributed to. */
export const UNATTRIBUTED_KEY = "00000000-0000-0000-0000-000000000000";

/** What the estimated column adds to the direct cost, and how it is split. */
export const ESTIMATE_HINT =
  "Direct cost plus a share of fixed hosting, split by server + DB time";

const DIMENSION_ICON: Record<BreakdownBy, LucideIcon> = {
  organization: Building2,
  ecosystem: Boxes,
  user: User,
  persona: Bot,
};

/** The page's rows in server order, with the unattributed row moved to the end. */
export function unattributedLast(rows: readonly BreakdownRow[]): BreakdownRow[] {
  return [
    ...rows.filter((r) => r.key !== UNATTRIBUTED_KEY),
    ...rows.filter((r) => r.key === UNATTRIBUTED_KEY),
  ];
}

/** Input + output + cache tokens (reasoning is already inside output). */
const tokensOf = ({ llmTokens: t }: BreakdownRow) =>
  t.input + t.output + t.cacheRead + t.cacheWrite;

/**
 * A row's direct cost. `null` is unpriced — "Unpriced", never `$0.00`; a priced row that still has
 * unpriced lines is a floor, `≥`, the same marks the Costs pane uses.
 */
export function DirectCell({ row }: { row: BreakdownRow }) {
  if (row.directMicros === null) return <span className="text-apt-orange">Unpriced</span>;
  return (
    <span className="tabular-nums">
      {row.unpricedLines > 0 ? "≥ " : ""}
      {formatMicros(row.directMicros)}
    </span>
  );
}

function EstimateHeader() {
  return (
    <span className="inline-flex items-center gap-1" title={ESTIMATE_HINT}>
      Estimated total
      <Info size={12} aria-label={ESTIMATE_HINT} />
    </span>
  );
}

/**
 * One page of the breakdown. Sorting is the server's (always highest first), so a sortable header
 * only names the key; clicking a row opens its detail.
 */
export function BreakdownTable({
  by,
  rows,
  loading,
  sort,
  onSortChange,
  openKey,
  onOpen,
}: {
  by: BreakdownBy;
  rows: BreakdownRow[];
  loading: boolean;
  sort: BreakdownSort;
  onSortChange: (sort: BreakdownSort) => void;
  openKey: string | undefined;
  onOpen: (key: string) => void;
}) {
  const Icon = DIMENSION_ICON[by];
  const columns = useMemo<DataTableColumn<BreakdownRow>[]>(
    () => [
      {
        key: "label",
        header: "Name",
        render: (row) => (
          <span className="inline-flex items-center gap-2 text-sm text-apt-text">
            <Icon size={14} className="shrink-0 text-apt-text-dim" aria-hidden />
            {row.label}
          </span>
        ),
      },
      {
        key: "requests",
        header: "Requests",
        sortable: true,
        align: "end",
        width: "7rem",
        render: (row) => <span className="tabular-nums">{formatCount(row.requests)}</span>,
      },
      {
        key: "time",
        header: "Server + DB time",
        align: "end",
        width: "9rem",
        render: (row) => (
          <span className="tabular-nums">{formatDuration(row.serverMs + row.dbMs)}</span>
        ),
      },
      {
        key: "tokens",
        header: "LLM tokens",
        align: "end",
        width: "7rem",
        render: (row) => <span className="tabular-nums">{formatCompact(tokensOf(row))}</span>,
      },
      {
        key: "direct",
        header: "Direct cost",
        sortable: true,
        align: "end",
        width: "8rem",
        render: (row) => <DirectCell row={row} />,
      },
      {
        key: "estimated",
        header: <EstimateHeader />,
        sortable: true,
        align: "end",
        width: "10rem",
        render: (row) => (
          <span className="tabular-nums text-apt-text-muted">
            {row.directMicros === null || row.unpricedLines > 0 ? "≥ " : ""}
            {formatMicros(row.estimatedMicros)}
          </span>
        ),
      },
    ],
    [Icon],
  );

  return (
    <DataTable<BreakdownRow>
      ariaLabel="Breakdown"
      columns={columns}
      rows={rows}
      getRowId={(row) => row.key}
      describeRow={(row) => row.label}
      loading={loading}
      emptyLabel="No usage in this range."
      sort={{ key: sort, dir: "desc" }}
      onSortChange={(next) => onSortChange(next.key as BreakdownSort)}
      selectedIds={openKey ? new Set([openKey]) : undefined}
      // One row open at a time: a click selects it, and selecting is opening.
      onSelectionChange={(ids) => {
        const [key] = ids;
        if (key !== undefined) onOpen(key);
      }}
    />
  );
}
