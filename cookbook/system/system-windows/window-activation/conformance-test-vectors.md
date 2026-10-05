
No test file for this package exists in the repo (only the scripting runner has its own test file); vectors are traced to the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| window-activation-001 | catalog-match | Matching `termProgram` "WarpTerminal" against the terminal catalog | Returns the Warp entry with bundle ID `dev.warp.Warp-Stable` |
| window-activation-002 | catalog-match | Matching `termProgram` "iterm.app" against the terminal catalog | Returns `nil` (match is case-sensitive) |
| window-activation-003 | catalog-match, catalog-match-default | Matching `termProgram` "Foo" against a custom catalog of one entry (displayName "Foo", bundleID "x.foo", termProgramValues ["Foo"]) | Returns the custom "Foo" entry |
| window-activation-004 | iterm-applies | Target with `termProgram` `""`, then `iTerm.app`, then `Apple_Terminal`, tested against the iTerm TTY strategy | Applies: `true`, `true`, `false` |
| window-activation-005 | ax-applies | Target with `projectName` `Unknown`, then `unknown`, then `""`, tested against the accessibility title-match strategy | Applies: `false`, `true`, `true` |
| window-activation-006 | front-applies, front-catalog-default | Target with `termProgram` `vscode`; target with `termProgram` `""`, tested against the bring-terminal-to-front strategy | Applies: `true`; then `false` |
| window-activation-007 | front-not-running, ax-injected-apps | Stub provider returning no apps; target `termProgram` `Apple_Terminal`, run through the bring-terminal-to-front strategy | Returns `false`; log unchanged |
| window-activation-008 | ax-no-match | Stub provider returning no apps; target `projectName` `demo`, run through the accessibility title-match strategy | Returns `false`; log unchanged |
| window-activation-009 | tty-invalid-pid, iterm-no-tty | Target with `pid` 0, run through the iTerm TTY strategy | Returns `false`; log gains one entry ending `  iTerm TTY: pid 0 has no TTY` |
| window-activation-010 | log-entry-format, log-text-format | A memory-only log; appending "a" then "b" | Log text equals `[<ts1>] a\n[<ts2>] b\n` with ISO 8601 fractional-second timestamps; log path is `nil` |
| window-activation-011 | log-text-format, log-clear | In-memory log with two entries; clearing it | Log text equals `""` |
| window-activation-012 | log-file-create, log-file-append-only | A file-backed log pointed at a missing file; appending "x" then "y" | File contents equal the log text byte for byte, two lines |
| window-activation-013 | log-clear | File-backed log with entries; clearing it | File exists and is zero bytes |
| window-activation-014 | tester-permission-abort, tester-clear-first | Process not trusted for accessibility; running the harness | Returns `(0, 0)`; log text is exactly the three lines harness header, `Accessibility: DENIED`, `ABORT: Accessibility permission required` |
| window-activation-015 | tester-cascade-stop, tester-strategy-result, tester-not-applicable | Trusted; strategies [S1 applies and returns true, S2 applies, S3 not applicable] | Log shows `Strategy S1: SUCCESS`, `Strategy S2: skipped (already activated)`, `Strategy S3: skipped (already activated)`; S2 and S3 never attempted |
| window-activation-016 | tester-not-applicable, tester-strategy-result | Trusted; strategies [S1 not applicable, S2 applies and returns false] | Log shows `Strategy S1: skipped (not applicable)` then `Strategy S2: FAILED` |
| window-activation-017 | tester-verify-rule, tester-frontmost-title | Trusted; stub provider with no frontmost application | Log shows `After activation: frontmost=""` and `Result: FAIL`; target counted as failed |
| window-activation-018 | tester-results | Trusted; empty target list | Returns `(0, 0)`; log ends with `=== Results: 0 passed, 0 failed ===` |

