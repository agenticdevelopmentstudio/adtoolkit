
- **Decision**: Build on `CommandPalette` rather than a bespoke search
  dialog.
  **Rationale**: Per source comment in `rdid-picker.tsx`'s top-of-file JSDoc,
  "the palette already IS this interaction — a modal over one field,
  keyboard-driven, first result preselected, Enter runs it and closes." A
  second dialog with its own search box and result list would duplicate that
  shape under a different name.
  **Approved**: pending
- **Decision**: No `scope` prop; a caller restricts results by closing over
  its own filter inside `search`.
  **Rationale**: Per source comment in `rdid-picker.tsx`'s top-of-file JSDoc
  ("SCOPING IS THE CALLER'S" paragraph), a `scope` prop would mean this
  component owns the list of scopes, requiring every new entity type to come
  back and edit it; closing over the filter keeps `RdidPicker` ignorant of
  what an "ecosystem" (or any other entity type) is.
  **Approved**: pending
- **Decision**: Debouncing and abort-on-supersede live in `RdidPicker`, not
  in `CommandPalette`.
  **Rationale**: Per source comment in `rdid-picker.tsx`'s top-of-file JSDoc
  ("DEBOUNCING LIVES HERE" paragraph), `CommandPalette` is a controlled input
  with no opinion on when the host fetches; but this picker's list IS the
  fetch, so the trailing delay and the abort of a superseded request belong
  to it.
  **Approved**: pending
- **Decision**: `onPick` receives the whole `RdidOption`, not just the
  `rdid` string.
  **Rationale**: Per source comment on the `onPick` prop in
  `rdid-picker.tsx`, a caller that needs the entity id must not have to
  re-resolve the address it just picked — a second lookup that can disagree
  with the first.
  **Approved**: pending
- **Decision**: `search` is read through a ref (`searchRef`) inside the
  debounce effect instead of listing `search` itself as a dependency.
  **Rationale**: Per source comment above the `searchRef` effect in
  `rdid-picker.tsx`, `search` is usually an inline arrow function with a new
  identity on every render; keying the effect on it would restart the
  debounce on every parent re-render, and a steadily typing user would never
  reach the trailing edge.
  **Approved**: pending
- **Decision**: Closing the picker clears `query`, `options`, `error`, and
  `loading`.
  **Rationale**: Per source comment above the close-triggered reset effect in
  `rdid-picker.tsx`, reopening onto a stale query and a stale list would
  offer a result for a search the user has already moved on from.
  **Approved**: pending
- **Decision**: A failed search clears `options` rather than leaving stale
  results in place.
  **Rationale**: Per source comment in the rejection handler in
  `rdid-picker.tsx`, an empty list after a failed request reads as "no such
  address," the one wrong conclusion available; clearing `options` and
  setting `error` avoids that misreading.
  **Approved**: pending
- **Decision**: Only `title`, `placeholder`, and `entityTypeLabel` are
  caller-overridable strings; the group label's "addresses" suffix, both
  empty-state labels, and the non-`Error` rejection fallback ("Search
  failed") are fixed English literals with no localization mechanism.
  **Rationale**: `rdid-picker.tsx` exposes no other string-customization
  prop and contains no localization key extraction or i18n call; this is the
  component's current, deliberate string surface rather than an oversight,
  and any broader localization would need to be added as new props.
  **Approved**: pending

