
The file system service is the one place in the toolkit that touches the
real file system on the caller's behalf. It wraps the platform's
file-system APIs behind seven asynchronous operations — read file, read
directory, stat, write file, create directory, delete, and rename — each
running its blocking file-system work on one private serial background
queue and bridging back to the caller's asynchronous call. It knows nothing
about URIs, workspaces, or extensions; a caller holding a URL converts to a
path string before calling in, and the workspace layer that implements VS
Code's `vscode.workspace.fs` surface is documented as the sole caller today.

Alongside it, the file signature is an unrelated but co-located value: a
cheap size-and-modification-date pair used to answer "has this file
changed?" without reading its bytes. A matching substitution interface
exists solely so a test double can stand in for the service.

Every operation classifies its own failures into one file-system error
outcome — trying a lower-level operating-system error code first, then a
higher-level framework error code — so a caller gets a not-found,
already-exists, is-a-directory, not-a-directory, directory-not-empty, or
no-permissions outcome where the source can tell, and an operation-shaped
fallback (read-failed, write-failed, stat-failed, read-directory-failed,
delete-failed, rename-failed, create-directory-failed) carrying the
original error otherwise.

