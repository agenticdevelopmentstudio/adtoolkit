
`timeAgo` returns four hardcoded English literals with no lookup through any i18n/l10n
mechanism (a message catalog, `Intl`, or similar):

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a — hardcoded literal, no key | `just now` | Returned when elapsed time is under 60 seconds, or negative |
| n/a — hardcoded template literal, no key | `` `${diffMins}m` `` | Returned when elapsed minutes is under 60 |
| n/a — hardcoded template literal, no key | `` `${diffHours}h` `` | Returned when elapsed hours is under 24 |
| n/a — hardcoded template literal, no key | `` `${days}d` `` | Returned when elapsed hours is 24 or greater, unbounded |

Neither the fixed phrase `just now` nor the unit letters `m`/`h`/`d` would render correctly
for a non-English-reading caller; both are baked directly into the function body rather
than resolved from any translatable source.

