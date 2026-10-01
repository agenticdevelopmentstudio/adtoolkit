# LLM Backend Design Direction

What we intend to take from Apple's Foundation Models provider architecture into
apt's `Backend` contract, and what we intend to leave behind.

**This is a direction, not a spec.** It does not resolve the paused A1/A2
orchestration decision in [`planning.md`](planning.md), it is
not M1 scope, and it does not redesign the chat package's fixed HTTP contract
(POST `{ message, history }` → `{ reply }` or a stream of `ChatStreamEvent`).
It records what we decided while the reasoning is fresh, so the work is cheap
when its turn comes.

## Why write this now rather than when we build it

Every change proposed here is close to free today and expensive later:

| | Today |
|---|---|
| `Backend` conformers | **zero** — `grep ": Backend"` across `packages/apple` returns nothing |
| `InboundEvent` producers | **zero** |
| `AgenticDeveloperToolkit` tests | **zero** — no `Tests/` directory exists |
| Planned ports of the same contract | **three** (M6: Apple, Windows, Android) |

A protocol with no implementations can absorb a new case for the cost of typing
it. The same case added after four implementations exist across three languages
is a coordinated migration. `small-reversible-decisions` says spend the decision
now, while it is still small.

The forcing detail is M6. `contract/index.ts` opens with "TypeScript expression
of the Swift protocols under `apple/AgenticDeveloperToolkit/Sources/`. Keep both in
lockstep" — and lockstep is currently enforced by nothing but discipline across
two languages, with two more coming.

## Where the ideas come from

`~/Development/projects/applellmprovider` is a Foundation Models provider for
OpenAI-compatible gateways, plus `LanguageModelConformance` — sixteen scenarios
any correct provider must pass. Its code is not reusable here: it is Swift, it
is gateway-specific, and it targets an OS floor nine major versions above
AgenticDeveloperToolkit's.

What transfers is the catalogue of **rules a chat contract does not enforce and
that fail silently when broken**. Each one below compiles, runs, answers, and is
wrong in a way no error reports.

## Direction 1 — extend `InboundEvent` before it has producers

`InboundEvent` is twelve well-chosen cases. The draft mechanism in particular
(`draftUpdated` / `draftCleared` → `messageReceived`, keeping `Message`
immutable) is the same answer Apple reached with transcript entries, arrived at
independently. Keep it.

Four things it cannot currently express:

### 1a. Nothing reports what a turn cost

There is no usage event. A consuming app cannot display token counts or spend,
and we cannot tell whether prompt-prefix caching is working — because nothing
reads the number that would say so.

```ts
| {
    readonly kind: 'usageReported'
    readonly participantID: string
    readonly inputTokens: number
    readonly cachedInputTokens: number
    readonly outputTokens: number
    readonly reasoningTokens: number
  }
```

```swift
case usageReported(
    participantID: String,
    inputTokens: Int,
    cachedInputTokens: Int,
    outputTokens: Int,
    reasoningTokens: Int)
```

**The non-obvious part is the semantic, and it belongs in the doc comment:
totals are cumulative and replace wholesale — they are not increments.** A
backend that adds each report to the last produces a plausible number, with no
error and nothing to catch in review. Break `cachedInputTokens` out separately
rather than folding it into `inputTokens`; a cached token is billed differently
and is the only signal that prefix stability is holding.

### 1b. Failure is an unactionable string

Today: `messageFailed(localID:reason: String)` and
`transportError(message: String)`. A UI cannot branch on prose. "You are sending
messages too quickly," "this conversation has grown too long," and "the model
declined to answer" need three different affordances and currently arrive
identically.

```ts
export type BackendFailure =
  | { readonly kind: 'rateLimited'; readonly retryAfterSeconds?: number }
  | { readonly kind: 'contextOverflow' }
  | { readonly kind: 'refused' }
  | { readonly kind: 'contentFiltered' }
  | { readonly kind: 'unauthorized' }
  | { readonly kind: 'timedOut' }
  | { readonly kind: 'transport'; readonly message: string }
  | { readonly kind: 'server'; readonly status: number; readonly message?: string }
```

