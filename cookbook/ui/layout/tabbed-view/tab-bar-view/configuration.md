
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `edge` | Edge | (required, set at construction) | Which side of the container this bar is docked to; fixed for the bar's lifetime. |
| `startInset` | Number (points) | `8` | Where the first item begins, measured along the bar from its start. |
| `hostController` | Content reference (optional, held weakly) | None | Parent a content-hosting item's content is added to; unset means hosted content is never parented (see Edge Cases). |
| `onSelect` | Callback (tab id, optional) | None | Invoked when a tab is clicked, or when an assistive-technology press activates one. |
| `onClose` | Callback (tab id, optional) | None | Invoked when a tab's close control is activated. |
| `onReorder` | Callback (tab id and new index, optional) | None | Declared for a caller to observe reordering; never invoked by this concept itself (see **bar-never-fires-reorder** and the matching Design Decision). |

