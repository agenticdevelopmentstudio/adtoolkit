
- **Data collected**: None by the component itself - it only renders
  caller-supplied item/section values for display.
- **Storage**: In-memory only, for the component's lifetime; nothing is
  written to disk, a settings store, or any other store by this
  component.
- **Transmission**: Not applicable - no networking call appears anywhere
  in source.
- **Retention**: None beyond the component's lifetime; state is discarded
  when the component is deallocated.

