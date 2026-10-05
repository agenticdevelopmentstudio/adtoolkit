
- **holds-the-record**: The panel MUST hold the record it was created with and
  expose it read-only to callers; only adopt and commit change it.
- **title-from-record**: The panel's sidebar title MUST equal the record's title
  when it is created.
- **commit-reports-a-real-edit**: Committing an edited record that differs from
  the held record MUST store it as the held record, update the sidebar title to
  match, and report it through the save callback exactly once.
- **commit-ignores-no-change**: Committing a record equal to the held record
  MUST NOT report anything and MUST NOT change the title, so a field that ends
  editing on the value it began with sends no write.
- **adopt-stores-without-saving**: Adopting a record MUST replace the held
  record and update the sidebar title, and MUST NOT report through the save
  callback.
- **title-set-only-when-different**: The panel MUST assign the sidebar title
  only when it differs from the record's title, so an unchanged title causes no
  sidebar update.
- **focus-name-selects-the-name-field**: Focusing the name MUST put the cursor in
  the name field with its text selected, and MUST do nothing when the pane's
  view is not yet loaded or the pane names no name field.
- **no-name-field-by-default**: A pane that does not name a name field MUST
  have none, so focusing the name is a no-op for it.
- **never-persists**: The panel MUST NOT write the record to storage or a
  service; persistence is the owner's, reached only through the save callback.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

