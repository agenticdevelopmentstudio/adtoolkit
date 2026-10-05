
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| system-permissions-001 | automation-mapping | An automation probe result of 0 | granted |
| system-permissions-002 | automation-mapping | An automation probe result of -1743 | denied |
| system-permissions-003 | automation-mapping, undetermined-meaning | Automation probe results of -1744 and of -600 | undetermined for both |
| system-permissions-004 | automation-mapping | A checker with a stub probe returning -1743; read status for automation targeting bundle identifier `"com.googlecode.iterm2"` | denied |
| system-permissions-005 | automation-probe-flag | A recording stub probe; read status for automation targeting `"com.googlecode.iterm2"`, then call the request operation for the same | After the status read: the last recorded bundle identifier is `"com.googlecode.iterm2"` and prompting was not allowed; after the request: prompting was allowed. |
| system-permissions-006 | is-granted | A stub probe returning 0, then -1743, then -600, each checked via the granted-check convenience for automation targeting `"x"` | true, false, false |
| system-permissions-007 | notifications-mapping | Notification authorization outcomes of authorized, denied, and not-yet-determined | granted, denied, undetermined |
| system-permissions-008 | notifications-mapping | Notification authorization outcomes of provisional and ephemeral | granted for both |
| system-permissions-009 | location-mapping, location-when-in-use-denied | Location authorization outcomes of always-authorized, when-in-use (raw value 4), denied, restricted, not-yet-determined | granted, denied, denied, denied, undetermined |
| system-permissions-010 | microphone-mapping | Audio-capture authorization outcomes of authorized, denied, restricted, not-yet-determined | granted, denied, denied, undetermined |
| system-permissions-011 | keychain-mapping | Keychain read statuses of `errSecSuccess`, `errSecItemNotFound`, `errSecUserCanceled`, `errSecAuthFailed` | granted, undetermined, denied, denied |
| system-permissions-012 | display-name | The display name of each of the seven cases (automation targeting `"com.googlecode.iterm2"`, keychain for service `"Claude Code-credentials"`) | `"Accessibility"`, `"Notifications"`, `"Automation"`, `"Location"`, `"Microphone"`, `"Screen Capture"`, `"Keychain"` |
| system-permissions-013 | identifier-token-derived, explanation-keychain-service | Keychain permissions for services `"Claude Code-credentials"` and `"Stenographer Claude Accounts"` | Tokens `"keychain-claude-code-credentials"` and `"keychain-stenographer-claude-accounts"`; the two explanations differ, and the first contains `"Claude Code-credentials"`. |
| system-permissions-014 | identifier-token-derived | The identifier token of an automation permission targeting `"com.googlecode.iterm2"` | `"automation-com-googlecode-iterm2"` |
| system-permissions-015 | identifier-token-fixed | The identifier token of the screen-capture permission | `"screen-capture"` |
| system-permissions-016 | icon-name, explanation-default | Every permission case | A non-empty icon name and a non-empty explanation for each. |
| system-permissions-017 | settings-pane-url-tcc | The settings-pane location of accessibility, automation targeting `"com.googlecode.iterm2"`, location, microphone, screen capture | Locations ending in `...security?Privacy_Accessibility`, `...?Privacy_Automation`, `...?Privacy_LocationServices`, `...?Privacy_Microphone`, `...?Privacy_ScreenCapture` respectively. |
| system-permissions-018 | settings-pane-url-notifications | The notifications permission's settings-pane location, read in a process with a bundle identifier | Starts with `x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=` |
| system-permissions-019 | settings-pane-url-keychain, action-title | A keychain permission for service `"Claude Code-credentials"`; the accessibility permission | Keychain: no settings-pane location, action title `"Allow…"`; accessibility: action title `"Open Settings"`. |
| system-permissions-020 | action-title-all | The full list of action titles | `["Open Settings", "Allow…"]` |
| system-permissions-021 | explanation-automation-target | An automation permission targeting `"com.googlecode.iterm2"`, with its target-name resolver returning `"iTerm"` | `"Needed to find, raise and open windows in iTerm."` |
| system-permissions-022 | ledger-key, ledger-values | Record granted in the keychain ledger for service `"Claude Code-credentials"`, then read its status | The persisted key `"permission.keychain-claude-code-credentials.status"` holds `"granted"`; the read status is granted. |
| system-permissions-023 | ledger-undetermined-erases, ledger-forget | After vector 022, forget the `"Claude Code-credentials"` service | The key is removed; the read status is undetermined. |
| system-permissions-024 | ledger-record-status-code | Record the raw status code for `errSecUserCanceled` for service `"S"` | The read status for `"S"` is denied. |
| system-permissions-025 | ledger-values | The persisted key for service `"S"` holds the value `"maybe"` | The read status for `"S"` is undetermined. |
| system-permissions-026 | keychain-status-no-access | Read status for keychain service `"S"` with the ledger holding denied and no matching keychain item | Returns denied; no keychain query is issued. |
| system-permissions-027 | location-request-settled | Location authorization already denied; call the request operation | Returns denied immediately without waiting. |
| system-permissions-028 | location-request-timeout | Location authorization not-yet-determined; call the request operation; no decision arrives for 120 seconds | Resumes after 120 seconds with the then-current status (undetermined if still undecided). |

Vectors 001–012 (location arm included), 013, and 016–019 are automated.
Vectors for accessibility, screen capture, and the live
notification/microphone/keychain request flows are manual: they depend
on real TCC and keychain state that a test process cannot control.

