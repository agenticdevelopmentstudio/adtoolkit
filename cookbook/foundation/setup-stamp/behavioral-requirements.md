
- **missing-needs-setup**: Setup MUST be reported as needed when the stamp file is missing or cannot be read as UTF-8 text.
- **equal-version-no-setup**: Setup MUST NOT be reported as needed when the recorded version, trimmed of whitespace and newlines, equals the running bundle version exactly.
- **any-difference-needs-setup**: Setup MUST be reported as needed for any difference between the recorded and running versions, whether older or newer.
- **whitespace-ignored**: Leading and trailing whitespace and newlines in the stamp file MUST be ignored when comparing.
- **record-writes-version**: Recording MUST write the bundle version as UTF-8 text to the stamp file, atomically, and MUST create the stamp file's parent directory, with intermediate directories, when it does not exist.
- **record-propagates-errors**: Recording MUST propagate a directory-creation or write failure to the caller rather than swallowing it.
- **default-location**: The default stamp location MUST be a file named `last-setup-version` inside a directory named by the caller, inside the user's application support directory.

