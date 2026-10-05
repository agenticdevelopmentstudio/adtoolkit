
| Setting | Default | Effect |
|---|---|---|
| Hover request debounce | injected per hover-controller instance | Delays issuing a hover request after pointer movement to avoid a request per pixel of movement. |
| Semantic-token refetch debounce | 300 ms | Collapses consecutive edits into one `semanticTokens/full` request. |
| Semantic-token query timeout | 5 seconds | Bounds how long a parked highlight query waits for an in-flight fetch before answering empty. |
| Save debounce | 1 second, overridable at creation | Bounds how long a dirty document's write is delayed before it is flushed to disk. |
| Directory watcher factory | injected directory-watching implementation | Substitutable for tests; production uses an OS-level directory-watching implementation. |
| File reader | injected function | Substitutable for tests; production reads the file at the given URL. |

