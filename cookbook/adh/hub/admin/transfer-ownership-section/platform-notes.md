
- **SwiftUI**: Start from a `DisclosureGroup` for the collapsed/expanded "Transfer Ownership"
  section, a `Menu` with nested `Menu` sub-items for the workspace tree (mirroring
  `DropdownMenuSub`), and a `.sheet`/custom modal for the two-stage (preview then type-to-confirm)
  flow. Drive the confirm gate with a `TextField` bound to `@State` text compared, trimmed, against
  the object's identifier, and use a generation counter alongside the preflight `Task` to discard a
  stale preview the way `previewSeq` does here, since a plain `async` call has no built-in
  "supersede this in-flight request" primitive.
- **Compose**: Use an expand/collapse composable (e.g. driven by `AnimatedVisibility`) for the
  Disclosure equivalent, a `DropdownMenu` with a nested `DropdownMenu` for submenu targets — Compose
  has no native infinitely-nested submenu primitive, so the nested case needs a custom recursive
  composable exactly as this source does — and an `AlertDialog` for the confirm flow. Gate the
  confirm button from a `mutableStateOf` string compared via `.trim()`, and cancel a stale preflight
  `Job` (from a `CoroutineScope`) when a new target is chosen, mirroring the sequence guard here.
- **React/Web**: This is the source. See
  `packages/web/packages/adh-ui/src/blocks/transfer-ownership-section.tsx`, which composes
  `@agenticdevelopertoolkit/ui`'s `Disclosure`, `Button`, `Input`, `Label`, `ErrorText`, the
  `DropdownMenu` family (including `DropdownMenuSub`/`DropdownMenuSubContent`/`DropdownMenuItem`),
  and the `Dialog`/`DialogContent` family. The component's own doc comment names it a sibling of
  `DeleteEntitySection`, whose confirm vocabulary and type-to-confirm gate it follows. State is
  plain `React.useState`/`useRef` — `disclosed` defaults to `false` via `useState(false)`;
  `chosen`/`preview`/`typed`/`busy`/`error` live in `useState`, cleared by `reset()` or on unmount,
  with nothing written to `localStorage`, a cookie, or any persistent store. The async preview-race
  guard is a manually incremented `previewSeq` ref rather than an `AbortController` (no cancellation
  primitive is used). The root element is a `<section aria-label="Transfer Ownership">`; the
  disclosure trigger's icon is `ArrowRightLeft`; the token-revocation warning uses the
  `TriangleAlert` icon. The current item's `onClick` is left `undefined` rather than calling
  `choose`, so it cannot be activated. `TransferTarget` is `{ slug: string; kind?: "customer" |
  "organization"; name: string; children?: TransferTarget[] }`; `TransferTargetRef` is
  `Pick<TransferTarget, "slug" | "kind">`; `TransferPreviewResult` is `{ tokens: number; revoking:
  { kind: "user" | "team" | "persona" | "organization" | "app" | "token"; id: string; name: string;
  via: "role" | "team" | "direct" | "participant" | "group" }[] }`. `onPreview` is typed
  `(target: TransferTarget) => Promise<TransferPreviewResult>`; `onConfirm` is typed
  `(target: TransferTarget) => Promise<void>`. `renderTarget` recurses over nested `children`,
  keying each rendered item and the "(current)" match by `targetKey` (derived from `(kind, slug)`),
  which doubles as the React list `key` — a duplicate `(kind, slug)` pair produces a React key
  collision. `noun` is computed as `entityNoun.toLowerCase()`. Rejections are type-checked via
  `instanceof Error` to decide whether to show the rejection's `message` or the generic fallback
  text. Every user-facing string is a literal JS/JSX string or template literal, with no i18n
  library import. The type-to-confirm `Input` is labeled by an explicit `<Label
  htmlFor={inputId}>` tied to the input via `React.useId()`. No custom key handling (`onKeyDown`,
  `tabIndex` override) appears in source; tap targets are owned by the shared
  `Button`/`DropdownMenuItem`/`Input` components (all `size="sm"` or their defaults).
  Contrast/color is governed by the `apt-*` semantic color tokens (`apt-text`, `apt-text-muted`,
  `apt-gold`); no raw hex value appears in source. The dialog's `DialogContent`
  (`@agenticdevelopertoolkit/ui/components/dialog`, whose `DialogContent` renders a plain
  `DialogPrimitive.Popup` with no live-region wrapper) carries no `aria-live`/`role="status"`
  region. Layout: the disclosed body is `flex flex-col gap-3`; the dialog's status/preview area is
  `flex flex-col gap-2 text-sm`; the confirm-gate group is `flex flex-col gap-2`; body/dialog copy
  is `text-sm`, the identifier and typed-back value are `font-mono`. `DialogContent` uses
  `max-w-xl`, wider than the platform's default `max-w-md`.
- **AppKit/UIKit**: Use an `NSDisclosureButton`/custom expand-collapse `NSView` (AppKit) or a
  collapsible `UITableView` section header (UIKit) for the Disclosure equivalent, and an `NSMenu`/
  `UIMenu` with a nested submenu (`NSMenuItem.submenu`/nested `UIMenu`) for the workspace tree —
  both platforms support native nested submenus, unlike Compose. Use an `NSAlert`/
  `UIAlertController`, or a small custom sheet/panel given the richer body content here, for the
  two-phase confirm; gate the confirm control from a text-field delegate callback compared with
  `.trimmingCharacters(in: .whitespaces)`, and track the in-flight preflight with a generation
  counter checked when its completion handler returns.
- **WinUI 3**: Use an `Expander` (`IsExpanded="False"` by default) for the Disclosure equivalent,
  with its `Header` a horizontal `StackPanel` of a `FontIcon`/`SymbolIcon` (for `ArrowRightLeft`)
  plus a `TextBlock` reading "Transfer Ownership". Inside, a `Button` opens a `MenuFlyout` whose
  `MenuFlyoutItem`s render the leaf targets and whose nested destinations use `MenuFlyoutSubItem` —
  WinUI 3's native nested-submenu control, directly matching `DropdownMenuSub` — with the current
  item's `MenuFlyoutItem.IsEnabled` set `False` and its text carrying " (current)". Model the
  confirmation flow as a `ContentDialog` with `PrimaryButtonText="Transfer"`, binding
  `IsPrimaryButtonEnabled` to the trimmed-match comparison from a `TextBox.TextChanged` handler, and
  suppress dismissal while transferring by handling the dialog's `Closing` event and setting
  `args.Cancel = true` whenever a `confirming` flag is set — the WinUI analogue of the
  `onOpenChange` guard here. Render the "Checking…" text, the token-count warning, and
  the revoked-principal list as conditionally visible `TextBlock`/`ItemsRepeater` content inside the
  `ContentDialog` body, and style the Transfer button with a custom `Style` tinted for the Fluent
  "Caution"/warning system color rather than the built-in destructive/red button style, matching the
  source's `warning`-not-`destructive` choice.

