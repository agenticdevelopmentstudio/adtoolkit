
`url.ts` in `packages/web/packages/status-web/src/lib/` exports one pure function, `hostOf(url: string): string`. It parses the argument with the WHATWG `URL` constructor and returns the parsed `host` (hostname plus a non-default port). If the constructor throws, the function catches the error and returns the original string unchanged.

The status board uses it to turn a monitored endpoint's URL into a short display label or a site name. Callers include `row-detail.ts` (the endpoint row title), `StatusRow`, `StatusMatrix`, `Dashboard`, `StaleMonitorsBanner`, `UnconfiguredProjectsBanner`, and the configure screens `ProjectBrowser` and `EndpointsSection`. `EndpointsSection` uses the result as the name of a new site and as the input to `slugify` for its slug. The module is not re-exported from the package entry point `src/index.ts`, so it is internal to status-web.

