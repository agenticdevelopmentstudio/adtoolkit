
`timeAgo` returns hardcoded English text with no message catalog or `Intl` lookup:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | `just now` | Elapsed time under 60 seconds, or negative |
| none (hardcoded) | number followed by `m` | Elapsed minutes under 60 |
| none (hardcoded) | number followed by `h` | Elapsed hours under 24 |
| none (hardcoded) | number followed by `d` | 24 hours or more |

