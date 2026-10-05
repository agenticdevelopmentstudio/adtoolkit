
**Decision**: Change delivery is deferred by one main-queue turn, so a read immediately after a write sees the new value but the callback has not yet fired.
**Rationale**: Deferring lets a write made during a tracking loop finish before views redraw; the cost is that a caller cannot rely on the callback having run when the write returns. A synchronous mode would need a second contract.
**Approved**: pending

**Decision**: The observer holds a single change callback slot, so only one listener is supported.
**Rationale**: Settings views each own their observer, so one slot has been enough; supporting several listeners would need a subscription list and an unsubscribe path.
**Approved**: pending

