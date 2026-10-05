
Subsystem: the app's own bundle identifier | Category: the bridge and each registration, separately scoped by type name.

| Event | Level | Message |
|-------|-------|---------|
| A provider for a view id has no `getChildren` function to call | error | `<extensionIdentifier>'s provider for view id <viewID> has no getChildren to call` |
| `getChildren`/`getTreeItem` threw, was unavailable, its result could not be settled, its rejection reason, or it answered something that is not an array/TreeItem | error | `<extensionIdentifier>'s tree data provider for view id <viewID> <what>: <detail>` |
| Two children in one `getChildren` answer minted the same handle | error | `getChildren listed two children under one id; the later one is dropped` (logged by the registration) |
| `activate(_:)`'s dispatched command threw | error | `<extensionIdentifier>'s tree row command <commandID> failed: <error.localizedDescription>` |
| A second `registerTreeDataProvider`/`createTreeView` call replaces an existing provider for the same view id | error | `<extensionIdentifier> registered a second tree data provider for view id <viewID>; the later one wins` |

