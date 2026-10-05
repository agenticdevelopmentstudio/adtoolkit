
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Harness targets | list of window-activation targets | required | Windows to activate, tested in order |
| Harness log | activation test log | required | Destination for all diagnostics; cleared at the start of each run |
| Harness strategies | list of strategies | the built-in cascade | Activation cascade, run in order |
| Harness running-apps source | running-applications provider | the real provider | Source of running and frontmost apps for inventory and verification |
| Accessibility title-match strategy, running-apps source | running-applications provider | the real provider | Source of apps to scan for matching windows |
| Bring-terminal-to-front strategy, catalog | list of terminal catalog entries | the full terminal catalog | Terminals matched by `termProgram` |
| Bring-terminal-to-front strategy, running-apps source | running-applications provider | the real provider | Source of running instances by bundle ID |
| Log's application-support subdirectory | string | — | Subdirectory of user Application Support holding `activation-test.log` |
| Log's file URL | URL or nil | — | Explicit mirror file, or `nil` for memory only |
| Accessibility trust | system privacy setting | — | Required; without it running the harness aborts |
| Automation permission for iTerm2 | system privacy setting | — | Required for the iTerm strategy and inventory to succeed |

Fixed timings in source: 0.15 s between app activation and window raise, 0.5 s before verification, 1.0 s between targets.

