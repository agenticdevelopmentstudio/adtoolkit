
### Window-activation target

- **target-fields**: A window-activation target MUST carry exactly five immutable fields: `identifier` (string, shown in logs), `projectName` (string, used for title matching), `cwd` (string, working directory, used for title matching), `pid` (process ID, used for TTY resolution) and `termProgram` (string, the `$TERM_PROGRAM` value).
- **target-unknown-term-program**: An unknown `$TERM_PROGRAM` MUST be represented as the empty string in `termProgram`, per the field's documentation.
- **target-value-semantics**: A window-activation target MUST be an immutable value type, safe to share across concurrent contexts, comparable for equality, with memberwise equality over all five fields.

### The activation-strategy contract

- **strategy-name**: Every strategy MUST expose a short human-readable name used in log lines.
- **strategy-applies-to**: Every strategy MUST answer whether it applies to a target synchronously with a boolean and no side effects on the log.
- **strategy-activate-signature**: Every strategy MUST implement an activation step that returns `true` when it considers the target's window brought to the front and `false` otherwise, appending its own diagnostics to the supplied log.
- **strategy-sendable**: The activation-strategy contract MUST require every strategy to be safe to share across concurrent contexts.

### The iTerm TTY strategy

- **iterm-name**: The iTerm TTY strategy's name MUST be `iTerm TTY`.
- **iterm-applies**: The strategy MUST apply when `termProgram` equals `iTerm.app` exactly or is the empty string, and MUST NOT apply for any other value.
- **iterm-no-tty**: When the target's PID has no resolvable TTY, the strategy MUST append `  iTerm TTY: pid <pid> has no TTY` and return `false` without running any script.
- **iterm-dev-prefix**: The strategy MUST prefix the resolved TTY with `/dev/` unless it already starts with `/dev/`.
- **iterm-script**: The strategy MUST run one script against iTerm2 that walks every window and every tab, compares the tab's current session `tty` to the `/dev/` path, and on the first match selects that tab, activates iTerm2 and returns `found`; if no tab matches the script MUST return `not_found`.
- **iterm-success**: The strategy MUST return `true` only when the script succeeds and its string result, trimmed of whitespace and newlines, equals `found`.
- **iterm-not-found**: When the script succeeds with any other result (including no string), the strategy MUST append `  iTerm TTY: <devTTY> not found in any iTerm session` and return `false`.
- **iterm-compile-failed**: When the script fails to compile, the strategy MUST append `  iTerm TTY: AppleScript failed to compile` and return `false`.
- **iterm-runtime-failed**: When the script fails at runtime, the strategy MUST append `  iTerm TTY: AppleScript failed: <message> (error <number>)` and return `false`.

### The accessibility title-match strategy

- **ax-name**: The strategy's name MUST be `AX title match`.
- **ax-applies**: The strategy MUST apply whenever `projectName` is not exactly `Unknown` (case-sensitive), including when it is empty.
- **ax-regular-apps-only**: The strategy MUST consider only running applications whose activation policy is regular (visible to the user as a normal running app), skipping accessory and background apps.
- **ax-app-order**: The strategy MUST walk applications in the order the running-applications provider returns them and each application's accessibility windows in the order the accessibility layer returns them, stopping at the first match.
- **ax-skip-unreadable**: The strategy MUST skip an application whose accessibility window list cannot be read, and MUST skip any window whose title is missing or empty.
- **ax-match-rule**: A window MUST match when its title contains, by localized case-insensitive comparison, any one of: `projectName`, the last path component of `cwd`, or the full `cwd`.
- **ax-match-log**: On a match the strategy MUST append `  AX match: "<title>" in <app name>`, using `?` when the application has no localized name.
- **ax-activation-sequence**: On a match the strategy MUST activate the owning application, block the calling thread for 0.15 seconds, perform the raise action on the window through the accessibility layer, and then set the window's main attribute to true, in that order.
- **ax-raise-result**: The accessibility title-match strategy returns true on a title match without checking the results of the application activate call, the raise action or the set-main call, so an accessibility failure is reported as success, short of the contract "Return true if the front window now belongs to the target".
- **ax-no-match**: When no window in any regular application matches, the strategy MUST return `false` without appending a log line.
- **ax-injected-apps**: The strategy MUST read the running-application list only through its injected running-applications provider, defaulting to the real provider.

### The bring-terminal-to-front strategy

