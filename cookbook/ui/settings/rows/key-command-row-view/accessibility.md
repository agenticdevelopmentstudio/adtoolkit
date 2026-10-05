
- **Role/trait**: This component sets no accessibility role on itself.
  The toggle keeps the platform's native switch role via
  **links-toggle-accessibility-title**. The capture field's own role belongs
  to its component; see `adtoolkit://cookbook/ui/controls/key-command-capture-field`,
  which records the open question.
- **Label requirements**: The toggle's accessible name comes from the title
  label via **links-toggle-accessibility-title**. The capture field is given
  only an accessibility *identifier*
  (`"settings.key-commands.<id>.recorder"`, a UI-test hook) and no
  accessibility *label* or title-element link to the title label; whether a
  screen reader announces it meaningfully depends on the platform's default
  exposure of its internal, unlabeled text field, which neither this file
  nor the capture field's own source configures explicitly.
- **Announce state changes (e.g., loading, disabled)**: A refusal or an
  availability change updates the status label's text and color role
  synchronously, but no call in source posts an accessibility announcement.
  A sighted user sees the refusal appear immediately next to the switch; a
  screen-reader user gets no announcement of it from this file.
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-driven
  composition with no touch input path in source; the 44×44pt minimum is
  touch guidance. This component sets no non-default control size on the
  toggle, so it keeps the platform's regular system click-target metrics.

