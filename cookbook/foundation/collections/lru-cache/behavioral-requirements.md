
- **constructor-contract**: The cache MUST be constructed with a capacity and MUST reject a capacity of zero or less as a programmer error.
- **read-marks-used**: Reading a key MUST return its value, or nothing when absent, and when present MUST mark the entry as the most recently used.
- **set-marks-used**: Storing a value MUST make that entry the most recently used, replacing any existing value for the key.
- **overflow-evicts-lru**: When a store takes the number of entries above the capacity, the cache MUST remove exactly the least recently used entry.
- **overwrite-does-not-evict**: Overwriting an existing key MUST NOT evict any other entry.
- **peek-is-not-use**: A peek and a membership check MUST report on a key without counting as a use, so a caller deciding whether to refetch does not keep that entry alive.
- **remove-and-clear**: The cache MUST support removing one key (a no-op when absent) and removing all entries.
- **count-reported**: The cache MUST report the number of entries it holds, which never exceeds the capacity after any operation completes.
- **lock-guarded**: Every operation MUST be serialized by one lock so concurrent reads and writes from different threads never corrupt the table.

