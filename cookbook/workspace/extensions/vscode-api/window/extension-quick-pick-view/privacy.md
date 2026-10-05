
- **Data collected**: Not applicable — the component collects no data of
  its own; it renders the title/placeholder/item text the caller supplied
  in `ExtensionQuickPickRequest` and reports back selected indices through
  `onAccept`/`onHighlight`.
- **Storage**: Not applicable — no read/write to disk or any other store
  occurs anywhere in this component.
- **Transmission**: Not applicable — no networking call appears anywhere
  in this component; how the originating request
  reached the host process is outside this component's scope.
- **Retention**: Not applicable — the component retains only its own
  subviews and its `model` reference for its own lifetime; it persists
  nothing beyond that.

