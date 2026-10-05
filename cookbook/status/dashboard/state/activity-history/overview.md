
This logic manages the fetching and merging of historical activity rows beyond the live window, with built-in shed-row absorption and an automatic pagination budget. It expands a bounded live feed (capped at a fixed row count and floored 24 hours back) backward in time through a server-side cursor, re-ordering merged results by a timestamp-then-id comparator, and holding caught rows that age out of the live window during paging. This logic is enabled conditionally by an age-out filter and exposes methods to load older rows and reset the auto-fetch budget.

