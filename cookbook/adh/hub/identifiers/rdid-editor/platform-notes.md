
- **React/Web**: Source at
  `packages/web/packages/adh-ui/src/components/rdid-editor.tsx`, exported
  as `RdidEditor` from `@agentic-toolkit/adh-ui`. Its props
  (`RdidEditorProps`): `label: React.ReactNode`, `prefix: string`,
  `value: string`, `onChange: (next: string) => void`,
  `placeholder?: string`, `hint?: React.ReactNode`,
  `error?: React.ReactNode`, `disabled?: boolean`, `id?: string`.
  Composes `Input` from `@agenticdevelopertoolkit/ui`
  (`packages/web/packages/ui/src/components/input.tsx`)
  for the field shell and `FieldFootnote` from
  `@agenticdevelopertoolkit/ui` for the hint/error slot, plus
  `fieldCaptionClass` from `@agenticdevelopertoolkit/ui`'s typography
  module for the caption (**renders-associated-label** uses a native
  `<label htmlFor>` bound to the input's `id`, generated via
  `React.useId` when not supplied — **generates-stable-input-id**). The
  fixed prefix renders as an inert `<code>` element
  (**renders-static-prefix**); **lowercases-input-on-change** calls
  plain `.toLowerCase()` (not `.toLocaleLowerCase()`) on every change
  event. The invalid state is `aria-invalid="true"` set or omitted
  entirely (**marks-input-invalid-on-error**,
  **omits-invalid-attribute-without-error**); `FieldFootnote`'s
  `errorId` prop (for wiring `aria-describedby`) is never supplied (see
  Design Decisions). It never imports the rdid grammar (`prefixFor`,
  `validateLeaf`, `SEGMENT_RE`, `IDENTIFIER_MAX_LENGTH` from `rdid.ts`)
  itself — the caller supplies `prefix` and `error` already computed.
  Styling: root stack `gap-1.5`; prefix row `gap-1`; label
  `font-mono text-[0.7rem] uppercase tracking-wider text-apt-text-muted`
  (`fieldCaptionClass`); prefix `text-sm text-apt-text-muted shrink-0`;
  the input's `rounded-lg`, `px-3 py-2`, `bg-apt-bg`, height (`h-9`),
  `w-full`, `min-w-0`, border, focus ring, and invalid-state ring all
  come from the shared `Input` shell, which resolves its `apt-*` color
  tokens from the M3 role variables `AdhThemeStyle` injects.
- **SwiftUI**: Start from a `TextField` inside an `HStack` (for the
  prefix mode) or alone (for the no-prefix mode), since SwiftUI's
  `TextField` has no built-in leading-adornment slot — the fixed prefix
  has to be composed as a separate `Text` view, mirroring the web
  version's manual layout. Lowercasing has to be applied explicitly in
  the `onChange`/`.onChange(of:)` handler (SwiftUI does not lowercase
  input automatically); the caption becomes a `Text` styled to match
  the shared caption style's mono/uppercase/tracked look, and the
  hint/error footnote becomes a second `Text` below the field, switching
  its content and color the same way the shared footnote component
  does.
- **Compose**: Start from Material 3's `TextField`/`OutlinedTextField`,
  which — unlike the web version — has a native
  `prefix: @Composable (() -> Unit)?` slot, so the fixed prefix does not
  need a hand-built `Row`. Its `isError` parameter maps directly to
  whether an error is set, and its `supportingText` slot maps directly
  to the hint/error footnote (swap content the same way the shared
  footnote component does, rather than showing both). Lowercase the
  value inside `onValueChange` to match
  **lowercases-input-on-change**.
- **AppKit / UIKit**: Start from `NSTextField`/`UITextField`. Neither
  has a built-in prefix slot, so compose the fixed prefix as a sibling
  `NSTextField(labelWithString:)`/`UILabel` inside an
  `NSStackView`/`UIStackView`, the same manual-composition shape the web
  version uses. Lowercase the typed value inside the delegate callback
  (`controlTextDidChange`/`textField(_:shouldChangeCharactersIn:)`)
  before propagating it, and render the hint/error footnote as a
  separate label below the field whose text and color swap exactly as
  the shared footnote component's do.
- **WinUI 3**: Start from `TextBox`, which has a built-in `Header`
  property that can absorb the caption (`label`) instead of a separate
  label element, and a `PlaceholderText` property that maps directly to
  `placeholder`. WinUI 3's `TextBox` has no built-in leading-adornment
  slot (unlike Compose's `prefix` slot), so for the prefix mode, compose
  a `TextBlock` bound to `prefix` next to the `TextBox` inside a
  horizontal `StackPanel`, the same hand-built layout the web version
  uses. `TextBox`'s default control template only defines
  `Normal`/`PointerOver`/`Focused`/`Disabled`/`ReadOnly` visual states
  in its `CommonStates`/`FocusStates` groups — there is no built-in
  `Invalid` state equivalent to the web version's invalid-border
  behavior, so mark the invalid state with a bound
  `BorderBrush`/`BorderThickness` (or a custom `VisualState` added to an
  overridden `ControlTemplate`) rather than assuming one exists.
  `TextBox` has no per-field hint/error slot either, so render a
  `TextBlock` below it (e.g.
  `Foreground="{ThemeResource SystemFillColorCriticalBrush}"` when
  showing the error) whose text swaps between hint and error exactly as
  the shared footnote component does, and lowercase the value in the
  `TextChanged` handler to match **lowercases-input-on-change**.

