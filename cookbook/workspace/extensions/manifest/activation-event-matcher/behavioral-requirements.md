
- **event-kind-cases**: An activation event's kind MUST expose exactly
  seven kinds: any (`"*"`), startup finished (`"onStartupFinished"`),
  language (`"onLanguage:swift"` → the language id, e.g. `"swift"`), command
  (`"onCommand:foo.bar"` → the command id, e.g. `"foo.bar"`),
  workspace-contains (`"workspaceContains:**/*.csproj"` → the glob), webview
  panel (`"onWebviewPanel:markdown.preview"` → the view type), and view
  (`"onView:package-explorer"` → the view id).
- **event-value-semantics**: An activation event and an activation trigger
  MUST be immutable, comparable values usable safely from any thread; an
  event's kind MUST also be an immutable, comparable value.
- **raw-value-preservation**: An activation event's raw text MUST hold the
  entry exactly as the manifest spelled it — including any leading or
  trailing whitespace — even though recognition of the entry's shape
  operates on a trimmed copy; this is so a diagnostic can quote what the
  author wrote.
- **whitespace-trimming**: Parsing an activation event MUST trim leading
  and trailing whitespace before recognizing the entry's shape.
- **entry-parsing-order**: Parsing MUST test the trimmed value, in order,
  against: empty (fails), exactly `"*"`, exactly `"onStartupFinished"`,
  then the prefixes `"onLanguage:"`, `"onCommand:"`, `"workspaceContains:"`,
  `"onWebviewPanel:"`, `"onView:"`; the first match wins.
- **empty-entry-rejection**: An entry that trims to the empty string MUST
  fail to parse.
- **prefixed-payload-extraction**: For each of the five colon-prefixed
  forms, the payload MUST be everything after the prefix, taken verbatim
  and never case-normalized — VS Code language and command ids are
  lowercase by convention but the editor never enforces it, so normalizing
  here would accept manifests VS Code itself would not activate.
- **empty-payload-rejection**: A prefixed entry whose payload is empty
  after the colon (for example `"onLanguage:"`) MUST fail to parse rather
  than being read as a match against the empty string.
- **unrecognized-entry-rejection**: A trimmed value matching none of the
  seven recognized shapes MUST fail to parse.
- **matcher-value-semantics**: The activation event matcher MUST be an
  immutable, comparable value usable safely from any thread.
- **parse-triage**: Building the matcher from a manifest MUST parse every
  entry of `activationEvents`, in order, placing every entry that parses
  into the recognized-events list (in original manifest order) and the
  raw, untrimmed text of every entry that fails to parse into the
  unrecognized-entries list (in original manifest order); an unrecognized
  entry MUST NOT be dropped silently.
- **eager-activation-flag**: Eager activation MUST be true if and only if
  the recognized-events list contains an entry whose kind is any.
- **glob-triage**: For every parsed workspace-contains event, in order,
  building the matcher MUST attempt to build a glob pattern from the glob
  text; a glob that parses MUST be added to the matcher's internal pattern
  list (used to answer workspace-scan triggers), and a glob that fails to
  parse MUST have its raw payload text (not the `"workspaceContains:"`
  prefix) appended to the unsupported-patterns list, in order; a pattern in
  the unsupported-patterns list MUST NOT ever match.
- **glob-syntax-supported**: A supported `workspaceContains:` glob's syntax
  is: a literal character matches itself; `?` matches exactly one character
  other than a path separator; `*` matches a run of zero or more characters
  excluding a path separator; two consecutive `*` characters that begin and
  end a whole path segment — starting the pattern or preceded by a path
  separator, and ending the pattern or followed by a path separator — match
  zero or more whole path segments, crossing path separators; two
  consecutive `*` characters that do not form a whole segment (for example
  a run that starts mid-segment or ends mid-segment) are treated as a
  single `*`; and a brace group of comma-separated alternatives (an
  alternative MAY be empty) matches if any one alternative matches, but a
  brace group MUST NOT contain a nested brace group.
- **glob-syntax-unsupported**: A `workspaceContains:` glob containing a
  square-bracket character class, or one beginning with an exclamation-mark
  negation, MUST fail to parse rather than being approximated as a literal
  or a partial match; treating an unsupported construct as a literal
  "would make a pattern match paths its author never intended."
- **glob-anchoring**: A parsed glob pattern MUST match a path only when the
  pattern consumes the whole path at both ends; a partial or substring
  match MUST NOT count as a match.
