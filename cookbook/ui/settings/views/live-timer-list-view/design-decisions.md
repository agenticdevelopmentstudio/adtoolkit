
**Decision**: The occlusion observer is tested only through the injected visibility check, not through real window notifications.
**Rationale**: A real occlusion change needs an on-screen window, which the unit target does not have; the injected check covers the logic.
**Approved**: pending

**Decision**: The default automatic-origin tooltip is hardcoded English.
**Rationale**: It is settable by the caller; a localization pass would supply string keys.
**Approved**: pending

