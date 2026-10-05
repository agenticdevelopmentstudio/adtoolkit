
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `reply` | `String` | `"This is a mock reply."` | The full assistant reply text streamed back for every turn, regardless of what the caller sends. |
| `chunkSize` | `Int` | `3` | The number of `Character`s per `.responseDelta` chunk. A value at or below `0` yields the whole reply as one chunk. |
| `interChunkDelay` | `Duration` | `.milliseconds(10)` | The delay awaited between successive `.responseDelta` chunks. |

This component defines no environment variable and no settings key of its own — every value it operates on arrives as one of the three constructor parameters above.

