
### Port adapter

- **port-shape**: constructing the port adapter, given a client, MUST return
  an object implementing all six operations of the engine's port contract:
  listing every endpoint, listing sites, updating an endpoint, creating a
  site, creating an endpoint, and deleting a site.
- **port-default-api**: when no backing implementation is supplied, the port
  adapter MUST use the monitoring-configuration client's own functions as its
  backing implementation.
- **port-client-passthrough**: every port operation MUST forward the supplied
  client as the first argument to the matching monitoring-configuration
  client function.
- **port-create-methods-wired**: the create-site, create-endpoint, and
  delete-site operations MUST be fully wired to the client even though the
  match operation never reaches them. The design intent stated alongside
  them: "an adapter that threw for half its port would be a trap for the next
  caller."
- **endpoint-projection**: listing every endpoint MUST map each endpoint view
  to a projected shape holding exactly `id`, `siteId`, `url`, `kind`,
  `environment`, `platform`, `deployProject`, and `ignoreProjectWarning`. The
  endpoint's probe and monitoring fields (`expectedStatus`, `expectBody`,
  `dnsCheckA`, `dnsCheckAaaa`, `dnsCheckCname`, `checkIntervalSeconds`,
  `isActive`) MUST NOT appear in the output. This projection drops data
  deliberately.
- **opt-out-fold**: the projected `ignoreProjectWarning` MUST be `true` when
  the endpoint's own `ignoreProjectWarning` is `true`, or when its `isActive`
  is `false`, and `false` otherwise. This is the same opt-out fold the
  config-status logic and the backend's own adapter apply.
- **site-projection**: listing sites MUST map each site view to exactly
  `{ id, slug, groupId }`. Every other field MUST be dropped.
- **update-passthrough**: updating an endpoint MUST call the client's
  update-endpoint operation with the given identifier and body, and resolve
  to what it returns. The body is forwarded unchanged; the only check is a
  type check, not a runtime validation.
- **create-site-projection**: creating a site MUST send only `name`, `slug`,
  and `groupId` from the caller's body, and MUST resolve to `{ id }` taken
  from the created site.
- **create-endpoint-projection**: creating an endpoint MUST forward the
  caller's body unchanged and MUST resolve to the created endpoint passed
  through the same projection as listing every endpoint.
- **delete-passthrough**: deleting a site MUST call the client's delete-site
  operation with the given identifier and resolve when it resolves.
- **port-errors-propagate**: a rejection from any monitoring-configuration
  client operation MUST propagate unchanged out of the port operation that
  called it. The adapter catches nothing.

### Match operation

- **match-only**: the match operation MUST run the shared engine without a
  create option. A project that no existing endpoint monitors MUST therefore
  be skipped with the engine's reason `no site monitors this domain yet`,
  and MUST NOT cause any create-site or create-endpoint call.
- **injected-port-precedence**: when an engine port is supplied directly, the
  match operation MUST use it as the engine's port and MUST NOT construct
  one from a supplied client.
- **client-required**: when no port and no client is supplied, the match
  operation MUST reject with an error whose message is `runMatch:
  opts.client is required when opts.api is not supplied`. It MUST NOT fall
  back to a default network client.
- **client-port**: when no port is supplied but a client is, the match
  operation MUST build the port adapter from that client and use it.
- **live-projects-forwarded**: the match operation MUST forward the caller's
  live-project index to the engine unchanged. The engine uses it to tell
  stale wiring apart from a live conflict.
- **progress-forwarded**: the match operation MUST forward the caller's
  progress callback to the engine unchanged. The engine calls it as
  `(done, total)` once per project, after that project settles.
- **added-is-count**: the match result's `added` count MUST equal the number
  of projects the engine reported as added. The engine's created list MUST
  NOT be counted; it is empty by construction because create is never
  requested.
- **skipped-flattened**: the match result's `skipped` list MUST list one
  `{ project, reason }` per engine skip, in the engine's order. `project`
  MUST be the skipped project's name and `reason` MUST be the engine's
  reason text, unchanged.
- **notes-flattened**: the match result's `notes` list MUST list one
  `{ project, note }` per engine note, in the engine's order. `project` MUST
  be the project's name and `note` MUST be the engine's note text,
  unchanged.
- **sequential-execution**: projects MUST be applied strictly one after
  another, never concurrently, so that each match sees the wiring written by
  the previous one. This ordering is enforced by the engine itself, and the
  match operation MUST NOT reorder or batch its input.
- **per-project-resilience**: a project whose apply fails MUST be recorded in
  the skip list, with the failure's message as its reason (or a string
  conversion for a non-error failure), and MUST NOT stop the rest of the
  batch. The engine provides this behavior.
- **snapshot-failure-rejects**: when the engine's initial read of every
  endpoint or every site rejects, the match operation MUST reject with that
  error. No partial match result is returned.
- **one-snapshot-per-run**: each match-operation call MUST read endpoints and
  sites once, at the start, and MUST plan every project against that
  snapshot as updated by the run's own writes. Other runs, whether on this
  adapter or the backend, are not seen.
- **match-write-shape**: each successful match MUST issue one
  update-endpoint call whose body sets `platform`, `deployProject`, and
  `environment`. The engine builds this body; the match operation does not
  alter it.

### Detail blocks

- **detail-line-limit**: the shared row cap MUST equal `5`, and both
  detail-block builders MUST use it as their cap.
- **detail-empty**: the skip-detail and note-detail block builders MUST
  return the empty string `""`, with no header, when their input is absent
  or an empty list.
- **detail-leading-separator**: a non-empty block MUST start with two
  newlines (`"\n\n"`) and then its header line.
- **detail-row-format**: each named row MUST read `• <project>: <why>` on
  its own line, in input order.
- **detail-cap**: a block MUST name at most the first rows up to the shared
  row cap.
- **detail-remainder**: when the input has more rows than the cap, the block
  MUST end with a final line `…and <N> more`, where `N` is the input length
  minus the number of rows shown, not the total.
- **detail-no-remainder**: when the input has the cap's row count or fewer,
  the block MUST NOT contain a `…and` line.
- **skip-header**: the skip-detail block builder MUST use the header
  `Left alone:` and MUST take each row's `why` from `reason`.
- **note-header**: the note-detail block builder MUST use the neutral header
  `Also:` and MUST take each row's `why` from `note`.
- **detail-pure**: both block builders MUST be pure and synchronous, with no
  I/O and no mutation of their input.

### Concurrency and side effects

- **single-threaded**: within one run, port calls are awaited one at a time,
  except for the engine's first read, which issues the endpoint list and the
  site list together, concurrently rather than sequentially.
- **no-cross-run-serialization**: the match operation MUST NOT serialize
  itself against other concurrent match-operation calls. Callers own that
  guard: the per-platform project panel runs one match at a time per
  platform.
- **network-side-effects**: the only side effects of a match run MUST be the
  port's calls through the supplied client: two reads, then one
  update-endpoint call per matched project.
- **no-timeout-or-retry**: the match operation MUST NOT add a timeout,
  retry, or cancellation of its own. A hung request holds the run until the
  client's own transport settles. There is no cancellation parameter.

