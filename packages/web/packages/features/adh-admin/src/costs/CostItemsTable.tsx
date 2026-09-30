"use client";

import { useMemo, useState } from "react";
import { Tag } from "lucide-react";
import { Badge } from "@agenticdevelopertoolkit/ui/components/badge";
import { Button } from "@agenticdevelopertoolkit/ui/components/button";
import { formatMicros } from "@agentic-toolkit/adh-ui/money";
import { formatCompact } from "@agenticdevelopertoolkit/ui/lib/quantities";
import {
  EditableList,
  useEditableList,
  type EditableListColumn,
  type EditableListFacet,
} from "../components/editable-list";
import type { InsightItem } from "../api/insight";
import { SetPriceDialog } from "./SetPriceDialog";

type Source = InsightItem["source"];

const SOURCE_LABEL: Record<Source, string> = {
  rate: "Rate",
  captured: "Captured",
  unpriced: "Unpriced",
  mixed: "Mixed",
  customer_key: "Customer key",
};

const SOURCE_TITLE: Record<Source, string> = {
  rate: "Priced by a rate an admin set",
  captured: "Priced by the cost the provider or catalog reported",
  unpriced: "No rate and no captured price — not guessed at",
  mixed: "Priced differently on different days of the range",
  customer_key: "Paid with the customer's own key — quantity only, never in our cost",
};

const SOURCE_VARIANT: Record<Source, "neutral" | "accent" | "orange" | "blue" | "success"> = {
  rate: "blue",
  captured: "success",
  unpriced: "orange",
  mixed: "accent",
  customer_key: "neutral",
};

/** `input_tokens 1.2M · requests 340`, the item's quantities in a line. */
export function quantitiesText(quantities: InsightItem["quantities"]): string {
  return Object.entries(quantities)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([key, n]) => `${key} ${formatCompact(n)}`)
    .join(" · ");
}

/**
 * The cost cell. `null` is unpriced and reads "Unpriced" — never `$0.00`, which would claim a
 * price of nothing. A priced item that still has unpriced lines is a floor, shown as `≥`. A
 * customer-key item costs us nothing by definition, so it shows a dash rather than a figure.
 */
export function CostCell({ item }: { item: InsightItem }) {
  if (item.source === "customer_key") {
    return <span className="text-apt-text-dim" title={SOURCE_TITLE.customer_key}>—</span>;
  }
  if (item.costMicros === null) {
    return <span className="text-apt-orange">Unpriced</span>;
  }
  const floor = item.unpricedLines > 0;
  return (
    <span
      className="tabular-nums"
      title={floor ? `${item.unpricedLines} line(s) have no price, so this is a floor` : undefined}
    >
      {floor ? "≥ " : ""}
      {formatMicros(item.costMicros)}
    </span>
  );
}

/** An item's identity across reports: category, provider and SKU. */
export const itemId = (item: InsightItem) => `${item.category}/${item.provider}/${item.sku}`;

/** The month's cost items, each with the source of its price, and Set price on the selected one. */
export function CostItemsTable({
  items,
  loading,
  error,
}: {
  items: InsightItem[] | undefined;
  loading: boolean;
  error: unknown;
}) {
  const [pricing, setPricing] = useState<InsightItem | null>(null);

  const columns = useMemo<EditableListColumn<InsightItem>[]>(
    () => [
      {
        key: "category",
        header: "Category",
        width: "8rem",
        value: (item) => item.category,
        render: (item) => <span className="text-sm text-apt-text">{item.category}</span>,
      },
      {
        key: "provider",
        header: "Provider",
        width: "10rem",
        value: (item) => item.provider,
        render: (item) => <span className="text-sm text-apt-text">{item.provider}</span>,
      },
      {
        key: "sku",
        header: "SKU",
        value: (item) => item.sku,
        render: (item) => <span className="font-mono text-sm text-apt-text">{item.sku}</span>,
      },
      {
        key: "quantities",
        header: "Quantities",
        value: (item) => quantitiesText(item.quantities),
        render: (item) => (
          <span className="truncate text-sm text-apt-text-muted tabular-nums">
            {quantitiesText(item.quantities)}
          </span>
        ),
      },
      {
        key: "source",
        header: "Price source",
        width: "9rem",
        value: (item) => SOURCE_LABEL[item.source],
        render: (item) => (
          <Badge variant={SOURCE_VARIANT[item.source]} title={SOURCE_TITLE[item.source]}>
            {SOURCE_LABEL[item.source]}
          </Badge>
        ),
      },
      {
        key: "cost",
        header: "Cost",
        width: "8rem",
        align: "end",
        // The number, so a sort is numeric; null (unpriced) sorts last in both directions.
        value: (item) => (item.source === "customer_key" ? null : item.costMicros),
        render: (item) => <CostCell item={item} />,
      },
    ],
    [],
  );

  const facets = useMemo<EditableListFacet<InsightItem>[]>(
    () => [
      { id: "source", label: "Price source", valuesOf: (item) => [SOURCE_LABEL[item.source]] },
      { id: "category", label: "Category", valuesOf: (item) => [item.category] },
    ],
    [],
  );

  const list = useEditableList<InsightItem>({
    rows: items,
    getRowId: itemId,
    columns,
    facets,
    initialSort: { key: "cost", dir: "desc" },
  });

  const selected = list.selectedRows;
  const target = selected.length === 1 ? selected[0]! : null;

  return (
    <>
      <EditableList<InsightItem>
        list={list}
        ariaLabel="Cost items"
        loading={loading}
        error={error}
        errorTitle="Couldn't load the cost items"
        columnWidthsKey="admin-costs-items"
        describeRow={itemId}
        searchPlaceholder="Provider, SKU, category"
        emptyLabel="No usage in this month."
        emptyFilteredLabel="No items match these filters."
        actions={
          <Button
            size="sm"
            variant="ghost"
            // A customer-key item has no price of ours to set: it is never billed to us.
            disabled={target === null || target.source === "customer_key"}
            onClick={() => setPricing(target)}
          >
            <Tag data-icon="inline-start" />
            Set price
          </Button>
        }
      />
      <SetPriceDialog
        // Keyed by the item so each item's dialog starts on its own prefilled rates.
        key={pricing ? itemId(pricing) : "none"}
        item={pricing}
        open={pricing !== null}
        onClose={() => setPricing(null)}
      />
    </>
  );
}
