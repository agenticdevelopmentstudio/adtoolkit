
All edge-case behavior — the non-optional view-model parameter ruling out
a missing value, unbounded text length, UI-thread-serialized concurrent
access, the absence of any throwing or error-producing API, no
networking, and the change-notification-callback overwrite when a second
observer is constructed against the same view model — is inherited
unmodified from the text edit row, whose initializer this component
reuses without change; see
`adtoolkit://cookbook/ui/settings/rows/text-edit-view#edge-cases`.
This component's own source contributes no code beyond constructing its
field as a secure field, so it introduces no edge case of its own.

