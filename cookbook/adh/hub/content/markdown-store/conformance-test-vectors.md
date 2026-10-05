
| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| markdown-core-001 | delete-tombstones-both-flags | The delete operation invoked on a live document | Both delete columns set on the document row and every marker row |
| markdown-core-002 | update-refuses-authored-drift | The update operation called with visibility changed from the stored row | Throws the dedicated-intent error naming the visibility field |
| markdown-core-003 | publish-invariant | The publish operation called with an empty route | Throws the inconsistent-publication error |
| markdown-core-004 | outbox-order-is-sequence | Operations enqueued out of creation order but in sequence order | The pending-operations read returns them in sequence order |
| markdown-core-005 | opposing-intents-cancel | The publish operation followed by the unpublish operation before the queue drains | Exactly one operation remains queued |
| markdown-core-006 | cycle-refusal | Adding a category edge where the proposed parent is already a descendant of the proposed child | Throws the category-cycle error; a diamond shape is still allowed |
| markdown-core-007 | revive-on-conflict | Creating a keyword for a label whose only holder is tombstoned | The tombstoned row is revived, not duplicated |
| markdown-core-008 | number-range-clamping | A pulled JSON number outside the 64-bit signed integer range | The value is stored as a lossy floating-point value rather than trapping |
| markdown-core-009 | unencodable-value-throws | A pulled array or object value bound for a scalar column | Throws rather than binding a null value |
| markdown-core-010 | postgres-form-repair | The timestamp reader given a database wire-form timestamp with a space separator and a two-digit offset | Parses to the same instant the writer would produce for the ISO-8601 spelling |