`messageFailed` then carries a `BackendFailure` instead of a `reason` string,
and `transportError` becomes its `transport` case. Retry policy stops being a
hardcoded set of HTTP status numbers and becomes a switch over intent.

`refused` earns its place twice over: a refusal arrives with a **200 and looks
like ordinary content**. A backend that lets it through as text hands the user a
plausible answer the model explicitly declined to give — the worst failure in
this list, because it is invisible.

### 1c. Reasoning has nowhere to go except into the answer

No reasoning event exists. A persona backed by a thinking model has two
options today: discard the reasoning, or append it to `draftUpdated` — where it
commits into the user-visible `Message`.

Mirror the draft pair rather than inventing a new shape:

```ts
| { readonly kind: 'reasoningUpdated'; readonly participantID: string; readonly text: string }
| { readonly kind: 'reasoningCleared'; readonly participantID: string }
```

The rule to write down: **reasoning and answer text are separate channels and
must never merge**, including when they alternate mid-turn. Interleaving is
where implementations actually fail.

### 1d. `done` cannot distinguish finished from truncated

There is no finish reason anywhere in `InboundEvent`, and `ChatStreamEvent`'s
`{ type: 'done' }` carries none either. A response cut off at the token limit
commits as a complete `Message` and looks exactly like one. Whether this becomes
a field on `messageReceived` or a `contextOverflow`-adjacent failure is a design
call for the spec; that it must be distinguishable is the direction.

### 1e. Two things to confirm rather than change

- **`draftUpdated.text` — fragment or accumulation?** The doc comment says the
  participant "has appended to their in-progress draft," but the field is
  `text` and `ActiveDraft.text` is plainly the whole accumulated draft. Both
  readings are defensible and mixing them silently doubles every message. Pin
  it down with a test, not a comment.
