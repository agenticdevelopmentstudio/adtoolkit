
- **React/Web (source)**: `packages/web/packages/adh-ui/src/blocks/rdid-picker.tsx`
  (`@agentic-toolkit/adh-ui`, `"use client"`). Composes `CommandPalette`
  and `CommandGroup` from
  `@agenticdevelopertoolkit/ui/blocks/command-palette`; `RdidPicker`
  itself owns only the debounce/abort/reset state machine (held in
  `React.useState`) and the group/label/placeholder derivation — no
  dialog, listbox, or keyboard logic of its own. `CommandPalette`
  supplies the accessible name (a visually-hidden `DialogTitle` bound to
  `ariaLabel`), a `role="combobox"` search input with
  `aria-controls`/`aria-expanded`/`aria-autocomplete="list"`/`aria-activedescendant`,
  and a `role="listbox"` of `role="group"`/`role="option"` rows with
  `aria-selected`, arrow/Home/End/Enter handling, and Escape-to-close via
  the underlying `Dialog` — traced to `command-palette.tsx`, which has
  no ingredient of its own yet in this cookbook. Debounce/abort is
  hand-rolled: a `setTimeout` reschedule per keystroke (clearing the
  prior with `clearTimeout`) and an `AbortController` created per search
  call, aborted on supersede; the current `search` function is read
  through a ref (`searchRef`) rather than listed as an effect
  dependency, so retyping doesn't restart the debounce on every parent
  re-render (see Design Decisions).
- **SwiftUI**: Present as a `.sheet`/`.popover` hosting a `List` with a
  `.searchable(text:)`-bound query; drive the debounced fetch from a
  `.task(id: query)` after a `Task.sleep(for:)` of `debounceMs` — a new
  `id` automatically cancels the prior `Task`, giving abort-on-supersede for
  free without a manual `AbortController` analogue. Surface `loading`/`error`
  as an overlay (`ProgressView`, `ContentUnavailableView`) over the `List`.
- **Compose**: Host in a `ModalBottomSheet` or `AlertDialog` with a
  `LazyColumn`; bind the search `TextField` through a `Flow` using
  `.debounce(debounceMs)` and `.collectLatest { }`, which mirrors the
  trailing-delay-plus-cancel-on-supersede this ingredient implements by hand with
  `setTimeout`/`AbortController`. Hoist `loading`/`error`/`options` as Compose
  state the same way `query`/`options` are hoisted here.
- **AppKit/UIKit**: Present modally (`NSPanel` or a `UIViewController`) over
  an `NSSearchField`/`UISearchController` and a table view. Debounce by
  rescheduling a single `DispatchWorkItem`/`Timer` on every keystroke (cancel
  and replace, matching the `clearTimeout`+new `setTimeout` here), and cancel
  the in-flight `URLSessionTask` the way `AbortController.abort()` is called
  here before starting the next one.
- **WinUI 3**: Use an `AutoSuggestBox` inside a `ContentDialog` (or a
  `Popup`) as the direct analogue of `CommandPalette`'s combobox input +
  listbox pairing — `AutoSuggestBox` already binds a text box to a
  keyboard-navigable suggestion list with Enter-to-commit, matching the
  type/arrow/Enter contract this ingredient requires. Bind `ItemsSource` to a
  small view-model list exposing `Rdid`/`EntityType` for the item template's
  primary text and badge (mirroring `renders-each-result-by-rdid-with-badge`).
  Debounce in the `TextChanged` handler with a `DispatcherTimer` that is
  stopped and restarted on every keystroke (the `setTimeout` reset here), and
  cancel the previous lookup via a stored `CancellationTokenSource.Cancel()`
  before creating a new one and awaiting `SearchAsync(query, token)` — the
  direct analogue of `AbortController`. Bind `IsLoading` to show a
  `ProgressRing` (or the `AutoSuggestBox`'s built-in loading indicator) and
  bind an `ErrorMessage` string to a status `TextBlock`, toggled exactly as
  `loading`/`error` gate `CommandPalette`'s render here. Clear
  `AutoSuggestBox.Text` and the bound `ItemsSource` in the dialog's `Closing`
  handler, mirroring the `open`-keyed reset effect in source.

