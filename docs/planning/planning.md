# agenticdevelopertoolkit — Planning

Captured from the M1 brainstorming session on 2026-05-09. The session locked
scope, locked the high-level backend model, and paused before deciding the
final orchestration split. No design spec has been written yet.

## What this repo is

`agenticdevelopertoolkit` (adt) is the developer-facing toolkit that lets a
consuming app drop in a persona-driven chat UI backed by:

- **`agenticregistry`** — official persona registry. Holds persona records
  (`slug`, `modelPrompt`, `voice`, `character`, `examples`), per-user
  connected LLM services (`serviceId`, `model`, stored credentials), and
  provider integrations for Anthropic / OpenAI / Gemini at
  `web/backend/src/lib/providers/`.
- **`my-agentic-storage`** — personal storage service exposing
  `buckets / lists / events / kv / counters / queues / memory / keywords`.
  Chat history fits naturally into `lists` or `events`.

apt replaces `agentic-persona-coordinator` (apc). apc is deprecated; do not
add new work there. The coordinator role plus a broader set of tools live
here.

## Locked decisions

1. **Scope of this brainstorm = M1 only** (web chat slice). Everything else
   gets its own design spec when the time comes.
2. **Registry + storage are the chat backend.** The consuming site's own
   backend is not on the chat path. (`learntruefacts/backend/` exists, but
   it is not what the chat talks to.)
3. **The chat package already exists** at
   `agentic-web-toolkit/packages/features/chat/`. It has `ThreePaneChat`,
   `MobileChat`, `InlineChat`, `PersonaChat`, a `useChatSession` hook, and a
   `FetchBackend` that POSTs `{ message, history }` and accepts `{ reply }`
   or a stream of `ChatStreamEvent`s. Moving it into apt is a relocation,
   not a redesign.
4. **The coordinator package does not exist yet.** It is what M1 builds.

## Settled decision — A1

**Chosen: A1.** The registry and storage are both folded into the adh monorepo
(`~/Development/projects/adh/adh`), which removes A2's main argument — there is
no cross-service credential to avoid when the two services are one. adh
orchestrates; the coordinator relays.

The two options are kept below as written at the time, because the ingredient
spec's Design Decisions reference the trade-off.

### How it was split (historical)

### Option A1 — Registry orchestrates, coordinator is thin

- Add `POST /api/personas/:slug/chat` to the registry. Body: `{ sessionId,
  message }`.
- Registry resolves the persona, reads history from storage server-to-server
  (using a per-user storage credential it holds), calls the provider, persists
  the new turn back to storage, returns the reply (or streams).
- Coordinator package is mostly a `FetchBackend` factory + auth helper.

**Pros:** one network round-trip per turn from the browser; sites with no
backend can use this directly.
**Cons:** registry must hold a storage credential per user (key-management
story); coordinator package is thin and does not earn its name.

### Option A2 — Coordinator orchestrates, registry stays history-stateless

- Add `POST /api/personas/:slug/complete` to the registry. Body: `{ messages:
  [...] }`. Returns or streams a completion using the persona's `modelPrompt`
  + `serviceId` + the user's stored creds.
- Coordinator package implements `ChatBackend`. It reads history from
  storage, calls the registry's `complete` endpoint, writes the new user
  message + assistant reply to storage, and emits the appropriate
  `ChatStreamEvent`s.

**Pros:** registry and storage stay orthogonal — neither holds a credential to
the other. Coordinator does meaningful work, and the same orchestration logic
ports to the Python terminal tool, the Apple coordinator, etc. when those
milestones arrive.
**Cons:** two browser-side network paths per turn; coordinator must handle
streaming choreography itself.

### Why A1 won

A2's whole case was decoupling: neither service holding a credential to the
other. Folding the registry and storage into one deployment made that a
non-issue, and A1's one-round-trip-per-turn and zero-backend-required
properties survived. The cost — a thin coordinator — turned out to be the
point: three of the four platform ports are a few hundred lines each precisely
because there is nothing to orchestrate client-side.

Specified in `docs/specs/ingredients/persona-chat-coordinator.md`.

## Milestones

| | Scope | Notes |
|---|---|---|
| **M1** | Relocate the web chat package; build the coordinator package; switch `learntruefacts` from vendoring `agentic-web-toolkit` to consuming apt as a real npm dependency. | The brainstorm covers this milestone only. |
| M2 | Python scripts that configure persona chats; a Python tool for trying out a persona in the terminal. | Will exercise the same orchestration model M1 settles on. |
| M3 | A Claude skill (or set of skills) for creating personas. A skill that populates persona info into the registry. | Builds on the registry contract M1 establishes. |
| M4 | A whimsical name + bio generator. | Pure feature add. The bones of this work started life as `personacreator`. |
| M5 | Absorb `personacreator` (Python lib + Claude skill) into this repo. | Coordinate with that project's owner; not blocking. |
| M6 | Apple, Windows, and Android coordinator ports. | Apple shipped. Windows and Android are planned in [`ports/`](ports/) and not started. |

## Test bed

`learntruefacts` (`~/Development/projects/learntruefacts/`) is the dogfood
site for apt. It is a separate monorepo of its own, not a directory inside
some other product's repo. Today its `sites/main` uses the chat by vendoring
`agentic-web-toolkit` at `vendor/agentic-web-toolkit/`. The success criterion
for M1 is: that vendor copy is gone, replaced by an apt dependency, and the
chat is talking to a real persona in the registry with messages persisted in
storage.

## Next steps

1. ~~User decides A1 vs A2.~~ Settled: A1.
2. ~~Spec.~~ Written as an ingredient
   (`docs/specs/ingredients/persona-chat-coordinator.md`) and a recipe
   (`docs/specs/recipes/persona-chat.md`) rather than a dated design doc, so
   each platform port derives from the same conformance vectors.
3. ~~TypeScript and Swift implementations.~~ Both ship, both proved against the
   vectors by mutation testing.
4. Switch `learntruefacts/sites/main` off the vendored toolkit and onto a real
   apt dependency — the remaining M1 success criterion.
5. Windows and Android ports, per [`ports/`](ports/).

## See also

[`llm-backend-direction.md`](llm-backend-direction.md) — what we intend to
take from Apple's Foundation Models provider architecture into the `Backend`
contract (usage reporting, classified failures, reasoning as its own channel,
capabilities, a conformance catalogue). Written ahead of its milestone because
`Backend` has no conformers yet and the changes are free until it does. It does
not resolve A1/A2 — the event vocabulary is the same under either.
