
### Operation

- **host-of-signature**: `hostOf` MUST take exactly one string argument and MUST return a string synchronously.
- **host-of-parsed-host**: When the argument parses as an absolute URL, `hostOf` MUST return that URL's WHATWG `host` value.
- **host-of-non-default-port**: When the parsed URL carries a port that is not its scheme's default, the result MUST include `:` and that port (for example `example.com:8443`).
- **host-of-default-port-dropped**: When the parsed URL carries its scheme's default port (443 for `https`, 80 for `http`), the result MUST omit the port.
- **host-of-no-path-query-userinfo**: The result MUST NOT contain the scheme, userinfo, path, query or fragment of the input.
- **host-of-normalized-host**: For special schemes (`http`, `https`, `ws`, `wss`, `ftp`), the result MUST be the parser-normalized host: ASCII-lowercased, with an internationalized domain converted to its Punycode (`xn--`) form, and with an IPv6 literal kept in brackets.
- **host-of-empty-host**: When the argument parses as an absolute URL whose host is empty (for example `mailto:`, `file:///`, or a bare `name:port` string that parses as scheme `name:`), `hostOf` MUST return the empty string rather than the input.
- **host-of-parse-failure-fallback**: When the argument does not parse as an absolute URL (for example a bare domain `example.com`, a relative path, or the empty string), `hostOf` MUST return the argument unchanged.
- **host-of-no-throw**: `hostOf` MUST NOT throw for any string argument; every parse error MUST be caught inside the function.
- **host-of-failure-indistinguishable**: The return value MUST NOT signal whether the fallback was taken. A caller receives the same kind of string for a parsed host and for an unparseable input, and the source offers no second channel. The fallback is a deliberate lossy projection for display.

### Side effects, state and concurrency

- **host-of-pure**: `hostOf` MUST have no side effects. It MUST NOT perform network, storage or DOM access, logging, or mutation of shared state.
- **host-of-deterministic**: `hostOf` MUST return the same output for the same input on every call.
- **host-of-synchronous-single-threaded**: `hostOf` runs synchronously on the calling JavaScript thread and keeps no state between calls, so concurrent callers cannot interleave. It MUST NOT introduce any ordering dependency between calls.

### Caller contract

- **caller-empty-fallback**: Because a parsed URL with an empty host yields `""`, callers that need a non-empty label MUST supply their own fallback. `StaleMonitorsBanner` and `UnconfiguredProjectsBanner` do this with `hostOf(url) || url`, and `siteUrlLabel` in `EndpointsSection` falls back to the URL or `"(no url)"`.
- **caller-nullish-guard**: The type signature accepts only `string`. Callers holding an optional URL MUST coalesce it before the call, as `ProjectBrowser` does with `hostOf(endpoint.url ?? "")`.

