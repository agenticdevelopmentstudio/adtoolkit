
- **ide-type-cases**: The IDE-type value MUST be a string-backed value type
  with exactly six cases — `xcode`, `xcodeWorkspace`, `swiftPackage`,
  `vscode`, `intellij`, `androidStudio` — MUST support equality comparison,
  hashing, enumerating all cases, and encoding/decoding, and MUST be safe to
  share across concurrent code; each case's underlying string value MUST
  equal its case name exactly (no case assigns a different explicit
  string).
- **ide-type-display-names**: The display-name lookup MUST return
  `"Xcode"`, `"Xcode Workspace"`, `"Swift Package"`, `"VS Code"`,
  `"IntelliJ IDEA"`, and `"Android Studio"` for the six cases respectively.
- **ide-type-system-images**: The icon-key lookup MUST resolve to a fixed
  icon key for each of the six cases (see Platform Notes for the exact
  icon identifiers used on Apple platforms).
- **ide-type-bundle-identifiers**: The associated-application-identifier
  lookup MUST return `"com.apple.dt.Xcode"` for `.xcode`,
  `.xcodeWorkspace`, and `.swiftPackage`; `"com.microsoft.VSCode"` for
  `.vscode`; `"com.jetbrains.intellij"` for `.intellij`; and
  `"com.google.android.studio"` for `.androidStudio` — the value is
  optional but the current six-case mapping never actually returns none
  (see Design Decisions).
- **ide-project-identity**: Each detected project's identity MUST equal its
  type's underlying string value joined to its path with a colon
  (`"<type>:<path>"`), computed on every access rather than stored.
- **ide-project-value-semantics**: A detected project value MUST be an
  immutable value type holding exactly a `type` (the IDE-type value), a
  `path` (the marker's path relative to the scanned root), and a
  `displayName`, all set once at construction; it MUST support equality
  comparison, hashing, identity lookup by its own id, encoding/decoding,
  and MUST be safe to share across concurrent code.
- **detector-published-state**: The IDE-marker detector MUST expose an
  observable `detectedIDEs` list (initially empty) and an observable
  `isDetecting` flag (initially `false`), and MUST be constructed with a
  fixed root location (see Platform Notes for the exact mechanism used on
  Apple platforms).
- **detect-guards-reentrancy**: The detect operation MUST return
  immediately without starting a scan when `isDetecting` is already
  `true`; only one scan MAY be in flight per detector instance at a time.
- **detect-offloads-scan-to-background-queue**: The detect operation MUST
  set `isDetecting` to `true` synchronously and run the scan operation off
  the UI thread, never on it (see Platform Notes for the exact mechanism
  used on Apple platforms).
- **detect-publishes-on-main-queue**: The detect operation MUST assign the
  scan's result to `detectedIDEs` and set `isDetecting` to `false` back on
  the UI thread, and MUST do nothing if the detector instance no longer
  exists by the time the scan finishes (see Platform Notes for the exact
  mechanism used on Apple platforms).
- **detect-logs-completion-summary**: On completion, the detect operation
  MUST log one info-level message reporting the result count and the
  root's last path component, then one debug-level message per detected
  project reporting its display name and path.
- **scan-visible-top-level-entries**: The scan operation MUST list the
  root's immediate visible children and pass every result to the
  marker-matching step.
- **scan-hidden-top-level-entries**: The scan operation MUST additionally
  list the root's children with no hidden-file filter, keep only entries
  whose name starts with `"."`, drop any whose path already appeared in
  the visible listing, and pass the remainder to the marker-matching step
  as well.
- **scan-recurses-one-level**: For every top-level entry that is a
  directory and is not itself an IDE marker directory, the scan operation
  MUST list that directory's contents (hidden entries included, in one
  unfiltered listing call) and pass every entry found to the
  marker-matching step. The scan operation MUST NOT descend further than
  this one level.
- **scan-excludes-marker-directories-from-recursion**: The scan operation
  MUST NOT treat a directory as a recursion target when its extension is
  `xcodeproj` or `xcworkspace`, or its name is `.vscode`, `.idea`, or
  `.git`.
- **scan-deduplicates-and-sorts-results**: The scan operation MUST remove
  any detected project whose id already appeared earlier in the
  accumulated results, then sort what remains by display name using a
  locale-aware, case-insensitive comparison in ascending order.
- **scan-top-level-read-failure-yields-empty**: When the visible top-level
  listing fails, the scan operation MUST return an empty result
  immediately — no hidden-entry listing, no depth-one recursion, and no
  error is thrown, logged, or otherwise surfaced by the scan operation
  itself.
- **scan-hidden-listing-failure-degrades**: When the second, hidden-entries
  listing fails, the scan operation MUST treat it as an empty
  hidden-entries list and continue with whatever the visible listing
  already produced, rather than aborting.
- **scan-depth-one-failure-skips-directory**: When the depth-one listing
  fails for one top-level directory, the scan operation MUST skip only
  that directory and still process the remaining top-level directories.
- **match-xcodeproj-by-extension**: The marker-matching step MUST match any
  entry whose extension (case-insensitively) is `xcodeproj` as the `xcode`
  type, with display name equal to the entry's name minus that extension,
  based solely on the extension — it MUST NOT check whether the entry is
  actually a directory.
- **match-xcworkspace-by-extension**: The marker-matching step MUST match
  any entry whose extension (case-insensitively) is `xcworkspace` as the
  `xcodeWorkspace` type, with display name equal to the entry's name minus
  that extension, UNLESS the entry's immediate parent directory's
  extension (case-insensitively) contains `"xcodeproj"` — a guard that,
  given `scan-excludes-marker-directories-from-recursion`, can never
  actually be triggered by any path the scan operation visits (see Design
  Decisions).
