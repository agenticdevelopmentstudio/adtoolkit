
- **Null/empty input**: The view model's `title` as an empty string produces a button with an empty title and no crash (see button-view-002). The view model's `wasPressedCallback` unset is the default, documented case (see **takes-no-action-without-callback**).
- **Boundary values**: Not applicable — the only enumerated input, placement, is a closed three-option set with no numeric range, so there is no minimum/maximum boundary to exercise.
- **Concurrent access**: Not applicable — the component is confined to the UI thread, so all construction and mutation is serialized to that thread (see **confines-to-ui-thread**).
- **Error states**: Not applicable — the component has no dependency on network, database, or file-system access. Its only external interaction is invoking the view model's `wasPressedCallback`, whose error handling, if any, is the caller's responsibility inside that callback, not something the component observes or handles.
- **Offline/disconnected state**: Not applicable — the component performs no networking.
- **Very long title**: The component sets no line-break or truncation mode on the button; if the title is wider than the space the active placement leaves available, the platform button's own default single-line truncation behavior applies unmodified by this component.

