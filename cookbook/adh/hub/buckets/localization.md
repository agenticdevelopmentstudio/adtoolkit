
None of the three given sources reference a string-key or localization
table; every user-facing string `BucketsTopic` produces is a hardcoded
English literal composed inline:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, no key) | `Buckets` | `BucketsTopic.entry.label` and the buckets-list level's `title`. |
| (none — literal, no key) | `Storage buckets and the tables they contain.` | `BucketsTopic.entry.description`. |
| (none — literal, no key) | `No buckets yet.` | Buckets list level's `emptyMessage`. |
| (none — literal, no key) | `New bucket` / `New table` | The two levels' `createAction.title`. |
| (none — literal, no key) | `Name and description.` / `The tables this bucket contains.` | The bucket level's fixed item sublabels. |
| (none — literal, no key) | `Tables` / `No tables yet.` | The tables level's `title`/`emptyMessage`. |
| (none — literal, no key) | `A bucket named "<name>" already exists.` | Create/settings save-action duplicate message (client precheck or server conflict). |
| (none — literal, no key) | `Every table needs a name.` | Create-table/table-detail save-action empty-name message. |
| (none — literal, no key) | `That name has no letters or digits that can be used in a SQL table name. Use at least one a–z letter or 0–9 digit.` | `BucketsTopic.unusableTableNameMessage`. |
| (none — literal, no key) | `Two tables share the name "<name>". Names must be unique.` | Create-table save-action duplicate message (client precheck or server conflict). |
| (none — literal, no key) | `Delete bucket "<name>"? Applications that granted it will lose those tables.` | Settings form's delete confirmation text. |
| (none — literal, no key) | `Remove table "<name>"? Data in it is not deleted until the bucket is.` | Table-detail form's delete confirmation text. |
| (none — literal, no key) | `Bucket` | Settings detail's fixed `title`. |
| (none — literal, no key) | `Name`, `Description`, `SQL table name` | Field labels across the four form specs. |

