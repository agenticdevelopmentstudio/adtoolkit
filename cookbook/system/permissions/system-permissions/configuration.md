
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| automation probe (construction parameter of the production status checker) | a probe dependency | a production probe implementation | Apple Events probe; injected so tests can stub the outcome |
| host bundle identifier | environment | host bundle id | Scopes the notifications settings-pane location; omitted when absent or empty |
| persisted settings-store keys `permission.keychain-<token>.status` | a string | absent (undetermined) | Keychain ledger records |
| Location request timeout | constant | 120 seconds | Not configurable |
| Notification authorization options | constant | alert, sound | Not configurable |
| Host usage descriptions and entitlements | app manifest / entitlements | — | Supplied by the host app; required by the system for location, microphone and Apple Events prompts to appear |

