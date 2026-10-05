
- **Data collected**: `BucketsTopic` and `BucketsDataSource` handle
  whatever bucket `name`/`description` and table `name` the user types
  into the create/settings forms, plus the server-assigned `id`,
  `ecosystemId`, `kind`, `sqlTableName`, `createdAt`, and `updatedAt`
  values `Bucket`/`BucketTable` decode; none of it is inherently
  distinguished as sensitive by these sources.
- **Storage**: None of the three given sources persist anything to disk,
  a database, or `UserDefaults`; `Bucket`/`BucketTable` values and the
  `FormState` values built from them (documented in the related HTDV
  Engine recipe) exist only in memory for the lifetime of the loaded
  level/detail.
- **Transmission**: `BucketsDataSource`'s nine operations transmit
  whatever a concrete implementation does internally (not among the given
  sources); none of the three given sources performs a network call
  directly or applies any encryption, redaction, or transformation to the
  values before handing them to `dataSource`.
- **Retention**: Not applicable at this layer — how long a bucket, a
  table, or their `description`/`name` text is retained is a server-side
  policy outside these three sources; nothing here defines a
  client-side expiry or cache.

