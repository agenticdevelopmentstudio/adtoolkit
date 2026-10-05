
| State | Appearance change |
|-------|------------------|
| Closed | The command palette is not shown; internal query text, result list, error message, and loading flag are reset |
| Open, query empty | Empty-results label reads "Start typing an address"; loading is false, error message is none, result list is empty |
| Open, query non-empty, debounce/search pending | A loading flag is passed to the command palette (shown beside any still-displayed prior results, per the command palette's own loading treatment) |
| Open, search resolved with results | The result list is populated; each renders as a group item keyed by `rdid` |
| Open, search resolved with zero results | The result list is empty; empty-results label reads "No matching address" |
| Open, search rejected | The error message is set to the rejection message (or "Search failed"); the result list is empty; loading is false |

