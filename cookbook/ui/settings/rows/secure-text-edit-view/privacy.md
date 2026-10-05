
- **Data collected**: The field's typed value — per the source's own doc
  comment, typically a secret such as an API key or password — which the
  platform's secure field masks on screen as it is typed. The component
  does not otherwise classify or redact this value; it holds it in the
  view model's value and passes it through unchanged (see
  `adtoolkit://cookbook/ui/settings/rows/text-edit-view#privacy` for
  the storage, transmission, and retention behavior this shares with the
  text edit row, which applies to whatever string value either component
  holds).
- **Storage**: Not applicable within this component's own source itself —
  persistence, when it happens, is owned by the caller-supplied view
  model's backing setting: the settings store routes a setting with
  secure storage enabled to a secure storage provider (a keychain-backed
  one, by default) — this is the reason the source recommends this view
  for secrets, but none of it is code in this component's own source
  itself.
- **Transmission**: Not applicable — no networking call appears anywhere
  in this component's own source or the text edit row behavior it
  inherits.
- **Retention**: Inherited unmodified from the text edit row — the value
  lives only in the field and the view model's value for as long as the
  row is on screen and its view model is retained; see
  `adtoolkit://cookbook/ui/settings/rows/text-edit-view#privacy`.
- **Security-violation handling**: Not applicable — this component has no
  detection surface of its own (no validation, rate-limiting, or
  authentication logic); it only masks on-screen glyphs. Any
  violation-handling behavior belongs to whatever storage/auth layer the
  caller's setting is wired to, outside these two files.

