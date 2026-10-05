
The source contains no localization mechanism (no string-catalog lookup, no resource-bundle strings
file, no localized-string macro) — every user-facing string below is a hardcoded English literal, per
Extra Rule 14 stated here as fact rather than as a gap:

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| — | `Choose at least one scope. An empty selection mints a broad legacy token, not the scoped one you intended.` | API tokens rail: no-scope-selected message |
| — | `Couldn't load the scope catalogue. Token creation is disabled until it loads — otherwise an empty selection would silently mint a broad legacy token instead of the scoped one you intended.` | API tokens rail: catalogue-unavailable message |
| — | `Revoke API token "{name}"? Anything using it will stop working.` | API tokens rail: revoke confirmation |
| — | `That name is already in use. Token names stay reserved even after revoke — pick a different one.` | Storage tokens rail: name-taken message |
| — | `Revoke storage token "{slug}"? Anything using it will lose access to its bucket.` | Storage tokens rail: revoke confirmation |
| — | `An access list named "{name}" already exists in that bucket.` | Access lists topic: create validation |
| — | `The built-in "everyone" list applies to every principal and can't be renamed.` | Access lists topic: everyone-group name help |
| — | `That member is already in this access list.` | Access lists topic: member-add conflict |
| — | `Row id must be 36 characters or fewer.` | Access lists topic: grant validation |
| — | `Choose at least one permission.` | Access lists topic: grant validation (create and save) |

(This is a representative sample of the roughly two dozen literals across the underlying source, not the
full set; every one of them follows the same pattern — a plain string with no key, no catalog entry, and
no pluralization/formatting rule beyond ad hoc string interpolation.)

