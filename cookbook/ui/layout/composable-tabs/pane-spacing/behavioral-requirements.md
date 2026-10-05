
### Setting definitions

- **edge-inset-default-zero**: Each of the four edge settings (`pane_spacing_top`, `pane_spacing_leading`, `pane_spacing_bottom`, `pane_spacing_trailing`) MUST default to `0` points until a value has been stored for it.
- **gutter-default-one-point**: Each of the two gutter settings (`pane_spacing_between_columns`, `pane_spacing_between_rows`) MUST default to `1` point until a value has been stored for it.
- **settings-not-secure**: The six `pane_spacing_*` settings MUST be stored as non-secure settings, never through a secure/sensitive-data storage path.

### Aggregation

- **current-reads-live-value-per-field**: Reading the current spacing value MUST read each of the six settings' live value at the moment it is accessed, rather than returning a value cached elsewhere.
- **current-populates-all-six-fields**: Reading the current spacing value MUST return a spacing structure whose `top`, `leading`, `bottom`, `trailing`, `betweenColumns`, and `betweenRows` each equal the corresponding setting's current value.
- **content-insets-maps-fields-to-edge-insets**: Converting the current spacing value into content insets MUST return a structure whose `top`, `left`, `bottom`, and `right` equal `current.top`, `current.leading`, `current.bottom`, and `current.trailing` respectively.
- **minimum-divider-grab-fixed**: The minimum interactive width guaranteed for a divider's hit-test region MUST equal `6` points regardless of the current values of `betweenColumns` or `betweenRows`.

### Divider thickness and paint

- **divider-thickness-selects-axis-gutter**: The pane split view's divider thickness MUST equal the current spacing value's `betweenColumns` when panes are arranged side by side (a vertical split), and `betweenRows` when panes are stacked (a horizontal split).
- **divider-paint-defers-when-hairline**: Painting the divider MUST defer to the platform's own default divider rendering, and MUST NOT fill the divider area itself, when the divider thickness is `1` point or less.
- **divider-paint-fills-with-pane-backdrop**: Painting the divider MUST fill the entire divider area with the active theme's pane-backdrop color when the divider thickness is greater than `1` point, and MUST NOT defer to the platform's default divider rendering in that case.

### Spacing-change refresh

- **spacing-change-toggles-divider-style**: Notifying the split view that spacing changed MUST set its divider style to a value other than its current one and then set it back to its original value, in that order, forcing the split view to recompute its divider layout from the new thickness.
- **spacing-change-requests-redraw**: Notifying the split view that spacing changed MUST mark the divider for redraw.

### Scope

- **spacing-shared-across-windows**: The spacing values and their underlying settings MUST be process-wide, not held per window, per project, or per pane instance, so every pane split view and every reader of the content insets observes the same six values.
- **setting-changes-persist-via-shared-store**: Assigning a new value to any of the six settings MUST write through the shared settings store, persisting to whatever storage provider backs it rather than to an in-memory cache local to the setting object.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

