
Not applicable — this is the Buckets domain's data-access protocol, data
shapes, and navigation/forms logic, not a visual component. The one
runtime state distinction this file makes — a bucket being built-in
(`kind != "custom"`) versus custom, which gates whether its settings form
exposes a delete action — is captured above as a requirement
(`bucket-is-built-in-derivation`, `settings-form-delete-gated-by-built-in`),
not in a visual-state table.

