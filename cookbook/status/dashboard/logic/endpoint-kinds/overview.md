
`endpoint-kinds.ts` (`packages/web/packages/status-web/src/lib/endpoint-kinds.ts`) is the status web app's single declaration of which `kind` values a monitored endpoint may carry. Its authoring comment calls it "ONE source for the editor dropdown (api/monitored-sites re-exports this), server-side validation (the endpoints routes), and the 'needs wiring' warning logic (config-status)".

It exports four things:

- `ENDPOINT_KINDS`, a readonly tuple of the six kind strings, in display order.
- `EndpointKind`, the string-literal union derived from that tuple.
- `isEndpointKind(k)`, a type guard that narrows an arbitrary string to `EndpointKind`.
- `NON_DEPLOY_KINDS`, re-exported unchanged from `@agentic-toolkit/deploy-platform/engine` (`classify.ts`). The module does not restate its members.

The module has no state, no I/O and no side effects. Inside status-web, `src/api/monitored-sites.ts` re-exports `ENDPOINT_KINDS` so existing imports from `./monitored-sites` keep working ([Status Web API](adtoolkit://cookbook/status/dashboard/api)). The status server keeps its own copy of the same vocabulary in `status-server/src/monitor/endpoint-kinds.ts`, which it says is "kept in step" with this file.

