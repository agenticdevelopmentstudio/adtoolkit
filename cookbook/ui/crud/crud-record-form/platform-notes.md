
- **React / Web (TypeScript):** `packages/web/packages/crud/src/CrudRecordForm.tsx`,
  exported from `@agentic-toolkit/crud`. Composes the shared `Field`, `Button`,
  `useAction` (from `@agenticdevelopertoolkit/ui`) and the package-local
  `CrudFieldInput` (rendering `Select`/`Checkbox`/`Textarea`/`Input` per
  column type) + `ErrorText`. Note it lives in `@agentic-toolkit/crud`, not
  `@agenticdevelopertoolkit/ui`.
- The pure metadata→payload helpers are exported for reuse/testing: `writableColumns`,
  `toDraft`, `buildPayload`, plus the `CrudDraft` / `CrudFormMode` types. An
  untouched create checkbox is represented as `undefined` in the draft.
  Pretty-printing uses `JSON.stringify(value, null, 2)`; the non-finite-number
  check is `Number.isFinite`.
- Root form: `<form className="flex flex-col gap-3">`. Boolean rows: a
  `<label className="flex items-center gap-2">` wrapping the `Checkbox`, with
  the caption styled via `fieldCaptionClass` (the shared uppercase-mono
  caption class from `@agenticdevelopertoolkit/ui/lib/typography`). Footer:
  `flex justify-end gap-2`; Cancel is `type="button"`, Save is
  `type="submit"`, both `size="sm"`. Colors/typography come from the
  toolkit's `apt-*` design tokens (e.g. `text-apt-text-muted`); no raw hex,
  no `!important`.
- Metadata comes from `src/generated/table-metadata.ts` (backend OpenAPI →
  `gen_table_metadata.py`); the submit callback typically maps to
  `useCrudResource`'s `create`/`update`.
- Demo: `ui-showcase` Topic `crud-record-form` (static `meta`; logs the payload).
- First consumer: the `/all-data` generic table editor (`AllDataPane`).
- **Responsive:** Fields stack in a single column; verify at 375 / 768 / 1440 via
  Playwright.
- **SwiftUI / Compose:** No native implementation in this repo; the same
  metadata-driven mapping would render `Picker` (SwiftUI) /
  `DropdownMenu` (Compose) for enum columns, `Toggle` / `Switch` for booleans, a
  multi-line `TextEditor` / `OutlinedTextField` for JSON columns, and
  `TextField` / `OutlinedTextField` for everything else, following the same
  required/`serverManaged`/`createOnly` rules above.
- **AppKit / UIKit:** No native implementation in this repo; the same mapping
  would render `NSPopUpButton` / `UIPickerView` for enum columns, `NSSwitch` /
  `UISwitch` for booleans, a plain multi-line text view for JSON columns, and
  `NSTextField` / `UITextField` for everything else, following the same
  required/`serverManaged`/`createOnly` rules above.
- **WinUI 3:** No native implementation in this repo; the same mapping would
  render `ComboBox` for enum columns, `ToggleSwitch` for booleans, a multi-line
  `TextBox` for JSON columns, and `TextBox` for everything else, following the
  same required/`serverManaged`/`createOnly` rules above.

