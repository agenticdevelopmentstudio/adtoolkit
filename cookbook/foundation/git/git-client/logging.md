
Subsystem/category are whatever this component's own logging
configuration assigns.

| Event | Level | Message shape |
|-------|-------|---------------|
| Every invocation attempt, regardless of outcome | info | `` `git <verb> <redacted-arguments> cwd=<path> from=<file>:<function> <ms>ms status=<exitStatus-or-"unfinished">` `` |

The command log MUST NOT log the process's standard output or standard
error — only that a call happened and where it came from, so git usage can
be counted, attributed, and audited without the log becoming a copy of the
repository. Arguments are logged at public visibility after passing through
the redaction rule (see Behavioral Requirements and Privacy above), never
collapsed as a whole, because that would hide the entire interpolation for
every verb rather than redacting the one argument position that needs it.
The redaction rule today covers only the config verb; a future addition is
expected to add coverage for a commit-message argument and any remote URL,
once those verbs exist.

