
- **Data collected**: None beyond what the caller already supplies. The component holds the message list handed to it by the view model and its own transient UI state (the expanded-message set, the selected-message id, the last-rebuilt transcript width, the cached render inputs); it originates no data of its own.
- **Storage**: In-memory only, for the lifetime of the component instance; nothing in this source persists to disk.
- **Transmission**: None. The component performs no networking; sending a message delegates entirely to the view model.
- **Retention**: The component's transient selection/expansion state is discarded when the component is deallocated; message content retention is the view model/session's concern, not the component's.

