
**Decision**: The git client is a Swift `actor` whose bottleneck is for
accounting (one identifiable door, one command log, one place to add a
future limit), not for serializing execution — every verb suspends at
`SubprocessChannel.run`, so concurrent callers get concurrent child
processes.
**Rationale**: (Swift actor implementation) A `status` on one repository
has no reason to wait behind a `worktree list` on another; a struct with a
shared queue would have serialized them for no benefit.
**Approved**: pending

**Decision**: The execution step records and then rethrows a cancellation
signal unchanged instead of wrapping it in the git client's own error
outcome.
**Rationale**: (Swift implementation) Wrapping it would break cooperative
cancellation propagation and structured-concurrency cleanup for every
caller, starting with a SwiftUI `.task` torn down while a `status` call is
in flight.
**Approved**: pending

**Decision**: The command log's argument redaction redacts by argument
*position* (everything at and after the first non-flag position, once that
position is spent) rather than by the *shape* of what is found there.
**Rationale**: The earlier, shape-based scan took the first argument not
beginning with `-` to be the key; a key beginning with `-` (`-x.token`) is
not a well-formed key, so that scan walked past it and logged the *secret*
that followed in clear text. Spending the position exactly once means a
shape this rule does not model costs a redacted argument, never a leaked
one.
**Approved**: pending

**Decision**: The execution step decodes captured standard output as UTF-8
first and falls back to ISO Latin-1, never to a lossy-replacement decoding.
**Rationale**: (Swift implementation) Swift's lossy `String(decoding:)`
would substitute U+FFFD for any byte git could not express in UTF-8 and
hand the parser a path matching nothing on disk, while a Latin-1 fallback
re-reads the whole capture losslessly, at the cost of mojibake only on the
rare capture that is not valid UTF-8.
**Approved**: pending

**Decision**: Parsing status slices and counts each porcelain record in
UTF-8 bytes, never by character.
**Rationale**: (Swift implementation) A path beginning with a combining
mark merges with the preceding separator into one grapheme cluster under
Swift's `Character`-based counting, which previously consumed a byte of
the path along with the separator and yielded an empty path that trapped
the directory roll-up.
**Approved**: pending

**Decision**: The execution step sets `GIT_TERMINAL_PROMPT=0`
unconditionally in the child's environment, merged under any
caller-supplied extra environment.
**Rationale**: Without it, a credential prompt would hang the child behind
a terminal nobody is watching, turning a network-auth failure into an
indefinite hang instead of a command-failed/timed-out outcome the caller
can act on.
**Approved**: pending

**Decision**: The `max(1, ...)` timeout clamp lives only in the
settings-derived configuration path, not in the plain constructor.
**Rationale**: (Swift implementation) The settings-derived path
(`fromSettings()`) is where a user-editable settings value reaches, where
zero or a negative number is a user-entry mistake that must not produce an
instantly-expiring budget; a directly-constructed configuration (as tests
build) is a programmatic value the caller is responsible for, so the plain
constructor imposes no clamp of its own.
**Approved**: pending

**Decision**: The three global-configuration verbs run with the user's
home directory as the child's working directory, never a repository
directory.
**Rationale**: `git config --global` neither discovers nor reads a
repository, so home is used only as somewhere legible for the child to
stand — never a location this client actually reads from or writes to as a
repository.
**Approved**: pending

