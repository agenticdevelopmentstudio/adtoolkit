
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| registry client | the registry client used for lookups | a default client pointed at the public Open VSX registry (`https://open-vsx.org/api`) | The client the check issues lookups through; injectable so tests can point it at a stub registry. |
| host version | a semantic version | the host's declared VS Code version (`1.138.0`) | The host version passed to the installability gate for every candidate; a caller who wants to check against a different declared version supplies it here. |
| installed extensions | a list of installed-extension records | — (required parameter of the batch check) | The extensions to check, one lookup per element; supplying an empty list is valid and yields an empty report. |

