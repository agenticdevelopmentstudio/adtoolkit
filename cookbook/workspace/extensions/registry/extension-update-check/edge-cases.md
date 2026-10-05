
- **Empty installed list**: checking an empty list MUST return a report with
  both lists empty; this is not an error condition. MUST behave this way.
- **Publisher is absent**: checking a single installed extension MUST throw
  the no-publisher error before making any request; when checking a list
  this surfaces as a "no publisher" not-checkable entry rather than a
  thrown error. MUST behave this way.
- **Publisher is the empty string**: treated identically to an absent
  publisher — a manifest whose publisher decoded as the empty string MUST
  also throw the no-publisher error. MUST behave this way.
- **Installed or published version string does not parse** (for example
  `"nightly-build"`, a prerelease suffix such as `"1.0.0-rc.1"`, or any
  string that fails to parse as a plain `major.minor.patch` version): MUST
  throw the versions-not-comparable error rather than compare on string
  inequality — version parsing accepts only a bare `major.minor.patch` form
  with no prerelease or build-metadata grammar, so any such string reaches
  this path as unparseable, not as a special case this concept itself
  distinguishes. MUST behave this way.
- **Published version equal to or older than installed**: MUST answer "no
  update" — not an error, and specifically not an offered downgrade, since
  the registry can legitimately be behind a self-hosted mirror mid-sync.
  MUST behave this way.
- **Published version is newer but fails the installability gate**
  (engine-incompatible, platform-specific, no-universal-build, or
  engine-range-unreadable): MUST answer "no update", identical to the "no
  update" outcome for an equal or older version — a caller cannot
  distinguish "already current" from "a newer, uninstallable build exists"
  from the return value alone. MUST behave this way.
- **Registry answers 404**: classified as "not published", the expected
  outcome for a sideloaded, unpublished, or private extension — this MUST
  NOT fail the enclosing batch check.
- **Registry answers any other non-2xx status, or the request fails to
  reach the registry at all** (a malformed registry URL, an undecodable
  response body, a transport-level failure such as no network connectivity
  or a request timeout, or a cancelled request surfacing as a thrown
  error): all of these MUST classify as "registry unreachable", the same
  reason a `503` produces — only "no such extension" (404) is distinguished
  from "no usable answer" (every other failure); the causes of "no usable
  answer" are not further distinguished.
- **Concurrent lookups, and their completion order**: checking a list MUST
  run every extension's lookup concurrently, and the outcome lists MUST be
  independent of which lookup completes first — this is guaranteed by an
  explicit sort applied after every result has been collected, not by any
  ordering the concurrency mechanism itself provides.
- **Duplicate entries in the installed list sharing the same identifier**:
  not addressed as a distinct case — checking a list adds one lookup per
  list element with no de-duplication by identifier, so two entries for the
  same extension produce two independent lookups and, in general, two
  entries in the resulting updates or not-checkable list. Because the sort
  applied afterward is stable, the relative order between two entries
  sharing an identifier is whichever order the concurrent lookups happened
  to complete in, which is not deterministic across runs.
- **A dependency (the registry) is unavailable for the whole call, not just
  one extension**: no distinct code path exists for "the registry as a
  whole is down" versus "this one lookup failed" — every extension whose
  lookup reaches the registry and gets no usable answer is reported
  individually as "registry unreachable" in the not-checkable list; there
  is no fail-fast short-circuit that stops issuing further lookups once one
  has failed this way.
- **Offline / disconnected state**: not a state this component detects or
  reports as such — a lost connection during a lookup surfaces as a
  transport error from the registry client, classified identically to a
  reachable-but-failing registry; this component has no separate concept of
  "offline".

