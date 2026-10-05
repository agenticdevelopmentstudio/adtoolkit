
Not applicable: the source declares no user-facing string literal of its own.
`VSIXInstallError`'s cases carry structured data — field names, claimed and
found values, and an underlying error's `localizedDescription` — rather than
authored display text, and the two log messages in the source are
developer-facing diagnostics, not strings a person using the app would read. Separately, `readManifest(in:)`
does call `ExtensionManifestLocalization.localize(_:forManifestIn:)` to
resolve `%key%` placeholders in the *extension being installed*'s own
manifest before decoding it — but that localizes the archive's content, not
any string this component itself displays.

