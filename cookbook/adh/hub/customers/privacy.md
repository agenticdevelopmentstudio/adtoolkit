
- **Data collected**: `CustomersTopic` and `CustomersDataSource` handle
  whatever `email`, `displayName`, `externalId`, `slug`, and `avatarUrl`
  the user types into the create/detail forms, plus the server-assigned
  `id`, `ecosystemId`, `createdAt`, and `updatedAt` values `Customer`
  decodes; `email` and `externalId` in particular are personally
  identifying, though none of it is inherently distinguished as sensitive
  by these sources.
- **Storage**: None of the three given sources persist anything to disk,
  a database, or `UserDefaults`; `Customer` values and the `FormState`
  values built from them (documented in the related HTDV Engine recipe)
  exist only in memory for the lifetime of the loaded level/detail.
- **Transmission**: `CustomersDataSource`'s five operations transmit
  whatever a concrete implementation does internally (not among the given
  sources); none of the three given sources performs a network call
  directly or applies any encryption, redaction, or transformation to the
  values before handing them to `dataSource`.
- **Retention**: Not applicable at this layer — how long a customer or
  their descriptive fields are retained is a server-side policy outside
  these three sources; nothing here defines a client-side expiry or
  cache.

