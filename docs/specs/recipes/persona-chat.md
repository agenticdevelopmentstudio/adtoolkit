---
id: E8EC809E-9B37-471B-A31A-F71BE67499C5
title: "Persona Chat"
domain: agenticdevelopertoolkit://recipes/chat/persona-chat
type: recipe
version: 1.0.0
status: draft
language: en
created: 2026-08-20
modified: 2026-08-20
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Wires a chat control to a persona conversation orchestrated by adh, through the cross-platform Backend contract and its orchestrator."
platforms:
  - ios
  - macos
  - swift
  - typescript
  - web
  - kotlin
  - windows
tags:
  - chat
  - persona
  - adh
ingredients:
  - agenticdevelopercookbook://ingredients/ui/components/ai-chat-control
  - agenticdevelopertoolkit://ingredients/chat/persona-chat-coordinator
depends-on: []
related:
  - agenticdevelopertoolkit://docs/planning/llm-backend-direction
references:
  - "docs/planning/planning.md — M1"
---

# Persona Chat

## Overview

A user converses with a persona. The chat control renders the transcript and
takes input; the coordinator relays turns to adh; adh does the orchestration.

This recipe exists to pin down the seam between those parts so the same
composition can be implemented on four platforms without each one inventing its
own answer. The parts themselves are specified in their ingredients — this
document is only about how they connect and what breaks where they meet.

Use this recipe for any surface where a user chats with a persona. It is the
composition M1 delivers.

## Ingredients

| Name | Domain | Role | Required | Configuration |
|------|--------|------|----------|---------------|
| AI Chat Control | `agenticdevelopercookbook://ingredients/ui/components/ai-chat-control` | Renders transcript, takes input, shows turn status | Yes | `statusUtterance` bound to the coordinator's status sink; `thinkingLabels` non-empty to enable rich status |
| Persona Chat Coordinator | `agenticdevelopertoolkit://ingredients/chat/persona-chat-coordinator` | Conforms to `Backend`; relays turns to adh | Yes | `personaSlug` required; `authorize` injected by the host app |

The orchestrator is not an ingredient. It is contract machinery that every
platform already has — `DefaultOrchestrator` in TypeScript, its Swift twin under
`AgenticDeveloperToolkit` — and this recipe consumes it rather than specifying it.

## Integration Requirements

- **pc-orchestrator-between**: The control MUST NOT hold a reference to the
  coordinator. All communication goes through the orchestrator.
- **pc-single-consumer**: The orchestrator MUST be the only consumer of
  `inboundEvents`. Fan-out to multiple observers is the orchestrator's job, per
  the `Backend` contract.
- **pc-control-is-passive**: The control MUST render from orchestrator state and
  MUST NOT own transport, retry, or accumulation.
- **pc-draft-rendering**: The control MUST render the active draft as
  provisional and visually distinct from committed messages, and MUST replace it
  with the committed `Message` on `messageReceived`.
- **pc-status-separate**: Turn status MUST reach the control through the status
  sink, not the transcript. Status MUST clear when the turn ends, including on
  failure and abort.
- **pc-coordinator-stability**: The host MUST keep one coordinator per
  `(personaSlug, model)` for the life of the surface. Recreating it discards the
  conversation.
- **pc-auth-injection**: The host app MUST inject credentials into the
  coordinator. Neither ingredient may import an auth module.
- **pc-destroy-on-teardown**: The host MUST call `destroy` when the surface goes
  away, cancelling any in-flight turn.
- **pc-tool-display**: Tool activity SHOULD be rendered as its own affordance,
  not as message text. A control that cannot render it MUST drop it rather than
  inline it.

## Layout

