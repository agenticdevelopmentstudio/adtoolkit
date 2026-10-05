
- **no-jsvalue-capture-in-store**: the diagnostic store MUST hold only
  plain values (a URL, a diagnostic value) in its stored collection
  state; it MUST NOT store a script value or a script context.
- **no-defaulted-seams**: constructing this component MUST NOT default
  any of the store, sink, or event-emitter arguments; a caller that
  omitted one would silently disconnect that seam while still compiling,
  per the component's own documentation drawing the same comparison to
  the languages bridge's store and vocabulary arguments.
- **collection-name-collision-keeps-name-uniquifies-owner**: creating a
  collection MUST, when the requested name is non-empty and already in
  use, keep the returned name equal to the requested name while
  uniquifying only the internal owner key (e.g. `"eslint0"`), matching
  upstream VS Code, so two `createDiagnosticCollection("eslint")` calls
  both report `.name === "eslint"` yet are distinct collections.
- **collection-name-generated-when-omitted**: creating a collection MUST,
  when the requested name is empty or omitted, generate both the
  internal owner key and the returned name as
  `_generated_diagnostic_collection_name_#<n>`, where `<n>` is the shared
  id counter's current value before incrementing.
- **id-pool-shared-across-branches**: the id counter MUST be a single
  counter shared by both the name-collision case and the generated-name
  case of creating a collection, matching upstream VS Code's single
  counter, rather than one counter per case.
- **remove-collection-returns-affected-uris**: removing a collection MUST
  return every URL the removed collection held (in its stored order) and
  MUST return an empty list for an owner key the store does not contain.
- **single-uri-set-nil-is-removal**: setting diagnostics for a single
  `Uri` MUST treat an absent diagnostics argument as removing that `Uri`
  from the collection, not as storing an empty list, matching upstream
  VS Code.
- **single-uri-set-non-nil-replaces**: setting diagnostics for a single
  `Uri` MUST replace that `Uri`'s entire diagnostics list with the
  supplied list rather than appending to it.
- **single-uri-set-no-op-on-absent-owner**: `set`, `setEntries`, `delete`,
  and `clear` MUST each be a no-op returning an empty list when the owner
  key is not present in the store.
- **array-set-overload-merges-repeated-uris**: applying an entries batch
  MUST merge (append to, not replace) the diagnostics of repeated
  same-`Uri` tuples within one array-taking `set` call, per `vscode.d.ts`'s
  documented "entries are merged" contract, not last-tuple-wins.
- **array-set-overload-sorts-by-uri-string**: applying an entries batch
  MUST stable-sort the input tuples by the `Uri`'s string form (ties
  broken by original index) before processing them, matching upstream
  VS Code's own tuple comparison.
- **array-set-overload-transition-cleanup-asymmetry**: applying an
  entries batch MUST, on transitioning to a new `Uri` in the sorted
  batch, delete the *previous* `Uri` from storage if it ended up empty,
  and MUST NOT perform this cleanup for the final `Uri` of the batch
  (there is no following transition to trigger it) — this asymmetry is
  upstream's own behavior and MUST be preserved, not "fixed."
- **array-set-overload-per-uri-undefined-clears-then-appends**: within
  one entries-batch call, a tuple whose diagnostics value is absent for
  a `Uri` MUST replace that `Uri`'s accumulated diagnostics with an empty
  list at the point it is processed; a later tuple for the same `Uri` in
  the same batch MUST then append to that now-empty list rather than to
  whatever preceded the absent-value tuple.
- **delete-and-clear-are-distinct**: `delete` MUST remove only the named
  `Uri`; `clear` MUST remove every `Uri` the collection holds and reset
  its stored state to empty, returning the previously-affected order.
- **get-returns-nil-for-absent-uri**: `get` MUST return an absent value —
  not an empty list — for a `Uri` the collection does not hold, matching
  `vscode.d.ts`'s declared `readonly Diagnostic[] | undefined`,
  deliberately different from upstream's own internal storage-backed
  accessor, which returns an empty list for the same case; that raw
  accessor is upstream's internal storage layer, not the interface
  contract this store's exposed `get` must match.
