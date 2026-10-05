
No logging. `CrudTable` is presentational; the caller's `onNew`/`onEdit`/`onDelete`
handlers (and `useCrudResource`) own any telemetry or error reporting.

