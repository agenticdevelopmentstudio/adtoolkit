
This ingredient models a reopen-on-launch policy with three states — follow the platform default, always, never — that decides whether previously open windows reopen when the app launches, plus two persisted preferences: a maximum count of recent documents shown in an Open Recent list, and the reopen-on-launch policy itself.

The policy resolves to a boolean through a decision function that takes the platform-wide default as an argument rather than reading it directly, exposes a human-readable display name per state, and reads the platform-wide "keep windows on quit" preference through a system-default accessor.

This concept holds the policy model and the stored preferences only. Behavior that acts on them — mirroring the recent-document count into the platform's own limit, evaluating the policy at launch, and presenting both preferences to the user — lives in consumers described in Platform Notes. Use this ingredient when an app needs a user-selectable "restore windows on launch" policy that can defer to the platform-wide setting, plus a user-adjustable cap on the recent-documents list.

