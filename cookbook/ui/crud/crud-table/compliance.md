
| Check | Status | Category |
|---|---|---|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`semantic-markup`, `screen-reader-support`, and `keyboard-navigable` rest on the real
`<table>`/`<thead>`/`<tbody>`/`<th>` markup, the `aria-label="Row actions"` header, and
the real, focusable `<button>` elements with visible text labels (`CrudTable.tsx`);
`dynamic-type-support` rests on the component's text sizing using `rem`-based Tailwind
classes (`text-sm`, `text-[0.7rem]`, `text-xs`) rather than fixed pixel sizes;
`contrast-ratio` is partial because the source only names `apt-*` theme tokens
(`text-apt-text`, `text-apt-text-dim`, `text-apt-border`) without the underlying color
values, so the actual ratios can't be confirmed from this file; `no-hardcoded-strings`
is failed because `New`, `Edit`, `Delete`, `Loading…`, `No rows yet.`, and the
row-count text ("N row"/"N rows") are all literal, unwrapped English strings in
`CrudTable.tsx`.

`separation-of-concerns` passes because `CrudTable` is presentational: `rows`, `loading`, `error`, `canWrite` and every action callback are props, and fetching, confirmation and permission decisions live in `useCrudResource` and the caller. `unit-test-coverage` is `partial` because `packages/web/packages/crud/src/__tests__/CrudTable.test.tsx` covers `displayColumns`, `cellText`, the loading, empty and error states, the New/Edit/Delete callbacks, and the read-only mode (`drops New and Delete and turns Edit into View when the viewer may not write`), but no test passes `readOnlyNote` or asserts the default note text, and none pins that colors are the theme's token values.

