
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| JIT availability value's two fields, given at construction | boolean, boolean | none — both required | Used directly only by the unit tests; production code reads the process-wide cached value or probes fresh rather than constructing a value by hand. |
| Divergence catalogue entry's six fields, given at construction | string ×4, detection kind | none — all six required | Used only to define the six catalogue entries; construction is available to any caller, so an external caller MAY build an additional divergence, but no call site in this codebase does. |
| Ledger recording's count | integer | 1 | The only defaulted field across the three pieces; every other field in all three is required with no default. |
| Ledger instance (injection seam) | ledger | the shared instance, at each consumer's own call site | Consumers depend on the concrete ledger rather than an abstract interface, but direct construction lets a test or an alternate host substitute an independent ledger, as one document-sync consumer's default parameter does. |

None of the three pieces reads an environment variable or a settings key of
its own.

