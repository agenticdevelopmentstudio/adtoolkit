
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| key | text | none (required) | Opaque per-secret identifier passed to get/set/delete/delete-legacy; naming convention is entirely the caller's, e.g. a provider configuration's field-key operation. |
| value | text | none (required, set only) | The secret to store under key; treated as opaque and never validated, transformed, or interpreted. |
| Active service identifier | text (mutable, process-wide) | the host application's own bundle identifier, or "com.agentictoolkit" if unavailable | The secure-storage scope every production-implementation call is implicitly scoped to; a host pins this once at startup outside this component. |
| Shared-storage access group | optional text (mutable, process-wide) | none | Optional shared-storage access group production-implementation calls are implicitly scoped to; referenced, not set, by this component. |
| Legacy service identifier | text (constant) | "com.agentictoolkit" | Fixed pre-pin fallback service delete-legacy retargets the active service identifier to for the duration of one call. |
| Injected secret store | abstract secret-store interface (injected dependency) | the production implementation | The secret-store implementation a caller such as the daemon's chat-completion operation injects; substituted with the in-memory test double in tests. |

