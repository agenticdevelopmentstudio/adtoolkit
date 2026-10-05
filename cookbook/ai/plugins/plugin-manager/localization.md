
No message in this component is externalized through a localization key. Every user-facing string is a hardcoded English string, interpolated into the corresponding error's message:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded) | `Plugin not found: <id>` | Not-found error's message |
| (none — hardcoded) | `Failed to load plugin bundle: <id>` | Load-failed error's message |
| (none — hardcoded) | `Plugin '<id>' has no NSPrincipalClass` | No-principal-class error's message |
| (none — hardcoded) | `Plugin '<id>' principal class does not conform to AIPlugin` | Principal-class-not-plugin error's message |

