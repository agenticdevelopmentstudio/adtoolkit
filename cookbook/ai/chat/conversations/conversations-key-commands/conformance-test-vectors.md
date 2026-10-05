
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| conversations-key-commands-001 | section-identity | Build the section | One section titled "Conversations Window" with application-wide scope |
| conversations-key-commands-002 | command-identifiers | Read the identifiers of the three commands | `conversations.toggleShelf`, `conversations.moveSelectionUp`, `conversations.moveSelectionDown` |
| conversations-key-commands-003 | toggle-shelf-command | Read the section's direct commands | Exactly one, titled "Show Conversation List", default Command-0 |
| conversations-key-commands-004 | single-mode-feature | Install the section in a registry and read the settings panel outline | The two selection commands appear under a "Single Conversation Mode" heading, after the toggle command |
| conversations-key-commands-005 | move-selection-commands | Read the feature's commands and run each against a stub controller | "Previous Conversation" is Command-Up and moves by -1; "Next Conversation" is Command-Down and moves by +1 |
| conversations-key-commands-006 | resolve-at-run-time | Build the section with a resolver that counts calls, install it, then run a command | The resolver is not called before the command runs, and is called each time one runs |
| conversations-key-commands-007 | absent-window-passes-key-on | Run each command with a resolver that returns no controller | Each reports that it did not take the key; nothing else happens |
| conversations-key-commands-008 | window-decides-ownership | Run a command against a controller that declines, then one that accepts | The command reports declined, then taken |
| conversations-key-commands-009 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

