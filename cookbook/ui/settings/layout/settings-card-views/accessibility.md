
- **Role/trait**: The group container's caption sets no explicit heading
  trait; it reuses the sibling header component's exact role assignment
  (secondary-text color, caption text role — see Design Decisions), and
  like that component's label it is therefore not exposed as a heading, which
  is recorded in that component's own recipe rather than repeated here. The card, card row,
  and divider set no accessibility role of their own; they are pure
  layout/paint containers, and the platform applies its own default
  container/decoration behavior. The search field wraps a genuine native
  search control, so the system's search-field accessibility role, rotor
  behavior, and clear-key behavior are native to that control rather than
  something this vocabulary adds — exactly the alternative to "a
  hand-drawn stand-in" its own rationale calls out.
- **Label requirements**: The group container's caption text is both the
  visible and accessible content of the caption, since the title is
  displayed verbatim with no separate accessibility label. The search
  field's placeholder becomes the wrapped control's own placeholder text,
  which the platform also exposes as part of that control's default
  accessibility description; no separate accessibility label is set.
- **Announce state changes**: Not applicable — none of the six pieces
  defines a state that changes (see States); there is nothing for a
  screen reader to announce beyond the wrapped search control's own native
  announcements of its text changing.
- **Minimum tap target**: Not applicable for the group container, card,
  card row, and divider, none of which is an interactive control. The
  search field's tappable target (text bezel, clear button) is entirely
  the wrapped native control's own sizing, not a size this vocabulary
  computes.
- **minimum-contrast-ratio**: The card divider MUST fill with the theme's
  divider role, and the component MUST NOT perform any contrast check or
  adjustment of its own on that fill. The divider role is derived as the
  background blended only 10% toward the foreground with no stated
  minimum-contrast floor (unlike the secondary-text role), so the 3:1
  non-text contrast ratio expected of a meaningful UI boundary is met only
  to the extent a given theme's colors happen to provide it.

