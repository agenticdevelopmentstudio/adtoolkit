
- **Data collected**: The text typed into the editor — typically an LLM
  prompt, a template, or a script snippet. The component does not classify
  or redact this value; it holds it in the editor and the view model's
  committed value, and passes it through unchanged.
- **Storage**: Not applicable within this component — the value is held
  only in the editor and the view model's committed value for the
  component's lifetime. Persistence, when it happens, is owned by the
  caller-supplied view model's backing setting; unlike the secure variant's
  documented behavior, this component says nothing about routing to secure
  storage, so the default storage provider applies unless the caller's
  setting specifies otherwise — none of which is this component's own
  concern.
- **Transmission**: Not applicable within this component — no networking
  occurs here. That automatic text substitutions are disabled "because text
  gets sent to a model verbatim" describes a downstream consumer's behavior,
  not anything this component itself transmits.
- **Retention**: The value lives only in the editor and the view model's
  committed value for as long as the row is on screen and its view model is
  retained. No explicit clearing or secure-erasure is performed on the
  string; it is released with the component and its view model like any
  other property.

