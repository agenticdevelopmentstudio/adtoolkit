
- **dev-deployment-envs-list**: The allowlist MUST be exported as the fixed
  three-element list `['local', 'testing', 'staging']`, and its associated
  type MUST be the literal union of exactly those three strings, derived
  from the allowlist's own value rather than declared separately.
- **dev-env-membership-check**: The server-side membership check MUST
  return `true` when, and only when, its input is non-null, non-undefined,
  and an exact, case-sensitive match for one of the three allowlist
  entries.
- **dev-env-fail-closed**: The server-side membership check MUST return
  `false` for `null`, `undefined`, the empty string, `"production"`, and
  any string that does not exactly match an allowlisted entry — including
  a differently-cased or whitespace-padded near-match such as `"LOCAL"`,
  `"Local"`, or `"staging "` — so an unset, misspelled, or unrecognized
  environment hides the dev affordance rather than exposing it.
- **dev-env-server-side-scope**: The server-side membership check MUST be
  evaluated against the environment variable `DEPLOYMENT_ENV`, which
  carries no build-time-inlined prefix and therefore never reaches the
  browser; its result MUST be used only to decide what a server render
  emits, never what code a client bundle contains.
- **dev-build-literal-comparisons**: The build-time flag MUST be assigned
  the result of exactly three equality comparisons — the environment
  variable `NEXT_PUBLIC_DEPLOYMENT_ENV` compared against `'local'`, against
  `'testing'`, and against `'staging'` — joined by OR, and MUST NOT be
  expressed via a runtime array-membership scan (a list-contains check, an
  iteration/some-match check, or an index search), because the build tool
  substitutes that variable's text and folds to a constant only for a
  direct comparison against a string literal; routing the same check
  through a runtime lookup leaves something the folder cannot resolve, so
  every branch gated on the result survives into the production bundle.
- **dev-build-load-time-evaluation**: The build-time flag MUST be computed
  exactly once, at module evaluation time, from whatever value the
  environment variable `NEXT_PUBLIC_DEPLOYMENT_ENV` holds at that moment;
  it MUST NOT be re-computed or re-read on a later access.
- **dev-build-agrees-with-server-gate**: For every environment value either
  check accepts, the build-time flag computed from
  `NEXT_PUBLIC_DEPLOYMENT_ENV` MUST equal what the server-side membership
  check computes from the same string value read as `DEPLOYMENT_ENV` — two
  separate declarations reading two separate (server-only vs.
  build-time-inlined) environment variables, but stating one fact.
- **chunk-gate-inline-comparison-requirement**: Any caller elsewhere in the
  codebase that gates a dynamically-loaded code chunk on this dev/
  production distinction MUST write the three
  `NEXT_PUBLIC_DEPLOYMENT_ENV === '<env>'` comparisons directly at that
  chunk's load call site rather than branching on an imported flag,
  because a build tool's dead-code elimination for a dynamically-loaded
  chunk resolves only a literal comparison it can see while parsing that
  exact call site, and does not follow an imported name back to where it
  is defined.
- **chunk-gate-subpath-specifier-requirement**: A module gated per
  chunk-gate-inline-comparison-requirement MUST be reached through its
  published subpath name, never a relative path, whenever the importing
  package's bundler configuration would otherwise inline a relative
  import's code into the same output file and erase the module boundary
  the gate depends on.
- **dev-build-safe-for-non-chunk-gating-uses**: Importing and branching on
  the build-time flag directly for a decision that is not a
  dynamic-chunk load (such as computing a boolean elsewhere) MUST be
  treated as safe and equivalent to re-declaring the same three
  comparisons locally, because the build-time substitution and constant
  fold apply to every module the build tool processes — including
  third-party dependencies — so a shared flag folds to the same literal a
  local restatement would.
- **cross-repo-allowlist-parity**: The three literal strings in the
  allowlist MUST remain exactly the set that a separate backend process's
  independently declared allowlist also names, because that process reads
  its own copy of the `DEPLOYMENT_ENV` variable to decide whether to serve
  theme data, and a divergence between the two lists either serves a theme
  surface the frontend has already hidden, or hides one the frontend still
  asks for.
- **module-load-is-total**: Loading this module MUST perform only a single
  synchronous read of the `NEXT_PUBLIC_DEPLOYMENT_ENV` environment variable
  (to compute the build-time flag); it MUST NOT perform file, network, or
  other I/O, and MUST NOT throw for any input, including when that
  variable is unset.

