
- **Data collected**: None of its own. The component holds only the file-location input it is given; it neither reads the file's bytes directly (the native preview control does that) nor collects anything else.
- **Storage**: Not applicable — the source performs no read or write of its own beyond handing the file location to the native preview control, which reads and renders the file itself.
- **Transmission**: Not applicable — no networking call appears anywhere in this file; preview rendering is entirely local to the device.
- **Retention**: Not applicable beyond the view's own lifetime — the only retained value is the file-location input, held for as long as the view exists; removal from the view hierarchy releases the preview-generation process (see **closes-preview-view-on-dismantle**) rather than retaining it past the view's lifetime.

