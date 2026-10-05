
The disabled-extensions setting is the extension host's sole persisted setting. It is keyed `"extensions.disabledIdentifiers"` and holds a set of strings, defaulting to an empty set: every identifier the set holds names an extension a person has switched off; an identifier the set has never held is enabled, so a freshly installed extension runs with no migration needed.

This concept declares no logic of its own beyond that one key and default. A general-purpose settings mechanism supplies the read, write, remove, existence-check, and change-notification behavior this setting inherits, and a persistence layer supplies the storage mechanics; both are collaborators covered by their own recipes, out of scope here. The enablement logic that reads and writes this set — deciding whether a given extension is enabled, disabling it, or removing it entirely — is likewise a collaborator's contract, out of scope in this recipe.

