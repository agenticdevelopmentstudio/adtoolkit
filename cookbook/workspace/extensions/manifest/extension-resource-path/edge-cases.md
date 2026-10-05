
- **Null/empty declared path — the directory itself**: a declared value of
  `"."` resolves, before the containment check, to the directory itself;
  the containment check then refuses it because the directory is not
  strictly below itself, so resolving the path fails with the escape error
  rather than handing a caller the directory to open as if it were a file.
  This is the exact case the containment check's own design guards
  against. MUST.
- **Boundary — exactly at the root versus one hop beyond it**: a declared
  path that climbs exactly to `root` (for example `"../base.json"` from a
  `themes/` folder one level below `root`) resolves and succeeds; the same
  path climbing one directory further (`"../../base.json"`) fails with the
  escape error. The boundary is the root directory itself, inclusive on the
  "still inside" side only in the sense that any path strictly below
  `root` succeeds. MUST.
- **Symlink escape with no literal `..` in the declared string**: a
  declared path containing no `..` at all can still escape if a symlink
  planted inside the extension's own directory points outside it; symlink
  resolution on the candidate resolves that symlink to its real target
  before the containment check runs, so the escape is caught even though
  nothing about the declared string itself was suspicious. MUST.
- **Concurrent access**: this component, the escape error, and the
  installed-content-location helper hold no mutable stored state — every
  entry point is a pure function over its arguments — so calling any of
  them concurrently, from any thread or concurrency domain, against the
  same or different directories, requires no synchronization. MUST.
- **Error states**: the only defined failure is the escape error, raised
  once, synchronously, by the resolve operation. Composing the
  application-support location communicates its one "nothing to name" case
  by returning absent, never by failing outright; a caller that ignores an
  absent result (no production caller does today) silently proceeds with
  one fewer search path rather than crashing. Stated as fact, not a
  marker — this component defines no other error condition.
- **Offline / disconnected state**: not applicable. Every operation reads
  only the local file system's symlink structure; there is no networking
  and therefore no connectivity state to lose mid-operation.
- **Cancellation and timeout**: the resolve operation, canonicalizing a
  directory, and deriving a not-yet-existing child location define no
  timeout and no cancellation, because every call is synchronous local
  file-system metadata access with no concurrency-deferred entry point. A
  slow or unresponsive mount underneath the directory being resolved blocks
  the caller for as long as symlink resolution takes, with no escape hatch
  defined in this component. Stated as fact, per the absent-feature rule —
  not a marker, since nothing in the purpose of a synchronous path resolver
  calls for one.
- **Unvalidated caller inputs beyond `appName`**: composing the home
  dotfolder location takes the folder's name at face value; the dotless
  convention exists so that "these are hidden folders" is a property of
  this function rather than of each caller's string literal, but the
  function does not verify the name omits a leading dot or a path
  separator — every caller today already passes a plain identifier such as
  `"agenticplugins"`, so this is a fact about the function's contract
  rather than an observed failure.

