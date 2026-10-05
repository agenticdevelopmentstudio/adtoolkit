
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `SnippetFileParseError.notAnObject.errorDescription` | "The file's root is not a JSON object. A snippets file is an object whose keys are snippet names." | Recorded verbatim as a `SnippetFileFailure.reason` and shown in the extensions settings panel when a snippets file's root is not a JSON object. |

This is the only user-facing string these three files define, and it is hardcoded English with no localization table entry or lookup key of its own — `SnippetFileFailure.reason` is a plain `String`, not a localization key, so this string ships in one language regardless of the app's locale.

