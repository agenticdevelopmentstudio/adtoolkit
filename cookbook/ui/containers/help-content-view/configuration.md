
Construction options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `content` | `HelpContent?` | — (required argument; `nil` is a valid, explicit value) | The topics to display, passed to the content-setting operation. `nil` or an empty topics array both show the fixed empty state. |

Beyond construction with no arguments, the component exposes one operation:
setting (or clearing) its help content.

The content type holds an ordered array of topics, each a `title`/`body`
string pair, and supports equality comparison.

