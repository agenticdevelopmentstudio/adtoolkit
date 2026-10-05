
- **Data collected**: None collected or retained by this file itself. It receives a
  caller-supplied URL string — a monitored endpoint's live URL, or a deploy's provider
  inspector URL — and returns a derived string, a host or a collapsed project-page URL, to
  the caller.
- **Storage**: None. The module holds no state beyond its own function definitions; it
  neither reads from nor writes to any store.
- **Transmission**: None. This file makes no network call and transmits nothing of its own;
  how a derived host or project-page URL travels onward — for example, included in a
  `sync.ts` log line or rendered as a deploy row's link — is the concern of the external
  caller.
- **Retention**: Not applicable — there is nothing this file collects or stores to retain.