- **has-checks-presence-not-emptiness**: `has` MUST return `true` for a
  `Uri` present in the collection (even with an empty diagnostics list)
  and `false` for a `Uri` not present.
- **pairs-order-is-shared-source-of-truth**: reading a collection's pairs
  MUST return `(url, diagnostics)` pairs in the collection's stored
  order, and this MUST be the same order `forEach` and `Symbol.iterator`
  both read from, so the two agree by construction.
- **cross-collection-diagnostics-for-uri-concatenates-in-creation-order**:
  reading diagnostics for one `Uri` MUST concatenate every collection's
  diagnostics for that `Uri` in collection-creation order, matching
  upstream VS Code's equivalent lookup.
- **cross-collection-all-diagnostics-merges-by-first-seen-uri**: reading
  all diagnostics with no argument MUST return every `Uri` across every
  collection in first-seen order, with diagnostics merged across every
  collection holding that `Uri`, matching upstream VS Code's no-argument
  behavior.
- **adaptor-owns-only-its-created-collections**: this component MUST
  track every owner key it created, and disposing it MUST tear down only
  those collections from a possibly-shared store, never another
  adaptor's collections.
- **disposal-flag-is-reference-typed**: each collection's disposed state
  MUST be a shared, reference-typed disposal flag, not a value captured
  independently by each closure, so that both the collection object's own
  extension-visible `dispose` method and the adaptor's own disposal can
  flip the same flag from outside each other.
- **disposed-collection-methods-are-inert-not-throwing**: once a
  collection's disposal flag is set, its `set`, `delete`, `clear`, and
  `forEach` methods MUST return `undefined` and perform no mutation and
  no sink notification; `get` MUST return `undefined`; `has` MUST return
  `false` — the seven methods MUST NOT throw, diverging from upstream
  VS Code, which throws on every method call of a disposed collection;
  precedent for quiet inertness over inventing a throw is this codebase's
  own "a disposed item ignores this call" handling for status bar items.
- **disposed-collection-symbol-iterator-yields-empty**: a disposed
  collection's `Symbol.iterator` MUST yield an empty sequence rather than
  causing a downstream failure from iterating an absent value.
- **disposed-collection-name-remains-readable**: the readonly `name`
  reader installed on a `DiagnosticCollection` object MUST continue to
  answer the collection's name — captured once at creation, not
  re-queried from the store — even after the collection's disposal flag
  is set.
- **collection-name-is-not-writable**: the `name` property MUST be
  installed as a read-only accessor with no setter, so an assignment such
  as `collection.name = 'tampered'` from extension code MUST be a silent
  no-op that does not change the value later reads see.
- **disposed-collection-stays-inert-after-name-reuse**: every method on a
  `DiagnosticCollection` object MUST check its disposal flag before its
  captured owner key is used to reach the store again; this ordering MUST
  hold even after a disposed collection's owner key has been reused by a
  later `createDiagnosticCollection` call, so a stale reference held by
  extension code cannot write into the collection now registered under
  that reused key.
- **create-diagnostic-collection-validates-name-argument**:
  `createDiagnosticCollection`'s handler MUST accept a first argument
  that is a string, `undefined`, or `null`; any other type MUST raise the
  exact message `"createDiagnosticCollection requires a string name, or
  no argument."`.
- **get-diagnostics-null-and-undefined-both-mean-no-argument**:
  `getDiagnostics`'s handler MUST treat both a `null` and an `undefined`
  (or omitted) first argument as the no-argument, all-diagnostics branch,
  matching upstream VS Code's own resource-presence dispatch; a present,
  non-`null`, non-`Uri` first argument MUST raise `"getDiagnostics
  requires a Uri, or no argument."`.
- **get-diagnostics-refuses-whole-array-on-undecodable-entry**: both
  branches of `getDiagnostics`'s handler MUST raise (`"Could not decode a
  diagnostic for this Uri."` for the resource branch, `"Could not decode
  a diagnostic entry."` for the no-argument branch) rather than return a
  silently shortened list when any diagnostic or pair fails to decode
  back into a value extension code can read.
