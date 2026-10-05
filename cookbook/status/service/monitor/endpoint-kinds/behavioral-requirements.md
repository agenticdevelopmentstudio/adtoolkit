
### Vocabulary

- **endpoint-kind-vocabulary**: The endpoint-kind vocabulary MUST be exactly these six distinct string literals, in this exact order: `'http'`, `'frontend'`, `'admin'`, `'health'`, `'custom'`, `'dns'`.
- **endpoint-kind-type**: The endpoint-kind type MUST be derived from the vocabulary's own elements, rather than a hand-written union maintained separately from it.
- **compile-time-immutability**: The vocabulary MUST be declared immutable, such that code MUST NOT reassign or mutate it without a type-checking error; the module MUST NOT additionally enforce this immutability at runtime, so it is enforced by the type checker only, not by the running program.

### Type Guard

- **type-guard-membership**: The membership check MUST return `true` when, and only when, its input is exactly equal to one of the six string values in the vocabulary; for any other input — a different casing, an empty string, or a string that merely contains one of the six values as a substring — it MUST return `false`.
- **type-guard-narrowing**: The membership check MUST be declared so that a call site which checks it and receives `true` has the checked value's static type narrowed to the endpoint-kind type for the remainder of that branch.
- **type-guard-synchronous**: The membership check MUST resolve synchronously via a single lookup against the vocabulary, performing no I/O and throwing for no input, including a non-string value reaching it at runtime.

### Shared Classification

- **non-deploy-kinds-reexport**: The module MUST re-export the identical non-deploy kind set from the deploy-platform engine's classifier (a read-only set of strings containing `'health'`, `'custom'`, and `'dns'`, constructed once in that engine) rather than declaring a separate set of its own, so this module, the auto-wire logic, and the engine behind `POST /auto-configure` (all external to this module) read the same object and cannot come to disagree about which kinds are deploy-backed.
- **non-deploy-kinds-type-narrowing**: The non-deploy kind set is typed as a read-only set of strings, not of endpoint kinds specifically, and nothing checks at compile time or runtime that every member of the non-deploy kind set also appears in the endpoint-kind vocabulary. Keeping the two in step is left to whoever edits them; if one changes without the other, the membership check and the "needs wiring" classification can disagree about that kind.

### Cross-File Consistency

- **vocabulary-sync-with-status-web**: This vocabulary is kept in step with the status site's separate frontend copy, so that the backend and frontend agree on the vocabulary the editor offers. That sync is done by hand: each package holds its own literal vocabulary, and no import, shared package or cross-package test ties the two together. Any edit to one has to be copied to the other in the same change.

### Side Effects

- **no-side-effects**: The module MUST perform no I/O, network call, file access, or persistence of any kind, at load time or whenever any of its exported values is used; the vocabulary, its derived type, and the membership check are pure and synchronous, and the re-exported non-deploy kind set is likewise constructed once, synchronously, with no I/O, inside the classifier.