- **front-name**: The strategy's name MUST be `bring terminal to front`.
- **front-applies**: The strategy MUST apply exactly when the terminal catalog finds a matching entry for the target's `termProgram` in the strategy's catalog.
- **front-catalog-default**: The strategy's catalog MUST default to the full terminal catalog and MUST accept a caller-supplied catalog at construction.
- **front-not-running**: When no catalog entry matches or no running application has the entry's bundle identifier, the strategy MUST return `false` without appending a log line.
- **front-activate-first**: When at least one running instance exists, the strategy MUST activate the first instance returned by the provider and does not select any specific window.
- **front-activate-result**: The bring-terminal-to-front strategy returns true after calling the application activate method without checking its boolean result, so a refused activation is reported as success, short of the contract "Return true if the front window now belongs to the target".

### The terminal catalog

- **catalog-entries**: The terminal catalog MUST contain, in this order: iTerm2 (`com.googlecode.iterm2`, `iTerm.app`), Terminal.app (`com.apple.Terminal`, `Apple_Terminal`), Warp (`dev.warp.Warp-Stable`, `WarpTerminal`) and VS Code (`com.microsoft.VSCode`, `vscode`).
- **catalog-match**: Matching a `termProgram` value against a catalog MUST return the first entry whose `termProgramValues` contains it by exact, case-sensitive string equality, or `nil` when none does.
- **catalog-match-default**: Matching MUST search the full terminal catalog when no catalog is passed.
- **known-terminal-value**: A terminal catalog entry MUST be an immutable value, comparable for equality, with `displayName`, `bundleID` and `termProgramValues` (an array, allowing several `$TERM_PROGRAM` values per terminal).

### The running-applications provider

- **provider-surface**: The running-applications provider MUST expose all running applications (unordered), the running applications for a given bundle identifier, and the frontmost application (optional).
- **provider-real**: The real running-applications provider MUST delegate to the shared workspace's running-application list, the running-application lookup by bundle identifier, and the shared workspace's frontmost application.
- **provider-sendable**: The provider contract MUST require every conformer to be safe to share across concurrent contexts, so strategies holding one stay safe to share too.

### The TTY resolver

- **tty-invalid-pid**: The TTY resolver MUST return `nil` without spawning a process when `pid` is 0 or negative.
- **tty-process**: For a positive PID the resolver MUST run `/bin/ps -p <pid> -o tty=`, discard standard error, block until the process exits, and read all of standard output.
- **tty-result**: The resolver MUST return the output decoded as UTF-8 and trimmed of whitespace and newlines (for example `s001`, with no `/dev/` prefix), or `nil` when the trimmed output is empty or the process fails to launch.
- **tty-internal**: The TTY resolver MUST be internal to the package, not part of its public interface.

### The activation test log

- **log-init-app-support**: Constructing the log with an application-support subdirectory MUST target `<user Application Support>/<subdirectory>/activation-test.log`, creating the subdirectory (with intermediates) if missing.
- **log-init-no-app-support**: When the user Application Support directory cannot be located, that construction path MUST produce an in-memory-only log (the log path is `nil`) rather than crash, per its documentation.
- **log-init-file-url**: Constructing the log with a file URL MUST mirror entries to that URL, or keep them in memory only when the URL is `nil`.
- **log-entry-format**: Appending a message MUST store the entry `[<timestamp>] <message>`, where the timestamp is ISO 8601 internet date-time with fractional seconds captured at the moment the append is called.
- **log-thread-safe-memory**: Reads and writes of the in-memory buffer MUST be serialized on one private queue so appending, clearing and reading the text are safe from any thread.
- **log-text-format**: Reading the log's text MUST return every entry followed by a single newline, concatenated, or the empty string when there are no entries.
- **log-file-create**: On the first append to a file that does not exist, the log MUST create it by writing the entry and a newline atomically.
- **log-file-append-only**: When the file exists, the log MUST append the entry and a newline at the end and MUST NOT truncate existing content; if the file cannot be opened for writing, or the seek or write fails, the line MUST be dropped from the file (it remains in memory), per its documentation.
- **log-file-write-ordering**: Appending to the log serializes only the in-memory append on its queue; the file write happens outside that queue. Concurrent appends can reach the file in a different order than the buffer, and two first appends can both see a missing file and each write it atomically, losing a line, so the text and the file are not guaranteed byte-identical.
- **log-clear**: Clearing MUST empty the in-memory buffer and, when a file URL exists, overwrite the file with an empty string atomically, ignoring any write error.
- **log-path**: Reading the log path MUST return the file-system path of the log file, or `nil` for an in-memory-only log.
- **log-shared-instance**: One process-wide shared instance MUST be created with the application-support subdirectory `Whippet`.
- **log-sendable**: The activation test log MUST be safe to share across concurrent contexts, relying on its private serial queue for memory-buffer isolation.

