
This component contains no localization mechanism — every user-facing string below
is a hardcoded English literal, stated here as fact rather than as a gap:

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| — | `No applications yet.` | Applications listing's empty-list message |
| — | `An application with identifier "{slug}" already exists.` | Create-form conflict message |
| — | `The identifier "{next}" is already in use.` | Settings-save rename-conflict message |
| — | `Delete application "{displayName}"? This cannot be undone.` | Settings delete confirmation |
| — | `No schemas defined yet. Create one in the Buckets section first.` | "Add schema" no-schemas message |
| — | `Remove the "{label}" grant? This application will lose access to its tables.` | Schema detail remove confirmation |
| — | `Per-row permissions are coming soon. Choose "Table".` | Table detail row-level-rejected message |
| — | `"{table.name}" can't exceed the schema's permissions.` | Table detail ceiling-violation message |
| — | `Copy this token now — you won't be able to see it again.` | Token reveal notice |
| — | `Revoke token "{name}"? Applications using it will lose access.` | Token revoke confirmation |

(This is a representative sample of the roughly two dozen literals across the
implementation, not the full set — every one follows the same pattern: a plain
string with no key, no catalog entry, and no pluralization rule beyond ad hoc string
interpolation.)

