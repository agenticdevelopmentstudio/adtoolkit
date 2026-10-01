# Charlie — chat wiring in the Temporal app

A reference snapshot of how the **Charlie** persona is wired in the Temporal
monorepo (`~/Development/projects/temporal`), as of 2026-05-15. Useful as a
worked example of an `@agentic-cookbook/agentic-web-toolkit` consumer talking
to a Ktor backend with persona-driven prompts and a shared tool registry.

## Surface map

| Layer | Path |
|---|---|
| Web UI page | `web/app/src/components/charlie/CharliePage.tsx` |
| Real backend adapter (active) | `web/app/src/components/charlie/CharlieRealBackend.ts` |
| Stub backend adapter (dev fallback, unused) | `web/app/src/components/charlie/CharlieStubBackend.ts` |
| App registry entry | `web/app/src/appRegistry.ts` |
| Ktor routes | `web/backend/src/main/kotlin/company/temporal/backend/routes/ChatRoutes.kt` |
| Chat orchestration | `web/backend/.../llm/ChatService.kt` |
| Tool surface (shared with MCP) | `web/backend/.../llm/ToolRegistry.kt`, `LlmTool.kt` |
| Provider factory | `web/backend/.../llm/LlmProviderFactory.kt` |
| Provider impls (no SDKs, HTTP only) | `OpenAiCompatProvider.kt`, `AnthropicProvider.kt`, `GeminiProvider.kt` |
| Persona seed | `web/backend/.../database/PersonaSeeder.kt` (slug `charlie`) |
| Narrative doc | `<temporal>/docs/personas/charlie.md` |

## 1. Frontend

`CharliePage` is a thin mount of the toolkit's `InlineChat`:

```tsx
import { InlineChat } from '@agentic-cookbook/agentic-web-toolkit/chat'
import { CharlieRealBackend } from './CharlieRealBackend'

const backend = useMemo(
  () => new CharlieRealBackend({ personaSlug: 'charlie' }),
  [],
)
return (
  <InlineChat
    backend={backend}
    persona={persona}
    user={USER}
    welcomeMessage={`Hi, I'm ${persona.name}. ...`}
  />
)
```

- `InlineChat` owns message state, the composer, the message list, scroll
  behavior, etc.
- Charlie supplies only a `ChatBackend` implementation and persona metadata
  (fetched via `getPersona('charlie')`).
- The `useMemo([])` keeps the backend stable across renders so the lazy
  conversation id survives — remount resets the conversation, since there is no
  "resume conversation" UI yet.

## 2. Backend adapter (`CharlieRealBackend`)

Implements the toolkit's `ChatBackend` interface with two calls against the
Ktor server, both using the shared `authFetch` helper (JWT cookie + bearer).

**Lazy conversation create** — fires once per `CharlieRealBackend` instance:

```http
POST /api/chat/conversations
Content-Type: application/json
{ "title": "Charlie chat", "personaSlug": "charlie" }
→ 200 { "id", "title", "model", "createdAt", "updatedAt" }
```

**Streamed message**:

```http
POST /api/chat/conversations/{id}/messages
Content-Type: application/json
Accept: text/event-stream
{ "message": "..." }
→ 200 text/event-stream
```

SSE event names are chosen to **match `ChatStreamEvent.type` exactly**, so the
adapter does no name translation — only `JSON.parse` of each `data:` payload:

| SSE `event:` | Payload | Toolkit type |
|---|---|---|
| `token` | `{ text }` | `{ type: 'token', text }` |
| `tool_call_started` | `{ name, arguments }` | `{ type: 'tool_call_started', name, arguments }` |
| `tool_call_completed` | `{ name, ok, result }` | `{ type: 'tool_call_completed', name, ok, result }` |
| `done` | `{}` | `{ type: 'done' }` |
| `error` | `{ message }` | `{ type: 'error', message }` |

Frame parser (`parseSse`) splits on `\n\n`, accumulates `event:`/`data:` lines,
strips one leading space after `data:`, drops the trailing newline. Standard
SSE handling — nothing custom.

## 3. Backend

### Routes (`ChatRoutes.kt`)

Mounted under `authenticate("jwt", "api-token")`, so the chat surface accepts
the same credentials as the rest of the web app **and** programmatic API
tokens. The streamed POST handler:

1. Loads conversation history via `ChatPersistence`.
2. Calls `ChatService.send(userId, conversation, message)`.
3. Forwards each `ChatStreamEvent` from the service as an SSE frame with the
   matching event name. Same name space as the frontend parser — no rewrite.

### Orchestration (`ChatService`)

For one user turn:

1. **Resolve persona** by `conversation.personaSlug` (default `charlie`).
2. **Assemble system prompt** in `assemblePersonaPrompt(persona)`: concatenates
   `modelPrompt`, `voice`, `character`, and `examples` columns from the persona
   row. Falls back to `ChatServiceConfig.DEFAULT_SYSTEM_PROMPT` only if the
   persona has no prompt fields.
3. **Pick the provider** via `LlmProviderFactory`, which inspects the persona's
   linked `persona_service` row to choose between OpenAI-compatible, Anthropic,
   and Gemini HTTP clients. Falls back to `LLM_BASE_URL`/`LLM_API_KEY`/
   `LLM_MODEL` env vars if no service is linked.
4. **Send** message + history + tool defs (`ToolRegistry.definitions(userId)`).
5. **Stream** tokens out as `token` events.
6. If the model emits `ToolCalls`, dispatch each through `ToolRegistry`, emit
   `tool_call_started`/`tool_call_completed`, append results to history, **loop
   back to step 4**.
7. Persist the assistant message; emit `done`.

The loop is the only thing that knows about tools — providers are pure
"messages in, messages out" with a `finishReason`.

### Providers — no SDKs

There is **no `@anthropic-ai/sdk`, no `openai`, no `@google/generative-ai`
dependency on the JVM side**. Each provider is hand-rolled over Ktor
`HttpClient`:

- `AnthropicProvider` — `POST $baseUrl/messages`, headers `x-api-key` and
  `anthropic-version: 2023-06-01`, parses native Anthropic SSE
  (`message_start`, `content_block_delta`, `message_stop`, …) and normalizes
  to the internal stream type.
- `OpenAiCompatProvider` — chat completions API, works against OpenAI, Groq,
  Together, etc.
- `GeminiProvider` — Generative Language API.

Trade-off: more code to maintain vs. **zero SDK lock-in, identical streaming
surface across providers, and one place to add observability hooks**.

## 4. Tool surface

Tools implement `LlmTool`:

```kotlin
interface LlmTool {
  val name: String
  val description: String
  val parametersSchema: JsonObject
  suspend fun execute(userId: UserId, args: JsonObject): JsonObject
}
```

Registered once in `Application.kt`; the same `ToolRegistry` instance powers
**both** Charlie chat **and** the MCP server at
`https://mcp.temporal.services/mcp`. Currently registered:
`SearchThreadsTool`, `MyBookmarksTool`, `MyNotificationsTool`, `MyProfileTool`,
`ListCategoriesTool`, `GetMyJobsTool`, `GetMyEducationTool`,
`GetMyLocationsTool`, `GetMyDatesTool`, `GetMyContactsTool`,
`GetMyRelationshipsTool`, `GetMyTagsTool`, `SearchMyNotesTool`,
`GetKeywordsForTool`, `GetCategoryContentsTool`.

