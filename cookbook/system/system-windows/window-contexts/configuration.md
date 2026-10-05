
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Context store: root directory | file-system location | none (required) | Root holding `state.json`, `contexts/`, `.lock`, and (by default) the custom rules file `heuristics.json`. |
| Window manager | window-control contract | none (required) | Lists windows and moves, resizes, focuses, and frames them; injected into both manager and model. |
| Window matcher | window matcher | a default window matcher | Fingerprinting, scoring, and batch matching; auto-assign threshold is `80`. |
| Custom heuristic store | optional custom-heuristic store | store at the state root | Persists user-defined heuristic rules. |
| Context manager: parking margin | number | `30000` | Distance left of the leftmost screen where inactive windows are parked. |
| Creating a context: `color` | string | `"#007AFF"` | Context color hex string. |
| Configuration: `selfAppName` | optional string | absent | Host app name exposed to views; own windows are excluded by process ID, not by this name. |
| Configuration: `settingsKey` | string | none (required) | Persisted-settings key for the contexts settings. |
| Configuration: `contextNoun` / `contextNounPlural` | string | `"context"` / noun + `"s"` | Nouns used in create-failure messages and exposed to views. |
| Configuration: `notificationTitle` / `notificationIdentifier` | string | none (required) | Reconcile notification title and request identifier. |
| Configuration: `defaultContexts` | list of default contexts | `[]` | Contexts seeded on first launch. |
| Configuration: `managesAppActivationPolicy` | boolean | `true` | Tells the settings UI whether to show the Dock toggle. |
| `isTestEnvironment` | boolean | detected by the presence of the platform's test-framework class | Disables notifications, observation, and seeding. |
| `notificationsEnabled` / `observationEnabled` | boolean | `true` (false in tests) | Runtime switches on the model. |
| Contexts settings fields | see settings-shape | see settings-shape | Launch at login, reconcile behavior, hidden apps, Dock visibility. |

