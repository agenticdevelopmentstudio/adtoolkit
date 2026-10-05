
**Decision**: One shared core, two configs.
**Rationale**: The menu is already `SiteMenu` -> `NavigationPopover` driven by two `MenuGroup[]` arrays; "duplicate the layout" means extracting the shared Hub core so both configs reuse it and only the top section diverges, which avoids the copy-paste drift the two configs risk today.
**Approved**: pending

**Decision**: Icons live in one `menu-icons` map.
**Rationale**: A single co-located map (`header/menu-icons.ts`) keyed by SiteId / route path / chrome key is the one authoritative icon per entry, none inline in JSX. Chosen over hanging an `icon` field on `SiteDef`: the registry is consumed by roughly 40 sites, so an added field is a higher-blast public-shape change for no current non-menu consumer; the map can be promoted to `SiteDef` later if a card or launcher needs the same glyphs, and every row still resolves through `menuIcon(key)`.
**Approved**: pending

**Decision**: Inline sub-items are a new row kind, not the existing flyout.
**Rationale**: The existing `topic` group discloses a side flyout; inline sub-items are always-visible indented leaves. They are distinct kinds so Hub can nest visibly while Workspaces and Recents still use flyouts.
**Approved**: pending

**Decision**: Settle-based Recents, not per-view instrumentation.
**Rationale**: Recording after the selection stack settles (about 1.5s) coalesces drill-through into the final destination with one observer and no per-page hooks (see `adh/docs/ui/deep-linking-foundation.md`); it records the eventual destination, not each click.
**Approved**: pending

**Decision**: Recents persist in local storage, not a backend.
**Rationale**: Recents is inherently ephemeral and per-device and the `ftd-storage` pattern already exists for exactly this, so there is no table or migration; a cross-device sync can be added later behind the same store API.
**Approved**: pending

