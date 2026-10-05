
**Decision**: The long-lived token and the OAuth login are separate credentials with separate keys, never merged under one account name.
**Rationale**: The type's own documentation records why: merging them produced one row, one usage number and one delete for two things that measure, expire and revoke independently. The key spelling therefore carries the kind so each credential keeps its own item, preference and quota card.
**Approved**: pending

**Decision**: An unrecognized raw kind still produces a distinct key rather than collapsing to the bare account name.
**Rationale**: The wire form may carry a kind this build has never heard of; that credential is still distinct and has to get a distinct key, so only a missing or empty kind falls back to the legacy form.
**Approved**: pending

