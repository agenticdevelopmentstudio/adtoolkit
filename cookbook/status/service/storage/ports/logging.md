
`ports.ts` itself emits no logs. The libSQL adapter logs with `console.error` in two places: a failed `reconcileOrphanedEndpoints` delete, and a deploy dropped by `upsertDeployments` for an invalid `createdAt`.

