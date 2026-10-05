
Now is client-only state that returns a coarse wall-clock timestamp: a millisecond epoch value captured when a caller starts using it, then refreshed every `intervalMs` milliseconds (default `30,000`). Its purpose is a stable, per-use clock to rely on instead of reading the wall clock directly during rendering, because doing so is impure, makes "time ago" labels jump on unrelated updates, and is commonly flagged by state-hook lint rules. The periodic refresh also keeps relative-time labels ticking on their own.

Various dashboard views and the board state use the returned value for relative-time labels and staleness checks; board staleness is judged against this clock.

