
- **Decision**: Remove the full-width action bar (New | divider | red Delete) from the FTD composition; New lives in the selector popup and Delete lives in the entity pane's Danger section behind a two-step confirm.
  **Rationale**: A redundant, always-present destructive affordance violates least-astonishment; contextual placement plus a deliberate two-step confirm removes it without losing the action.
  **Approved**: pending

- **Decision**: The rdid is mutable via the `registry.identifiers` table, which maps the mutable rdid to an immutable UUID primary key; renaming updates the mapping only, never the UUID or its foreign-key references. The mapping table and its `PATCH /registry/identifiers/{rdid}` endpoint already exist and are in the OpenAPI spec and generated clients, so no backend route or codegen is added by this recipe.
  **Rationale**: Matches the platform-wide pattern of renaming organizations/namespaces via the identifiers route rather than an entity's own update endpoint, so FK relationships never need to be rewritten on rename; because the endpoint already exists, this recipe's remaining work is frontend wiring.
  **Approved**: pending

- **Decision**: Replace `window.confirm()` with a two-step delete built as one shared block, `DeleteEntitySection` (`@agentic-toolkit/adh-ui/blocks`), parameterized by `Entity`, `rdid`, and `childEntities`; the step-1 warning copy is templated ("{gerund} {a/an} {entity} deletes all the data associated with the {entity}, including {childEntities}. Do you wish to proceed?") with the article chosen by the entity noun's leading sound (**warning-copy-article-agreement**).
  **Rationale**: One authoritative implementation is shared by every FTD route (DRY) instead of each route re-deriving its own confirm copy and article agreement.
  **Approved**: pending

- **Decision**: Step-1 warning dialog buttons are labelled `Cancel` / `Yes`.
  **Rationale**: Cancel/Yes reads as a plain acknowledgement; the destructive verb is reserved for the type-to-confirm step's button, not repeated at step one.
  **Approved**: pending

- **Decision**: The All view's `cards`/`list` toggle persists its chosen mode.
  **Rationale**: A layout preference set once should survive navigation and reload rather than reset to the default on every visit.
  **Approved**: pending

### Instantiations

Concrete bindings for each route that composes this contract. The general
contract above always wins on conflict.

#### Ecosystems

The first concrete FTD instantiation. Parameter bindings are given inline in
the Overview's Terminology table.

**Topic order** (top → bottom, no dividers): `Ecosystem` (the entity's own
pane), `Applications`, `Buckets`, `Users`. Route ids stay stable where only the
label changes, to avoid breaking deep links; renaming the `schemas` route
segment itself to `buckets` is a separate, reversible decision that would need
its own redirect.

**Layout, concretely:**
- Topic list: `Ecosystem, Applications, Buckets, Users`.
- All-view toolbar title: `All Ecosystems`.
- Delete dialog: "You are about to permanently delete this Ecosystem. Enter
  \"{{org_package}}.myecosystem\" below."
- `rdid` example: `{{org_package}}.myecosystem`.
- `childEntities` copy: "applications, buckets, and users".
- Persistence keys: `{{app_prefix}}:ftd:/ecosystems:lastId`,
  `{{app_prefix}}:ftd:/ecosystems:viewMode`.

**Frontend wiring** (identifier rename — the backend already supports it):
reuse `PATCH /registry/identifiers/{rdid}` and `GET …/{rdid}/exists`; no new
backend route, no codegen. An API client wraps the identifiers endpoints, and
the Identifier field's save renames via the *old* rdid, refreshing the
route/`lastId` to the new rdid on success. The ecosystem's own update endpoint
keeps ignoring `identifier` (it is server-managed).

**Hub file map:**
- `src/components/settings/topics.ts` — the ecosystem topic list: `Ecosystem` first (no divider above it), `Buckets` in place of `Schemas`.
- `src/components/settings/ecosystems/EcosystemDetail.tsx` — editable Identifier; Danger Zone.
- `@agentic-toolkit/adh-ui/blocks` — the shared `DeleteEntitySection` block, parameterized by `Entity`, `rdid`, `childEntities`.
- `src/components/home/resource/ResourcePopup.tsx` — the New action (trailing divider + non-radio `New {Entity}…`).
- `src/components/home/resource/ResourceLanding.tsx` — the All toolbar: filter, card/list toggle, list renderer.
- `src/components/home/resource/ResourceTab.tsx` — last-selected + view-mode persistence and bare-path resolution.

- **Decision**: Rename the Ecosystems "Schemas" topic to "Buckets".
  **Rationale**: Buckets are real ecosystem child data; "Schemas" no longer matches what the topic manages, and the delete-warning child-entities copy ("…applications, buckets, and users") already reflects this name.
  **Approved**: pending

#### Teams / Persona APIs

Both compose the shared `ResourceTab` orchestrator. The entity's own pane
(`Team` / `Service`) is the first topic; `paneOwnedActions` keeps the action
bar out of the composition; New is the selector popup's trailing action;
Delete is the entity pane's `DeleteEntitySection` Danger Zone, with the
type-to-confirm value bound to the team's `identifier` or the service's
`name`. `Members/Permissions` and `Models` keep their existing route ids.
Each tab seeds its list from the same module-level (stale-while-revalidate)
cache as Ecosystems.

