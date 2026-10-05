
- **Data handled**: The mirrored rows of every enrolled resource (arbitrary host data, MAY include personal data), the single opaque cohort cursor, the outbox of locally originated mutations, a conflicts audit, and the host-supplied device identifier.
- **Storage**: Rows, cursor, outbox and conflicts audit persist in the on-device store only; the client holds no credentials, which belong to the transport.
- **Transmission**: Pull requests and push ops (including the device identifier) leave the device only through the injected transport to the server-authoritative backend; an op for a resource outside the effective set is quarantined and never pushed, so data does not cross an enrollment boundary.
- **Retention**: Rows of a resource that leaves the effective set are purged; a resync resets the mirror and cursor but preserves the outbox; rejected and unadoptable ops are quarantined, never silently dropped.

