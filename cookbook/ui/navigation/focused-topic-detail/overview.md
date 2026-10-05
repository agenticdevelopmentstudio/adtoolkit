
This recipe defines the **general FTD contract** that governs *every* route built
on the Focused Topic Detail view. Concrete instantiations (Ecosystems, Teams,
Persona APIs) live in **## Instantiations**, below; when a general statement here
and an instantiation's own value seem to disagree, the general contract wins and
the instantiation is the one that's wrong.

A **Focused Topic Detail (FTD)** view manages a *collection of entities of one
kind* (ecosystems, teams, persona-services, …). At any moment the user is either:

- **Focused on one entity** — a left-hand **topic list** of that entity's sections, and a right-hand **detail panel** for the selected topic; or
- **Surveying all entities** — the **"All" view**, a browsable index of every entity in the collection.

The user moves between entities (and into "All") through a single **selector
popup** at the top-left of the view. The canonical implementation is the shared
`FocusedTopicDetail` block in `@agenticdevelopertoolkit/ui/blocks` (master/detail
layout) — all FTD routes compose it; none hand-roll the layout.

**Terminology / parameters.** Every FTD route binds these parameters (Ecosystems
values shown for reference — see **Instantiations**):

| Parameter | Meaning | Ecosystems value |
|---|---|---|
| `Entity` | Singular display name of the managed thing | **Ecosystem** |
| `Entities` | Plural | **Ecosystems** |
| `basePath` | Route root | `/ecosystems` |
| `rdid` | The **mutable** reverse-domain **identifier** that uniquely names an entity; shown as the **Identifier** field; maps to an immutable internal UUID via `registry.identifiers` | `identifier` (e.g. `{{org_package}}.myecosystem`) |
| `topics` | Ordered sections shown in the topic list | Ecosystem, Applications, Buckets, Users |
| `childEntities` | Dependent data a delete cascades through (used in delete copy) | applications, buckets, and users |

The identifier is the entity's **public, mutable** name; internally the row is
keyed by an immutable UUID, and `registry.identifiers` maps rdid → UUID so the
identifier can change without breaking UUID foreign keys.

Every `{id}` route segment — and the persisted `lastId` — is the **rdid**, never
the immutable UUID; the two exchange only through `registry.identifiers`.
Because the rdid is mutable, a deep link built from a pre-rename rdid no longer
matches any entity once the rename lands: the resolver treats an unrecognized
id exactly like a stale `lastId` (see **Edge Cases**) and falls back to the All
view rather than a 404.

