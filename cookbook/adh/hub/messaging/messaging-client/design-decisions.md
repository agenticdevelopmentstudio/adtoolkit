
**Decision**: `status(ecosystemID:)` failures are swallowed to `nil` with `try?` at both the
top-level rail (`rail-status-swallowed-at-top-level`) and inside the Send detail
(`send-detail-status-swallowed`), while `templates()`, `log(...)`, and `send(...)` failures are all
passed through `HubError.wrap(_:)` and rethrown.
**Rationale**: provider connectivity status is an auxiliary signal, not required to render the
rail or the compose form — degrading it to `"Provider status unavailable"` or a per-channel
"Couldn't check whether..." banner keeps both pages usable, whereas `templates`, `log`, and `send`
are the operations the user actually asked for and must surface a real failure rather than a
misleadingly quiet form.
**Approved**: pending

**Decision**: `send-template-placeholder-validation` reports one missing template variable per
save attempt (the loop throws on the first `HubText.nonBlank(vars[name]) == nil`) rather than
collecting every missing variable into one message.
**Rationale**: not documented beyond the surrounding doc comment explaining why the scan itself
covers the subject (see `template-placeholder-scan`); the practical effect is that a template with
several missing variables needs several round trips through the form to fully diagnose.
**Approved**: pending

**Decision**: `MessagingTemplate.placeholders` (defined in `MessagingModels.swift`) calls
`MessagingTopic.placeholders(in:)` (defined in `MessagingTopic.swift`) rather than each file
carrying its own copy of the regex.
**Rationale**: per the source's own comment, `placeholders(in:)` is declared `nonisolated`
specifically so this "plain, non-isolated struct" can call it synchronously; sharing the one scan
keeps the model and the send form from ever disagreeing on placeholder syntax, at the cost of a
model type depending on its topic/controller type rather than the more usual direction.
Platform scope: Swift/Apple — the `nonisolated` mechanism that makes the synchronous cross-file
call safe is Swift-specific; a port on another platform can share the same scan with a plain
function call and no isolation annotation.
**Approved**: pending

**Decision**: the log level always requests `page: 1` with `pageSize: MessagingTopic.logPageSize`
and never reads `MessagingLogPage.total` or requests a later page.
**Rationale**: not documented in the source; the effect is a most-recent-100 log view (see
**log-pagination**).
**Approved**: pending

