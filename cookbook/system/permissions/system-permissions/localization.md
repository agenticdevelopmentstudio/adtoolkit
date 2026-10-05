
All user-facing strings are hardcoded English literals with no
localization lookup:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none) | `Accessibility`, `Notifications`, `Automation`, `Location`, `Microphone`, `Screen Capture`, `Keychain` | display name |
| (none) | `Required to discover and activate terminal windows for your sessions.` | explanation, accessibility |
| (none) | `Allows notifications when sessions start, end, or become stale.` | explanation, notifications |
| (none) | `Needed to find, raise and open windows in <name>.` | explanation, automation |
| (none) | `Records where you are and which Wi-Fi network you're on, so activity can be grouped by place.` | explanation, location |
| (none) | `Lets this app record audio from your microphone.` | explanation, microphone |
| (none) | `Lets this app read what is on your screen, to capture a still of it or record it.` | explanation, screen capture |
| (none) | `Lets this app read the "<service>" item in your keychain directly, instead of asking another tool for it.` | explanation, keychain |
| (none) | `Open Settings` | action title, when a settings pane exists |
| (none) | `Allow…` | action title, when no settings pane exists |

The identifier-token property is deliberately kept separate from the
display-name property, so the displayed copy can be reworded or
localized without breaking identifiers.

