
**Decision**: A refresh and a forced revert are separate operations rather than one operation with a flag.
**Rationale**: The source's doc comment distinguishes them by intent: `load` is for a poll that must never replace what is being typed, and `force` is for a refused save where the text in the field is exactly what failed; separate names keep a call site from choosing the wrong policy by accident.
**Approved**: pending

**Decision**: A forced revert of a text field aborts its edit session, while a forced revert of a multi-line text view only assigns its text.
**Rationale**: The source calls `abortEditing()` for the single-line field so that ending the edit later cannot send the refused text again; for the multi-line view it only replaces `string`, and no code there ends the edit, so a later end-of-edit notification would still carry whatever the view then holds, which is the stored value.
**Approved**: pending

**Decision**: Pop-up selection matches by represented value, never by title.
**Rationale**: The source's comment states that two records can share a title, and a test (`selectPicksByRepresentedValueNotTitle`) builds two items with the same title to prove the second is selectable.
**Approved**: pending

