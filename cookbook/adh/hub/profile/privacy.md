
- **Data collected**: address rows (`label`, `line1`, `line2`, `city`, `region`, `postalCode`,
  `country`), social link rows (`platform`, `url`, `handle`), the caller's own privacy audience
  setting per target row (`targetTable`/`targetId`/`audienceMask`), and metered usage/cost figures
  (`requests`/`bytes`/`tokens`/`costMicros`) for the caller's own principals or, with `?workspace=`,
  a workspace's. The privacy-grant record is itself the mechanism that decides who else may see
  the address and social-link rows above.
- **Storage**: none client-side — per `module-holds-no-mutable-state` and
  `no-client-side-storage-of-sensitive-fields`, nothing in this domain is retained beyond the
  lifetime of a single call. Server-side storage is outside the scope of this domain.
- **Transmission**: yes. Every call carries a bearer credential attached by the shared auth client
  (`auth-delegated-to-shared-client`), not by this module; whatever transport security the
  deployment provides is outside the scope of this domain.
- **Retention**: none within this module; nothing this module handles is retained after the
  response it produced is returned to the caller.

