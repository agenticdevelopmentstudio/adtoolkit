
- **Data collected**: This component persists no user content of its own;
  the client configuration and the three settings it reads hold only an
  executable path, a timeout integer, and a boolean. The one
  privacy-relevant surface is the *value* argument of the
  set-global-config verb, which may carry an email address, a signing key,
  or a URL containing a token.
- **Redaction lives at the funnel, not at call sites**: The command log's
  argument redaction is scoped to the config verb and redacts every
  argument at and after the first non-flag position, so a caller-supplied
  value never reaches log output in clear text; standard-error text —
  which may itself echo a repository path — MUST NEVER reach the log at
  all.
- **Nothing leaves the device through this component**: every verb spawns
  a local git subprocess; nothing in this component performs network I/O
  itself, though the git binary it spawns may contact a remote if a future
  verb passes arguments that do (none of the seven given verbs do).

