
- Null/empty input: An empty `notes` list MUST render the list's "No admin notes yet." empty
  label instead of a table.
- Null/empty input: An editor Save with a draft that is empty or entirely whitespace MUST be
  rejected — no note is added or changed, and the editor stays open.
- Boundary values: The note editor's text field imposes no maximum length; the component
  MUST NOT truncate or otherwise limit note content itself.
- Boundary values: The generated `id` (a `note-` prefix followed by a millisecond timestamp)
  MUST be assigned once, at editor-Save time, not at editor-open time — two notes started in
  the same session but saved at different times get distinct ids. Because the id is derived
  from a millisecond-resolution clock, two saves landing in the same millisecond collide on
  the same id; this is a known, pre-existing limitation of the source's id-generation scheme,
  not a behavior another port needs to reproduce exactly.
- Concurrent access: If another admin adds a note to the same subject while this dialog is
  open and the local admin has staged edits, outer Save drops that concurrently added note —
  the working list only ever contains what was staged locally plus the seed it started from.
  This is a documented, deliberate limitation in the source, not an oversight: it is a
  data-merge problem the component's author explicitly scoped out of the staged-copy/save-gate
  design and left as a known, pre-existing gap rather than papering over it with an unreviewed
  merge. See the matching Design Decision below ("A concurrent edit made by another admin...").
- Error states: The component defines no error parameter and no failure UI of its own. Per
  its own documentation, the caller performs the save mutation and is responsible for closing
  the dialog only on success; this component's only role during a save attempt is disabling
  the outer Save control while `busy` is `true`. A save failure MUST NOT be assumed to be
  surfaced by this component — that responsibility remains with the caller.
- Offline/disconnected: Not applicable. The component makes no network calls of its own;
  connectivity handling belongs entirely to the caller's `onSave` implementation and is not
  observable in this file.

