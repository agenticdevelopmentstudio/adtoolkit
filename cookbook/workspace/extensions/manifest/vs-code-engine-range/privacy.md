
- **Data collected**: none beyond what the caller already supplied. The
  only data `VSCodeEngineRange` reads is the `engines.vscode` string from a
  caller-supplied manifest — third-party, extension-author-published text,
  never device- or user-identifying data.
- **Storage**: none. A `VSCodeEngineRange` value is held only in memory for
  the lifetime the caller keeps it; nothing is written to disk by this
  component.
- **Transmission**: none. This component performs no networking.
- **Retention**: for the lifetime of the `VSCodeEngineRange` value the
  caller holds; releasing the value releases the data with it.

