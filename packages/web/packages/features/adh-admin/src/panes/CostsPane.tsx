"use client";

import { useRef, useState } from "react";
import { useInsightItems, useRunRate } from "../api/insight";
import { CostItemsTable } from "../costs/CostItemsTable";
import { FixedCostsList } from "../costs/FixedCostsList";
import { RunRateHeader } from "../costs/RunRateHeader";
import { monthOf, monthRange, todayUtc } from "../costs/days";

// What the platform costs: a month's run rate, the priced items behind it, and the two price
// tables an admin edits (a per-unit rate per item, and fixed monthly costs). Every figure is read
// at request time from quantities, so setting a price here re-prices the month on the next load.

export function CostsPane() {
  const current = monthOf(todayUtc());
  const [month, setMonth] = useState(current);
  const runRate = useRunRate(month);
  const items = useInsightItems(monthRange(month));
  const itemsRef = useRef<HTMLElement>(null);

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-apt-text">Costs</h1>

      <RunRateHeader
        month={month}
        onMonthChange={setMonth}
        maxMonth={current}
        runRate={runRate.data}
        error={runRate.error}
        onShowUnpriced={() => itemsRef.current?.scrollIntoView?.({ behavior: "smooth" })}
      />

      <section ref={itemsRef} aria-label="Cost items" className="mb-8">
        <h2 className="mb-2 px-2 text-lg font-semibold text-apt-text">Items</h2>
        <CostItemsTable
          items={items.data?.items}
          loading={items.isLoading}
          error={items.error}
        />
      </section>

      <section aria-label="Fixed costs">
        <h2 className="mb-2 px-2 text-lg font-semibold text-apt-text">Fixed costs</h2>
        <FixedCostsList />
      </section>
    </div>
  );
}
