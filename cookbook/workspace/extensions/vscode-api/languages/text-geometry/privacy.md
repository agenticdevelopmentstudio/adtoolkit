
- **Data collected**: this ingredient collects no data of its own; it constructs `Position`/`Range`/`Location` value objects and the host-side mirror values out of whatever `line`, `character`, `uri`, and range/position values an extension or host caller already supplies, without retaining a copy beyond the returned instance and the per-context class cache.
- **Storage**: this ingredient performs no persistent storage of its own.
- **Transmission**: this ingredient makes no network call. `Location.uri` may itself reference a remote or local resource, but this ingredient never dereferences, resolves, or transmits it — that is the URI ingredient's and its callers' concern, outside this ingredient's scope.
- **Retention**: nothing in this ingredient is retained beyond the lifetime of one call's local variables, except the per-context installed-class cache (`__vscodeTextGeometryClasses`), which holds only the three constructor objects, never a position, range, or location value's own data.

