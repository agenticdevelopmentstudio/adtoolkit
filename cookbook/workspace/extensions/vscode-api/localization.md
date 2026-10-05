
Every user-facing string this concept produces is a hardcoded English literal; there is no localization key or lookup anywhere in it.

| String | Context |
| --- | --- |
| dispatch-unavailable message | shown to an extension, via a raised exception or a rejected promise, when the command/promise dispatch trampoline cannot be installed in its context |
| not-implemented error message | thrown to an extension reading an unimplemented `vscode.*` member, naming the member's path |
| read-only assignment/deletion type-error messages | thrown to an extension attempting to assign to or delete a member of a sub-namespace stub |
| trampoline/factory install-failure log lines | host-only diagnostic text, never seen by the extension itself |
| malformed-record and oversized-array log lines | host-only diagnostic text, never seen by the extension itself |

