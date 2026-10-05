
- **Null/empty input — empty root directory.** The scan operation on a root
  with zero entries MUST return an empty result without error, via the
  same path as any other empty result. MUST.
- **Null/empty input — empty file extension.** The language-resolution
  operation on a URL whose extension is empty MUST skip the custom-mapping
  lookup entirely and go straight to built-in detection. MUST.
- **Null/empty input — empty project path.** The open operation with an
  empty project path MUST resolve the target location to the root location
  itself (appending an empty path component is a no-op) and proceed
  exactly as with any other path. MUST.
- **Boundary values — recursion depth.** A marker two or more directories
  below the root (e.g. `a/b/Package.swift`) MUST NOT be found —
  `scan-recurses-one-level` bounds recursion to exactly one level. MUST.
  There is no other numeric or length boundary in either component: path
  and extension strings are unbounded.
- **Concurrent access — within one detector instance.** Overlapping
  detect-operation calls on the same instance MUST be serialized to at
  most one in-flight scan by the `isDetecting` guard
  (`detect-guards-reentrancy`). MUST.
- **Concurrent access — across detector instances.** The scan operation
  and its helpers touch only their own arguments and the file system, so
  concurrent scans on different roots from different instances MUST be
  safe with no shared mutable state between them. MUST.
- **Concurrent access — language detection and the custom-mapping store.**
  Unlike the IDE-marker detector, this path has no defined ordering: see
  `custom-mapping-cache-race` above and its pending design decision.
- **Error states — unreadable directory at any scanned level.** Every
  directory-listing call in the scan operation, the marker-matching step,
  and the JetBrains-type heuristic tolerates a failure without throwing
  out to the caller. The observable degradation differs by call site —
  whole-scan abort, hidden-entries-only drop, single-directory skip, or an
  `intellij` default — as detailed in the three `scan-*-failure-*`
  requirements and `jetbrains-type-heuristic`. MUST.
- **Error states — application-open failure.** The specific-application
  path logs and swallows the error (`open-bundle-path-failure-logged-only`,
  MUST); the fallback path swallows it with no signal at all
  (`open-fallback-result-unchecked`).
- **Offline/disconnected: not applicable.** Neither the IDE-marker
  detector nor the language-detection component performs any network
  I/O — every operation is a local file-system read or a local
  application-launch call.

