
This component contains hardcoded, unlocalized English string literals
presented to callers via its own error descriptions and the plugin's
error-description fallback paths. There is no string-catalog key for any of
them; the literal itself is both the value and its own identifier.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, no catalog key) | "The server returned an invalid response." | The invalid-response error's description |
| (none — literal, no catalog key) | "The request exceeded its %gs budget." | The timed-out error's description, interpolated with the elapsed seconds |
| (none — literal, no catalog key) | "HTTP %d" | Fallback message for the HTTP-failure error when the plugin's error-description operation returns nothing |
| (none — literal, no catalog key) | "Command exited with status %d" | Fallback message for the command-failure error when the plugin's error-description operation returns nothing |

