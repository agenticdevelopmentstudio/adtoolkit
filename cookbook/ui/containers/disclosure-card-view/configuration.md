
Construction options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `String` | — (required) | Text shown in the titlebar |
| `titleIsAccent` | `Bool` | — (required) | Colors `title` with `accentColor` when `true`, `primaryTextColor` when `false` |
| `titleAccessory` | `View?` | `nil` | View placed before the title, e.g. a host's logo mark |
| `titleTrailingStatus` | `StatusSymbol?` | `nil` | Symbol drawn right after the title, at the title's size, e.g. a seal on the one card in a stack worth acting on; a stack that marks only some cards hands the rest `StatusSymbol.placeholder(sizedLike:)` so every card asks for the same width |
| `titlebarAccessory` | `View?` | `nil` | View placed before the disclosure control, e.g. a per-card menu |
| `subtitle` | `String?` | `nil` | One quiet line under the masthead; hidden whenever the card is collapsed |
| `summary` | `[SummaryPart]` | `[]` | Readings shown on their own right-aligned line only while the card is collapsed |
| `status` | `StatusSymbol?` | `nil` | Symbol stamped on the card's top-right corner |
| `isCollapsed` | `Bool` | `false` | Whether the card is constructed folded; fixed for the instance's lifetime |
| `isDimmed` | `Bool` | `false` | Whether the whole card renders at reduced (0.55) opacity |
| `scaledSize` | `CGFloat` | — (required) | The text size driving every scaled inset, font, and badge dimension |
| `onToggle` | `((Bool) -> Void)?` | `nil` | Called with the requested new collapsed state when the disclosure control is activated |

`SummaryPart`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | `String` | — (required) | The reading's label, e.g. `"5H"` |
| `value` | `String` | — (required) | The reading's value, e.g. `"23%"` |
| `color` | `(SemanticPalette) -> Color?` | — (required, or derived from `colorName`) | Resolves the value's color against the live palette each time it is called |
| `colorName` (convenience option) | `String?` | — | Looked up via `palette.color(named:)` in place of a custom `color` closure |

Callers SHOULD supply `color` as a closure that resolves against the live
`SemanticPalette` each time it is called (or use the `colorName` convenience
option, which does this automatically), rather than capturing a static color
at construction time — a captured static color will not update on a theme
change. This is caller-side guidance: the component has no way to enforce it
and no observable behavior distinguishes a dynamic `color` closure from a
static one, so it has no requirement or test vector of its own.

`StatusSymbol`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `symbolName` | `String` | — (required) | Symbol name rendered in the corner badge or after the title |
| `color` | `(SemanticPalette) -> Color?` | — (required, or derived from `colorName`) | Resolves the symbol's tint against the live palette on every theme application; `nil` falls back to `secondaryTextColor` |
| `colorName` (convenience option) | `String?` | — | Looked up via `palette.color(named:)` in place of a custom `color` closure |
| `accessibilityLabel` | `String` | — (required) | Used as both the symbol's accessibility label and its tooltip |
| `isPlaceholder` | `Bool` | `false` (read-only) | `true` only for `StatusSymbol.placeholder(sizedLike:)`, which holds the named symbol's room with nothing drawn, spoken, or explained |

Beyond construction, the component exposes: an operation to add a content
view to the content area; a read/write property controlling the content
area's spacing (`contentSpacing`); and a read-only property exposing whether
the card is currently collapsed (`isCollapsed`).

