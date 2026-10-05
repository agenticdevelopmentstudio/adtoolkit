
- **Decision**: keep `readOnly` (the tool's nature, driving MCP safety
  annotations) and `adminOnly`/`isAdminTool` (who may call it) as two
  independent fields rather than one combined flag.
  **Rationale**: `tools.ts`'s own header comment states this directly —
  conflating the two is what let an earlier version of this surface widen
  access, because a tool's annotation-facing "this is just a read" nature
  was mistaken for "any tier may call it," when several reads have an
  admin-only REST twin and must stay admin-gated regardless of their
  read-only nature.
  **Approved**: pending
- **Decision**: enforce authorization at two independent layers
  (registration-time filtering via `selectTools`, and a per-handler
  re-check via `isAdminTool` inside every registered tool's callback)
  rather than trusting registration filtering alone.
  **Rationale**: stated directly in `server.ts`'s doc comment — the
  re-check guards against a `selectTools` defect that mis-registers an
  admin-gated tool for `'view'`; defense in depth rather than a single
  point of failure for the entire write/admin-read surface.
  **Approved**: pending
- **Decision**: have `list_platform_projects`/`find_unconfigured_sites`
  re-verify the live platform project list on every call rather than
  trusting the DB mirror the REST routes may have already cached.
  **Rationale**: `mcp-deploy-tools.int.test.ts`'s header comment states
  this directly — before this fix, an agent could act on a project the
  platform had already deleted, including re-creating a site the operator
  had just removed; the fix accepts an uncached round-trip on every call
  because "a tool call is rare and always deliberate" (per `tools.ts`'s
  own comment), unlike the REST route's higher-frequency traffic.
  **Approved**: pending
- **Decision**: derive `get_issue` from `boardProblems` (the same function
  `GET /board` calls) rather than reading the ledger table
  (`openByTarget`) directly.
  **Rationale**: the Task-14 regression fix, documented in
  `board-route.test.ts`'s header comment — a stale ledger row for a target
  the board no longer derives (for example, a long-deleted site) used to
  answer non-null forever; deriving from the same function the board uses
  guarantees `get_issue` can never drift from what `get_problems`/`GET
  /board` consider open.
  **Approved**: pending
- **Decision**: construct a fresh `McpServer`/transport per HTTP request
  with `sessionIdGenerator: undefined`, rather than a long-lived server
  with stateful MCP sessions.
  **Rationale**: not stated in source as a tradeoff; this is a plain fact
  about the code's actual shape. It keeps the tool set registered on any
  given server instance always current with the caller's just-resolved
  tier (no session-lifetime tier caching to invalidate), at the cost of
  rebuilding the tool registry on every call.
  **Approved**: pending

