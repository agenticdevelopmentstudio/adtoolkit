
### Construction & the placeholder

- **contributed-view-retained**: The pane MUST retain the contributed view and extension display name given at construction, using them respectively as the placeholder's subject and as the pane title's fallback until a tree is shown.
- **explicit-construction-only**: The pane MUST support construction only through its explicit initializer; construction through a generic archive/coder-based path MUST fail fast rather than produce a usable instance.
- **initial-placeholder-shown**: Before any data source has resolved, the pane MUST show the placeholder for the contributed view.
- **container-background-tracks-theme**: The container view's background MUST track the `.surface` semantic theme color.
- **resolve-requested-after-view-loads**: The pane MUST request resolution of the data source only once its view has finished loading, not while the view is still being constructed.

### Swapping to a tree once resolved

- **first-resolve-shows-outline**: The first time resolution delivers a data source, the pane MUST replace the placeholder with a tree bound to that data source.
- **resolve-after-discard-ignored**: A resolution delivered after the pane has begun teardown MUST NOT change what is displayed.
- **duplicate-resolve-ignored**: A second resolution delivered once the tree is already showing MUST be ignored — regardless of whether it carries the same or a different data source; only provider replacement (below) may install a different data source once one is showing.
- **provider-replacement-swaps-source**: When the currently-bound data source signals that it has been replaced, the pane MUST replace the displayed tree with a new one bound to the replacement data source, and MUST re-hook the replacement signal on the replacement so a further replacement continues the chain.
- **swap-tears-down-previous-content**: Swapping displayed content MUST tear down the outgoing child's content when it supports teardown, and MUST clear its title-change notification, before removing it from view.
- **swap-pins-new-content-to-edges**: The newly shown child's view MUST be constrained to all four edges of the container.
- **swap-notifies-title-change**: Swapping displayed content MUST invoke the pane's own title-change notification once, since the pane title may now answer differently.

### Pane title & teardown (outer pane)

- **outer-pane-title-delegates**: The pane title MUST return the currently-shown child's own title when that child provides one, and MUST return the contributed view's name otherwise (i.e. while the placeholder is showing).
- **outer-teardown-marks-discarding**: Teardown MUST set an internal flag that suppresses any further reaction to resolution.
- **outer-teardown-forwards-to-content**: Teardown MUST forward to the currently-shown child's own teardown when that child supports it.

### Tree construction & layout

- **outline-single-column-no-header**: The tree MUST be built with exactly one column and MUST hide its header.
- **outline-row-height**: The tree's row height MUST be 22pt.
- **outline-indentation-per-level**: The tree's indentation per level MUST be 14pt.
- **outline-inset-style**: The tree MUST use an inset visual style.
- **outline-allows-empty-selection**: The tree MUST allow an empty selection.
- **message-banner-shown-conditionally**: A non-empty data-source message MUST be shown as a banner above the tree; when there is no message, the tree MUST instead be pinned to the container's top edge and the banner MUST be hidden.
- **message-banner-inset**: The message banner MUST be inset 16pt from the container's leading and trailing edges and 8pt from its top edge; the tree MUST sit 8pt below the banner's bottom edge when the banner is shown.
- **message-banner-wraps**: The message banner MUST wrap onto multiple lines with no line-count limit and left alignment.
- **accessibility-ids-assigned**: The tree MUST carry the accessibility identifier `"<accessibilityPrefix>.tree"` and the message label MUST carry `"<accessibilityPrefix>.message"`, where `accessibilityPrefix` is the contributed view's registry id.

### Loading lifecycle

- **initial-load-when-view-is-ready**: When the tree's view becomes ready to use, it MUST request the root's children and MUST apply the data source's chrome (title/message/allows-multiple-selection).
- **callback-ownership-transfers-to-latest-pane**: Installing this pane's callbacks on a data source MUST record this pane as that data source's current callback owner, superseding whichever pane owned them before.
- **visibility-forwarded-only-by-owner**: Reporting visibility to the data source when the pane becomes visible or becomes hidden MUST happen only when this pane is still that data source's recorded callback owner; a superseded pane's visibility changes MUST NOT be reported.
- **message-label-wrap-width-tracks-container**: The message label's preferred maximum layout width MUST track the container's width minus 32pt (16pt inset on each side).
- **multiple-selection-mirrors-source**: The tree's support for selecting multiple rows MUST mirror the data source's allows-multiple-selection setting, re-applied every time chrome is applied.

### Reading children

