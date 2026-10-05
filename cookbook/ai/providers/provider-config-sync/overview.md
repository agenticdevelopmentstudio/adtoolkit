
This component declares two value types that together form the
app-to-daemon wire contract for AI provider configuration: the sync
envelope (whether AI summaries are enabled, which configuration is
selected, and every configured provider) and the resolved provider
configuration record (one fully-resolved configuration's identity, model,
and value bag). Per its own documented contract, this component "Replaces
the old flattened push: carries the WHOLE set of configurations plus a
pointer to the active one, so the daemon mirrors the full registry (keyed
by configuration identity) rather than a single plugin-keyed slot." Both
types are serializable and safe to share across concurrency domains, and
neither performs any I/O, validation beyond basic structural typing, or
any side effect — this component is the shape of the sync payload, not an
implementation of sending, receiving, or applying it. The
provider-configuration-keys component's own documented contract names the
two ends of this contract: the app's provider-configuration store and "the
daemon's registry (settings table / secure daemon-side store)"; the
resolved-configuration record's documented contract adds that the daemon
"persists each under the storage-key namespace keyed by id." No source in
this repository constructs a sync-envelope value outside of its own test
target, and none decodes or applies one — see the
`sync-application-unimplemented` requirement below.

