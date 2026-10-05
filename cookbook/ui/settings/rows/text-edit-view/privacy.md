
- **Data collected**: Whatever the field's typed value is — an arbitrary
  string supplied and read by the caller through the view model. The
  component does not classify, mask, or redact this value; it displays it
  in full as plain text (unlike its secure variant) and holds it in the
  view model's committed value, passing it through unchanged.
- **Storage**: Not applicable within this component — it holds the value
  only in the text field and the view model's committed value for the
  component's lifetime. Persistence, when it happens, is owned entirely by
  the caller-supplied view model's backing setting, outside this
  component's own concern.
- **Transmission**: Not applicable — no networking occurs here. Where the
  committed value goes afterward is entirely owned by whatever consumes the
  view model's committed value.
- **Retention**: The value lives only in the text field and the view
  model's committed value for as long as the row is on screen and its view
  model is retained. No explicit zeroing or secure-erasure is performed on
  the string; the value is released along with the component and its view
  model like any other property.

