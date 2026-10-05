
- **load-skips-a-field-being-edited**: A refresh of a single-line text field
  MUST leave the field unchanged while the user is editing it.
- **load-skips-an-unchanged-field**: A refresh of a single-line text field MUST
  NOT assign the field's text when it already equals the stored value.
- **load-replaces-an-idle-field**: A refresh of a single-line text field that is
  not being edited and whose text differs MUST replace the text with the
  stored value.
- **force-discards-an-edit-in-progress**: A forced revert of a single-line text
  field MUST end the field's edit session without committing it, so that no
  later end-of-edit can send the discarded text.
- **force-replaces-a-differing-field**: A forced revert of a single-line text
  field MUST set the text to the stored value when it differs.
- **load-skips-a-focused-multiline-view**: A refresh of a multi-line text view
  MUST leave the view unchanged while it holds keyboard focus, and MUST NOT
  assign its text when it already equals the stored value.
- **force-replaces-a-multiline-view**: A forced revert of a multi-line text
  view MUST set its text to the stored value when it differs, whatever is
  being typed.
- **select-matches-by-represented-value**: Selecting a value in a pop-up
  control MUST choose the item whose represented value equals the given value,
  and MUST NOT match by item title, because two records can share a title.
- **select-with-no-match-clears-selection**: Selecting a value that no pop-up
  item represents MUST leave the control with no selected item.
- **select-skips-an-unchanged-selection**: Selecting a value MUST NOT change
  the control when the matching item is already the selected one.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