- **match-package-swift-file**: The marker-matching step MUST match an
  entry named exactly `Package.swift` that is not a directory as the
  `swiftPackage` type, with display name equal to that entry's parent
  directory's name.
- **match-vscode-directory**: The marker-matching step MUST match an entry
  named exactly `.vscode` that is a directory as the `vscode` type, with
  display name hardcoded to `"VS Code"`.
- **match-idea-directory-resolves-jetbrains-type**: The marker-matching
  step MUST match an entry named exactly `.idea` that is a directory by
  running the JetBrains-type heuristic and using its result both as the
  detected project's type and, via that type's display name, as the
  display name.
- **jetbrains-type-heuristic**: The JetBrains-type heuristic MUST return
  the `androidStudio` type if any entry inside `.idea` has a lowercased
  name containing the substring `"android"`, and MUST otherwise return the
  `intellij` type — including when the `.idea` directory's own contents
  cannot be listed.
- **relative-path-computation**: The relative-path computation MUST return
  the child path with the root path plus a trailing `"/"` stripped when
  the child path starts with the root path, and MUST return the child's
  full path unchanged when it does not.
- **open-logs-target-before-opening**: The open operation MUST compute the
  target location as the root joined with the project's path, and MUST log
  one info-level message naming the project's type display name and the
  target's path before attempting to open anything.
- **open-prefers-resolved-application**: The open operation MUST open the
  target location with the specific installed application that resolves
  for the project type's associated-application identifier, whenever that
  identifier is present and an installed application resolves for it (see
  Platform Notes for the exact mechanism used on Apple platforms).
- **open-falls-back-to-default-handler**: The open operation MUST fall back
  to the system's default handler for the target location whenever the
  associated-application identifier is absent or no installed application
  resolves for it (see Platform Notes for the exact mechanism used on
  Apple platforms).
- **open-bundle-path-failure-logged-only**: When the specific-application
  open path's completion callback receives an error, the open operation
  MUST log it at error level with the error's full description, and MUST
  NOT retry the open, throw, or surface the failure to a caller or the
  user by any other means.
- **language-consults-custom-mapping-first**: The language-resolution
  operation MUST skip the custom-mapping lookup entirely when the file's
  extension is empty, and otherwise MUST look up a custom mapping for the
  lowercased extension before consulting built-in detection.
- **language-resolves-mapping-by-name-or-extension**: When a custom mapping
  is found for the extension, the language-resolution operation MUST
  return the first language value in the built-in language table (in that
  table's own order) whose canonical name equals the mapping's language
  name, case-insensitively, OR whose extension list contains the mapping's
  language name, case-insensitively.
- **language-falls-back-to-builtin-detection**: The language-resolution
  operation MUST fall through to built-in detection whenever there is no
  extension, no custom mapping for the extension, or the custom mapping's
  language name matches no language value by either canonical name or
  extension list.
- **builtin-detection-is-extension-only**: The language-resolution
  operation MUST call built-in detection with no file-content sample, so
  only its filename-extension matching path can run — its shebang- and
  modeline-based matching paths, which require a content sample, are
  unreachable from this call site — and MUST return the default language
  value when even that lookup finds no match.
- **lsp-language-id-fixed-remap**: The LSP-language-id remap MUST return
  `"shellscript"` for `bash`, `"csharp"` for `cSharp`,
  `"javascriptreact"` for `jsx`, `"typescriptreact"` for `tsx`,
  `"objective-c"` for `objc`, `"plaintext"` for `plainText`, `"go.mod"` for
  `goMod`, `"ocaml.interface"` for `ocamlInterface`, and `"markdown"` for
  `markdownInline`.
- **lsp-language-id-default-passthrough**: For every language identifier
  not listed in `lsp-language-id-fixed-remap`, the LSP-language-id remap
  MUST return the language identifier's own underlying string value
  unchanged; the operation MUST be total (no throw, no absent result) over
  every language identifier.
- **lsp-language-id-single-authority**: No other code in the toolkit
  SHOULD derive an LSP `languageId` from a file extension or a
  code-language value independently of the LSP-language-id remap — per the
  operation's own documentation, it is "the single place that mapping is
  made" (see Design Decisions for why the language-server configuration
  component cannot simply call it).
- **detect-scan-failure-unsignaled**: A failed top-level directory read (**scan-top-level-read-failure-yields-empty**) and an ordinary empty, marker-free directory both produce an empty detected list with the detecting flag cleared; the detect operation exposes no failure or error state, so a caller cannot tell "the scan failed" from "the scan found nothing" (see the pending design decision on scan failure signaling).
- **open-fallback-result-unchecked**: When the open operation takes the fallback branch (no associated application identifier, or none installed), it hands the project location to the system's default handler and does not read the success indicator that call returns: a failed fallback open is not logged, retried or reported, unlike the specific-application path, whose failure is logged (**open-bundle-path-failure-logged-only**) (see the pending design decision on the fallback open result).
- **language-unresolvable-mapping-unsignaled**: The settings UI collects a custom mapping's language name as free text and checks only that it is non-empty, with no validation against the built-in language table. When that text matches no canonical language name or extension entry, **language-falls-back-to-builtin-detection** silently ignores the user's mapping: no error, log or other signal says it never took effect (see the pending design decision on unresolvable language names).
- **custom-mapping-cache-race**: The custom-mapping store's lookup cache and active defaults key are mutable shared state with no lock or other serialization. Language resolution can run on any thread, so a concurrent save (which clears the cache) racing a concurrent mapping lookup has no defined ordering (see the pending design decision on custom-mapping store synchronization).

