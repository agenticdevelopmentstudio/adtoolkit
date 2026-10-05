
- **masks-entry-with-secure-field**: Component MUST construct its field as
  a masking (dot-obscured) secure text field, so the field is a secure,
  masking field rather than the plain field its base row would otherwise
  construct.

All other behavior — row layout, expanding the field to fill the row,
wiring the field's action, initializing from and syncing with the view
model, theme styling, restyling an existing placeholder, exposing the
label and the field, the designated-initializer-only construction rule,
and UI-thread confinement — is inherited unmodified from the text edit
row; see
adtoolkit://cookbook/ui/settings/rows/text-edit-view#behavioral-requirements
(arranges-row-layout, expands-text-field-to-fill-row,
wires-text-field-action, initializes-from-view-model,
commits-value-on-change, skips-redundant-commits, syncs-on-external-change,
applies-theme-styling, restyles-existing-placeholder,
exposes-constituent-views, requires-designated-initializer,
rejects-frame-only-initialization, confines-to-ui-thread). Foreclosing
further specialization of this component is a platform-specific
construction detail, recorded in Platform Notes rather than as a
normative requirement here (see Platform Notes).

- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

