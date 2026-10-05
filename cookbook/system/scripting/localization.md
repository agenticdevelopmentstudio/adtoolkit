
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `scripting.unknownError` | unknown error | The script-running operation's fallback substitution for the message when the error description carries no error-message entry (see runtime-failure-fallback-values) |

The key above is synthetic, for this table only: the string is a raw literal
returned directly to callers, not looked up from any string table, resource
bundle, or locale-aware API. This is the only hardcoded, user/caller-visible
string across the three given primitives, and it is a plain fact about the
current implementation, not a gap — there is no localization mechanism in
this component at all.

