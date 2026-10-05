
- **replacing-keeps-unnamed**: Each `replacing` copy MUST keep every field whose argument is omitted.
- **replacing-clears-nullable**: Nullable fields (project client, default rate, repo rate) MUST accept an explicit absent value that clears the field, distinct from omission.
- **stamps-untouched**: `createdAt` and `updatedAt` MUST be carried over unchanged; identity fields not offered (an entry's project, client, group key, raw seconds, currency, rounding, status, origin, lock) MUST NOT change.
- **repriced-amount**: `repriced(billedSeconds:rateCents:)` MUST set the billed seconds and rate and recompute the amount with the same money arithmetic the rollup uses; raw seconds MUST stay as tracked.
- **rate-parse**: `billingRate(parsing:)` MUST trim whitespace, parse the text as money into cents, and return nil if it is not a number or is outside the allowed default-rate range (0 to 10,000,000 cents).
- **rate-one-rule**: Every rate field MUST take its text through `billingRate(parsing:)` so all refuse the same input.
- **title-fallback**: `BillingRecordTitle.of(name)` MUST return the trimmed name, or `Untitled` when it is blank.
- **labels-disambiguate**: `projectLabels` MUST return a label per project id; a name two projects share MUST be followed by its client name (`No Client` when none), and by the first six characters of the id if the label still repeats.
- **labels-unique-first**: If two clients or two projects share an id, the first one listed MUST supply the name used for that id.

