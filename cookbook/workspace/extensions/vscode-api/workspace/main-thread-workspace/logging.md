
Subsystem: the app's own bundle identifier, or a fixed fallback when unavailable | Category: derived from this component's own name

| Event | Level | Message |
|-------|-------|---------|

This component supports the shared logging contract (see **logging-conformance**), but no member ever calls it: no `readFile`/`writeFile`/`readDirectory`/`stat`/`delete`/`rename`/`createDirectory` failure, no teardown rejection, and no `name`/`workspaceFolders`/`getWorkspaceFolder` resolution writes a log line anywhere in this component (fact, contrasted with the sibling commands bridge, which logs caller-less callback failures at error level; this bridge has no equivalent caller-less-dispatch concept to log about). Every failure this component produces reaches the extension directly, as a rejected promise or a raised exception, with no separate host-side log entry.

