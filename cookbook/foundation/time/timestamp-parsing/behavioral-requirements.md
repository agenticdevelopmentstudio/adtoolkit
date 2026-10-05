
- **three-shapes**: The parser MUST accept ISO 8601 with fractional seconds and a zone designator, plain ISO 8601 with a zone designator, and the SQLite text shape `yyyy-MM-dd HH:mm:ss` interpreted as UTC.
- **try-order**: The parser MUST try the fractional ISO shape first, then the plain ISO shape, then the SQLite shape, and return the first that parses.
- **sqlite-is-utc**: The SQLite shape carries no zone and MUST be read as UTC.
- **empty-is-nothing**: Empty text MUST return nothing.
- **unparseable-is-nothing**: Text that matches none of the shapes MUST return nothing, never a default date.
- **fractional-equals-plain-plus-fraction**: A fractional ISO timestamp MUST equal the plain timestamp of the same second plus the fraction.
- **shared-formatters**: The parser MUST reuse shared, never-mutated formatter instances rather than building one per call.
- **single-parser**: Every subsystem MUST parse through this one function; no site hand-rolls its own.

