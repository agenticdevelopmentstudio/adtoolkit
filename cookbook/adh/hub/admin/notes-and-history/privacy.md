
- **Data collected**: Not applicable: the component collects no data of its
  own; `content`, `author`, `actor`, and other fields it displays are
  already-fetched parameters supplied by the caller.
- **Storage**: Not applicable: no read/write to any storage occurs — the
  component holds no state beyond what is needed to render its
  parameters.
- **Transmission**: Not applicable: no network request is issued (see
  no-internal-data-fetching); nothing leaves the device from this
  component.
- **Retention**: Not applicable: the component retains nothing after it
  unmounts or re-renders with new parameters.

