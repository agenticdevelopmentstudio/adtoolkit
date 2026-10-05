
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env` (argument to `envColor`) | `string \| null \| undefined` | — | Environment name to color; nullish or unknown yields `ENV_FALLBACK_COLOR`. |
| `env` (argument to `envBadgeLabel`) | `string` | — | Environment name to label; unknown names are upper-cased. |
| `--color-apt-*` CSS custom properties | CSS color | Supplied by `@agenticdevelopertoolkit/themes` | Theme tokens every `var()` reference resolves against: `green`, `gold`, `gold-bright`, `red`, `blue`, `bg`, `surface`, `surface-2`, `border`, `text`, `text-muted`, `text-dim`, `cat-blue`, `cat-violet`, `cat-pink`. |

The module reads no environment variables, settings keys or injected dependencies.

