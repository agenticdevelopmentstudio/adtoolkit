
- **Data collected**: The field's typed value — potentially a secret
  (e.g. a token or password) when `model.request.isPassword` is `true`,
  in which case the secure field masks it on screen. The component does
  not otherwise classify or redact this value; it holds it in
  `model.value` and returns it verbatim via `onAccept`.
- **Storage**: Not applicable — the component and its model hold the
  value only in memory for the panel's lifetime; no write to disk,
  preference storage, or any other persistent store is part of this
  component.
- **Transmission**: Not applicable within this component — the accepted
  value is handed to the caller-supplied `onAccept` callback; this
  component performs no networking itself. Where that value goes
  afterward (back across the extension-host bridge to the requesting
  extension) is owned by the presenter/the VS Code API bridge above it,
  not by this component.
- **Retention**: The value lives only in `model.value` and the field's own
  text for as long as the panel is on screen. No explicit zeroing or
  secure-erasure of the string happens; the value is simply released
  along with the component and its model when the panel closes.

