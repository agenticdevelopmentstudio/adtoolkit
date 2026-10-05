
- **Decision**: A section is hidden entirely when its seed list is empty.
  **Rationale**: An email-only batch should not present an empty SMS section.
  **Approved**: pending

- **Decision**: Each section carries its own admin-note box.
  **Rationale**: Email and SMS messages differ enough in tone and length — SMS favors brevity — that a shared note would force a compromise; the component tracks `emailNote` and `smsNote` as independent state so each channel's message can be written separately.
  **Approved**: pending

- **Decision**: Recipients render read-only in this modal.
  **Rationale**: They are seeded from a selection the caller already made elsewhere (e.g. picking pending users), which the backend keys the invite off of; letting an admin edit them here would let the invite diverge from what was actually selected.
  **Approved**: pending

- **Decision**: Discard confirmation depends only on whether a note has been typed — pre-seeded recipients alone do not count as "populated".
  **Rationale**: Recipients are read-only and always present when a section renders, so treating them as populated would force a confirm on every single Cancel; only user-entered note text represents work that could be lost.
  **Approved**: pending

- **Decision**: Enter never triggers Send.
  **Rationale**: The note field is a multi-line `Textarea` where Enter must insert a newline, so Send requires an explicit activation of the Send control rather than an implicit keyboard submit.
  **Approved**: pending