- **children-answered-from-cache**: A request for an item's children MUST be answered from the cached row table, never by blocking the tree on the data source.
- **uncached-branch-triggers-load-and-empty-answer**: A request for the children of a branch with no cached answer MUST return an empty array immediately and MUST trigger a load of that branch.
- **load-skipped-while-in-flight**: A load already in flight for a handle MUST NOT trigger a second, concurrent ask of the provider for that same handle.
- **load-marked-stale-when-busy**: A load requested for a handle that already has one in flight MUST be remembered and re-issued once the in-flight one completes.
- **load-skipped-for-unreachable-handle**: A load MUST NOT be issued for a non-root handle whose row is not currently reachable in the table (never loaded, orphaned pending settlement, or already forgotten).
- **disclosure-driven-by-declared-state**: Whether a row offers a disclosure triangle MUST be determined solely by `item.collapsibleState.isExpandable`, independent of how many children (if any) a load of that row actually returns.
- **load-bounded-by-budget**: A children load MUST be bounded by `childrenBudget` (default 30 seconds).
- **timeout-logged**: A children load that exceeds `childrenBudget` MUST log an error.
- **timeout-leaves-branch-askable**: A children load that exceeds `childrenBudget` MUST NOT adopt any rows for that branch — the branch stays unread, not recorded as empty — and MUST remain askable by a later expansion, refresh, or the stale re-ask mechanism below.
- **late-answer-discarded-when-defunct**: A children answer that arrives after the pane has begun teardown, or for a non-root handle whose row no longer exists, MUST be discarded without updating the tree.
- **successful-load-updates-table-and-redraws**: A successful children answer MUST replace that branch's rows in the table — reusing the existing row object (and its already-loaded subtree) for every id that was already drawn somewhere, whether under this parent or another — and MUST redraw both that branch and any other branch a moved row was taken from.
- **duplicate-child-id-deduplicated**: When a single children answer contains the same item id more than once, only the first occurrence MUST be kept; the rest MUST be dropped.
- **moved-row-preserves-identity**: When an item dropped by one already-loaded branch is claimed by a different branch before the refresh that dropped it has settled (no loads in flight), the row MUST keep its object identity and its already-loaded subtree, regardless of the order in which the two branches' answers arrive.
- **orphan-return-by-same-parent-is-new-row**: When the same branch that stopped naming an id later names that same id again (in a separate, subsequent refresh), that id MUST be treated as a new row — its previous subtree discarded — rather than as a preserved one.
- **prune-orphans-after-settling**: Once no children loads are in flight, a row dropped during that refresh and never reclaimed by any branch MUST be forgotten, along with everything beneath it; a row still claimed by some branch MUST NOT be forgotten.
- **forget-is-cycle-safe**: Forgetting a handle and its descendants MUST terminate even when the extension's declared ids form a cycle, visiting each handle at most once.

### Redraw, expansion, selection

- **redraw-preserves-selection**: Redrawing a branch MUST preserve the prior selection across the reload for every previously-selected row that still exists afterward.
- **redraw-narrowing-selection-notifies-source**: If a redraw's restored selection contains fewer rows than were selected before it, the data source MUST be told the selection changed.
- **redraw-suppresses-source-notifications**: While the tree reloads for a redraw, the tree's own selection and expand/collapse notifications that the reload itself triggers MUST NOT be forwarded to the data source.
- **default-expansion-applied-once**: A child row whose `collapsibleState` is `.expanded` MUST be automatically expanded exactly once, the first time it is drawn under its current parent; a branch the user has since closed MUST stay closed through every later redraw.
- **expansion-request-triggers-load**: Expanding a row whose children have not yet been loaded MUST trigger a load for that row's handle.
- **expand-collapse-reported-to-source**: Expanding or collapsing a row by user action (not by the pane's own automatic expansion or a redraw) MUST report the corresponding expand/collapse to the data source.

### Tree-data change notifications

- **targeted-change-reloads-one-branch**: A tree-data change reported for a specific handle whose row is currently in the table MUST reload only that branch.
- **untargeted-change-reloads-loaded-branches**: A tree-data change reported with no handle, or with a handle not currently in the table, MUST re-ask every branch this pane has already loaded.
- **untargeted-change-reasks-root-when-empty**: If the table holds no loaded branches at all when an untargeted change arrives, the root MUST also be asked.
- **change-after-teardown-ignored**: A tree-data change reported after the pane has begun teardown MUST be ignored.

### Row rendering

- **row-view-recycled**: Rows MUST be drawn with a recycled row view, not a freshly built view hierarchy per row.
- **row-icon-from-symbol-name**: A row whose `symbolName` resolves to a system symbol image MUST show that image tinted the `.secondaryText` semantic color; a row with no symbol name, or one that fails to resolve, MUST hide the icon entirely.
- **row-label-shows-item-label**: A row's label MUST show `item.label`, truncating with a tail ellipsis when it does not fit.
- **row-caption-from-description**: A row's caption MUST show `item.description` when it is non-nil and non-empty, and MUST be hidden otherwise.
- **row-tooltip-fallback**: A row's tooltip MUST be `item.tooltip` when present, and MUST fall back to `item.label` otherwise.
- **row-background-recycled**: The row's background view MUST also be a recycled view rather than a freshly built one per row.

### Activation

- **double-click-activates**: Double-clicking a row MUST activate that row's item through the data source.
- **return-key-activates-selection**: Pressing Return or the numeric-keypad Enter while a row is selected MUST activate the selected row's item.
- **alternate-return-path-activates-selection**: When the platform delivers Return through an alternate text-editing-command path instead of a raw key event, the pane MUST activate the selected row's item — the same outcome as `return-key-activates-selection`, reached through the other path the platform can take.
- **other-keys-pass-through**: A key event that is neither Return nor keypad Enter MUST be left unhandled by the pane (passed through to the platform's default handling) rather than consumed.

### Pane title & teardown (tree component)

- **outline-pane-title-source-or-fallback**: The tree component's pane title MUST be the data source's title when it is non-nil and non-empty, and MUST fall back to the contributed view's manifest name otherwise.
- **outline-teardown-idempotent**: Teardown MUST have no additional effect when invoked more than once on the same instance.
- **outline-teardown-releases-callbacks-only-if-owner**: Teardown MUST clear the tree-data-change, chrome-change and provider-replacement callbacks on the data source, and MUST report visibility `false`, only when this pane is still that data source's recorded callback owner at teardown time; a superseded pane's teardown MUST NOT touch a data source it no longer owns.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