- **glob-character-granularity**: Glob matching MUST operate over whole
  displayed characters (grapheme clusters) of both the pattern and the
  path, never raw code points or code units, so a multi-scalar character is
  compared as one unit on either side of the match (Platform Notes: SwiftUI
  and Design Decisions — the granularity is not guaranteed to be identical
  across every platform's implementation).
- **workspace-scan-decomposition**: Building a workspace scan MUST
  decompose every relative path into its character sequence exactly once,
  at construction, storing the result at the matching index; this
  decomposition MUST NOT be repeated per pattern or per extension checked
  against the same scan.
- **workspace-scan-equality**: Two workspace scans MUST be equal if and
  only if their relative-paths lists are equal; the decomposed-paths index
  (a derived value) MUST NOT participate in equality.
- **workspace-scan-reuse**: A caller that checks more than one matcher
  against the same directory walk MUST construct one shared workspace scan
  and pass it to every workspace-scan check, rather than building a fresh
  workspace scan per extension; the cost of not doing so is concrete (a
  20,000-path workspace with 30 installed extensions redundantly
  decomposing 600,000 paths for input that never changed between calls).
- **implicit-activation-floor**: The implicitly activating commands MUST
  equal the set of `contributes.commands` command-id strings when the
  manifest's `engines.vscode` parses into an engine range that is either
  unconstrained (for example `"*"`) or whose minimum version is greater
  than or equal to 1.74.0; otherwise the implicitly activating commands
  MUST be empty. The version tested is the manifest's own declared engine,
  never the host's, because an extension that still targets an older VS
  Code cannot rely on behavior its stated minimum predates.
- **implicit-activation-unparseable-engine**: A manifest whose
  `engines.vscode` does not parse into an engine range MUST yield an empty
  implicitly-activating-commands set; an engine string this component
  cannot evaluate MUST NOT be treated as evidence the extension supports
  the newer inference.
- **command-match**: Matching a command-invoked trigger MUST return true
  if and only if the command id is a member of the implicitly activating
  commands, or the recognized-events list contains an entry whose kind is
  command with that same id (exact, case-sensitive match); otherwise it
  MUST return false.
- **document-opened-match**: Matching a document-opened trigger MUST return
  true if and only if the recognized-events list contains an entry whose
  kind is language with a language id exactly equal (case-sensitive) to the
  trigger's language id.
- **startup-match**: Matching the startup-finished trigger MUST return true
  if and only if the recognized-events list contains an entry whose kind is
  startup finished.
- **webview-panel-restored-match**: Matching a webview-panel-restored
  trigger MUST return true if and only if the recognized-events list
  contains an entry whose kind is webview panel with a view type exactly
  equal (case-sensitive) to the trigger's view type.
- **view-shown-match**: Matching a view-shown trigger MUST return true if
  and only if the recognized-events list contains an entry whose kind is
  view with a view id exactly equal (case-sensitive) to the trigger's view
  id.
- **workspace-scanned-match**: Matching a workspace-scanned trigger MUST
  return false immediately when the matcher's parsed workspace-contains
  pattern list is empty; otherwise it MUST return true if and only if at
  least one of the scan's decomposed paths matches at least one parsed
  pattern.
- **eager-short-circuit**: When eager activation is true, matching MUST
  return true for every activation trigger without evaluating any other
  rule.
- **webview-panel-ownership-exclusion**: Declaring ownership of a webview
  panel view type MUST NOT consult eager activation; it MUST return true if
  and only if the recognized-events list contains a webview-panel entry
  with that exact (case-sensitive) view type, regardless of whether the
  manifest also declares `"*"`. The reason: activating eagerly answers
  "does this wake the extension," while owning a view type answers "whose
  panel is this" — and an extension that only activates eagerly has made no
  claim on any view type, so handing it someone else's panel would be a
  silent mis-delivery.
- **empty-manifest-no-match**: A matcher built from a manifest with no
  `activationEvents` entries and no implicitly activating commands MUST
  have eager activation false, and matching MUST return false for every
  activation trigger; an extension with no recognized events and no
  implicitly activating commands MUST NOT fall back to eager activation.
- **backtracking-memoization**: Matching a glob pattern SHOULD memoize
  search state — on the pair of token index and path index for the
  pattern's own tokens, and on the triple of branch id, branch-internal
  index and path index for each brace-group branch — whenever the pattern
  contains more than one token capable of consuming a variable amount of
  the path (a lone `*`, a whole-segment double-`*`, or a brace-group
  alternation, each alternation counted together with its own contained
  tokens); a pattern with at most one such token MAY skip memoization,
  since every search state is then reached exactly once regardless. See
  Design Decisions for the rationale.
- **single-matcher-trigger-factory**: A convenience for building a
  workspace-scanned trigger directly from a list of relative paths MAY be
  used by a caller that has exactly one matcher to ask (a test, or a replay
  for a single extension with no prepared scan to hand); the
  `workspace-scan-reuse` requirement's prohibition applies only to a caller
  with more than one matcher.

