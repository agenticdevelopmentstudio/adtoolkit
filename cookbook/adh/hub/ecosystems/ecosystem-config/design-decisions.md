
**Decision**: the server-bags delete confirmation's removal message ("will be deleted. Anything reading it gets nothing — there is no default.") is declared independently rather than reusing the feature-flags delete confirmation's message ("will be removed. Anything reading it falls back to its default."), even though both are one-line "what deleting this costs" strings for a very similar delete-confirmation UI.
**Rationale**: the source's own comment states the reason directly: server bags have no defaults to fall back to, unlike feature flags — deleting one leaves readers with nothing at all. Borrowing the flags' message promised a fallback that does not exist, in the one dialog whose job is to say what deleting costs. Sharing the string would have made the confirmation dialog lie about what actually happens.
**Approved**: pending

**Decision**: the storage-tokens create form's save action uses a three-way catch (a conflict error → friendly message; any other shared error kind → rethrown as-is; anything else → a generic unexpected error) instead of the shared error-wrapping convention every other create/update/delete call in this component uses.
**Rationale**: the conflict case needs its own friendly text rather than whatever detail the backend's conflict response carries, and the source chooses to discard a non-shared-error-kind failure's own message in favor of a generic one rather than risk surfacing raw transport detail from a mint request specifically. This is documented here as an observed, intentional divergence rather than corrected to match the shared error-wrapping convention, since changing it would alter the exact error text this component's tests assert.
Platform scope: Swift implementation (the alternate client has no equivalent create-error taxonomy to diverge from).
**Approved**: pending

**Decision**: the storage-tokens detail sources its post-reveal notice text from a constant declared in a sibling Applications module (Applications' own token-reveal notice), rather than declaring its own copy.
**Rationale**: the source's own comment states this directly — the reveal-once behavior exists specifically because that sibling constant's promise ("you won't be able to see it again") must actually hold; the same lifecycle and constant are documented as canonical in the sibling recipe `adtoolkit://cookbook/adh/hub/security/authentication-client`, which this recipe treats as the complete reference for that shared behavior rather than re-deriving it here. The coupling means a future rename of that constant would need to be tracked across both modules with no compiler-enforced link beyond the direct reference.
Platform scope: Swift implementation — this is a cross-module source-file coupling specific to that codebase's module layout.
**Approved**: pending

**Decision**: JSON-shape validation for a server bag's value lives inside the value-parsing step on the Swift implementation, combining transport-adjacent orchestration with domain validation in one type; on the web implementation, the equivalent validation is not in the given data client at all — it lives in a sibling `features/ecosystem-config` package's dialog-state module.
**Rationale**: the two platforms split responsibilities differently: the Swift topic types are the single place that both talk to the data source and build the declarative form, so validation naturally lives there too; the web implementation keeps its data-client layer free of any dependency on UI-adjacent validation state, pushing that concern into the package that owns the dialog. Both are internally consistent with their own layering; this recipe documents the divergence rather than treating either as a gap.
Platform scope: applies differently to each of the two reference implementations, by design.
**Approved**: pending

**Decision**: on the web implementation, origin-format validation for a sign-in app's `allowedReturnOrigins` (mirroring the Swift implementation's origin-validation/canonicalization steps) is not present in the given data client — it lives in a UI-pane file's own validation helpers, outside this component's given sources.
**Rationale**: this follows the same data-client/features-package split as the server-bag JSON validation above, and was confirmed by reading the actual caller rather than assumed, per this recipe's requirement to resolve an apparent gap against the real codebase before marking it unresolved.
Platform scope: web implementation.
**Approved**: pending

**Decision**: feature-flag keys have no character-set restriction, unlike the slug-pattern restriction applied to the sign-in-app `clientId` field and the storage-token `name` field.

**Rationale**: the key is embedded unescaped in a colon-delimited composite id, so a colon in a key could collide with another item's id; closing the gap takes a validating pattern on the key field, or confirmation from the composite-id format's other consumers that a reserved character cannot collide.

**Approved**: pending

