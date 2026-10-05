
- **starts-empty**: A new view MUST hold an empty record and show empty fields.
- **shows-every-field**: Assigning a record MUST show all four values in their fields.
- **load-is-not-a-change**: Assigning a record MUST NOT invoke the change callback.
- **edit-reports-whole-record**: An edit made in a field MUST update the held record and invoke the change callback once with the whole record.
- **no-validation**: The view MUST accept any text in every field, including partial or malformed values.
- **reload-spares-the-field-being-edited**: Assigning a record MUST leave a field the user is currently typing in untouched; the typed text is written into the record when the edit ends.
- **load-is-immediate**: Assigning a record MUST update the fields at once and not on a later turn.
- **revert-restores-refused-fields**: After a save is refused, reverting MUST show the stored value again in each field whose attempted value differs from it, even if that field is being edited, and MUST discard that edit.
- **revert-spares-other-fields-being-edited**: Reverting MUST treat fields whose attempted value was not refused as an ordinary load, leaving a field the user has since started editing alone.
- **fields-carry-identifiers**: Each field MUST carry an identifier made of the caller's prefix and name, email, phone or url.
- **title-is-configurable**: The card's header MUST default to Contact and MAY be set by the caller.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

