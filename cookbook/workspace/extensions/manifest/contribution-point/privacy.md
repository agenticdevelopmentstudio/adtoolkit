
- **Data collected**: This file carries only extension identifiers and diagnostic keys (`contributionKey`, `extensionIdentifier`); it defines no field for a credential, token, or other user-sensitive value.
- **Storage**: `ContributionPoint.swift` itself performs no storage; `ContributionRegistrations` holds its payload and notes only in memory for as long as the owning conformer keeps it. A conformer whose payload is itself persisted, user-owned state is bound by persisted-state-absence-distinction, but that persistence mechanism lives in the conformer, not in this file.
- **Transmission**: Not applicable — this file contains no networking code.
- **Retention**: Not applicable at this layer — `ContributionRegistrations`' in-memory entries live only as long as the owning conformer keeps them, and are replaced or removed by `record`/`remove` (record-replaces-existing-entry, remove-clears-payload-and-its-notes); this file defines no retention policy beyond that.

