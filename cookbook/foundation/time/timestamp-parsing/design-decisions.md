
**Decision**: The SQLite shape is parsed by a dedicated fixed-format reader read as UTC.
**Rationale**: The standard ISO 8601 formatter silently cannot parse the space-separated form, which is what stored rows hold, so a dedicated reader is the only way to keep one parser for all three shapes.
**Approved**: pending

**Decision**: The shared formatters are held in unchecked statics.
**Rationale**: The platform marks the ISO formatter as not safe to share even though it is safe to parse with once configured; the statics are never mutated after creation, so the opt-out is sound, and building a formatter per call would be far slower.
**Approved**: pending

