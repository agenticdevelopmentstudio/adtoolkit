
- **seeds-working-copy-on-mount**: The component MUST initialize its internal working note
  list from the `notes` parameter.
- **discards-staged-edits-on-close**: When `open` transitions to `false`, the component MUST
  discard any staged edits and reset the working list to the current `notes` parameter.
- **adopts-refreshed-notes-when-unedited**: While `open` is `true`, if the working list is
  unchanged from the value it was last seeded from and the `notes` parameter changes, the
  component MUST adopt the new `notes` value into the working list.
- **preserves-staged-edits-across-refresh**: While `open` is `true`, if the working list
  diverges from the value it was last seeded from (the admin has staged an add, edit, or
  delete), a change to the `notes` parameter MUST NOT overwrite the working list.
- **opens-new-note-editor-with-blank-draft**: Activating "New note" MUST open the note editor
  with an empty draft and no note selected for editing.
- **opens-edit-note-editor-seeded-with-content**: Activating "Edit" on a note MUST open the
  note editor with the draft seeded from that note's `content`.
- **rejects-blank-editor-save**: Activating Save in the note editor MUST have no effect on
  the working list and MUST leave the editor open when the trimmed draft is empty.
- **appends-new-note-on-editor-save**: Activating Save in the note editor while creating a
  note MUST append a new note to the working list with a generated `id`, the trimmed draft
  as `content`, the current `author` parameter, empty `subjectTable`/`subjectId`, and
  `addedDate`/`modifiedDate` both set to the current date.
- **updates-existing-note-on-editor-save**: Activating Save in the note editor while editing
  an existing note MUST replace only that note's `content` and `modifiedDate` in the working
  list, leaving its `id`, `author`, `addedDate`, `subjectTable`, and `subjectId` unchanged.
- **closes-editor-on-successful-save**: A non-blank editor Save MUST close the note editor
  and clear the draft.
- **discards-draft-on-editor-cancel**: Activating Cancel in the note editor, or dismissing it
  via Escape or its close control, MUST close the editor and discard the draft without
  altering the working list, and MUST NOT present a confirmation prompt.
- **removes-deleted-notes-from-working**: Confirming deletion of one or more notes MUST
  remove exactly those notes, matched by `id`, from the working list.
- **disables-editor-save-when-draft-blank**: The note editor's Save control MUST be disabled
  whenever the trimmed draft is empty.
- **computes-dirty-by-structural-comparison**: The outer Save control's enabled state MUST be
  derived from a structural, order-sensitive comparison of the working list against the
  current `notes` parameter, considering every field (`id`, `content`, `author`,
  `addedDate`, `modifiedDate`, `subjectTable`, `subjectId`) of every note.
- **disables-outer-save-when-not-dirty-or-busy**: The outer Save control MUST be disabled
  when the working list is not dirty relative to `notes`, or when `busy` is `true`.
- **submits-id-and-content-only**: Activating the outer Save control MUST call `onSave` with
  one entry per note in the working list, each entry containing only that note's `id` and
  `content`. The `id` field of each entry is declared optional in `onSave`'s input shape, but
  every entry this component submits always carries one: existing notes keep their loaded
  `id`, and notes created during this session carry the client-generated `note-`-prefixed
  `id` (see **appends-new-note-on-editor-save**). A caller distinguishes an unpersisted note
  from an existing one by testing for that `note-` prefix; the optional field exists only to
  accommodate other callers, not a case this component itself produces.
- **closes-without-confirmation**: Activating outer Cancel, or dismissing the outer dialog via
  Escape or its close control, MUST discard the staged working list and invoke `onClose`,
  regardless of whether the working list is dirty, and MUST NOT present a confirmation
  prompt.
- **ignores-busy-for-dismissal**: The `busy` parameter MUST NOT block Cancel, Escape, or
  close-control dismissal of the outer dialog; it MUST only disable the outer Save control.
- **renders-note-list-columns**: The note list MUST display each note's `author`,
  `addedDate`, and `modifiedDate` as columns headed "Author", "Added", and "Modified".
- **renders-selected-note-detail**: Selecting a single note MUST display its `content` and an
  "Edit" action that opens the note editor for that note.
- **labels-outer-dialog-title**: The outer dialog MUST display the title "Admin notes".
- **labels-editor-title-by-mode**: The note editor MUST display the title "New note" when
  creating a note and "Edit note" when editing an existing note.
- **supplies-note-list-aria-label**: The component MUST supply "Admin notes" as the note
  list's accessible label.
- **labels-note-content-field**: The note editor's text field MUST carry an accessible label
  of "Note content".
- **accepts-optional-busy-parameter**: The `busy` parameter MAY be omitted; when omitted the
  component MUST behave as though it were `false`.

