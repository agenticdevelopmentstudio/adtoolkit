
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `json` | manifest bytes | none — required | The bytes of a `package.json`, strict or JSONC, to localize. |
| `directory` | a file-system location | none — required | The directory `json` was read from; also where `package.nls*.json` tables are looked for. |
| `locale` | a locale | the reader's current locale | Whose language, and region, to prefer when merging tables. |

No environment variable, settings key, or injected dependency exists
anywhere in this component. Both of the manifest's readers call the
localization function with only the manifest bytes and directory supplied,
relying on the locale default rather than passing one explicitly.

