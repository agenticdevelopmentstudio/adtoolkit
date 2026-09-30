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
 * and a host's `detailTitle` both win over this. The bare lookup: undefined when nothing is
 * selected or the selected id is not among the level's rows. The strip reads it through
 * `useSelectedTopicLabel` (detail-title.tsx), which holds the last label across a row filtered out
 * from under an open pane.
 */
export function selectedTopicLabel(
  levels: readonly { selectedId: string | null; items: readonly { id: string; label: string }[] }[],
): string | undefined {
  const level = levels[deepestSelectedLevel(levels)]
  return level?.items.find((item) => item.id === level.selectedId)?.label
}

// Suffix on a `pins` key that names a list's pin WHILE IT IS THE CHOOSING FRONTIER — kept apart
// from the list's ordinary pin so neither leaks into the other state. A NUL can never appear in a
// level id a host writes, so the two keys cannot collide. Shared by HTDV and HMDV: the empty
// detail's `«` was a dead button in HMDV because only HTDV had this key.
const FRONTIER_PIN = "\u0000frontier"

/** The `pins` key for rendered list `i`: its frontier key while it is the choosing frontier
 *  (`i >= coverableCount`), else its ordinary id. */
export function pinKeyFor(id: string, i: number, coverableCount: number): string {
  return i >= coverableCount ? `${id}${FRONTIER_PIN}` : id
}

/**
 * The pins after an "all" gesture — a ⌘-click on any `«`/`»`, or `<<<` / `>>>` — moving every list
 * to `target`. ONE function for all of them, because `<<<` is documented as a ⌘-click on the
 * frontier's own toggle and two copies had drifted: `<<<` replaced the map and pinned the frontier
 * only under its frontier key, so it and the ⌘-click left different stacks once the frontier gained
 * a selection (code review).
 *
 * - Lists above the frontier take `target` under their ordinary id.
 * - The choosing frontier is reached only by a gesture made from ITS toggle (`fromFrontier` —
 *   `<<<` sits beside it), and then under BOTH keys, so it is covered now and stays covered once
 *   the user chooses in it — what is on screen after the click is what persists. A ⌘-click on a
 *   parent leaves the frontier's pins as they were: it never hides the list being chosen from, and
 *   it no longer wipes a cover the user already put on it with the detail's `«` (it replaced the
 *   whole map, springing that list back open — code review).
 * - Opening reaches the frontier from anywhere: "open all" hiding nothing is never a surprise.
 * - Keys of lists not rendered now are kept, as a single toggle keeps them.
 */
export function pinAll(
  prev: Readonly<Record<string, boolean>>,
  ids: readonly string[],
  coverableCount: number,
  target: boolean,
  fromFrontier: boolean,
): Record<string, boolean> {
  const next: Record<string, boolean> = { ...prev }
  const reachFrontier = fromFrontier || !target
  ids.forEach((id, i) => {
    if (i < coverableCount) next[id] = target
    else if (reachFrontier) {
      next[id] = target
      next[pinKeyFor(id, i, coverableCount)] = target
    }
  })
  return next
}
