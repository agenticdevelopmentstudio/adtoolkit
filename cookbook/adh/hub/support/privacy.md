
- **Data collected**: These pieces handle whatever the caller passes
  through the form-builder's values/specification (arbitrary form field
  values), the date helper's date strings, and the JSON value type's
  arbitrary JSON payloads; none of the seven given pieces itself classifies
  any of this content as sensitive — sensitivity depends entirely on what a
  specific feature stores in it.
- **Storage**: None of the seven given pieces persist anything to disk, a
  database, or a settings store; every value exists only in memory for the
  duration of the call that produced it.
- **Transmission**: None of the seven given pieces performs a network
  call. The closure-taking error normalizer wraps whatever error a
  caller's own network call produces, but that network call and any data
  it transmits are outside these seven pieces.
- **Retention**: Not applicable at this layer — nothing here defines a
  client-side expiry or cache; retention is a caller/server concern outside
  these seven pieces.

