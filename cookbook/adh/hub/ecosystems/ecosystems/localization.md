
- **Hardcoded strings (rail-based implementation)**: `"Products"`, `"No
  products yet."`, `"New Product"`, `"Child Ecosystems"`, `"No child
  ecosystems yet."`, `"New Ecosystem"`, `"Settings"`, `"Delete Product"`,
  the delete-confirmation warning ("Deleting a product deletes all the data
  associated with the product, including applications, buckets, and
  users. Do you wish to proceed?"), the not-manageable title/message, the
  slug-too-long message ("Slug must be 64 characters or fewer."), every
  field label (`"Display Name"`, `"Slug"`, `"Identifier"`, `"Description"`,
  `"Geographic Region"`), and every "already in use"/"already exists"
  validation message this recipe's requirements quote.
- **Hardcoded strings (API-client implementation)**: every thrown-error
  friendly message (the "already exists"/"already in use" conflict
  messages), and the batch-apply's `Couldn't remove: <keys>` error. Catalog
  `label`/`description`/subscription-tier text is served by the backend and
  passed through untranslated.

Neither reference implementation has a lookup table, i18n key, or locale
parameter anywhere in these files — every user-facing string above is fixed
English. This is a plain, honestly-reported fact about the current source,
not a hidden gap (see Compliance).

