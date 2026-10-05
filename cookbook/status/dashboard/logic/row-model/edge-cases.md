
- **Null commit fields**: A null `commitHash`, `commitRepo` or `commitMessage` MUST yield `sha`, `commitUrl` and `message` of null, and `commitBody` of null (row-model-003).
- **Empty strings**: The commit-URL function called with an empty repository or an empty hash MUST return null. An empty `environment` MUST produce an empty env column in the row-text function's output, and an empty `sha` or `message` MUST be dropped from the commit column.
- **Unknown problem state**: A state absent from the state-label table MUST render verbatim (row-model-005). The server's documented state vocabulary contains only the seven names in state-label-table.
- **Unknown source**: A row's `source` that is not a known issue-source identifier (an activity row's `kind` fallback) MUST appear verbatim in the clipboard source column (row-model-025).
- **Malformed `at`**: A row's `at` is documented as an ISO timestamp. An unparseable value makes the relative-time calculation produce a non-numeric duration and render `"NaNd"`; this MUST be treated as a caller precondition violation, not handled here.
- **Future `at`**: A timestamp later than the current time gives a negative elapsed time and MUST render `"just now"`.
- **Boundary of the demotion window**: Elapsed time exactly equal to the window MUST NOT demote (row-model-032); one millisecond more MUST (row-model-028).
- **Missing probe interval**: An absent `probeIntervalMs` (older backend) MUST use the 10-minute floor; an interval of 120000 ms or less also yields the floor because five times it is at most 600000.
- **Unparseable deploy clock**: An in-flight deploy whose `phaseConfirmedAt` (or fallback `createdAt`) does not parse MUST demote — fail closed (row-model-030). A terminal deploy with an unparseable clock MUST NOT demote, since the in-flight test runs first.
- **Tabs and newlines in clipboard fields**: Not escaped; see the open question on text-field-escaping (row-model-033).
- **Commit subject over 200 characters**: `message` MUST be the first 200 characters with no ellipsis, while `commitBody` and the search-text function keep the full text.
- **Concurrent access**: Not applicable — every export is pure and synchronous, so calls cannot interleave.
- **Error states**: Not applicable — no function touches a network, file or other dependency, and none throws for well-formed input.
- **Offline or disconnected state**: Not applicable — no network is involved; freshness of the server data is judged elsewhere, by other logic outside this module.

