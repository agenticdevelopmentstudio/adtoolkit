
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| — (hardcoded literal, no key) | `Help` | Fixed heading label |
| — (hardcoded literal, no key) | `No Help Yet` | Empty-state group title, shown when the content-setting operation receives no content or no topics |
| — (hardcoded literal, no key) | `This panel doesn't have any help written for it. Its controls each carry their own explanation underneath.` | Empty-state explanation body |
| — (caller-supplied, no key in this file) | n/a | Each topic's `title`/`body` for a non-empty topic list — every heading and prose string is supplied by the caller, not a literal in this component's own source |

The heading label is set directly from a fixed string, not through any
localization lookup mechanism, and no localization-catalog reference
appears anywhere in source for the three literals above.

