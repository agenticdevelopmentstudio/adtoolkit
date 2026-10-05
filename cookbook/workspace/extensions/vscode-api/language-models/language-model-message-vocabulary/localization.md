
- **hardcoded-log-strings**: The two error log messages installation can produce (an evaluate failure, and a missing container member) are hardcoded English strings with no localization key. Unlike the diagnostic types installer's equivalent, this component's inner error handling never surfaces the underlying JavaScript error's own message, so there is no third, error-message-carrying log variant to localize.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `Could not install the 'vscode' language-model message vocabulary in context '<name>'; every member stays the shim's not-implemented stub` | Logged when evaluating the vocabulary's source returns nothing or a non-object. |
| (none — literal only) | `The 'vscode' language-model message vocabulary in context '<name>' is missing '<memberName>'; every member stays the shim's not-implemented stub` | Logged when the container is missing an expected member. |

