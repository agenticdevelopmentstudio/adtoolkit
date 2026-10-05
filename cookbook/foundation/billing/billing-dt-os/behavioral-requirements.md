
- **immutable-values**: Every record MUST be an immutable value with equality; the client, project, repo, segment and entry records MUST also carry an identifier.
- **three-statuses**: Billing status MUST be exactly unbilled, billed and paid; `next` MUST advance one step forward and be nil at paid; any status other than unbilled MUST lock the entry.
- **optional-strings-empty**: Unset contact, note and path fields MUST be the empty string, not null; unset foreign keys, rates and links MUST be null.
- **segment-origin**: A segment's origin MUST be `auto` or `manual`; the two spellings MUST be defined once; a segment with an empty end MUST be running; a manual segment MUST be one someone started.
- **segment-zone**: A segment MUST carry the zone captured when it was created, and local-day bucketing MUST use that zone.
- **entry-snapshot**: An entry MUST carry raw seconds, billed seconds, rate, currency, amount, rounding minutes and rounding mode as written, plus the client denormalised at write time.
- **entry-group-key**: An entry's group key MUST be empty or `rate:<cents>` at day granularity and `<session>|<start>` or the segment id at run granularity, and is part of the uniqueness key.
- **supplement-link**: An entry MAY name the entry it supplements.
- **overview-per-currency**: The overview MUST carry one bucket set per currency in use, most entries first, and MUST NOT sum across currencies; its top-level buckets MUST be the first currency's.
- **overview-compat**: The overview MUST decode when the per-currency list is absent, as an empty list.
- **audit-append-only**: An audit row MUST record entry, instant, field, old value, new value and a source of `auto` or `user`.
- **wire-sentinels**: A failed list read MUST be signalled by the single row `{"billing_read_failed":true}` and a failed count by -1.
- **settings-keys**: Settings keys MUST be built from one app-chosen prefix plus fixed key names, and the allow-list MUST contain exactly the eight billing keys.
- **defaults**: Unconfigured defaults MUST be: idle cutoff 15 minutes, day granularity, rounding 15 minutes up, rate 0, currency USD, manual timer cap 8 hours, track unassigned true.
- **limits**: Preference limits MUST be: idle cutoff 1 to 480 minutes, rounding 1 to 240, rate 0 to 10,000,000 cents, manual cap 1 to 24 hours; `clamp` MUST return the nearest bound.
- **refusal-sentences**: The refusal sentences MUST be defined once and shared by the daemon and any test double; a repo claim sentence MUST name the root and either "any branch" or the branch.

