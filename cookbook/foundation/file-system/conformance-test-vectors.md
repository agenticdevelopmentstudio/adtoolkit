
| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| file-system-001 | file-signature-shape, file-signature-stat-source | Read the file signature twice in a row against an untouched 8-byte file. | Both signatures are equal; the first one's size is 8. |
| file-system-002 | file-signature-equality-limit | Read the file signature before and after a rewrite that changes both length and modification date. | The two signatures are unequal. |
| file-system-003 | file-signature-equality-limit | Read the file signature before and after a rewrite pinned to the same modification date as the original. | The two signatures are equal, by design. |
| file-system-004 | file-signature-absence-is-nil | Read the file signature for a location naming nothing on disk. | Returns nothing (no signature), without throwing. |
| file-system-005 | read-file-exact-bytes | Perform the read-file operation against a file whose bytes are known. | Returns exactly those bytes. |
| file-system-006 | read-file-not-found | Perform the read-file operation against a path with nothing there. | Throws a not-found outcome. |
| file-system-007 | read-file-is-a-directory | Perform the read-file operation against a directory path. | Throws an is-a-directory outcome. |
| file-system-008 | read-directory-entry-shape, read-directory-link-child-union-bits | Perform the read-directory operation against a directory holding a plain file, a subdirectory, and a symbolic link to the file. | Answers one entry per child; the link entry's type bitmask equals 65. |
| file-system-009 | read-directory-follows-link | Perform the read-directory operation against a path that is itself a symbolic link to a directory. | Lists the target directory's children. |
| file-system-010 | read-directory-not-a-directory | Perform the read-directory operation against a plain file's path. | Throws a not-a-directory outcome. |
| file-system-011 | stat-does-not-follow-terminal-link, stat-link-target-bit-union | Perform the stat operation against a symbolic link to a file, a symbolic link to a directory, and a dangling symbolic link. | Type bitmask values 65, 66, and 64 respectively. |
| file-system-012 | stat-does-not-follow-terminal-link | Perform the stat operation against a symbolic link whose own path string is shorter than its target's contents. | The reported size equals the link's own path-string byte length, not the target's size. |
| file-system-013 | stat-missing-path | Perform the stat operation against a path with nothing there. | Throws a not-found outcome. |
| file-system-014 | write-file-create-flag | Perform the write-file operation with the create flag false against a missing path. | Throws a not-found outcome, writes nothing. |
| file-system-015 | write-file-create-flag | Perform the write-file operation with the create flag true against a missing path. | Succeeds; the path now holds the given contents. |
| file-system-016 | write-file-overwrite-flag | Perform the write-file operation with the overwrite flag false against an existing file. | Throws an already-exists outcome, leaves the original bytes. |
| file-system-017 | write-file-overwrite-flag | Perform the write-file operation with the overwrite flag true against an existing file. | Succeeds; the path now holds the new contents. |
| file-system-018 | write-file-onto-directory | Perform the write-file operation against a directory path. | Throws an is-a-directory outcome. |
| file-system-019 | create-directory-with-parents | Perform the create-directory operation against a path several missing intermediate levels deep. | Succeeds; the path and every missing parent now exist. |
| file-system-020 | create-directory-exists-error | Perform the create-directory operation against a path already occupied by a plain file. | Throws an already-exists outcome. |
| file-system-021 | delete-nonrecursive-emptiness-check | Perform the delete operation with the recursive flag false against a directory holding one entry, then against an emptied copy of the same directory. | The populated case throws a directory-not-empty outcome; the empty case succeeds. |
| file-system-022 | delete-recursive-flag-scope | Perform the delete operation with the recursive flag true against a directory holding several entries. | Succeeds; the directory and every entry in it are gone. |
| file-system-023 | delete-trash-flag | Perform the delete operation with the Trash option set against an ordinary file. | The file is no longer at the path; it is reachable through the user's Trash rather than permanently removed. |
| file-system-024 | delete-link-not-target | Perform the delete operation against a symbolic link to a file that still needs to exist afterward. | The link is gone; the file it pointed to still exists with its original contents. |
| file-system-025 | rename-case-only-and-self-renames-succeed | Perform the rename operation, changing only the case of a name on a case-insensitive volume, with the overwrite flag false. | Succeeds; the file still exists under the new casing. |
| file-system-026 | rename-case-only-and-self-renames-succeed | Perform the rename operation from a path onto itself, with the overwrite flag false. | Succeeds; the file is unchanged. |
| file-system-027 | rename-overwrite-refusal | Perform the rename operation with the overwrite flag false, where the destination already names a distinct file. | Throws an already-exists outcome, moves nothing. |
| file-system-028 | rename-overwrite-sequence | Perform the rename operation with the overwrite flag true, where the destination already names a distinct file. | Succeeds; the destination now holds the source's former contents, and the source no longer exists. |
| file-system-029 | rename-hard-link-and-inode-identity | Perform the rename operation with the overwrite flag true, where the destination is a hard link to a different name for the very inode already at the source's eventual destination shape. | The other name is replaced correctly rather than treated as identical to the source. |
| file-system-030 | calls-serialize-on-the-queue | Perform eight concurrent read-file operations into one service instance, each against a different file with distinct contents. | Each caller's call returns exactly its own file's bytes, with none mixed up. |