- **`CommandInvocation.id` must be per-invocation, not derived from
  `commandName`.** apt already made the right call by carrying whole
  `argumentsJSON` rather than streamed fragments, which sidesteps a whole class
  of accumulation bug. The remaining risk is two parallel invocations of the
  same command colliding if the id is name-derived. (An identical bug appears
  live in adh's Gemini provider, which sets `id = part.functionCall.name`.)

Also worth noting: `CommandInvocation` and `CommandResult` exist as types, but
no `InboundEvent` case carries either, and `ChatViewModel` exposes no pending
invocations. Tool calls can be *described* but not *observed*. That gap needs
closing whenever tool support becomes real.

## Direction 2 — declare capabilities, and check before dispatch

Nothing in the contract says whether the model behind a persona can call tools,
reason, or accept images. The `Command` / `Tool` / `Skill` / `Permission`
machinery assumes it can.

The failure mode is documented in a sibling project rather than hypothetical:
adh's `service.ts:176` hardcodes `tools: []` on the persona path with the
comment that "many chat models reject a `tools` param outright." Lacking a
capability check, the workaround was to disable the feature globally. Its
`LlmModel` type does declare `supportsTools` / `supportsVision` /
`supportsThinking` — populated by no provider and read by nobody.

The direction: capabilities are declared by the backend, read before dispatch,
and an incompatible request is **refused up front rather than degraded
silently**. `fail-fast` and `explicit-over-implicit`. A declared capability is a
promise the conformance catalogue below then holds you to.

## Direction 3 — a conformance catalogue, written before the first conformer

This is the highest-value item, and apt is a better fit for it than the project
it came from. We are committing to one contract with four implementations
(TypeScript now; Swift, Kotlin, and Windows at M6) and a lockstep requirement
currently enforced by a comment.

Write a catalogue of scenarios describing what any correct `Backend` must do,
expressed against the contract and runnable per platform. Claims like: text
fragments concatenate in order; a draft commits to exactly one immutable
message; usage replaces rather than accumulates; a truncated stream does not
present as complete; a refusal surfaces as `refused` and never as text;
reasoning never lands in the answer; parallel invocations keep distinct ids;
declining a capability is reported, not silently skipped.

Two rules that make the difference between a catalogue and decoration:

- **A scenario that has never failed has proved nothing.** Break the backend
  until each scenario fails for exactly the reason it claims to catch — no
  fewer scenarios (it asserts nothing), no more (it asserts something it does
  not claim). In `applellmprovider` all sixteen passed on first run and were
  only trustworthy after the provider was broken twelve ways, one at a time.
- **A skipped scenario is a reported outcome, never silence.** A backend that
  quietly stops declaring a capability must not turn its scenarios green by
  deleting them.

`AgenticDeveloperToolkit` having zero tests today makes this the natural first thing to
put under it.

## Direction 4 — Apple (M6): Foundation Models behind `Backend`, not the reverse

`Backend` stays the seam. On Apple, `LanguageModelSession` becomes one
implementation behind it, availability-gated, giving on-device inference through
the same contract as the remote persona path.

This is the opposite of the recommendation that fits a single-platform Apple
toolkit, and the reasons are specific to apt:

- **The floor.** `AgenticDeveloperToolkit` targets iOS 17 / macOS 14 on Swift 5.10.
  Foundation Models needs 26+, and its executor protocols 27+. Adopting Apple's
  `LanguageModel` as *the* seam would raise apt's floor by nine major versions
  on every platform, to serve one.
- **Android and Windows are real milestones here**, with folders and a place in
  M6 — not placeholders. A cross-platform contract is load-bearing.
- **`Backend` is rich enough to be worth conforming to.** The usual argument
  against wrapping Apple's framework is that the wrapper is a bare string
  stream and throws away tools, structured output, and transcript management.
  `Backend` is not that: it has attachments, widgets, permissions, commands,
  read state, and immutable messages. The adapter loses little.

The gated adapter is additive and can be built the day someone wants on-device
personas. Nothing here needs deciding at M1.

## What we are deliberately not taking

- **The instruction/adapter split** (`ChannelInstruction` + `ChannelWriter` +
  a branchless `ChannelAdapter`). It exists solely because Apple's channel
  `Event` is write-only — you can send one and never read it back, so ordering
  logic had to move somewhere observable. `InboundEvent` is already a plain
  inspectable union that tests can assert on directly. Copying the seam would
  buy a layer to solve a problem we do not have. It is the most elaborate thing
  in that package and the clearest thing to skip.
- **Porting the wire layer.** apt does not talk to model APIs and should not
  start. The knowledge worth sharing is the wire facts, and those are written
  down where they are used.
- **A `Transcript` abstraction.** `Message` (immutable) plus `ActiveDraft`
  already occupies that ground, and arrived at the same answer.

## What this depends on

apt can only carry what its backend produces. Usage counts, classified
failures, capability declarations, and reasoning all have to *originate* wherever
the provider call is made — `agenticregistry`'s
`web/backend/src/lib/providers/` for the persona path. If the registry cannot
report cached input tokens, `usageReported` carries zeros, and that is a
registry gap rather than a contract gap.

Which side does the classifying depends on the paused A1/A2 split: under A1 the
registry classifies and the coordinator relays; under A2 the coordinator
classifies what the registry's `complete` returns. **The event vocabulary is the
same either way**, which is why this document can be written before that
decision and does not pre-empt it.

## See also

- [`planning.md`](planning.md) — milestones and the paused
  A1/A2 decision.
- `~/Development/projects/applellmprovider/docs/conformance.md` — the sixteen
  scenarios and, more usefully, the section on what a harness deliberately does
  not cover.
- `~/Development/projects/applellmprovider/docs/design.md` — "The rules that are
  not in the signatures."
