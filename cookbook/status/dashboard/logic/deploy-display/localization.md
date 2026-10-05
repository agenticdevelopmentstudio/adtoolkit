
The module returns hardcoded English strings and has no localization layer. These are facts of the source, not gaps.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `deployStatusLabel.success` | `ready` | Status label for a successful deploy |
| `deployStatusLabel.failed` | `FAILED` | Status label for a failed deploy (upper case for emphasis) |
| `deployStatusLabel.building` | `building` | Status label while building or deploying |
| `deployStatusLabel.queued` | `queued` | Status label for a queued build |
| `deployStatusLabel.canceled` | `canceled` | Status label for a canceled build |
| `deployStatusLabel.unknown` | `outcome unknown` | Status label for an in-flight phase the backend expired without confirmation |
| `platformLabel.*` | `VERCEL`, `CLOUDFLARE`, `RAILWAY`, `HTTP`, `DNS`, `CRUNCHY` | Brand and check names. These are proper nouns and are not translated. |
| `platformLabelShort.*` | `CF`, `CB` | Compact brand abbreviations for dense strips |

The upper-case fallback uses a locale-independent case conversion.

