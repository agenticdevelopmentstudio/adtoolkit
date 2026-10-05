
The source has no unit tests for these six files; the context manager's tests exercise only a mock of the window-control contract. Every vector below is derived from the named behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| system-windows-001 | parse-required-fields | Record with number 7, PID 100, bounds, but no layer key | Parsing returns nil |
| system-windows-002 | parse-optional-defaults, parse-bounds-defaults | Record with number 7, PID 100, layer 0, bounds `{X: 10, Width: 300}`, no owner name, no window name, no on-screen flag | `app == ""`, `title == ""`, `isOnScreen == false`, frame (10, 0, 300, 0) |
| system-windows-003 | policy-layer | Records: layer 0 frame 100×100 app "Notes"; layer 25 same frame | List contains only the layer-0 window |
| system-windows-004 | policy-excluded-apps | Layer-0 100×100 windows owned by "Dock" and "Notes" | List contains only the "Notes" window |
| system-windows-005 | policy-zero-size | Layer-0 windows of "Notes" sized 0×50, 50×0, 50×50 | List contains only the 50×50 window |
| system-windows-006 | backfill-skip | Every listed window has a non-empty title | List returned unchanged; no accessibility window enumeration performed |
| system-windows-007 | backfill-single-window-app | Window titled "" at (0,0,500,400); app has one accessibility window titled "Doc" at (900,900) | Title becomes "Doc" |
| system-windows-008 | backfill-unique-frame | Window "" at (100,100,500,400); accessibility windows "A" at (101,100) 500×401 and "B" at (300,300) 200×200 | Title becomes "A" |
| system-windows-009 | backfill-ambiguous | Window "" at (100,100,500,400); two accessibility windows "A" and "B" both at (100,100) 500×400 | Title stays "" |
| system-windows-010 | backfill-unique-frame | Window "" at (100,100,500,400); accessibility windows at (102,100) 500×400 and (0,0) 10×10 | Title stays "" (a 2-point delta is not within tolerance) |
| system-windows-011 | match-title-score, match-winner | Target "Report" at (0,0,800,600); accessibility windows: W1 "Other" at (0,0) 800×600 (score 8), W2 "Report" at (500,500) 100×100 (score 10) | W2 selected |
| system-windows-012 | match-winner | Target "Report" at (0,0,800,600); accessibility windows: W1 and W2 both "Report" at (0,0) 800×600 | W1 selected |
| system-windows-013 | match-zero-rejected | Target "Report" at (0,0,800,600); accessibility windows: one window "X" at (500,500) 10×10 | nil; moving throws the accessibility-not-available error |
| system-windows-014 | match-empty-title-score | Target "" at (0,0,800,600); accessibility windows: W1 "" elsewhere (1), W2 "Tab" elsewhere (0) | W1 selected |
| system-windows-015 | resolve-not-found | Moving window id 424242 to (0,0) with no such window listed | Throws the window-not-found error (window id 424242) |
| system-windows-016 | set-frame-partial | Movable but non-resizable window; setting frame to (50,50,300,300) | Throws the attribute-set-failed error for `AXSize`; window origin is (50,50) |
| system-windows-017 | horizontal-visibility | One screen, frame x 0…1440; window frames (-5000,200,800,600) and (-100,200,800,600) | false for the first, true for the second |
| system-windows-018 | display-fallback | Point (-99999,-99999) | Returns the main display id |
| system-windows-019 | focus-unpark | Main screen visible minX 0; window parked at (-5000,300,800,600) | Before raise, window moved to (80,300) |
| system-windows-020 | focus-activate | Window listed, accessibility element found, raise succeeds, owning app has quit | Throws the activation-failed error (app and pid) |
| system-windows-021 | error-descriptions | Attribute-set-failed error for attribute "AXPosition", code -25200 | description "Failed to set AXPosition: AXError code -25200" |
| system-windows-022 | observer-start-idempotent, observer-refresh | Mock control listing windows {1,2} for PID 10 and {3} for PID 20; start observation twice | Full window list read once; snapshot {10: {1,2}, 20: {3}} |
| system-windows-023 | window-destroyed | Snapshot {10: {1,2}}; mock now lists {1}; destroyed notification | Window destroyed reported for id 2 exactly once; snapshot {10: {1}} |
| system-windows-024 | window-created-baseline, window-created-report | Snapshot {10: {1}}; created notification for PID 10; before 0.5 s a destroy refresh adds id 5; after 0.5 s mock lists {1,5} | Window created reported for id 5 |
| system-windows-025 | title-changed-match | Element of PID 10 at (0,0) 800×600 titled "New"; mock lists PID 20 window id 9 and PID 10 window id 4, both at (0,0,800,600) | Title change reported for window id 4, new title "New" |
| system-windows-026 | observer-stop | Observing; stop observation; then a launch notification | No delegate call; accessibility observers and snapshot empty |
| system-windows-027 | permission-is-granted | Untrusted process; read the trust state ten times | Returns false each time; no system prompt appears |

