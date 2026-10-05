
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| path (read-file, read-directory, stat, create-directory) | string | none (required) | The file-system location the operation acts on; not a URL, so a caller converts before calling in. |
| source path, destination path (rename) | string | none (required) | The source and destination paths for the one move-backed rename. |
| path (delete) | string | none (required) | The file-system location to remove or move to the Trash. |
| contents (write-file) | bytes | none (required) | The exact bytes written to the path; never appended to or chunked. |
| create flag (write-file) | boolean | none (required) | When true, a missing path is created; when false, a missing path throws a not-found outcome. |
| overwrite flag (write-file) | boolean | none (required) | When true, an existing path is replaced; when false, an existing path throws an already-exists outcome. Independent of the create flag. |
| recursive flag (delete) | boolean | none (required) | When false, a non-empty directory throws a directory-not-empty outcome; the removal itself always recurses once it proceeds. |
| Trash option (delete) | boolean | none (required) | True routes through the user's Trash; false permanently removes the item. |
| overwrite flag (rename) | boolean | none (required) | Governs only what happens when the initial move fails because something distinct already occupies the destination path. |

The service's construction itself takes no parameters and exposes no
configurable state: each instance owns one private serial queue, fixed for
the instance's lifetime, and nothing about that queue's label, priority, or
behavior is caller-adjustable.