```
┌──────────────────────────────────────────────┐
│  AI Chat Control                             │
│  ┌────────────────────────────────────────┐  │
│  │ transcript (committed messages)        │  │
│  │ active draft (provisional)             │  │
│  │ tool activity (own affordance)         │  │
│  ├────────────────────────────────────────┤  │
│  │ status line  ◄── status sink           │  │
│  ├────────────────────────────────────────┤  │
│  │ input row                    [ Send ]  │  │
│  └────────────────────────────────────────┘  │
└───────────────┬──────────────────────────────┘
                │ observes state / calls send
                ▼
┌──────────────────────────────────────────────┐
│  Orchestrator (contract machinery)           │
│    messages · activeDrafts · participants    │
└───────────────┬──────────────────────────────┘
                │ Backend.send  ▲ inboundEvents
                ▼               │
┌──────────────────────────────────────────────┐
│  Persona Chat Coordinator  (implements       │
│  Backend)                                    │
└───────────────┬──────────────────────────────┘
                │ HTTPS + SSE
                ▼
┌──────────────────────────────────────────────┐
│  adh                                         │
│    persona lookup · prompt assembly          │
│    history read/write · provider call        │
└──────────────────────────────────────────────┘
```

The control never reaches past the orchestrator, and the coordinator never
reaches up. That is the whole point of the arrangement: three of the four boxes
are replaceable without touching the others.

## Shared State

| State | Source | Consumer | Direction | Mechanism |
|-------|--------|----------|-----------|-----------|
| Committed messages | Orchestrator | Control | one-way | State observer notification |
| Active draft | Orchestrator | Control | one-way | State observer notification |
| Tool activity | Orchestrator | Control | one-way | State observer notification |
| Turn status | Coordinator | Control | one-way | Status sink, bypassing the orchestrator |
| Outgoing message text | Control | Orchestrator | one-way | `send` call, returns `localID` |
| Conversation id | adh | Coordinator | one-way | Creation response; retained by the coordinator only |
| Credentials | Host app | Coordinator | one-way | Injected at construction |

Turn status is the one line that bypasses the orchestrator, and it does so
deliberately: status is not part of the transcript, and routing it through the
event stream would make a retry indistinguishable from something the persona did.

## Integration Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pc-001 | pc-orchestrator-between | Send a message from the control | Coordinator receives `send`; control holds no coordinator reference |
| pc-002 | pc-draft-rendering | Tokens `"Hel"`, `"lo"`, then `done` | Draft renders `"Hel"` then `"Hello"`; on commit exactly one message reading `"Hello"`, draft gone |
| pc-003 | pc-draft-rendering | `done` with zero tokens | One empty committed message; no lingering draft |
| pc-004 | pc-status-separate | Full turn | Status set on send, updated on first token, cleared at end; transcript contains no status text |
| pc-005 | pc-status-separate | Turn fails mid-stream | Status cleared; failure surfaced |
| pc-006 | pc-single-consumer | Two controls on one orchestrator | Both render identical state; `inboundEvents` consumed once |
| pc-007 | pc-coordinator-stability | Re-render the surface | Same conversation id; no new conversation created |
| pc-008 | pc-destroy-on-teardown | Tear down mid-turn | Request cancelled; no message commits |
| pc-009 | pc-tool-display | Tool call during a turn | Tool affordance shown; draft text unchanged |
| pc-010 | pc-control-is-passive | adh returns HTTP 200 with an in-band `error` | Control shows failure, not an empty successful turn |

These validate the seam. Per-ingredient behavior is covered by the ingredients'
own conformance vectors and is not repeated here.

## Edge Cases

- **Send while a turn is in flight.** The composition allows one turn at a time.
  A second send before `done` MUST be rejected or queued by the host, never
  interleaved into the same draft.
- **Surface remounts mid-turn.** The coordinator outlives the control when
  memoized correctly, so the turn continues and the transcript reconciles from
  orchestrator state. If the coordinator was recreated instead, the conversation
  is lost — the failure mode `pc-coordinator-stability` exists to prevent.
- **Two controls, one conversation.** Supported, because the orchestrator
  multiplexes. Both see the same draft.
- **adh adds an event the client does not know.** Ignored by the coordinator, so
  the composition degrades rather than breaking.
- **Truncated stream.** The connection drops before `done`. Surfaces as a
  failure; a partial reply MUST NOT commit as a complete message.
- **Tool call with no matching completion.** The affordance remains in its
  in-progress state for the rest of the turn and is cleared when the turn ends.

## Platform Notes

- **SwiftUI** — The orchestrator is `@Observable`; the control observes it
  directly. The coordinator is an `actor` held by the host view model, not the
  view, so it survives view identity changes. `destroy` belongs in the view
  model's teardown, not `onDisappear`, which fires on ordinary navigation.

