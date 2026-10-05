
- **add-reports-through-callback**: Pressing add MUST invoke the add callback.
- **remove-reports-through-callback**: Pressing remove MUST invoke the remove callback.
- **remove-starts-disabled**: The remove button MUST be disabled when the footer is created.
- **remove-enablement-is-settable**: The footer MUST expose a flag the owner sets to enable or disable the remove button.
- **add-is-always-enabled**: The add button MUST NOT be disabled by the footer itself.
- **buttons-are-described**: The add and remove buttons MUST carry the accessibility descriptions Add and Remove.
- **accessory-insertion-order**: Accessory controls MUST be placed after the remove button, before the trailing free space, in the order they were added.
- **trailing-view-takes-slack**: A trailing view at the right edge MUST take any spare width.
- **identifiers-from-prefix**: When built with an accessibility prefix, the buttons MUST carry the identifiers prefix.add and prefix.remove.
- **spacing-from-layout**: Insets MUST come from the settings layout's row-spacing value and the gap between controls MUST be small and fixed.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

