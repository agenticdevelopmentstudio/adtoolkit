
Not applicable: none of the three types reads, stores, or transmits a token,
credential, or other secret. The only data they hold is local filesystem
paths (`FileBrowserDirectories`, `FileBrowserRestorationState`) and git/IDE
metadata about those same paths (`FileTreeManager`), all of it already
visible to the user in their own checkout, and none of the three types makes
a network call.

