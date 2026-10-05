
| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [platform-theming](agenticdevelopercookbook://compliance/platform-compliance#platform-theming) | passed | Platform Compliance |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`screen-reader-support` and `keyboard-navigable` rest on `Field`'s label
wrapping and the native `<label>`/`<input>`/`<button>` elements in
`CrudRecordForm.tsx`. `platform-theming` rests on `fieldCaptionClass` and the
shared classes drawing every color from `apt-*` tokens (no raw hex).
`no-hardcoded-strings` fails because the `Cancel`/`Save`/`Saving…`/`Close`
labels and the required/number/JSON error messages in `CrudRecordForm.tsx` are
literal English strings with no localization call.

`separation-of-concerns` passes because `CrudRecordForm` generates fields from `CrudTableMeta` and hands the validated payload to its `onSubmit`-style callback, while fetching and persistence live in `useCrudResource` and the surrounding page. `unit-test-coverage` passes because `packages/web/packages/crud/src/__tests__/CrudRecordForm.test.tsx` exercises the form's field generation, validation and submit behavior.

