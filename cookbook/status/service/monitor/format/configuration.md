
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hash` | `string \| null \| undefined` | n/a (required positional argument) | `shortSha`'s input sha; truncated to 7 characters when truthy. |
| `message` | `string \| null \| undefined` | n/a (required positional argument) | `commitFirstLine`'s and `commitFullMessage`'s input commit message. |
| `max` (in `commitFirstLine`) | `number` | `200` | Maximum character length of the returned first line. |
| `max` (in `commitFullMessage`) | `number` | `4000` | Maximum character length of the returned full message. |

