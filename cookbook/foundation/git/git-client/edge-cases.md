
- **Null/empty input**: Parsing an empty status output MUST return an
  empty status result (git-client-001). Parsing a branch listing of only
  blank lines MUST return an empty list (git-client-021). Parsing an empty
  NUL-separated config listing MUST return an empty list (git-client-025).
  Parsing an empty worktree listing MUST return an empty list
  (git-client-018). The current-branch verb on a detached HEAD MUST return
  nothing, never the literal string `"HEAD"`.
- **Boundary/malformed values**: A porcelain record with no path at all
  (`" M \0"`) or a path that is only separators (`" M ///\0"`) MUST cost
  only that one record, never trap the parser (git-client-013,
  git-client-014). A path beginning with a Unicode combining mark MUST keep
  every byte rather than being truncated by a character-based slice
  (git-client-012). A `git config` argument list whose key position holds
  a dash-leading flag-shaped string (`-x.token`) MUST redact the value that
  follows it rather than mistaking the flag for the key and logging the
  secret in clear text (git-client-030). A `git config` argument list whose
  key position holds a bare, non-key-shaped word (`"email"`) MUST redact
  both it and the value that follows (git-client-031).
- **Concurrent access**: The git client's verbs each suspend for the whole
  lifetime of the child process, so ten concurrent callers run ten
  concurrent git processes rather than being queued behind one another — a
  deliberate accounting-only bottleneck, not a serialization guarantee. A
  call cancelled while a verb is in flight MUST see the cancellation
  signal propagate unchanged, never wrapped in the git client's own error
  outcome, so cooperative cancellation and any cleanup tied to it keep
  working for the caller.
- **Error states**: A configured executable path with nothing executable
  there MUST throw an executable-not-found outcome before any process is
  spawned, and the attempt MUST still be recorded (git-client-037). A
  command that runs to completion and exits non-zero MUST throw a
  command-failed outcome carrying the real exit status and standard-error
  text, with that standard-error text never reaching the command log
  (git-client-038, git-client-046). The unset-global-config verb on a key
  that was never set MUST surface git's exit status 5 as an ordinary
  command-failed outcome, with no dedicated outcome for it.
- **Timeout (this component's offline-equivalent state)**: This component
  has no network path of its own; its analog of an unreachable server is a
  git process that exceeds the configured timeout. That MUST throw a
  timed-out outcome, with the child terminated before the throw, and the
  attempt recorded with no exit status (git-client-039). A launch failure
  (for example, a working directory that does not exist) and any other
  failure from the underlying process-launch mechanism are collapsed by
  the execution step's total mapping into a launch-failed outcome — no
  error type outside the git client's own error outcome, aside from a
  cancellation signal, can escape it.

