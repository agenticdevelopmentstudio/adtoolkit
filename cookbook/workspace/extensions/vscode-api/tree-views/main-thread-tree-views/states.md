
Not applicable — this is a logic component, not a visual one. Its lifecycle-shaped behavior (a registration's live-versus-superseded-versus-invalidated status, and the bridge's own disposed status) is captured under Behavioral Requirements (**provider-replacement-ordering**, **registration-disposable-is-token-guarded**, **invalidate-is-idempotent-and-releases-the-change-subscription**, **disposal-invalidates-every-live-model**) rather than as a visual-state table.

