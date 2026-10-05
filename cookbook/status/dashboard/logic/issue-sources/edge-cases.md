
- **Empty string**: The issue-source guard operation on `""` MUST return `false`. No member is empty.
- **Case and whitespace variants**: `"DNS"`, `"Http"` and `" http"` MUST return `false`. The guard does no normalization, so a caller with untrimmed input has to normalize first.
- **Integration spelling of Cloudflare**: The issue-source guard operation on `"cloudflare"` MUST return `false`. The deploy-integration vocabulary spells the platform `"cloudflare"`, and the board's target keys canonicalise `"cloudflare-pages"` down to `"cloudflare"`. Only the un-canonicalised `"cloudflare-pages"` passes the guard. A companion test elsewhere in the client asserts that an activity row's source arrives as `"cloudflare-pages"` so it survives the source filter's default seed.
- **A source the server emits that the client lacks**: If the server adds a member to its union and the client is not updated, looking up that source in the label map MUST yield no result and the guard operation on it MUST return `false`. Callers that index the label map directly with a value already typed as a vocabulary member (for example the global panel and the activity panel's checkbox label) then render nothing; the row-building logic narrows first and shows the raw string instead. The module's own doc comment states this failure, and the owner of the fix is whoever edits the server union.
- **Unattributed rows**: An activity row with no attributed source falls back to its kind (for example `"deploy"`). The issue-source guard operation MUST return `false` for such a string, and the caller shows it unlabeled.
- **Non-text input at runtime**: A caller that passes an absent value or a non-text value MUST get `false`, because an exact-match comparison does not throw and no member equals a non-text value.
- **Mutation of the source order list**: The list is not protected against in-place modification. A consumer that pushed to or sorted it in place would change the filter order and the guard's answers for every other consumer. No consumer does so; they only derive new lists from it.
- **Long-running builds**: A deploy BUILDING for more than 30 minutes MUST NOT become a client-side Problem. Any stuck verdict arrives from the backend on the board.
- **Null, boundary and error states**: There are no numeric inputs and no I/O. The only numeric export is the fixed stuck-deploy threshold. The module cannot fail at runtime.
- **Concurrent access**: Not applicable. The exports are never mutated.
- **Offline or disconnected**: Not applicable. The module performs no network access.

