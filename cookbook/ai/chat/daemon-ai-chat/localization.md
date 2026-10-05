
No message in this component is externalized through a localization key. Every user-facing string this component itself authors is a hardcoded English literal:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded) | `Claude CLI not found (install Claude Code or check PATH)` | the completion error type's CLI-not-found case description |
| (none — hardcoded) | `Empty reply from the model` | the completion error type's empty-reply case description |
| (none — hardcoded) | `Failed to launch claude: <message>` | the CLI path's launch-failure mapping |
| (none — hardcoded) | `claude -p failed: <stderr or "exit <code>", truncated to 200 chars>` | the CLI path's non-zero-exit mapping |
| (none — hardcoded) | `Failed to load AI plugin '<id>': <underlying message>` | the plugin path's plugin-load error wrap |
| (none — hardcoded) | `Plugin could not build the request: <underlying message>` | the plugin path's request-build error wrap |
| (none — hardcoded) | `AI plugin not installed: <identifier>` | the live plugin cache's unknown-identifier error |

The completion error type's provider-error case has one remaining call site (the stream-consumption wrap) that carries a plugin/transport-supplied error description through verbatim rather than authoring new text — that upstream string's own localization is out of this component's control.

