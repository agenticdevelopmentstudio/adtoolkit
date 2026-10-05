
- Create vs edit is inferred purely from `initial` (absent = create). No
  separate mode parameter.
- Untouched create checkbox: stays unset and is omitted so a default-true DB
  column isn't silently forced to `false`; a required boolean instead sends `false`.
- Edit clearing an optional field: nullable columns send `null`, plain (non-enum)
  strings send `''`; other types can't represent "cleared", so the column is
  omitted (its old value survives — the honest option for a partial update).
- `createOnly` columns (client-supplied `rdid`s — a caller-chosen identifier,
  e.g. a slug, rather than a server-generated one): rendered disabled on edit
  and stripped from the update payload before any required-validation runs.
- `1e999` in a number field: rejected (not a finite number) rather than
  silently serialized to `null`.
- A validation throw (required/number/JSON) surfaces inline via the
  submission-state mechanism's error and leaves the draft intact so the user
  can fix and resubmit.
- Object/array/unknown columns round-trip as JSON text (pretty-printed when
  seeded); `unknown` is treated as JSON because the backend's OpenAPI schema
  types jsonb columns that way (see Platform Notes for how metadata is
  generated).

