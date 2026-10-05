
- **Role/trait**: The component sets an accessibility identifier on itself
  and on each subview (for automated-test addressing) but sets no
  accessibility role and does not mark itself as a single accessibility
  element grouping its children (unlike the tab button used elsewhere in the
  tabbed view, which does group its children). The screen reader reads the
  card as five separate, individually-focused text elements in sequence,
  with no indication that they describe one tab.
- **Label requirements**: The close control's icon carries an accessibility
  label of "Close" (see Localization). Each status icon carries the
  caller-supplied accessibility label for its symbol. The agent, session,
  directory, branch, and summary labels receive no explicit accessibility
  label in this component; the screen reader falls back to each label's own
  displayed text, the platform's default for a plain text label.
- **Announce state changes**: Recomputing appearance recolors and
  repositions the card whenever it becomes or stops being the front card,
  but the component posts no accessibility notification when that happens; a
  screen reader user tracking a different element is not told this card's
  selection state changed when no click of their own caused it.
- **Minimum tap target**: The close control's hit area is a fixed `14×14pt`.
  This is a pointer-driven desktop context; the `44×44pt` (mobile) /
  `48×48dp` (Android) touch-target minimums do not apply directly here and
  instead inform the touch-platform translations in Platform Notes.