### The activation test harness

- **tester-init**: The activation test harness MUST take `targets`, a log, a strategies list (default the built-in cascade) and a running-applications provider (default the real provider).
- **tester-default-cascade**: The built-in cascade MUST be, in order: the iTerm TTY strategy, the accessibility title-match strategy, the bring-terminal-to-front strategy, each with default arguments.
- **tester-threading**: The activation test harness MUST be used single-threaded per its documentation: created on the main thread, with its run-all-tests operation run on a background queue and no concurrent internal access.
- **tester-clear-first**: Running all tests MUST clear the log before writing anything, then append `=== Window Activation Test Harness ===` and `Accessibility: GRANTED` or `Accessibility: DENIED` according to whether the process is trusted for accessibility.
- **tester-permission-abort**: When the process is not trusted for accessibility, running all tests MUST append `ABORT: Accessibility permission required` and return `(passed: 0, failed: 0)` without enumerating or testing any target and without reactivating the host app.
- **tester-header**: When trusted, running all tests MUST append `Targets: <count>`, `Strategies: <names joined by ", ">` and an empty line.
- **tester-inventory**: When trusted, running all tests MUST append a `--- Terminal Window Inventory ---` section iterating the full terminal catalog (not the strategies' catalogs) in catalog order, logging `<displayName>: not running` or `<displayName>: PID=<pid>` for each.
- **tester-inventory-iterm**: For a running iTerm2 (`com.googlecode.iterm2`) the inventory MUST list every window (`  WINDOW id=<id> name=<name>`) and every tab (`    TAB <n>: tty=<tty> name=<name>`, 1-based) through one script, logging `  (no output)` for a nil result, `  (AppleScript compile failed)` for a compile failure, and `  (AppleScript failed: <message>, error <number>)` for a runtime failure.
- **tester-inventory-ax**: For any other running catalog terminal the inventory MUST list each accessibility window as `  AX[<index>]: "<title>"` (0-based, `<no title>` when the title is missing), or `  (no AX windows)` when the window list cannot be read.
- **tester-per-target**: The harness MUST test targets sequentially in the order given, blocking 1.0 second after each target.
- **tester-target-header**: For each target the harness MUST append `--- Test: <projectName> ---` followed by the `identifier`, `cwd`, `pid` and `termProgram` lines.
- **tester-cascade-stop**: The harness MUST run strategies in list order and stop attempting once one returns `true`, logging every later strategy as `  Strategy <name>: skipped (already activated)`.
- **tester-not-applicable**: A strategy that reports it does not apply to the target MUST be logged as `  Strategy <name>: skipped (not applicable)` and not attempted.
- **tester-strategy-result**: Each attempted strategy MUST be logged as `  Strategy <name>: SUCCESS` or `  Strategy <name>: FAILED`.
- **tester-verify-delay**: After the cascade, whether or not any strategy succeeded, the harness MUST block 0.5 seconds and then read the frontmost window title, logging `  After activation: frontmost="<title>"`.
- **tester-frontmost-title**: The frontmost title MUST be the empty string when there is no frontmost app or its focused window or title cannot be read, and MUST be the literal `Sessions` when the frontmost app's bundle identifier equals the host app's own.
- **tester-verify-rule**: A target MUST pass when the frontmost title is non-empty and not exactly `Sessions`, and fail otherwise, logging `  Result: PASS` or `  Result: FAIL`; the verification does not check that the frontmost window belongs to the target.
- **tester-results**: After all targets, running all tests MUST append an empty line and `=== Results: <passed> passed, <failed> failed ===` and return `(passed, failed)`.
- **tester-reactivate-host**: After a completed (non-aborted) run the harness MUST asynchronously, on the main queue, activate the host application ignoring other apps.
- **tester-no-cancellation**: Running all tests MUST run to completion once started; it exposes no cancellation or timeout.

