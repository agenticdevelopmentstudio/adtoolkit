
The Buckets domain is the Hub's storage-bucket management: buckets (rows of
`/bucket/buckets`) and the tables each one contains (rows of
`/bucket/bucket-types`). It is three cooperating pieces:

- **`BucketsDataSource`** (`BucketsDataSource.swift`) — the protocol
  through which the Buckets topic reaches the server: list/get/create/
  update/delete for buckets, and the parallel five for tables.
- **The data shapes** (`BucketsModels.swift`) — `Bucket`, `BucketMetadata`,
  `BucketCreate`, `BucketUpdate`, `BucketTable`, `BucketTableCreate`, and
  `BucketTableUpdate`, the serializable payloads the data source sends and
  receives.
- **`BucketsTopic`** (`BucketsTopic.swift`) — the `EcosystemTopicProvider`
  that renders this domain into the Hub's rail/detail (HTDV) navigation:
  a bucket list, each bucket's Settings and Tables panes, and the create/
  edit/delete forms for both buckets and tables. `BucketsTopic` builds on
  the HTDV navigation and Forms types (`HTDVLevel`, `HTDVChild`, `FormSpec`,
  `FormState`, and the rest) documented in the related HTDV Engine recipe;
  those types are not redescribed here.

`FormSheet`, `FormDetails`, `RailPath`, `HubError`, `EcosystemTopicProvider`,
`EcosystemRail`, and `Ecosystem` are Hub-wide helpers `BucketsTopic` is built
on but that are not among this recipe's three given sources; they are
described here only to the extent needed to state what `BucketsTopic` itself
does with them.

