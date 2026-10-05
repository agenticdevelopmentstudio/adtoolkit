
The detail blocks contain hardcoded English, with no localization lookup:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none) | `Left alone:` | skip-detail block header |
| (none) | `Also:` | note-detail block header |
| (none) | `…and <N> more` | Remainder line in both blocks |
| (none) | `runMatch: opts.client is required when opts.api is not supplied` | the client-required check's error message, meant for developers |

The per-project reasons and notes are English text produced by the engine, and this module forwards them unchanged.

