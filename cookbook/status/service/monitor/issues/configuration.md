
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Storage (input to the ledger read and the apply operation) | the storage port | none — caller-supplied | The persistence port this module writes through; every call in this module reaches storage exclusively via the storage port's issues operations. This module never constructs or configures a storage implementation itself. |
| Board (input to the apply operation) | the board shape | none — caller-supplied | The derived verdict to record — produced by the board-derivation logic from board facts, external to this module, and passed in unchanged by the board-reconciliation operation. |

This module reads no environment variable and defines no module-level constant of its own; every configurable value (the alert webhook URL, retention windows, probe cadence) belongs to modules external to this one.

