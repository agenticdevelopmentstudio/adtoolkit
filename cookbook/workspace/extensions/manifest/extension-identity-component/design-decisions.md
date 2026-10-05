
**Decision**: Use a denylist of forbidden shapes (empty, leading dot, `/`,
`\`, `:`, C0 controls, DEL) rather than an allowlist of permitted characters.
**Rationale**: Publisher and extension names are internationalized; an
allowlist of characters would refuse a legitimate Japanese or Cyrillic name
long before it refused a hostile ASCII one. What must be rejected is
whatever changes where the value points, not whatever falls outside some
alphabet (source doc comment on `ExtensionIdentityComponent`; traced by test
`internationalisedNamesAreAccepted`).
**Approved**: pending

**Decision**: Refuse a value containing a separator rather than
percent-encoding it before splicing.
**Rationale**: Percent-encoding a `/` would install or address the extension
under a mangled spelling that no longer matches what the registry and the
settings list call it — a silent identity change. A refusal is a legible
failure at the point of installation or lookup; an escape would hide the
mismatch until later (source doc comment on `ExtensionIdentityComponent`;
test `anEncodedSeparatorIsNotASeparator` confirms an already-encoded
sequence such as `%2F` is accepted, because nothing here decodes it).
**Approved**: pending

**Decision**: Reject only the leading `.`, not every interior `.`.
**Rationale**: An interior dot appears in almost every real extension
identifier and version string (`ms-python.python`, `2024.1.0-rc.1`); only a
leading `.` is structural — it produces `.`/`..` (directory climb) or a
hidden-file name. Refusing all dots would reject the overwhelming majority
of legitimate values (source doc comment on `ExtensionIdentityComponent`;
test `interiorDotsAreAccepted`).
**Approved**: pending

**Decision**: Stop the control-character denylist at `U+007F` (DEL) and do
not extend it into the `U+0080`–`U+009F` C1 range.
**Rationale**: `U+0080`–`U+009F` are technically C1 control codes, but none
of them is a path or URL separator on this platform; extending the denylist
there would start rebuilding the allowlist this predicate exists to avoid
(source: inline comment on test `theControlRangeEdgesAreRight` in
`ExtensionIdentityComponentTests.swift`).
**Approved**: pending