- **Compose** — The orchestrator exposes state as `StateFlow`; the control
  collects it with `collectAsStateWithLifecycle`. The coordinator belongs to a
  `ViewModel` so it survives configuration changes. `destroy` goes in
  `onCleared`. Planned; not yet implemented.

- **React/Web** — The orchestrator is bridged into React by a hook that
  subscribes to state notifications and re-renders. The hook MUST NOT own
  transport — that is `pc-control-is-passive` expressed in React terms. The
  coordinator is memoized on `(personaSlug, model)`; `destroy` runs in the effect
  cleanup.

- **Windows** — The orchestrator raises `INotifyPropertyChanged`; the control
  binds to it. The coordinator is owned by the page's view model and disposed
  with it. Planned; not yet implemented.

## Design Decisions

**Decision**: The control talks to the orchestrator, never to the coordinator.
**Rationale**: It is the only arrangement where the transport can be swapped
without touching UI, and it is what makes the same control usable against a
scripted backend in tests. It also fixes the existing web split, where the React
hook owned both state and transport.
**Approved**: yes

**Decision**: Turn status bypasses the orchestrator.
**Rationale**: Status is not a transcript event. Adding it to `InboundEvent`
would force every platform to filter it back out before rendering history.
**Approved**: yes

**Decision**: One turn in flight at a time.
**Rationale**: adh pins a conversation to a single ordered history, and the draft
model has one active draft per participant. Concurrent turns would need a draft
identity the contract does not have. Deliberately deferred rather than designed
around.
**Approved**: pending

**Decision**: The orchestrator is consumed, not specified as an ingredient.
**Rationale**: It is contract machinery that already exists on the platforms that
matter, and a recipe composes ingredients rather than restating shared
infrastructure.
**Approved**: pending

**Decision**: Tool activity does not survive the turn that produced it.
**Rationale**: `activeCommands` is a live channel, cleared when the draft
clears, so a committed message carries no record of what the persona did to
produce it. This is the contract's shape, not an oversight — a command is
something in progress, and `Message` is immutable. The web control's earlier
behaviour differed: it kept tool pills on the committed bubble, and the legacy
`ChatBackend` adapter still does, by writing a frozen record into the message's
own payload. So the two paths currently disagree about history, which is the
part that needs a decision rather than a default. Resolving it means either
teaching `Message` a completed-invocations field (contract change, all
platforms) or accepting that tool activity is ephemeral and the adapter's
record is a compatibility shim with an expiry date. `pc-009` pins only the live
behaviour, which both paths agree on.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [rf-frontmatter-complete](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-frontmatter-complete) | passed | Artifact Formatting |
| [rf-type-field](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-type-field) | passed | Artifact Formatting |
| [rf-title-heading](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-title-heading) | passed | Artifact Formatting |
| [rf-overview](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-overview) | passed | Artifact Formatting |
| [rf-ingredients](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-ingredients) | partial | Artifact Formatting |
| [rf-integration-requirements](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-integration-requirements) | passed | Artifact Formatting |
| [rf-layout](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-layout) | passed | Artifact Formatting |
| [rf-shared-state](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-shared-state) | passed | Artifact Formatting |
| [rf-integration-test-vectors](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-integration-test-vectors) | passed | Artifact Formatting |
| [rf-edge-cases](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-edge-cases) | passed | Artifact Formatting |
| [rf-platform-notes](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-platform-notes) | passed | Artifact Formatting |
| [rf-design-decisions](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-design-decisions) | passed | Artifact Formatting |
| [rf-compliance](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-compliance) | passed | Artifact Formatting |
| [rf-change-history](agenticdevelopercookbook://compliance/artifact-formatting/recipe-formatting#rf-change-history) | passed | Artifact Formatting |

`rf-ingredients` is **partial**: the check requires every ingredient to resolve
under `agenticdevelopercookbook://ingredients/`, and the coordinator currently
lives in this repo under `agenticdevelopertoolkit://`. It resolves when the
artifacts move to the cookbook.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-08-20 | Mike Fullerton | Initial creation |
