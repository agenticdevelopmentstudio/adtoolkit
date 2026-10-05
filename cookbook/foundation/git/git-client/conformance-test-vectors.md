
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-client-001 | status-porcelain-record-shape | Parse an empty status output. | Returns an empty status result. |
| git-client-002 | status-porcelain-record-shape | Parse status output ` M foo.txt` (NUL-terminated). | `foo.txt` has status modified. |
| git-client-003 | status-porcelain-record-shape, status-directory-rollup | Parse status output `?? untracked/new.txt`. | `untracked/new.txt` is untracked; the `untracked` directory rolls up to untracked. |
| git-client-004 | status-directory-rollup | Parse status output ` M a/b/c.txt`. | Directories `a` and `a/b` both roll up to modified. |
| git-client-005 | status-porcelain-record-shape | Parse status output `R  new.txt` followed by NUL-terminated origin path `old.txt`. | `new.txt` is renamed; `old.txt` has no separate entry. |
| git-client-006 | status-porcelain-record-shape | Parse status output `RM new.txt` followed by origin path `old.txt`. | `new.txt` is renamed; no entry is recorded for the combined `old.txt -> new.txt` label. |
| git-client-007 | status-porcelain-record-shape | Parse status output ` R App/Sources/Foo.swift` (origin `App/Sources/Bar.swift`) followed by ` M README.md`. | `Foo.swift` is renamed, `Bar.swift` has no separate entry, `README.md` is modified, and exactly two entries total are recorded. |
| git-client-008 | status-porcelain-record-shape | Parse status output `C  copy.txt` (origin `original.txt`) followed by ` M kept.txt`. | `copy.txt` is recorded as copied under the new path, `original.txt` has no separate entry, `kept.txt` is modified. |
| git-client-009 | status-conflict-pair-detection | Parse status output `AA a/both-added.txt` and `DD b/both-deleted.txt`. | Both are conflicted; directories `a` and `b` both roll up to conflicted. |
| git-client-010 | status-conflict-pair-detection | Parse status output `A  added.txt` and `D  deleted.txt`. | `added.txt` is added; `deleted.txt` is deleted — the conflict rule does not apply to ordinary add/delete pairs. |
| git-client-011 | status-byte-accurate-path-decode | Parse status output ` M café.txt` (non-ASCII, no shell quoting). | `café.txt` is keyed exactly, byte for byte. |
| git-client-012 | status-byte-accurate-path-decode | Parse status output for a path beginning with a standalone combining accent mark. | The path keeps its leading combining mark rather than being truncated; no empty-path entry is recorded. |
| git-client-013 | status-byte-accurate-path-decode | Parse status output with an empty path record (` M ` followed immediately by NUL) followed by ` M kept.txt`. | `kept.txt` is modified; no entry is recorded for the empty path. |
| git-client-014 | status-directory-rollup | Parse status output for a path consisting only of separators (` M ///`). | No directory rollup entries are produced. |
| git-client-015 | worktree-main-is-first, worktree-branch-shortening | Parse a 4-record worktree listing. | The first record is marked as the main worktree, at the repository's own root path, on branch `main`. |
| git-client-016 | worktree-branch-shortening | The same 4-record listing. | The second record's branch is shortened to `tabs`. |
| git-client-017 | worktree-parse-flush-on-new-record | The same 4-record listing. | The third record is detached with no branch; the fourth record is bare. |
| git-client-018 | worktree-parse-flush-on-new-record | Parse an empty worktree listing. | Returns an empty list. |
| git-client-019 | worktree-parse-flush-on-new-record | Parse a worktree listing with one record and no trailing blank line (`worktree /solo`, `HEAD abc`, `branch refs/heads/solo`). | One entry is recorded, marked main, with branch `solo`. |
| git-client-020 | branch-parse-tab-separated | Parse branch listing `main<TAB>*<TAB>origin/main`, `feature<TAB><TAB>`, `tabs<TAB><TAB>origin/tabs`. | Three branch entries: `main` (current, tracking `origin/main`), `feature` (not current, no upstream), `tabs` (not current, tracking `origin/tabs`). |
| git-client-021 | branch-parse-tab-separated | Parse a branch listing consisting only of blank lines. | Returns an empty list. |
| git-client-022 | branch-parse-tab-separated | Parse branch listing `main<TAB> <TAB>origin/main`, `feature<TAB> <TAB>` (a single-space HEAD field, as a real listing produces for a non-current branch). | `main` is recorded as not current. |
| git-client-023 | config-entry-parse-split-rule | Parse a NUL-separated config listing: `user.name`/`Mike`, `user.email`/`mike@example.com`, and `core.editor`/`vim -f` followed by a literal `extra` with no value. | Three entries are recorded; the `core.editor` entry's value includes the embedded newline verbatim. |
| git-client-024 | config-entry-parse-split-rule | Parse a NUL-separated config listing consisting of the single key `alias.st` with no value. | One entry, `alias.st`, with an empty value. |
| git-client-025 | config-entry-parse-split-rule | Parse an empty NUL-separated config listing. | Returns an empty list. |
| git-client-026 | redaction-scope-and-positional-rule | Redact arguments for verb `status` with args `["status", "--porcelain=v1", "-uall", "--ignore-submodules"]`. | Unchanged. |
| git-client-027 | redaction-scope-and-positional-rule | Redact arguments for verb `config` with args `["--global", "--list", "--null"]` and separately `["--global", "--unset", "user.email"]`. | Both unchanged — nothing follows the key position in either case. |
| git-client-028 | redaction-scope-and-positional-rule | Redact arguments for verb `config` with args `["--global", "user.email", "someone@example.com"]`. | `["--global", "user.email", "<redacted:19>"]`. |
| git-client-029 | redaction-scope-and-positional-rule | Redact arguments for verb `config` with args `["--global", "core.pager", "--dash-leading-value", "trailing"]`. | `["--global", "core.pager", "<redacted:20>", "<redacted:8>"]`. |
| git-client-030 | redaction-scope-and-positional-rule | Redact arguments for verb `config` with args `["--global", "-x.token", "s3cr3t"]`. | `["--global", "-x.token", "<redacted:6>"]` — the dash-leading key never leaks its value. |
| git-client-031 | redaction-scope-and-positional-rule | Redact arguments for verb `config` with args `["--global", "email", "someone@example.com"]`. | `["--global", "<redacted:5>", "<redacted:19>"]` — a non-key-shaped word is redacted too. |
| git-client-032 | redaction-scope-and-positional-rule | Redact an empty argument list for verb `config`. | Returns an empty list. |
| git-client-033 | config-default | Read the default configuration. | Executable path `/usr/bin/git`; timeout `5`; submodule handling set to ignore. |
| git-client-034 | config-from-settings-timeout-clamp | Derive configuration from settings: path `/opt/homebrew/bin/git`, timeout `12`, submodules `true`. | The derived configuration reflects all three exactly. |
| git-client-035 | config-from-settings-timeout-clamp | Derive configuration from settings with a timeout setting of `0`. | The derived timeout is `1`. |
| git-client-036 | config-from-settings-timeout-clamp | Derive configuration from settings with a timeout setting of `-5`. | The derived timeout is `1`. |
| git-client-037 | executable-preflight | Configure the executable path as `/nonexistent/git` and call the current-branch verb. | Throws an executable-not-found outcome naming `/nonexistent/git`, before any process is spawned. |
| git-client-038 | non-zero-exit-mapping | Call the status verb against a nonexistent directory. | Throws a command-failed outcome. |
| git-client-039 | total-failure-mapping | Configure a timeout of `0.001` seconds and call the status verb against a real repository. | Throws a timed-out outcome naming the `status` verb. |
| git-client-040 | global-config-directory, set-global-config | Call set-global-config with key `atkgitclienttest.added`, value `added-value`, against a redirected global-config location. | The redirected file, not the real user-wide config, gains the entry. |
| git-client-041 | unset-global-config-exit-5, global-config-directory | Call unset-global-config on a previously seeded key, then read global config. | The key is gone; the listing is empty; the real user-wide config is untouched. |
| git-client-042 | status-command-construction | Call the status verb against a real one-commit fixture repository with one modified file. | `a.txt` has status modified. |
| git-client-043 | current-branch-detached-head | Call the current-branch verb against a fixture's root checkout and its `feature` worktree. | Returns `"main"` and `"feature"` respectively. |
| git-client-044 | branches-format-string | Call the branches verb against a fixture with `main` and `feature` branches. | Both names are present; `main` is marked current. |
| git-client-045 | worktree-main-is-first | Call the worktrees verb against a fixture's root plus one added worktree. | Two entries; the first is main on branch `main`, the second is on branch `feature`. |
| git-client-046 | error-description-vs-log-description | Produce the log-facing description of a command-failed outcome carrying verb `status`, exit status `128`, and standard-error text `"fatal: ... '/Users/secret/repo'"`. | Excludes `"secret"`; includes `"status"` and `"128"`. |
| git-client-047 | error-description-vs-log-description | Produce the log-facing description of a launch-failed outcome carrying reason `"secret-path-in-the-reason"`. | Excludes `"secret"`. |
| git-client-048 | error-description-vs-log-description | Produce the log-facing description of an executable-not-found outcome carrying path `"/Users/secret/bin/git"`. | Excludes `"secret"`. |

