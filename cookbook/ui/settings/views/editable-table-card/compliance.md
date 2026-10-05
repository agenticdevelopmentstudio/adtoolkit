
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is partial: the card keeps storage, sorting and add/remove policy with the owner through callbacks, but it also parses typed day, time, duration and money text and manages edit deferral in one large view. Unit-test-coverage is partial: `EditableTableCardTests.swift`, `EditableTableCardTypedEditTests.swift`, `EditableTableCardUpdateTests.swift` and `EditableTableCardFooterTests.swift` cover columns, sorting, rows, toggles, edits, held reloads, binding to rows and columns, typed edits and rejections, row updates, selection, recycling and footer controls; indicator accessibility labels, the locale and time zone reload and the mismatched cell are not tested.

