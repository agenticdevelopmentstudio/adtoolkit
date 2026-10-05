
**Decision**: Start with every source selected, and allow the selection to become empty.

**Rationale**: The source is documented as starting with all sources selected, toggling one adds or removes it. No minimum is enforced. The activity panel keeps the result usable by bypassing the filter when only one source exists, and by letting through rows that have no platform.

**Approved**: pending

**Decision**: The selection is in-memory only and per use, with no persistence.

**Rationale**: The source uses bare in-memory state with no storage calls, so the choice resets on reload. This differs from the sibling Environment Filter, which persists its selection to storage (on the web platform, `localStorage`). A port that adds persistence changes observable behavior.

**Approved**: pending

**Decision**: Extract the toggle into a shared concept even though only one pane uses it today.

**Rationale**: The source is documented as existing so the three panes can't drift in how they filter, naming active problems, recently resolved and activity. In the given source only the activity panel imports it, so the documentation describes the intended set of consumers, not the current one. Source Filter's own contract is unaffected.

**Approved**: pending

**Decision**: The toggle operation is not memoised.

**Rationale**: The source defines it as a plain function created on each render. Its one consumer passes it only to interaction handlers, never to a dependency list, so the changing identity has no observable effect there.

**Approved**: pending

