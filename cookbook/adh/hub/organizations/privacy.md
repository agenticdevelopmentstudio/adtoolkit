
- **Data collected**: organization administrative metadata (`id`, `slug`, `name`, `description`,
  `rdid`, and the provisioned `namespace`/`teamId`/`ecosystem` ids), plus, via the roster list
  operation, roster rows naming a member's `userId`, `email`, `displayName`, `isAdmin` status, and
  `addedAt` timestamp. Unlike the organization fields, the roster's `email` and `displayName` ARE
  personal data about a real person.
- **Storage**: this domain holds no cache of its own; every call is a live round-trip, per
  `no-client-side-cache`. Whatever a caller does with the resolved data (for example, a cache keyed
  via the organizations cache-key prefix) is outside this domain.
- **Transmission**: every call travels through the shared authenticated request client, per
  `auth-delegated-to-shared-client`; this domain attaches no credentials or cookies of its own.
- **Retention**: none within this domain. `email`/`displayName`'s exposure is already narrowed
  server-side to members within the caller's ecosystem, per `workspace-member-nullable-fields` —
  this client neither widens nor persists that exposure.

