
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| skip-patterns storage key | string (fixed) | `"projectScanSkipPatterns"` | The literal name the setting is declared with; pinned per **skip-patterns-key**. |
| skip-patterns default | list of strings (fixed) | the scanner's own default root skip-pattern list | Returned whenever no value has been stored or a stored value cannot be decoded. |
| active-pane-highlight storage key | string (fixed) | `"highlight_active_pane"` | Pinned per **highlight-active-pane-key**. |
| active-pane-highlight default | boolean (fixed) | `true` | Returned whenever no value has been stored. |
| pointer-follows-focus storage key | string (fixed) | `"active_pane_follows_mouse"` | Pinned per **follows-mouse-key**. |
| pointer-follows-focus default | boolean (fixed) | `false` | Returned whenever no value has been stored. |
| secure-storage flag (all three) | boolean (fixed) | `false` | Not set explicitly at any of the three declarations, so the default applies, routing all three through the non-secure storage provider rather than a credential-vault-backed provider. |
| the shared settings store | singleton | the shared store | The store all three settings read and write through. A consuming app may replace the shared store before first access. |

No environment variable is read by this file — it is three plain settings
declarations with no parameters of their own; a separate coordinator is
the one caller that reads the skip-patterns setting's current value and
passes it into the scanner's own configuration, but that wiring lives
outside this component's own file and is not part of its contract.

