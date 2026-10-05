
This is a controlled dialog for reviewing and editing an admin's freeform notes about some
subject. The caller supplies the already-loaded `notes` and a save callback; the component
seeds a private staged working copy from `notes`, lets the admin add, edit, and delete notes
against that staged copy through a list-with-details pane and a nested note editor, and only
reports the result to the caller when Save is activated. Fetching and the actual persistence
write live in the caller, never in this component. The "New note" control is supplied to the
list-with-details pane as one of its actions; the list-with-details pane renders it and owns
its placement — see `agenticdevelopertoolkit://recipes/list-with-details-pane`.

A note record is used here with exactly seven fields: `id`, `content`, `author`,
`addedDate`, `modifiedDate`, `subjectTable`, and `subjectId`, all strings. `addedDate` and
`modifiedDate` are ISO 8601 calendar dates in `YYYY-MM-DD` form.

