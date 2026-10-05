
- **Decision**: `enableForms` defaults to whatever `enableScripts` resolved to, rather than defaulting independently to `false`.
  **Rationale**: the source's own doc comment and the test suite's comment agree on why: a scripted page that cannot submit a form fails in a way its author cannot see — "the click does nothing and the console says only that a content policy refused it" — so the safer silent default is the one that keeps forms working wherever scripts already do.
  **Approved**: pending
- **Decision**: `declaredLocalResourceRoots` preserves the distinction between an absent declaration (`nil`) and an explicit, empty one (`[]`), rather than collapsing both into the same default root list.
  **Rationale**: the source's doc comment states the consequence of collapsing them directly — it would hand a panel that deliberately renounced file access the whole workspace instead of honoring what it asked for.
  **Approved**: pending
- **Decision**: the five upstream `WebviewOptions` fields this type omits (`retainContextWhenHidden`, `enableFindWidget`, `enableCommandUris`, `portMapping`, `iconPath`) are not represented anywhere on the type — not even as an ignored or always-`true` stored property.
  **Rationale**: the header comment gives each a distinct reason: `retainContextWhenHidden` is already permanently true of every pane here, so a field whose only honest implementation is "already true" is one nothing may read; `enableFindWidget` names a widget with no implementation to enable; `enableCommandUris` and `portMapping` are real, unbuilt capabilities tracked by `NotImplementedLedger` rather than by a flag nothing honors; and `iconPath` is pane chrome answered by the panel's own title, not by this type.
  **Approved**: pending
- **Decision**: `contentSecurityPolicy` names only `object-src`, `base-uri`, `form-action`, and `frame-ancestors`, and never touches `script-src`, `style-src`, `img-src`, or `connect-src`.
  **Rationale**: the source's comment explains that a real policy on those four directives would either be permissive theatre (`'unsafe-inline'`) to avoid breaking every extension page, or strict enough to break pages whose own CSP nonce this host's policy cannot know about; the four directives that are named are the ones "no webview gives up anything by losing," matching how VS Code itself leaves the content policy to the extension's own page.
  **Approved**: pending
- **Decision**: resolving `localResourceRoots` into a candidate list (this type's job) is kept separate from enforcing that a requested resource actually stays inside those roots (a different file's job, `WebviewResourceURL`/`ExtensionResourcePath`).
  **Rationale**: the source's own comment on `declaredLocalResourceRoots` states this plainly — resolving roots into the containment boundary needs the owning extension's directory, "which no struct here knows" — so this type only computes the candidate list, and the escape/containment check happens downstream, at request time, in a component that does have that context.
  **Approved**: pending
- **Decision**: two initializers exist — an as-declared one that derives `enableForms`'s default from `enableScripts`, and a resolved-form one (used by `Decodable` and by tests) that assigns all three values straight through with no derivation.
  **Rationale**: the source's comment on the resolved-form initializer states the reason directly: "a restored panel must come back with the answer the panel actually had," so decoding routes through straight assignment rather than back through the as-declared initializer's derivation, which would silently re-derive a stored `enableForms` from a possibly different `enableScripts` if it were ever fed already-resolved values instead of raw ones.
  **Approved**: pending

