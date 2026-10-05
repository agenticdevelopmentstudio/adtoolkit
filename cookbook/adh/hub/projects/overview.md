
This is the Projects ("work-tracking") domain logic of the hub: the logic
that models a *board* (a `Project`), the *cards* on it (a `WorkItem`), and
the surrounding scaffolding a board needs to run — columns
(`ProjectStatus`), participants, saved views, labels, plan points
(`Milestone`), cross-board time-boxes (`Iteration`), cross-board roll-ups
(`Program`), signed health reports (`ProjectStatusUpdate`), repeatable shapes
(`Template`), an intake inbox, a cross-board search, an append-only audit
trail, a threaded conversation, polymorphic pointers to content elsewhere in
the platform, and a payload-less live wake. This recipe has one reference
implementation today (see Platform Notes); the responsibilities below are
grouped by role rather than by source file:

- **Boards** — root board CRUD, plus `statuses`/`participants`/`savedViews`
  sub-groupings, `labels`, and a key-prefix validator with a client-side
  mirror of the backend's work-item-key shape rule.
- **Cards** — card CRUD, `move`, `children`, `dependencies`, `relations`,
  field values, and a byte-order comparator for a card's opaque
  fractional-index rank.
- **Iterations** — the workspace-owned time-box a card is committed to.
- **Programs** — the workspace-owned roll-up of several boards.
- **Milestones** — the board-owned plan points and their derived,
  `canceled`-excluded progress.
- **Status updates** — the signed reports `Project.health` is derived from.
- **Templates** — the "stamp this shape out again" workspace templates and
  helpers that read a card count or narrow a stored body to its kind.
- **Triage** — the intake queue a card sits in while `triagedAt` is null.
- **Search** — cross-board full-text card search.
- **Activity** — the newest-first, keyset-paginated audit trail.
- **Comments** — the one-level-deep card conversation.
- **Artifacts** — the polymorphic ingested/produced content links.
- **Live wake** — the refcounted, coalesced, payload-less "something
  changed" signal and the hook that consumes it.
- **Wire shapes** — the backend row and request-body shapes every mapper and
  call site above reads and writes; type-only.
- **Public surface** — every grouping above, plus the closed-set
  vocabularies (`StatusCategory`, `RelationKind`, `EstimateScale`,
  `PriorityScale`, `IterationState`, `ProjectHealth`, `TemplateKind`,
  `MilestoneCounts`, `WorkItemMoveTarget`, `TriageAcceptBody`) a consumer must
  be able to name in a signature without already holding a row.

Every grouping shares one shape: a mapper from a wire row type to a public
entity, a route constant, and a plain object of asynchronous methods over an
authenticated request helper. Two cross-cutting conventions recur throughout
and are stated once here rather than at each site: a shared "compact" helper
drops only `undefined` keys and preserves an explicit `null`, which is what
lets a partial update clear a column (`assigneeId: null`, `archivedAt:
null`) while an omitted key leaves it untouched; and every single-item fetch
resolves to `null` on a thrown 404 rather than rethrowing, so "not found" is
a value, not a `catch` a caller must write everywhere.

