
- **Missing key**: The read returns nothing; Environment Filter MUST keep the default (all selected).
- **Empty string stored**: An empty string is treated as absent; Environment Filter MUST keep the default without parsing.
- **Empty array stored**: `[]` is a valid array; Environment Filter MUST hydrate to an empty selection. A consumer that treats "none selected" as "show nothing" shows nothing after reload.
- **Only unknown names stored** (for example after an environment is removed from `ENVIRONMENTS`): Environment Filter MUST hydrate to an empty selection, not the default.
- **Non-array JSON** (`null`, a number, an object, a quoted string): Environment Filter MUST keep the default.
- **Malformed JSON**: the parse exception MUST be caught and the default kept.
- **Storage unavailable** (disabled cookies/site data, sandboxed frame, private mode that throws): both the read and every write MUST be caught; Environment Filter MUST keep working in memory only, and the choice is lost on reload.
- **Quota exceeded on write**: the in-memory toggle MUST still apply; the stored value stays at its previous content.
- **Unknown environment passed to `toggle`**: the name MUST be accepted in memory and persisted, then dropped by the next hydration. While it is present, `envs.size` can equal `all.length` without every environment being selected, which misleads a consumer's "unfiltered" check such as the Overview's.
- **Toggle before hydration**: cannot occur in practice; hydration completes before a later user event is handled, and all code is single-threaded.
- **Several instances active**: each MUST keep its own selection; the last writer's value is what the next instance hydrates from.
- **Another tab changes the value**: Environment Filter SHOULD NOT reflect it until recreated, because it registers no cross-tab change listener (rationale in Design Decisions).
- **Pre-hydration render**: storage is never touched before hydration, so Environment Filter MUST report the default without referencing storage.
- **Timeouts, cancellation, network loss**: not applicable; Environment Filter performs only synchronous storage calls and no network I/O.

