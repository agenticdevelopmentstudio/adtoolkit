
Subsystem: the host application's bundle identifier | Category: the save scheduler

| Event | Level | Message |
|-------|-------|---------|
| An autosave write fails | error | `Auto-save failed for <uri>: <reason> — still pending, will retry` |

The text document, the document store, and the URL-to-document-URI conversion make no logging call of their own; only the save scheduler logs, and only on a failed write.

