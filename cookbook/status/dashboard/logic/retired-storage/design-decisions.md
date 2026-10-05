
**Decision**: Purge a named allow-list of retired keys instead of clearing storage.
**Rationale**: The app still stores live preferences such as `adh-font-scale`, `adh-env-filter` and `adh-healthy-ttl`. A wipe would destroy them. The test "leaves keys the app still uses alone" pins this.
**Approved**: pending

**Decision**: Swallow every storage exception silently, per key.
**Rationale**: The doc comment says "There is nothing to recover if it fails, and it must never be able to break the board's mount." A leftover dead blob is harmless to the current build, which never reads it. A throw during mount would break the board.
**Approved**: pending

**Decision**: Keep the purge in client code instead of relying on a server fix.
**Rationale**: The phantom `hub-help-testing` problem lived only in one tab's `adh-activity-v1` key, so no server-side change could clear it. Only code running in that browser can delete the key.
**Approved**: pending

**Decision**: Run the purge on every call instead of recording that it has run.
**Rationale**: Removing a missing key costs nothing and is idempotent. A "done" marker would itself be another storage key to retire later.
**Approved**: pending

