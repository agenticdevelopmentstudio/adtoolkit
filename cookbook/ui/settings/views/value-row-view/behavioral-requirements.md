
- **shows-title-and-value**: The row MUST show the title it was built with and the initial value.
- **value-is-settable**: The row MUST expose its value as a property that reads the text on screen and replaces it when assigned.
- **value-is-read-only-to-user**: The user MUST NOT be able to edit the value.
- **value-is-selectable**: The user MUST be able to select the value text for copying.
- **value-is-right-aligned**: The value MUST be right-aligned.
- **value-uses-monospaced-digits**: The value MUST use monospaced digits.
- **value-is-labelled-by-title**: The value MUST expose the row's title as its accessibility label, so assistive technology reads the pair as one.
- **pins-content-to-edges**: The row MUST fill its own bounds with its content and rely on its container for width.
- **is-settings-view**: The row MUST be usable anywhere a settings view is expected.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

