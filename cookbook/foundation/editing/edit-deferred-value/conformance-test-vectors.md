
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| edit-deferred-value-001 | initial-state | Create a new holder. | Not editing; nothing pending. |
| edit-deferred-value-002 | offer-passes-through | Offer `rows-1` with no edit in flight. | Returns `rows-1`; pending stays empty. |
| edit-deferred-value-003 | offer-while-editing-parks | Begin editing, then offer `rows-1`. | Returns nothing; pending is `rows-1`. |
| edit-deferred-value-004 | newest-offer-wins | Begin editing, offer `rows-1`, then offer `rows-2`. | Pending is `rows-2`. |
| edit-deferred-value-005 | end-editing-releases | Begin editing, offer `rows-2`, end editing. | Returns `rows-2`; not editing; nothing pending. |
| edit-deferred-value-006 | end-editing-safe-twice | End editing twice in a row after a held offer. | First returns the held value, second returns nothing. |
| edit-deferred-value-007 | end-editing-safe-twice | End editing on a new holder that never began. | Returns nothing; not editing. |

