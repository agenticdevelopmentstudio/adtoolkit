
**Decision**: Any version difference triggers setup, including a downgrade.
**Rationale**: A downgraded bundle may expect an older layout around it just as an upgraded one expects a newer one, so equality is the only safe skip.
**Approved**: pending

**Decision**: A read failure is treated as setup needed.
**Rationale**: An unreadable stamp cannot prove setup completed; re-running idempotent setup is cheaper than skipping a required one.
**Approved**: pending

