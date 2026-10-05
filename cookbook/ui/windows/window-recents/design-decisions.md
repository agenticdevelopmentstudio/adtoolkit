
**Decision**: `useSystem` is the default policy, and `shouldReopen(systemDefault:)` takes the system value as a parameter instead of reading it.
**Rationale**: Deferring to the OS matches the platform convention (the doc comment models the enum on Xcode's restore preference), and injecting the Boolean keeps the decision pure and testable without touching global defaults, which is how `ReopenOnLaunchPolicyTests` exercises it; `systemDefault` is the one impure accessor.
**Approved**: pending

**Decision**: `systemDefault` reports the raw `NSQuitAlwaysKeepsWindows` value, whose sense is the inverse of the System Settings checkbox label.
**Rationale**: The doc comment records that checking "Close windows when quitting an application" sets the key to `false`; reading the key directly avoids a second inversion, and a missing key reads `false` (do not keep windows).
**Approved**: pending

**Decision**: The recent-documents cap is a toolkit setting mirrored into AppKit's `NSRecentDocumentsLimit` user default by `WindowManager`, rather than set on `NSDocumentController`.
**Rationale**: Per the `WindowManager` comments, `maximumRecentDocumentCount` is read-only and writing the user default is "the public knob" that avoids subclassing `NSDocumentController`; the cost is that a lower cap applies only on the next `noteNewRecentDocumentURL` call.
**Approved**: pending

**Decision**: `reopenOnLaunchPolicy` covers document windows only; project windows restore regardless of it.
**Rationale**: Per `ProjectWindowManager.restoreOpenProjects()`, "A project window is the app's workspace, not a document", and closing the window is how the user stops it reopening.
**Approved**: pending

**Decision**: `displayName` returns English literals.
**Rationale**: The strings serve only as settings-panel choice labels; externalizing them is not done in the source and is recorded as a failed check under Compliance.
**Approved**: pending

