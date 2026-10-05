
**Decision**: The panel reports edits through one callback and never writes the record itself.
**Rationale**: The source's doc comment says a refused save is then handled once, by the window's owner, rather than once per field; the cost is that every owner must wire the callback.
**Approved**: pending

**Decision**: Commit compares the edited record with the held one and sends nothing when they are equal.
**Rationale**: The source guards on inequality so a field that ends editing on the value it began with sends no write; this requires the record type to be comparable for equality.
**Approved**: pending

**Decision**: Adopt exists separately from commit so a refresh from storage can retitle the sidebar without reporting a save.
**Rationale**: The source documents adopt as taking current stored values without saving, called first by a subclass's apply before it refreshes its fields.
**Approved**: pending

