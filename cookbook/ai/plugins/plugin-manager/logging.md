
Subsystem: the app's bundle identifier (falls back to a fixed placeholder if unset) | Category: the plugin manager's logging category

| Event | Level | Message |
|-------|-------|---------|
| A candidate bundle has no readable descriptor file (cannot be opened, or decode failure) | warning | `Skipping plugin without a readable descriptor: <bundle filename>` |
| A descriptor's schema version is outside the supported range | warning | `Skipping incompatible plugin '<displayName>': schema <n> not in 2...<currentSchemaVersion>` |
| A new, non-duplicate identifier is recorded | info | `Discovered plugin: <displayName> (<identifier>)` |
| Loading a plugin fails inside "load all plugins" | error | `Failed to load plugin '<displayName>' (<identifier>): <message>` |
| Loading a plugin succeeds | info | `Loaded plugin: <displayName>` |
| Unloading a plugin is called, loaded or not | info | `Unloaded plugin: <identifier>` |

