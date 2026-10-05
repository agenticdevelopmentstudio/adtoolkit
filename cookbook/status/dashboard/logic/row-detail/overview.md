
This logic turns one status-board row (specified in [Status Row Model](adtoolkit://cookbook/status/dashboard/logic/row-model)) into the fields the details pane shows for a selected row, and turns those fields into plaintext for the pane's "copy" button. Its callers are the activity panel view and the activity details view.

It provides one data shape and two pure functions:

- **The row detail** is the shape of labeled, nullable fields the details pane renders.
- **The detail-building function** maps a row to a row detail. Its documented intent is that it "mirrors the row's own link derivations so the row and the details pane always agree on titles/links", and it renders the status word exactly as the server sent it.
- **The serialization function** turns a row detail into "a clean, labeled plaintext block" so "the whole problem ... can be pasted straight into an LLM without opening the provider dashboard".

This logic depends on a host-extraction helper, which returns a URL's host or the input unchanged when parsing fails, and on the platform label function specified in [Deploy Display](adtoolkit://cookbook/status/dashboard/logic/deploy-display). It has no state, no I/O and no side effects.

