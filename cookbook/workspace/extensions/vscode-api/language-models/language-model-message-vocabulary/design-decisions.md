
**Decision**: All eight members are constructed inside one evaluated unit rather than eight independent evaluations, one per member.
**Rationale**: `LanguageModelChatMessage`'s `content` setter constructs a `LanguageModelTextPart`, and `LanguageModelDataPart.json`/`.text` construct a `LanguageModelDataPart` through the shared `utf8EncodeToUint8Array` function; all three need to see each other as ordinary lexical bindings inside the same closure rather than re-finding one another off the global scope on every call, which would also reintroduce the exact per-call re-lookup cost the single-cached-container pattern (shared with the Uri installer) exists to avoid. On Apple platforms this is implemented as one evaluated IIFE rather than eight independent `evaluateScript` calls.
**Approved**: pending

**Decision**: `LanguageModelDataPart.image` applies no default `mime` when the argument is omitted, while `.json` and `.text` both default theirs.
**Rationale**: not stated in the source's comments beyond the line-by-line `vscode.d.ts`/`extHostTypes.ts` citations for the file as a whole; there is no single natural default MIME type for arbitrary image bytes the way `'text/x-json'` and `'text/plain'` serve `.json`/`.text`, and the given sources include no upstream citation specific to `.image`'s own default behavior. This recipe states the observed behavior — no default is applied — as a requirement (**data-part-image-factory**) rather than inferring a rationale the source does not give.
**Approved**: pending

**Decision**: a present-but-malformed value is never checked by any of the eight members' constructors — `input`, `content`, `data`, and `value` are all stored exactly as given, with no rejection path anywhere in this component, unlike the validating constructors in the diagnostic types component.
**Rationale**: matches `extHostTypes.ts`'s own implementation for these eight declarations, none of which validates its constructor arguments (only `Diagnostic` and `DiagnosticRelatedInformation`, in a different file, do). Adding validation here that upstream does not have would diverge from the vocabulary this component exists to mirror.
**Approved**: pending

