
`time-ago.ts` (`packages/web/packages/status-web/src/lib/time-ago.ts`) is the status
dashboard's single pure function for turning one absolute timestamp into a compact,
human-readable elapsed-time label. It exports one function, `timeAgo(iso, nowMs)`, whose
doc comment states its purpose: "Format elapsed time as a compact string. nowMs is passed
in for testability." Its callers are dashboard components (`DeployList`, `Dashboard`,
`GlobalPanel`, `FleetView`, `StatusMatrix`, `StaleMonitorsBanner`, `SnapshotStaleBanner`,
`configure/ProjectBrowser`); most take `nowMs` from the `useNow` hook, and
`SnapshotStaleBanner` passes `Date.parse(snapshot.generatedAt)` instead. The function body
is byte-for-byte identical to the status server's
[Status Server Monitor Time Ago](adtoolkit://cookbook/status/service/monitor/time-ago);
the two copies share one contract and differ only in their callers and in the web copy
having a test file (`time-ago.test.ts`).

