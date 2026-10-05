
- **SwiftUI**: A `VStack(alignment: .leading, spacing: 16)` holding two
  child `VStack`s (one per section), each starting with a small,
  semibold, uppercase `Text` header. Within each child, switch on
  (loading, isEmpty) the same way the source's ternary does: a literal
  "Loading…" `Text` for the loading case, a muted "No admin notes."/"No
  history." `Text` for the empty case, and otherwise a `ForEach` over
  `Identifiable` note/history models rendering each item's fields — use a
  plain `ForEach` inside the `VStack`, not `List`, to avoid `List`'s row
  chrome and keep history rows as flat, unstyled lines like the source.
- **Compose**: A `Column(verticalArrangement = Arrangement.spacedBy(16.dp))`
  with a nested `Column` per section, each headed by a small, semibold,
  uppercase `Text`. Mirror the source's three-way branch with a `when` on
  (loading, list.isEmpty()): a "Loading…" `Text`, a "No admin notes."/"No
  history." `Text`, or a `Column` (or `LazyColumn` for very large lists)
  built with `items(notes)`/`items(history)` rendering each row.
- **React/Web**: Source file
  `packages/web/packages/adh-ui/src/blocks/notes-and-history.tsx`. A plain
  function component (`ReactElement`, no `"use client"` directive, no
  hooks) that consumes `AdminNote`/`HistoryEntry` types from `../lib/
  invitations-types` — `{ id: string; content: string; author: string;
  addedDate: string; modifiedDate: string; subjectTable: string;
  subjectId: string }` for `AdminNote`, `{ id: string; actor: string;
  action: string; timestamp: string }` for `HistoryEntry`; `toAdminNote`/
  `toHistoryEntry` in that same file produce the pre-formatted
  `modifiedDate`/`timestamp` strings via `updatedAt.slice(0, 10)` /
  `createdAt.slice(0, 10)`. Two sibling `<section>`s in a `flex flex-col
  gap-4` container; each section is a ternary chain (`loading ? … : empty
  ? … : list`) styled with Tailwind utilities and the `apt-*`
  design-token vocabulary (`rounded-md`, `mt-4`, `gap-4`, `p-2`, `mt-1`,
  `gap-2`, `gap-1`, `text-xs`, `font-semibold`, `uppercase`,
  `tracking-wide`, `text-sm`, `bg-apt-surface-2/40`, `text-apt-text-muted`,
  `text-apt-text`, `text-apt-text-dim`, `border border-apt-border`) — no
  CSS modules, no styled-components. Each `<section>` carries no
  `aria-label`/`aria-labelledby`; heading navigation instead relies on the
  native `<h4>` inside it. The loading-to-populated/empty transition has
  no `aria-live`/`role="status"` wrapper. No `tabIndex` attribute or
  router/link usage appears in the file. List items are keyed by
  `key={n.id}`/`key={h.id}` with no de-duplication, mirroring React's own
  duplicate-key console warning when keys collide. No `truncate`/
  `line-clamp` class is applied to `content`/`action` text. The five
  strings are hardcoded JSX literals with no `t()`, `useTranslation`, or
  `FormattedMessage` call. No `console.*`/logger call appears anywhere in
  the file.
- **AppKit/UIKit**: A vertical `UIStackView` (spacing 16) with two child
  stack views, each headed by a `UILabel` styled as small, semibold,
  uppercase (UIKit has no built-in `text-transform`, so uppercase the
  string directly or via `NSAttributedString`). Body content mirrors the
  source's flat, unvirtualized rendering: build a child `UIStackView` of
  one row view per note/history entry (a bordered/background view for
  notes, a plain `UILabel` line for history) rather than a `UITableView`,
  since the source never recycles rows or lazily loads.
- **WinUI 3** (the reason this recipe exists): Root `StackPanel
  Orientation="Vertical" Spacing="16"` with two child `StackPanel`s, each
  headed by a `TextBlock` using `Style="{StaticResource
  CaptionTextBlockStyle}"` plus `Foreground="{ThemeResource
  TextFillColorSecondaryBrush}"` — uppercase the header string in
  code-behind/x:Bind converter, since XAML has no CSS-style text
  transform. Bind an `ItemsRepeater` (not `ListView`, to avoid selection
  and virtualization chrome the source never has) to the notes/history
  collection inside each `StackPanel`; give each `StackPanel`/
  `ItemsRepeater` pair two independent `VisualStateGroup`s
  ("NotesState"/"HistoryState" with states "Loading"/"Empty"/"Populated"),
  driven by two independent `bool` `x:Bind` properties (`NotesLoading`,
  `HistoryLoading`) — mirroring the source's two separate loading flags
  rather than one shared loading state. Loading and empty `TextBlock`s use
  `Foreground="{ThemeResource TextFillColorTertiaryBrush}"` (mapping the
  source's dim `apt-text-dim`), and body-content `TextBlock`s use
  `Foreground="{ThemeResource TextFillColorPrimaryBrush}"` (mapping
  `apt-text`). Note item template: a `Border CornerRadius="6"
  BorderThickness="1" Padding="8"
  BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"
  Background="{ThemeResource CardBackgroundFillColorSecondaryBrush}"`
  wrapping a `StackPanel` with the content `TextBlock`
  (`TextFillColorPrimaryBrush`) and a secondary, muted `TextBlock`
  (`TextFillColorSecondaryBrush`, mapping `apt-text-muted`) reading
  "author · modifiedDate". History item template: a single `TextBlock`
  with a muted (`TextFillColorSecondaryBrush`) inline `Run` for the
  timestamp followed by a plain (`TextFillColorPrimaryBrush`) run reading
  " — actor action" — no `Border`, matching the source's unstyled history
  rows.

