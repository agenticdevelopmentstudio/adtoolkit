
This component is `reactionsApi` (three methods: `list`, `add`, `remove`) plus the pure
folding helpers `tally` and `byTarget` and the mapper `toReaction`, all in `reactions.ts`,
with their wire shapes in `wire.ts`. It is the one client for emoji reactions on ANY
subject in the product: the backend store names a reaction's subject as a free
`(targetKind, targetId)` pair rather than a foreign key into one table, so a comment, a
discussion post and a research document all reach the same `/api/content/reactions`
surface through the same three calls — a new kind of thing to react to needs only a new
`targetKind` string, never a new table, route, or client. This is a **logic** component:
`reactions.ts` and `wire.ts` render nothing — they are a plain fetch-based client, two pure
array-folding functions, and type-only wire shapes, consumed by presentational UI (the
sibling `ReactionBar` component, not part of this component's given sources) that owns no
reaction state of its own.

