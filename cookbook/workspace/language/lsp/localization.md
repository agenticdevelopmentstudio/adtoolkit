
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `LanguageServerSessionError.serverExited` | The language server exited with status {status}. | Session failure description |
| `LanguageServerSessionError.sessionHasBeenStopped` | The language server session has been stopped. | Session failure description |
| `LanguageServerSessionError.notRunning` | The language server is not running. | Session failure description |

Every string above is hardcoded English with no lookup table, ICU message,
or locale parameter anywhere in this component — this is a plain fact about
the source, not a gap: these are structured, localizable failure
descriptions surfaced in developer-facing logs/failure states, and a port to
a platform with an i18n layer MUST decide, as a design choice outside this
contract, whether and how to route them through it.

