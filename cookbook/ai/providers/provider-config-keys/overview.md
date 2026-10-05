
The provider-configuration-keys component is a stateless namespace — never
instantiated — that is, per its own documented contract, "the single source
of truth for the per-configuration storage-key namespace" shared by the
app's provider-configuration store and the daemon's registry (reached
through the daemon provider resolver and the daemon's chat-completion
path). Four operations (field key, model key, secret-fields key, fields
key) format an identifier-scoped key string for one provider
configuration's field values, selected model, and secret-ledger
bookkeeping; four fixed constants (selected-configuration-id key,
configurations key, enabled key, legacy-cleaned key) name registry-wide
settings that are not scoped to any one configuration. Because both the app
and the daemon compute keys through this one component rather than
duplicating the format, a configuration identifier maps to the same key
strings on both sides and the two layouts cannot drift. It is a **logic**
component with no visual surface: every operation is a deterministic,
side-effect-free computation (or a fixed literal), it performs no I/O, and
it never fails.

