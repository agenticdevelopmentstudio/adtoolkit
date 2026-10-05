
- **confirm-declines-without-window**: A destructive confirmation requested with no window MUST log a warning and answer that the user declined.
- **confirm-shows-sheet**: With a window, a destructive confirmation MUST show a warning sheet attached to it with a destructive action button and a Cancel button, and report whether the action was chosen.
- **destructive-button-is-not-default**: The destructive button MUST NOT respond to the Return key; Return MUST press Cancel.
- **escape-cancels**: The Escape key MUST press Cancel even though the destructive button is not the default.
- **action-title-defaults-to-delete**: The destructive button's title MUST default to Delete and MAY be overridden by the caller.
- **async-confirm**: A confirmation MUST be available in a form that is awaited and returns the answer.
- **injectable-confirm**: An awaited ask MUST accept an injected confirmation closure and return its answer, so callers can be tested without UI.
- **choose-folder-is-a-sheet**: Choosing a folder MUST attach a sheet to the window and report the chosen location, or nothing if cancelled.
- **choose-folder-declines-without-window**: Choosing a folder with no window MUST report nothing.
- **folder-panel-allows-one-directory**: The folder chooser MUST allow exactly one selection and MUST allow directories only, never files.
- **report-trims-message**: Reporting an error MUST trim surrounding whitespace from the message before showing it.
- **report-without-window-logs**: Reporting an error with no window MUST log the message and show nothing.
- **report-shows-sheet**: Reporting an error with a window MUST show a warning sheet with a single OK button.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

