
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, hardcoded) | `"No history."` | `AdminNotesRail.historyText` empty-history fallback |
| (none — literal, hardcoded) | `"(empty note)"` | `AdminNote.headline` all-blank-content fallback |
| (none — literal, hardcoded) | `"New note"` | Notes level `createAction` label |
| (none — literal, hardcoded) | `"No notes yet."` | Notes level empty-state message |
| (none — literal, hardcoded) | `"Add users"` | Pending users list `createAction` label |
| (none — literal, hardcoded) | `"Enter an email address or a phone number."` | Add-users spec contact-requirement save error |
| (none — literal, hardcoded) | `"Choose at least one channel."` | Send-invitation spec no-channel save error |
| (none — literal, hardcoded) | `"This user has no phone number."` / `"This user has no email address."` | Send-invitation spec per-channel save error |
| (none — literal, hardcoded) | `"Email"` / `"Text message"` | `Invite.channelTitle` for `"email"`/`"sms"` |
| (none — literal, hardcoded) | `"—"` | Blank-field display fallback throughout |
| (none — literal, hardcoded) | `"Registration failed (<status>)"` (web, template) | `registerWithInvite`'s fallback error message when the backend supplies none |

Every one of these strings is a hardcoded English literal with no
localization key or lookup mechanism in any of the seven given sources; this
is stated as a plain fact of the current source, not a gap.

