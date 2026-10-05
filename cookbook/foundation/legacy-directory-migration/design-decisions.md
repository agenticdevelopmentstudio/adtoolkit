
**Decision**: When both directories hold data the migration moves nothing and reports both exist.
**Rationale**: Merging two live databases at launch would have to guess which side wins; leaving both lets the caller use the current one and report the leftover.
**Approved**: pending

**Decision**: A non-empty placeholder is renamed aside, never deleted.
**Rationale**: The migration's guarantee is that no data is ever lost; a placeholder's contents are probably disposable, but only the user can decide that.
**Approved**: pending

**Decision**: Only an exclusive same-volume rename is used, with no copy fallback.
**Rationale**: A rename is atomic and cannot leave a half-copied directory; failing on a cross-volume move is safer than a copy that a crash could interrupt.
**Approved**: pending