- **collection-set-falsy-first-argument-clears**: `set`'s handler MUST,
  when the first argument is falsy under the extension-code truthiness
  rules (including `0`, `""`, `false`, `NaN`, `null`, `undefined`, or an
  omitted argument — but NOT an empty array, which is an object and
  therefore truthy), clear the whole collection, regardless of which
  overload the call otherwise resembles, matching upstream VS Code.
- **collection-set-dispatches-on-isarray**: `set`'s handler MUST dispatch
  to the array-taking overload when the (truthy) first argument is an
  array, and to the single-`Uri` overload otherwise; an argument that is
  truthy, not an array, and not decodable as a `Uri` MUST raise
  `"DiagnosticCollection.set requires a Uri, an entries array, or no
  argument."`.
- **collection-set-raises-on-invalid-entries-array**: an array first
  argument containing a tuple whose `Uri` slot or diagnostics slot fails
  to decode MUST raise `"Invalid entries passed to DiagnosticCollection.set."`,
  refusing the whole call rather than applying the entries that did
  decode.
- **collection-set-raises-on-invalid-diagnostics-array**: the
  single-`Uri` overload's second argument, when present and not
  decodable as `Diagnostic[] | undefined`, MUST raise `"Invalid
  diagnostics array passed to DiagnosticCollection.set."`.
- **collection-delete-requires-uri**: `delete`'s handler MUST raise
  `"DiagnosticCollection.delete requires a Uri."` when its first argument
  is missing or not decodable as a `Uri`.
- **collection-get-requires-uri-and-raises-on-decode-failure**: `get`'s
  handler MUST raise `"DiagnosticCollection.get requires a Uri."` for a
  missing/undecodable `Uri` argument, and MUST raise `"Could not decode a
  diagnostic for this Uri."` — not return `undefined` — when the stored
  diagnostics for an otherwise-valid `Uri` fail to re-encode.
- **collection-has-requires-uri**: `has`'s handler MUST raise
  `"DiagnosticCollection.has requires a Uri."` when its first argument is
  missing or not decodable as a `Uri`.
- **collection-foreach-requires-callable-callback**: `forEach`'s handler
  MUST validate its first argument with a callable check, MUST NOT accept
  a non-callable object such as `{}`, and MUST raise
  `"DiagnosticCollection.forEach requires a callback function."` on
  failure.
- **collection-foreach-third-argument-is-the-live-receiver-not-a-capture**:
  the collection object passed as the callback's third argument MUST be
  read from the live call-site receiver at call time, and MUST NOT be
  captured ahead of time when the method is installed, because a value
  captured at that point can be released before it is next needed,
  silently making every later `forEach` call iterate nothing.
- **collection-foreach-propagates-thrown-callback-exception**: a callback
  invocation that throws MUST cause `forEach`'s handler to propagate that
  exception and stop iteration immediately, mirroring upstream VS Code's
  plain loop that lets a thrown exception propagate rather than being
  swallowed or logged.
- **collection-foreach-decode-failure-raises-never-skips**: an entry that
  fails to decode during `forEach` MUST raise one of
  `"DiagnosticCollection.forEach could not decode the Uri of an entry."`,
  `"DiagnosticCollection.forEach could not decode a diagnostic for this
  Uri."`, or `"DiagnosticCollection.forEach could not invoke its
  callback."`, and MUST NOT skip past it, because `get`, `forEach`, and
  `Symbol.iterator` all read the same stored pair order and must fail
  consistently at the same entry rather than silently disagree on entry
  counts.
- **symbol-iterator-delegates-to-a-real-array**: `Symbol.iterator` MUST
  be installed so that it delegates to a genuine array's own iteration
  protocol built from the collection's stored pairs, rather than
  hand-writing a generator protocol.
- **symbol-iterator-agrees-with-foreach-order**: the pairs
  `Symbol.iterator` yields MUST be built from the same stored pair order
  `forEach` reads, and MUST raise `"Could not decode a diagnostic
  entry."` rather than silently shortening the sequence when an entry
  fails to decode.
