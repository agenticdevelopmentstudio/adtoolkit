
**Decision**: The same field-key string addresses both a plain (non-secret) settings entry and a secure-store-backed secret entry for the same field, distinguished only by the caller's own routing (whether the field is marked secret, which store the caller chooses), never by any structural difference in the key itself.
**Rationale**: per the component's own documented contract, the goal is that "a configuration id maps to the same key strings on both sides" of the app/daemon boundary; encoding a "secure" marker into the key string would create two parallel namespaces for what is otherwise one field, duplicating the distinction a field descriptor's secret flag already drives at the call site.
**Approved**: pending

**Decision**: The enabled key and legacy-cleaned key are declared as fixed constants but have no call site anywhere in the given sources that reads or writes them by name; the enabled key's literal value (`"ai_summaries_enabled"`) is independently duplicated as a hardcoded string in a separate settings-configuration component, rather than referencing this component's enabled key.
**Rationale**: this is recorded here as an observed fact rather than corrected, because routing that other component through this component's enabled key would change a file outside this component's own contract; nothing today ties the two literals together, so a future rename of either would silently break the pairing with no compiler error. (Apple platform implementation.)
**Approved**: pending

**Decision**: The secret-fields-key operation and its newline-joined ledger shape are documented on this component but never populated or consulted anywhere in this repository.
**Rationale**: the documented contract attributes the ledger to daemon-side removal logic ("(Daemon-side.)"), which may live outside this repository; rather than assume that consumer exists and behaves correctly, or invent one, this is recorded as the `secret-fields-key-consumer` behavior in Behavioral Requirements. (Apple platform implementation.)
**Approved**: pending

**Decision**: Field names are not validated or escaped against the newline character that delimits the fields-key and secret-fields-key ledgers.
**Rationale**: The field-key operation is a pure string interpolation and the ledger shape is a bare newline-joined list, so a field name containing a newline silently splits into two entries when the daemon's chat-completion path parses the ledger. Closing it would take a defined character set for plugin field-descriptor keys, or an escaping scheme or validating constructor in this component.
**Approved**: pending

