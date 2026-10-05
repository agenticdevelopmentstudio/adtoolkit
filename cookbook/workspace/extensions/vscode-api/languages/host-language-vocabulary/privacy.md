
- **Data collected**: none beyond what the contribution point already
  holds. The only data this component reads is language identifiers —
  either the built-in language catalogue or identifiers already extracted
  from installed extensions' manifests — never device- or user-identifying
  data.
- **Storage**: none. This component stores only a reference to the
  contribution point it was constructed with; it writes nothing to disk
  itself.
- **Transmission**: none. This component performs no networking.
- **Retention**: for the lifetime of this component's instance and the
  contribution-point reference it holds; releasing either releases the
  data with it.

