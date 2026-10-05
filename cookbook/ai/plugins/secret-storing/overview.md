
The secret store is an interface that indirects an AI-plugin host's
credential storage away from its concrete backing store, so, per its own
documented contract, tests can substitute an in-memory store and never touch
the real secure-storage system. It declares four operations — get, set,
delete, and delete-legacy — each keyed by an opaque, caller-supplied text
value; the interface deliberately says nothing about key-naming convention,
leaving that to the caller (in practice, a provider configuration's
field-key operation, for this framework's one production consumer, the
daemon's chat-completion path). The production implementation is a
stateless conformance that delegates get/set/delete verbatim to the
platform's secure-storage helper, plus a fifth capability, delete-legacy,
that removes an entry written by a pre-pin build under the secure-storage
helper's own default fallback service identifier ("com.agentictoolkit") by
briefly retargeting the helper's active service identifier and restoring it
afterward. A test-only implementation backs the same interface with a
lock-guarded in-memory dictionary so the daemon's chat-completion tests
never touch the real secure store.

