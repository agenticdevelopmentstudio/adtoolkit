
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| secret-storing-001 | concurrent-share-safety | Inject the production implementation as a chat-completion operation's default secret-store argument and capture it inside the daemon's asynchronous completion work | Compiles and runs cleanly with no concurrency-safety diagnostic |
| secret-storing-002 | get-contract | Call set with value "sk-secret-123" for key, then call get for the same key | Returns "sk-secret-123" |
| secret-storing-003 | get-contract | Call get for a key never stored | Returns none |
| secret-storing-004 | set-overwrites | Call set with "first" for key, then set with "second" for the same key, then call get for that key | Returns "second" |
| secret-storing-005 | return-value-optional | Call set as a bare statement with its returned success value unused | Succeeds with no "result unused" diagnostic |
| secret-storing-006 | delete-idempotent | Call delete for a key never stored | Returns success |
| secret-storing-007 | key-value-opacity | Call set with an empty string for key, then call get for the same key | Returns an empty string, not none — an empty string is a legitimate stored value distinct from "absent" |
| secret-storing-008 | production-store-delegation | Inspect the production implementation's get, set, and delete operations | Each is a single-expression call to the corresponding secure-storage-helper operation with no other statement |
| secret-storing-009 | production-store-stateless, production-store-init | Construct two separate instances of the production implementation and call get for the same key from each | Both instances return the identical result, since neither holds instance state |
| secret-storing-010 | legacy-service-constant | Read the production implementation's legacy-service identifier | Equals "com.agentictoolkit", matching the secure-storage helper's own default-fallback identifier |
| secret-storing-011 | deletelegacy-targets-legacy-service | Pin the active service identifier to "com.example.host"; store "legacy-value" for key while temporarily retargeting the active service identifier to the legacy-service identifier; restore the pin; store "current-value" for key under "com.example.host"; then call delete-legacy for key | The legacy-service entry for key is gone (a direct read under the legacy-service identifier returns none); a get for key under the pinned service still returns "current-value" |
| secret-storing-012 | deletelegacy-restores-pinned-service | Pin the active service identifier to "com.example.host"; call delete-legacy for key; read the active service identifier immediately after the call returns | Equals "com.example.host" — the value held immediately before the call |
| secret-storing-013 | deletelegacy-idempotent | Call delete-legacy for a key never stored under the legacy service | Returns success |
| secret-storing-014 | interface-over-concrete-usage | Inspect the chat-completion operation's parameter type for its injected secret store, and its tests' fixtures | Parameter type is the abstract secret-store interface, never the concrete production implementation; every test call site substitutes the in-memory test double |
| secret-storing-015 | same-key-concurrent-mutation | Issue set("A") and set("B") for the same key from two concurrent tasks with no external lock | Per the underlying store's internal delete-then-add write path, the losing task's add can fail, making that set call return failure for well-formed input — demonstrating the unspecified ordering; no test in the given sources exercises this concurrent scenario |

