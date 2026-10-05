
- **Corner radius**: The shared settings layout's card-corner-radius token,
  inherited by composing the group component's themed card — see
  adtoolkit://cookbook/ui/settings/layout/group-view#appearance for the
  current value. This file sets no corner radius of its own.
- **Padding**: The sheet itself contributes 0pt of padding around the topic
  list (pinned flush to the root view's top/leading/trailing) and fixed
  offsets around the Done button: 12pt above it (from the topic list), 20pt
  to its trailing edge, 16pt below it. Inside each panel, the shared
  settings layout's panel-inset token (20pt) insets the group stack from
  the panel's top/leading/trailing (bottom is a "no more than" constraint,
  so it never forces extra height), and the shared settings layout's
  group-spacing token (20pt) separates the Spacing panel's two groups (the
  Tabs panel has only one group, so this spacing is never visually
  exercised there) — both are this component's own panel-level settings,
  not the group component's. Inside each card, the shared layout's
  card-horizontal-inset and card-vertical-inset tokens pad each row's
  content, and its caption-spacing token separates each group's caption
  from its card — see
  adtoolkit://cookbook/ui/settings/layout/group-view#appearance for the
  current values, since the group component is what consumes them.
- **Font**: Each group's caption ("Tab Bars", "Frame Spacing", "Pane Divider
  Spacing") renders with a caption text role (the group component's own
  header, built internally). Each Tabs toggle's title is forced to the
  body text style by this component's own theme-observing logic. The
  Spacing panel's number/label fonts belong to the spacing control's own
  implementation, not to this component.
- **Background**: The sheet's root view paints the `.windowBackground`
  theme role. Each group's card paints the theme's `.elevatedSurface` role
  — see adtoolkit://cookbook/ui/settings/layout/group-view#appearance
  for its exact construction. The topic list's own panel body additionally
  paints the window-background color behind the cards (composed by the
  panel component, not set directly by this component).
- **Foreground/Text**: Each Tabs toggle's title is forced to the
  `.primaryText` theme role by this component. Each group's caption
  resolves to the theme's `.secondaryText` role (the group header's own
  label). The Done button's title uses the platform's default system
  label color; this component sets no explicit color on it.
- **Border**: Each card has no border stroke of its own, and a hairline
  divider separates a card row from the row above it — both are the group
  component's construction, not this component's; see
  adtoolkit://cookbook/ui/settings/layout/group-view#appearance for the
  current values (the shared layout's divider-thickness token, drawn as a
  themed divider).
- **Shadow**: Not applicable — no shadow property is set anywhere in this
  component, nor in the group/panel/card components it composes.
- **Min/Max size**: The preferred content area is fixed at 760×520pt; the
  topic list additionally floors the detail pane at 420pt. No maximum size
  is set anywhere in the component.

