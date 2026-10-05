
None of the keys below exist in source — the component makes no
localization call of any kind. They are proposed keys for the localization
pass named in the open question below, not an inventory of what is
implemented.

| Proposed Key | Default (en) | Context |
|-----------|-------------|---------|
| `theme_preview.chrome.title` | Window Title | Chrome sample's title label |
| `theme_preview.chrome.body` | Body text in the body font. | Chrome sample's body label |
| `theme_preview.chrome.caption` | Secondary caption text | Chrome sample's caption label |
| `theme_preview.chrome.button` | Button | Chrome sample's accent-filled pill |
| `theme_preview.chrome.selected` | Selected | Chrome sample's selection-filled pill |
| `theme_preview.chrome.panel_caption` | Panel · outline | Chrome sample's outlined inner panel |
| `theme_preview.list.tab_notes` | Notes | List sample's first tab |
| `theme_preview.list.tab_chat` | Chat | List sample's second tab |
| `theme_preview.list.tab_terminal` | Terminal | List sample's third tab |
| `theme_preview.list.row1_title` / `row1_detail` | Release notes / Yesterday | List sample's first row |
| `theme_preview.list.row2_title` / `row2_detail` | Design review / 2 days ago | List sample's selected row |
| `theme_preview.list.row3_title` / `row3_detail` | Scratch / Last week | List sample's third row |
| `theme_preview.controls.typed` | Typed text | Controls sample's filled field |
| `theme_preview.controls.placeholder` | Placeholder | Controls sample's placeholder field |
| `theme_preview.controls.checkbox_line` | ☑︎ Enabled    ☐ Disabled | Controls sample's checkbox line |
| `theme_preview.status.success` / `warning` / `error` / `info` | Success / Warning / Error / Info | Status sample's four badges |
| `theme_preview.terminal.prompt` | user@mac ~ % ls | Terminal sample's prompt line |
| `theme_preview.terminal.dir` | Documents | Terminal sample's directory entry |
| `theme_preview.terminal.file` | README.md | Terminal sample's file entry |

Every string above is a literal set directly as a label's text (not routed
through any state/binding-driven text mechanism), and none of it is routed
through a localization table anywhere in source. Source gives no
localization path today for any of these illustrative demo strings.

