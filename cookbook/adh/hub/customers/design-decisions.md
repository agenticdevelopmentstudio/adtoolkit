
**Decision**: `createSpec(for:)`'s save action checks for a duplicate
email against a freshly fetched customer list *before* calling
`create(_:)`, and also catches an `HubError.conflict` the create call
itself might throw, re-throwing it as the identical duplicate-email
message either way; `detail(for:)`'s save action skips the precheck and
relies on the conflict catch alone.
**Rationale**: The precheck-then-create sequence has an unavoidable
check-then-act window — nothing in these three sources locks the
ecosystem between the list read and the create write — so a second,
concurrent create for the same email can still reach the server after the
precheck passed. Catching the server's own conflict response and
re-mapping it to the same user-facing message means a caller sees one
consistent duplicate-email error regardless of which guard actually
caught it. The source does not explain why `detail`'s save skips the
precheck the create path performs; the observable effect is that renaming
an existing user's email to one already in use is caught only by the
server's response, one round trip later than the create path's own local
check.
**Approved**: pending

**Decision**: `input(from:ecosystemID:)` trims `email` but never
substitutes `nil` for it, while trimming-and-nil-substituting
(`HubText.nonBlank`) the other four fields.
**Rationale**: `CustomerInput.email` is declared non-optional, so there is
no `nil` to substitute — an absent or blank email becomes the empty
string `""`, which the shared `emailPattern` regex then rejects rather
than the Forms-required-field check rejecting it outright (since
`email`'s own `isRequired: true` already blocks an empty submission
before this function runs at all). The other four fields are genuinely
optional on the wire, so a blank value legitimately means "no value,"
which `HubText.nonBlank` expresses as `nil` rather than posting an empty
string.
**Approved**: pending

**Decision**: `fieldSpec(isRequiredEmail:)` takes a Boolean parameter that
both `createSpec` and `detail` always pass as `true`, per the source's own
comment that the parameter "keeps the create and detail specs literally
shared."
**Rationale**: Sharing one field-building function guarantees the
"email" field's label, placeholder, pattern, and pattern message stay
identical between the create dialog and the detail form without a second
field literal to drift out of sync; the parameter exists as a documented
seam for a future caller that might need an optional-email variant, even
though no such caller exists among these three sources today.
**Approved**: pending

**Decision**: customer get, update, and delete are not scoped to the current ecosystem on the client; only the list operation takes an ecosystem.

**Rationale**: the id-only operations carry no ecosystem and nothing compares the fetched customer's ecosystem to the topic's; closing the gap takes a client-side ecosystem comparison after the fetch, or confirmation that the deployed data source enforces scoping server-side.

**Approved**: pending

