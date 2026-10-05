
`stale-monitors.ts` (`packages/web/packages/status-web/src/lib/stale-monitors.ts`) owns the rule that picks which monitors the status dashboard offers for a one-click retire. It exports one constant, `STALE_MONITOR_MS` (7 days), one output type, `StaleMonitor`, and one pure function, `selectStaleMonitors(services, nowMs, thresholdMs?)`.

Per the module header, this is "the AMBIGUOUS half of ghost cleanup, and only that half". A monitor whose project or host provably stopped existing is deleted by the backend cycle (`retireUnclaimedMonitors` in the status server's `src/monitor/sync`) and never reaches this function. What remains is a monitor still claimed by a live deploy project but DOWN for a week: that may be a site nobody turned off or an outage nobody fixed, so it is surfaced for the operator to decide rather than removed. DNS resolution selects nothing in either direction; it is carried through only so the UI can word its confirm prompt.

The input rows are `LiveServiceDTO` values from the live snapshot ([Live Types](adtoolkit://cookbook/status/dashboard/logic/live-types)). The sole production call site is the `StaleMonitorsBanner` component, which calls the function with a day-floored clock and turns each row into a retire button backed by `deleteEndpoint(slug)`.