**Per-user isolation** is enforced by the registry: `userId` is injected from
the authenticated principal in the route layer and passed to `execute(...)`.
The LLM never names a user — it can only act as the caller. Adding a new tool
means implementing `LlmTool` and adding it to the registration list; both the
chat surface and the MCP endpoint pick it up automatically.

## 5. Auth model

| Endpoint | Auth |
|---|---|
| `/api/chat/conversations[/:id/messages]` | JWT **or** API token (Ktor `authenticate("jwt", "api-token")`) |
| `/mcp` | API token only (call-pipeline interceptor, not a Ktor auth realm) |

MCP runs in **stateless** Streamable HTTP mode specifically so the `Server`'s
`userIdProvider` can close over the per-request authenticated principal — a
stolen `MCP-Session-Id` cannot impersonate another user. The chat route does
not have this concern because there is no session multiplexing — one HTTP
request, one user.

## 6. What's not in place yet

Operationally, not code-wise. The wiring is end-to-end, but `ChatService` will
return an `error` event unless one of these is true:

- **Env fallback**: `LLM_BASE_URL`, `LLM_API_KEY`, `LLM_MODEL` set on the Ktor
  process, **or**
- **Per-persona service**: a row in `persona_services` linked to the Charlie
  persona via the admin UI, supplying base URL + key + model.

No TODOs, no stubbed handler in the Kotlin code, no commented-out route. The
stub adapter (`CharlieStubBackend.ts`) is dormant — `CharliePage` imports the
real one.

## Takeaways for other toolkit consumers

- **Match SSE event names to `ChatStreamEvent.type` on the server side.** The
  adapter then becomes a near-pure passthrough — no name table to keep in
  sync.
- **Keep the backend adapter dumb.** `CharlieRealBackend` is one file, two
  HTTP calls, and a generic SSE parser. All persona logic lives server-side so
  the same adapter shape works for any persona.
- **Lazy-create conversations on first message.** Avoids dangling empty
  conversations and lets the UI mount without a network round-trip.
- **One `ToolRegistry`, two surfaces.** Chat and MCP share the exact same tool
  list and per-user isolation. Adding a tool is a one-line registration.
- **`userId` from the principal, never from the model.** Tools take `userId`
  as a parameter to `execute(...)` and the registry injects it from the
  authenticated call — model arguments cannot override it.
- **No vendor SDKs.** Provider implementations are HTTP + a streaming parser.
  Adding a provider is one Kotlin file; swapping providers is a DB row.
