
The three user-facing strings in this file are hardcoded English literals with no override option today; the table lists them as built.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a (literal) | "Go to this conversation" | Tooltip on the app icon when `attribution.appIdentity` is empty |
| n/a (literal) | "Go to this conversation in {appIdentity}" | Tooltip on the app icon when `attribution.appIdentity` is non-empty |
| n/a (literal) | "Go to {attribution.headerLine}" | Accessibility label on the app icon, set only when `actions.onJump` is wired |

None of the three literals — the two app-icon tooltips or the accessibility label built from the attribution's header line — is routed through the platform's string-localization lookup, so none reaches a string catalog (see Platform Notes for the exact call sites).

