/**
 * The index of the deepest level that HAS a selection — the level a Back, a breadcrumb-up, or a
 * pop backs the user out OF. `-1` means there is nothing to back out of: an empty stack, or a
 * stack in which nothing is selected at all.
 *
 * The rule is "the level above the FIRST hole", not "the deepest non-null one". A stack can carry
 * a selection below an unselected level (a level that published a default, or one whose selection
 * outlived its parent being cleared), and everything under that hole is unreachable — the leaf the
 * user can act on is the last one in the unbroken run from the root.
 *
 * Exported so the view's Back and the host's pop read the SAME answer. Two copies of this that
 * could disagree about which level is the leaf would clear the wrong list, intermittently, in a
 * way nobody could reproduce.
 *
 * Structurally typed (not `TopicLevel`) so the frontier math carries no dependency on the view
 * that renders it.
 */
export function deepestSelectedLevel(levels: readonly { selectedId: string | null }[]): number {
  const firstUnselected = levels.findIndex((l) => l.selectedId == null)
  return firstUnselected === -1 ? levels.length - 1 : firstUnselected - 1
}

/**
 * The detail strip's DEFAULT title: the label of the row the detail is showing — the selected row
 * of the {@link deepestSelectedLevel}. Mike: "It should be the title in the topic view by default,
 * but this should be overridable by the details pane" — so a pane's own title (detail-title.tsx)
 * and a host's `detailTitle` both win over this. Undefined when nothing is selected, or when the
 * selected id is not among the level's rows (a selection outliving its row): no title rather than
 * a stale one.
 */
export function selectedTopicLabel(
  levels: readonly { selectedId: string | null; items: readonly { id: string; label: string }[] }[],
): string | undefined {
  const level = levels[deepestSelectedLevel(levels)]
  return level?.items.find((item) => item.id === level.selectedId)?.label
}
