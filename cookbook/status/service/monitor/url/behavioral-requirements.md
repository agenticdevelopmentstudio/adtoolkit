
### hostOf

- **host-of-extraction**: `hostOf(url)` MUST return the `host` property of `new URL(url)` —
  the hostname, plus a non-default port when one is present, per the WHATWG URL standard —
  when `url` parses as an absolute URL.
- **host-of-invalid-fallback**: `hostOf(url)` MUST return `url` unchanged, verbatim, when the
  `URL` constructor throws for a malformed or relative URL string; the `catch` block's only
  action is `return url`.

### projectPageUrl

- **project-page-url-null-on-falsy**: `projectPageUrl(url)` MUST return `null` when `url` is
  `null`, `undefined`, or the empty string `''`, via the guard `if (!url) return null;`,
  before any URL parsing is attempted.
- **project-page-url-vercel-collapse**: `projectPageUrl(url)` MUST return
  `` `${u.origin}/${parts[0]}/${parts[1]}` `` — the parsed URL's origin joined with the first
  two non-empty path segments — when `new URL(url).hostname` is exactly `vercel.com` and
  `u.pathname.split("/").filter(Boolean)` yields 3 or more segments.
- **project-page-url-drops-suffix**: when collapsing a Vercel URL, `projectPageUrl` MUST
  discard the third and every subsequent path segment (the deploy id and anything after it)
  together with the URL's query string and fragment, since the returned string is built from
  only `u.origin`, `parts[0]`, and `parts[1]`.
- **project-page-url-vercel-short-path-passthrough**: `projectPageUrl(url)` MUST return `url`
  unchanged when the hostname is `vercel.com` but `u.pathname.split("/").filter(Boolean)`
  yields fewer than 3 segments.
- **project-page-url-non-vercel-passthrough**: `projectPageUrl(url)` MUST return `url`
  unchanged when `new URL(url).hostname` is any value other than `vercel.com`.
- **project-page-url-invalid-fallback**: `projectPageUrl(url)` MUST return `url` unchanged
  when the `URL` constructor throws for a truthy `url` (a malformed or relative URL string);
  this fallback is the same string the function returns for a recognized-but-unaffected
  hostname, so a caller cannot tell a parse failure apart from an intentional passthrough.

### Purity and Side Effects

- **pure-synchronous**: `hostOf` and `projectPageUrl` MUST each execute synchronously and
  MUST perform no I/O, network call, logging, or persistence of any kind; each is a pure
  function of its single argument with no dependency on module-level or external state.
- **no-throw**: each function MUST NOT throw for any input within its declared parameter type
  (`string` for `hostOf`; `string | null | undefined` for `projectPageUrl`) — every branch,
  including the `URL` constructor's thrown error, is caught and converted to a return value.