- **sink-notified-on-every-mutation-with-affected-uris**: every mutating
  operation on a `DiagnosticCollection` — both `set` overloads, `delete`,
  `clear`, and the collection's own `dispose()` — MUST report to the
  diagnostic sink exactly the URLs that operation affected, whenever that
  set is non-empty.
- **sink-not-notified-on-reads**: `get`, `has`, `forEach`, and
  `Symbol.iterator` MUST NOT report to the diagnostic sink under any
  circumstance; only mutations notify.
- **sink-not-notified-on-empty-affected-set**: an empty `clear()` or an
  empty collection-level `dispose()` (no `Uri`s were actually removed)
  MUST NOT report to the diagnostic sink, diverging from upstream VS
  Code, which fires unconditionally; kept because the shared emitter is
  keyed by `Uri`, so an empty affected set contributes nothing to it
  either way.
- **ondidchangediagnostics-emitter-is-shared-and-not-defaulted**:
  building the shared `onDidChangeDiagnostics` emitter MUST take its
  window-scheduling dependency with no default, and the resulting emitter
  MUST be handed to every instance of this component and to the host
  diagnostic sink as the same shared object, matching upstream's one
  shared emitter per extension host rather than one per extension.
- **ondidchangediagnostics-delay-is-fifty-milliseconds**: the debounce
  delay MUST equal fifty milliseconds, matching upstream VS Code's own
  delay.
- **ondidchangediagnostics-merge-flattens-only**: the emitter's merge
  step MUST flatten the queued batches of URL lists into one URL list and
  MUST NOT deduplicate — deduplication is a separate, later step's
  responsibility, applied after flattening.
- **ondidchangediagnostics-dedups-by-uri-identity-not-object-identity**:
  the later deduplication step MUST deduplicate the flattened URLs by
  their string form, so two distinct `Uri` objects for the same path
  collapse to one entry in the delivered `uris` array.
- **ondidchangediagnostics-preserves-first-insertion-order**: the later
  deduplication step MUST preserve the first-insertion order of distinct
  URLs across the merged window, never re-sorting.
- **ondidchangediagnostics-uris-array-is-frozen**: the `uris` array on
  the delivered `{ uris }` event object MUST be frozen, so extension code
  cannot mutate it in a way that is visible to another listener or to the
  next window.
- **ondidchangediagnostics-refuses-whole-event-on-bad-uri**: building the
  delivered event MUST fail for the entire event — not a `uris` array
  silently missing one entry — if any URL fails to convert into a value
  extension code can read.
- **ondidchangediagnostics-is-a-call-signature-member-that-raises-on-teardown**:
  `onDidChangeDiagnostics` MUST be published as a call-signature member
  that raises — rather than resolving a promise — when the owning adaptor
  has been deallocated, matching `vscode.d.ts`'s `Event<T>` call-signature
  declaration, because the member answers a `Disposable` synchronously
  rather than a `Thenable`.
- **dispose-marks-disposal-flags-before-removing-from-store**: disposing
  this component MUST set every owned collection's disposal flag as part
  of the same step that removes it from the store, and this ordering MUST
  be treated as load-bearing — omitting it would leave a
  `DiagnosticCollection` object already handed to still-live extension
  code reading itself as not disposed forever, letting a stale reference
  write diagnostics into whatever collection a later
  `createDiagnosticCollection` call reused that owner key for.
- **dispose-notifies-sink-per-nonempty-removed-collection**: disposing
  this component MUST report to the diagnostic sink once per owned
  collection whose removal affected a non-empty set of URLs, and MUST NOT
  report for a collection that had none.
- **dispose-removes-only-this-adaptors-own-event-listeners**: disposing
  this component MUST remove only this adaptor's own
  `onDidChangeDiagnostics` listener registrations from the (possibly
  shared) emitter, never another adaptor's.
- **weak-capture-of-adaptor-strong-capture-of-disposal-flag**: every
  method installed on a `DiagnosticCollection` object MUST hold this
  component only weakly and MUST hold its disposal flag strongly; the installed methods MUST NOT hold the extension-visible collection object
  itself, not even weakly.
- **loggable-conformance**: this component MUST publish log messages
  through the same shared logging seam every other extension-bridge
  component uses.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

