
Not applicable — this is a type-only DTO contract module, not a visual component. Its only lifecycle-shaped concept, the freshness relationship between `generatedAt`, `lastCycleAt` and a separate `/health` cycle clock, is captured under Behavioral Requirements (**last-cycle-at-is-data-freshness-clock**, **last-cycle-at-distinct-from-health-clock**) rather than as a visual-state table.

