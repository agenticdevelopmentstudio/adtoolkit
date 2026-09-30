"use client";

import { X } from "lucide-react";
import { Button } from "@agenticdevelopertoolkit/ui/components/button";
import { DataTable, type DataTableColumn } from "@agenticdevelopertoolkit/ui/components/data-table";
import { Alert, AlertTitle, AlertDescription } from "@agenticdevelopertoolkit/ui/components/alert";
import { errorMessage } from "@agenticdevelopertoolkit/ui/lib/errors";
import { formatMicros } from "@agentic-toolkit/adh-ui/money";
import { formatCompact } from "@agenticdevelopertoolkit/ui/lib/quantities";
import { TimeSeriesChart } from "@agentic-toolkit/adh-ui/components/time-series-chart";
import {
  useBreakdownDetail,
  type BreakdownBy,
  type InsightItem,
  type InsightRange,
} from "../api/insight";
import { CostCell, itemId, quantitiesText } from "../costs/CostItemsTable";

const ITEM_COLUMNS: DataTableColumn<InsightItem>[] = [
  { key: "category", header: "Category", width: "8rem", render: (item) => item.category },
  { key: "provider", header: "Provider", width: "10rem", render: (item) => item.provider },
  {
    key: "sku",
    header: "SKU",
    render: (item) => <span className="font-mono text-sm">{item.sku}</span>,
  },
  {
    key: "quantities",
    header: "Quantities",
    render: (item) => (
      <span className="text-sm text-apt-text-muted tabular-nums">
        {quantitiesText(item.quantities)}
      </span>
    ),
  },
  {
    key: "cost",
    header: "Cost",
    width: "8rem",
    align: "end",
    render: (item) => <CostCell item={item} />,
  },
];

/** One breakdown row opened: its daily direct cost and requests, and the items behind them. */
export function BreakdownDetail({
  by,
  itemKey,
  range,
  onClose,
}: {
  by: BreakdownBy;
  itemKey: string;
  range: InsightRange;
  onClose: () => void;
}) {
  const detail = useBreakdownDetail(by, itemKey, range);
  const daily = detail.data?.daily ?? [];

  return (
    <section
      aria-label="Breakdown detail"
      className="mt-6 rounded-lg border border-apt-border bg-apt-surface p-4"
    >
      <div className="mb-4 flex items-center justify-between gap-4">
        <h2 className="text-lg font-semibold text-apt-text">{detail.data?.label ?? "Detail"}</h2>
        <Button variant="ghost" size="sm" onClick={onClose}>
          <X data-icon="inline-start" />
          Close
        </Button>
      </div>

      {detail.error != null && (
        <Alert variant="error" className="mb-4">
          <AlertTitle>Couldn't load the detail</AlertTitle>
          <AlertDescription>{errorMessage(detail.error)}</AlertDescription>
        </Alert>
      )}

      {detail.data && (
        <>
          {/* Two scales, so two charts. An unpriced day is a gap, never a $0.00. */}
          <div className="mb-6 grid gap-6 lg:grid-cols-2">
            <div>
              <h3 className="mb-2 text-sm font-medium text-apt-text-muted">Daily direct cost</h3>
              <TimeSeriesChart
                points={daily.map((d) => ({ x: d.day, directMicros: d.directMicros }))}
                series={[{ key: "directMicros", label: "Direct cost" }]}
                format={(n) => formatMicros(Math.round(n))}
                height={180}
              />
            </div>
            <div>
              <h3 className="mb-2 text-sm font-medium text-apt-text-muted">Daily requests</h3>
              <TimeSeriesChart
                points={daily.map((d) => ({ x: d.day, requests: d.requests }))}
                series={[{ key: "requests", label: "Requests" }]}
                format={formatCompact}
                height={180}
              />
            </div>
          </div>
          <DataTable<InsightItem>
            ariaLabel="Items"
            columns={ITEM_COLUMNS}
            rows={detail.data.items}
            getRowId={itemId}
            emptyLabel="No items in this range."
          />
        </>
      )}
      {detail.isLoading && <p className="text-sm text-apt-text-muted">Loading…</p>}
    </section>
  );
}
