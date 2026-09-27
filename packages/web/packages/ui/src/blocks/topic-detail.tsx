"use client"

import {
  Fragment,
  useCallback,
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type ComponentProps,
  type CSSProperties,
  type MouseEvent as ReactMouseEvent,
  type PointerEvent,
  type ReactElement,
  type ReactNode,
} from "react"

import { ChevronRight, Circle, Loader2, Plus, Search, Trash2, X } from "lucide-react"

import { AlertModal } from "../components/alert-modal"
import { Checkbox } from "../components/checkbox"
import { CollapseToggle } from "../components/collapse-toggle"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "../components/tooltip"
import { cn } from "../lib/utils"

// Faithful port of the adh.com/home topic rail, originally translated 1:1 from
// hub/src/components/settings/SettingsLayout.tsx + its settings.css (.settings-layout /
// .settings-nav / .settings-nav-item / .settings-nav-divider / .settings-content) into
// utilities with the apt-* tokens (--accent → apt-gold, --text → apt-text, --border →
// apt-border …). That original is GONE — the hub now renders this, so this file is the
// source of truth and there is nothing left to stay faithful to.

export interface TopicDetailItem {
  id: string
  label: string
  /** Part of the NAME, set beside it at the same size and weight — a shard, a variant, a
   *  qualifier without which two rows are indistinguishable. Distinct from {@link sublabel},
   *  which is metadata ABOUT the row and is drawn small and dim: a word the reader needs in
   *  order to tell this row from the one under it is not metadata, and shrinking and greying
   *  it makes two rows that differ only there read as duplicates. Truncates last, after both
   *  the label and the sublabel, for the same reason. */
  labelSuffix?: ReactNode
  /** Small dim second line (e.g. a reverse-domain identifier). */
  sublabel?: string
  /** Render `sublabel` INLINE after the label on ONE line (dim), instead of stacked on a
   *  second line — for dense entity lists (sites / groups / platforms) where a single row
   *  per item is wanted. The label keeps layout priority (grows + truncates first); the
   *  sublabel shrinks + truncates after it. No effect in the icon-only (collapsed/covered)
   *  strips, which hide the label entirely. */
  inlineSublabel?: boolean
  /** A few lines of the row's CONTENT, under the label — a note's body, a message's text. Dim,
   *  clamped to {@link previewLines}, and shown only where the label is (never in the collapsed /
   *  covered icon strips). Opt-in: a list that sets no `preview` renders exactly as it did. */
  preview?: string
  /** How many lines of {@link preview} to show, clamped to 0-4 (default 1). ZERO renders no
   *  preview at all, so a list whose row height is a user preference can keep passing `preview`
   *  and let this one number carry the setting — including its "off" position. */
  previewLines?: number
  /** What this topic is for — one or two sentences. **This component renders it nowhere.** It fed the
   *  card grid that a level could opt into for its unselected frontier, and that opt-in is gone (the
   *  unselected frontier is the select nudge and nothing else), so setting it changes no pixel here. It
   *  survives because hosts carry the same row shape into surfaces that DO show a blurb (a selected
   *  topic's `EmptyState`); to explain a LIST, use the level's `overviewHelp`, which is the copy the
   *  nudge renders. */
  description?: string
  /** 16px leading icon; tints with the label (currentColor). The rail is always
   *  collapsible, so every row is guaranteed an icon — a neutral ring fills in
   *  when omitted — so the collapsed icon-only strip never shows a blank slot. */
  icon?: ReactNode
  /** What choosing this row leads to — another topic LIST, or the DETAIL (a FINAL CHOICE).
   *  Overrides the level's `leadsTo` default for this one row; unset on both means `"detail"`.
   *  Declared, not inferred: the cascading view's detail hold and final-choice auto-collapse
   *  (hold-the-detail-until-the-final-choice) key off it at click time. `"detail"` is the
   *  fail-safe — an undeclared row swaps the pane immediately, it can never hold it hostage. */
  leadsTo?: "list" | "detail"
  /** Render a separator row after this item (hub: before Settings). */
  dividerAfter?: boolean
  /** With {@link dividerAfter}: a caption under the separator naming the section it opens
   *  (the feature picker's "Coming soon"). Hidden in the icon-only strips, like every label. */
  dividerLabel?: string
  /** Render a flexible spacer after this item, pushing every following item to the
   *  rail's bottom edge (e.g. a bottom-pinned Settings). Applies in the collapsed /
   *  covered icon strips too. */
  spacerAfter?: boolean
  /** Dimmed + non-clickable (hub: scoped topics while "All" is active). */
  disabled?: boolean
  /** BATCH MODE only: the row's CHECKBOX is disabled while the row itself stays selectable —
   *  a tick that is a statement of fact rather than a control (the feature picker's
   *  already-added features, whose details you can still read). */
  checkDisabled?: boolean
  /** Trailing accessory pinned to the row's right edge (e.g. a warn Badge or a
   *  count). Hidden in icon-only modes (collapsed / covered), like the label. */
  trailing?: ReactNode
  /** Enable a right-justified trash button on this row, revealed on hover (and keyboard focus).
   *  Clicking it opens a confirmation dialog; ON CONFIRM this runs (may be async — the dialog shows
   *  a spinner until it settles). Only rendered in the expanded list, never the collapsed/covered
   *  icon strips. In the hierarchical stack the selection connector line breaks around the button. */
  onDelete?: () => void | Promise<void>
  /** Accessible name for the trash button and the confirm dialog's subject. Defaults to `label`. */
  deleteLabel?: string
  /** Confirmation body copy. Defaults to a generic "can't be undone" warning. */
  deleteConfirm?: ReactNode
  /** Marks this row as holding a field that is blocking some other action elsewhere in the view
   *  (e.g. a disabled Save whose blocking field lives on this topic's pane). The row gets an amber
   *  dot on its icon — visible in the expanded list AND the collapsed / covered icon strips, which
   *  is where a user hunting for a greyed-out Save most needs it — plus a screen-reader-only
   *  "needs attention" so the marker is not colour-only. It also carries `data-blocked="true"`
   *  for callers and tests that need to find the row programmatically. */
  blocked?: boolean
}

/** A leading rail row rendered ABOVE the topics (e.g. a custom list header, or a PopupMenu control in
 *  FocusedTopicDetail). A function form receives the rail's collapsed state so it can shrink/hide when
 *  undisclosed. Rendered only when provided — an absent slot reserves NO space (the first topic sits at
 *  the top padding). This is distinct from the `+` create affordance (`onNew`) — first in a titled
 *  rail's list toolbar — which the hierarchical stack uses for its "New …" button. */
export type RailSlot = ReactNode | ((collapsed: boolean) => ReactNode)

/**
 * SEARCH for one topic list: a magnifier in the list's toolbar that pops a query field up OVER the
 * list. Popped rather than pinned because most rails are far too narrow to hold a filter field
 * beside anything else (Mike, 2026-09-24: the old page-wide filter strip was "clunky", and a field
 * squeezed into a 180px rail is worse) — so the field floats at a readable width and gets out of
 * the way when dismissed.
 *
 * Pass `{}` and the rail filters its own rows on label + sublabel. Pass `query` (with
 * `onQueryChange`) and the HOST owns the query and the filtering — for a list whose rows are
 * matched on more than what they show, or whose query is also read elsewhere.
 */
export interface TopicListSearch {
  /** Controlled query. Omit to let the rail hold it and filter its own rows. */
  query?: string
  /** Every keystroke, controlled or not. */
  onQueryChange?: (query: string) => void
  /** Placeholder and accessible name for the field. Defaults to "Search". */
  placeholder?: string
}

/** Whether a list has anything for its toolbar. The hierarchical stacks ask it of every visible
 *  level, and once one does, every titled rail reserves the row — so first rows stay aligned
 *  across the rails instead of stepping down under whichever one has tools. */
export function hasListTools(level: {
  onNew?: unknown
  search?: unknown
  titleActions?: unknown
}): boolean {
  return !!(level.onNew || level.search || level.titleActions)
}

/** A plain `<button>`'s props, less the accessible name, which `label` gives. */
export type ListToolButtonProps = Omit<ComponentProps<"button">, "aria-label"> & {
  /** The accessible name, and the tooltip unless `title` says otherwise. Required: the button is
   *  an icon and nothing else, so this is all a screen reader or a hovering pointer gets. */
  label: string
  /** Gold rather than muted gray: the tool is acting on the list right now (a create in
   *  progress, a query narrowing the rows). */
  active?: boolean
}

/**
 * One tool on a list's toolbar: the icon it is handed as `children`, muted gray, with no button
 * chrome. The rail draws its own `+`, magnifier and ✕ with it; a host's `titleActions` should
 * too, so a tool it adds sits beside the rail's as one of a set. (A gear that opens a MENU is
 * `GearMenuTrigger`'s job; this is a tool that acts on one click, or opens a dialog.)
 *
 * It is a component because the look was a class literal, repeated in every tool here and copied
 * out by hosts: the Manage features puzzle piece copied it, while the bucket gear beside a `+`
 * went with a ghost `Button` — drawn larger and brighter than the `+`, the look the puzzle piece
 * had already been moved off (Mike, 2026-09-24). A literal copied into a host drifts on the next
 * token change; a component cannot.
 */
export function ListToolButton({
  label,
  active = false,
  title,
  type = "button",
  className,
  ...rest
}: ListToolButtonProps): ReactElement {
  return (
    <button
      {...rest}
      type={type}
      aria-label={label}
      title={title ?? label}
      className={cn(
        "flex shrink-0 items-center justify-center rounded p-0.5 outline-none hover:text-apt-text focus-visible:ring-2 focus-visible:ring-apt-gold/40",
        active ? "text-apt-gold" : "text-apt-text-muted",
        className,
      )}
    />
  )
}

/** The rows a self-filtering rail shows for `query`: label or sublabel contains it, case-folded.
 *  The SELECTED row always survives — filtering it away would leave the detail pane showing an
 *  item the list no longer admits to, with no row to carry the selection bar. */
export function filterTopicItems(
  items: TopicDetailItem[],
  query: string,
  selectedId: string | null,
): TopicDetailItem[] {
  const q = query.trim().toLowerCase()
  if (!q) return items
  return items.filter(
    (it) =>
      it.id === selectedId ||
      it.label.toLowerCase().includes(q) ||
      (it.sublabel?.toLowerCase().includes(q) ?? false),
  )
}

/** The nearest ancestor of `el` that CLIPS it sideways — computed `overflow-x` anything but
 *  `visible` — or null when nothing above it does.
 *
 *  The search pop-over asks how far it may spill. In the hub's covered stack every rail sits in
 *  an `overflow-hidden` column wrapper with an inline z-index, no wider than the rail, so on a
 *  rail narrower than 16rem the wrapper cut off the pop-over's ✕ and the end of the typed query
 *  (and `z-30` could not lift it: the clip is on an ancestor). The pop-over is capped at this
 *  box's right edge instead. A portal would escape the clip, but the covered stack closes an
 *  open hover branch on any `pointerover` outside `[data-htd-col]`, so a pop-over portalled out
 *  of its column would collapse the rail under the pointer that reached for it. */
function horizontalClipOf(el: HTMLElement): HTMLElement | null {
  for (let node = el.parentElement; node; node = node.parentElement) {
    const overflowX = getComputedStyle(node).overflowX
    // EMPTY is a style engine with nothing to say (jsdom resolves only what a sheet or an inline
    // style declared), not a clip.
    if (overflowX && overflowX !== "visible") return node
  }
  return null
}

// One shared element reference for icon-less rows — stable across renders so
// React's reconciler skips it. The rail always collapses to an icon-only strip,
// so every row needs a guaranteed leading icon; this fills in for rows that omit
// one. `||` (not `??`) also fills in for a `false` node from `cond && <Icon/>`.
const FALLBACK_ICON = <Circle size={16} aria-hidden />

// The clamp for each supported preview height. A lookup and not `line-clamp-${n}`: Tailwind reads
// the source text, so a class it never sees written out is a class it never generates.
const PREVIEW_CLAMP: Record<number, string> = {
  1: "line-clamp-1",
  2: "line-clamp-2",
  3: "line-clamp-3",
  4: "line-clamp-4",
}

// The rail's natural (full) width and the collapsed icon-strip width. Dragging the rail's
// trailing border narrower than a third of FULL snaps it to undisclosed; dragging it past
// FULL snaps it back to full.
// The rail's natural (full) width and the collapsed icon-strip width. Exported so
// HierarchicalTopicDetail's fit math uses the SAME contract (one authoritative home).
export const FULL_RAIL = 240
export const COLLAPSED_RAIL = 48

/**
 * The range an AUTO-FIT rail is allowed to land in (see `TopicRail`'s `onFit`).
 *
 * A rail measured to its longest row would otherwise be as unreadable as one that truncates
 * everything: a list of one-word rows would come out as a sliver with a header that no
 * longer fits, and a list holding one pathological row would eat the detail pane. So the
 * measurement decides WITHIN these, and the floor is what a titled header with its collapse
 * toggle and `+` needs rather than a number picked for the rows.
 */
export const MIN_FIT_RAIL = 150
export const MAX_FIT_RAIL = 420

/** The root font size this family's layout math resolves `rem` against — READ FROM THE DOCUMENT,
 *  not assumed. 16 is the browser default, and it is what every hard-coded number here was written
 *  for; the adh family sets `html` to 12px, so each of them was a THIRD too generous. The visible
 *  consequence was a fit range whose FLOOR (150px, "what a titled header needs") was really 200
 *  design px at a 12px root — wide enough to swallow every short rail, so a two-row rail came out
 *  as wide as a forty-row one. It is the same bug `minDetailPx` was already fixed for.
 *  SSR has no document; 16 is the only answer available there, and the first client measurement
 *  corrects the layout before paint. */
export function rootFontPx(): number {
  if (typeof document === "undefined") return 16
  const px = parseFloat(getComputedStyle(document.documentElement).fontSize)
  return Number.isFinite(px) && px > 0 ? px : 16
}

/** A layout number written against a 16px root, expressed in THIS document's units. */
export function railPx(designPx: number): number {
  return (designPx * rootFontPx()) / 16
}

// How long a pointer (or the keyboard focus) must rest on a row before it counts as intent.
// Short enough to be invisible ahead of a click, long enough that sweeping down a list warms
// nothing — a per-row fire would cost MORE requests than the caching saves.
const PREFETCH_DWELL_MS = 100

function TopicList({
  items,
  selectedId,
  onSelect,
  emptyLabel,
  railSlot,
  railSlotActive,
  collapsed,
  covered = false,
  isRoot = false,
  selectionStyle = "bar",
  rowDisclosure = false,
  hoverBar = true,
  hideItemIcons = false,
  onPrefetch,
  checkable = false,
  checkedIds,
  onToggleChecked,
}: {
  items: TopicDetailItem[]
  selectedId: string | null
  onSelect: (id: string) => void
  emptyLabel: ReactNode
  /** Optional leading row above the topics (a custom header / control). Rendered only when provided. */
  railSlot?: RailSlot
  /** Move the gold selection bar onto the rail slot (nothing in the list selected). */
  railSlotActive?: boolean
  /** Currently collapsed → icon-only rows; labels move to title/aria-label. */
  collapsed?: boolean
  /** This is the ROOT (outermost) list: its selected row shows a leading gold dash (marker style). */
  isRoot?: boolean
  /** Covered (peeking under a child in the "covered" style): render a clean LEFT-aligned icon strip
   *  (icon only, so the icon stays inside the ~40px peek). The whole list is revealed on hover by the
   *  covered stack (it re-layers the real rail full-width above its neighbours), so there is no
   *  per-row popover here. */
  covered?: boolean
  /** How a selected row is marked: `"bar"` (default) is the classic gold left bar — for standalone
   *  TopicDetail and the minimized stack. `"marker"` drops the bar for the dash (root) + the
   *  parent→child connector line (drawn by the covered stack's overlay). */
  selectionStyle?: "bar" | "marker"
  /** Whether hovering an unselected row previews the left bar. Default true (every existing rail).
   *  `false` removes it: the cascading menus want no hover bar — there, hover is conveyed by the row
   *  UN-DIMMING, and a second white bar on top of that just reads as noise. */
  hoverBar?: boolean
  /** Drop the LEADING icon from every row in this list. Expanded list only: the collapsed
   *  and covered strips are icon-only — the icon is the entire row there — so this is
   *  ignored while `iconOnly` is true. For lists whose rows have no identity icon worth
   *  showing (research's documents), where the fallback `Circle` was noise. */
  hideItemIcons?: boolean
  /** Trailing chevron on every selectable row, signalling that picking it discloses another pane —
   *  the narrow (nav-stack) layout's only affordance for that, since it has no peeking sibling column
   *  to hint at what a tap pushes in. Hidden on a `disabled` row (it isn't going anywhere) and in the
   *  icon-only layouts (no room, and the covered/minimized styles already show that via layering). */
  rowDisclosure?: boolean
  /** Warm this row before it is clicked. Called with the row's id once the pointer or the
   *  keyboard focus has rested on it for {@link PREFETCH_DWELL_MS}. Fire-and-forget: the row
   *  never waits on it and never shows anything for it. Omit for no prefetching at all. */
  onPrefetch?: (id: string) => void
  /** BATCH MODE: show a checkbox on every row, so several can be acted on at once. The row button
   *  keeps its own single-selection behaviour underneath — ticking a box is not selecting a row,
   *  and a surface that conflated the two would lose the open detail every time the user ticked a
   *  fourth thing to delete. Ignored in the icon-only strips (collapsed / covered): a 16px box in a
   *  40px peek has nothing to say which row it belongs to. Drive it with `useBatchSelect`, which
   *  owns the one rule that matters — leaving the mode clears the ticks. */
  checkable?: boolean
  /** Which rows are ticked. Read-only: the row calls {@link onToggleChecked} and the owner writes. */
  checkedIds?: ReadonlySet<string>
  onToggleChecked?: (id: string) => void
}) {
  // Icon-only layouts share the no-label row: `collapsed` CENTRES the icon (minimized icon strip);
  // `covered` keeps it LEFT-aligned so the icon stays inside the peek.
  const iconOnly = !!collapsed || covered

  // Row delete: a row's hover-revealed trash button opens this confirm; ON CONFIRM the item's
  // (possibly async) onDelete runs, with a spinner shown until it settles. Reuses the shared
  // AlertModal so the prompt matches every other destructive confirm on the platform.
  const [pendingDelete, setPendingDelete] = useState<TopicDetailItem | null>(null)
  const [deleting, setDeleting] = useState(false)
  // ONE timer for the whole list: intent moves from row to row, and a per-row timer would let a
  // sweep leave several armed at once.
  const dwellRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const disarmPrefetch = useCallback(() => {
    if (dwellRef.current) {
      clearTimeout(dwellRef.current)
      dwellRef.current = null
    }
  }, [])
  const armPrefetch = useCallback(
    (id: string) => {
      if (!onPrefetch) return
      if (dwellRef.current) clearTimeout(dwellRef.current)
      dwellRef.current = setTimeout(() => {
        dwellRef.current = null
        onPrefetch(id)
      }, PREFETCH_DWELL_MS)
    },
    [onPrefetch],
  )
  useEffect(() => disarmPrefetch, [disarmPrefetch])
  // Retain the last target through the dialog's close animation so its title doesn't blank out.
  const lastDeleteRef = useRef<TopicDetailItem | null>(null)
  if (pendingDelete) lastDeleteRef.current = pendingDelete
  const deleteTarget = pendingDelete ?? lastDeleteRef.current
  const runDelete = async () => {
    if (!pendingDelete?.onDelete) {
      setPendingDelete(null)
      return
    }
    try {
      setDeleting(true)
      await pendingDelete.onDelete()
      setPendingDelete(null)
    } catch {
      // Leave the dialog open (no longer busy) so the user can retry or cancel; the consumer's
      // onDelete owns surfacing the failure.
    } finally {
      setDeleting(false)
    }
  }

  const itemButton = (item: TopicDetailItem, active: boolean) => {
    const hideLabel = iconOnly
    const centered = !!collapsed
    // Never in the icon-only strips: there the icon IS the row.
    const hideIcon = hideItemIcons && !iconOnly
    // Every row is guaranteed a leading icon so the icon-only strip never shows a blank slot.
    const icon = item.icon || FALLBACK_ICON
    // A deletable expanded row reserves extra right padding so the label never runs under the
    // hover-revealed trash button (and the rail width accounts for it).
    const deletable = !!item.onDelete && !hideLabel
    // The preview, resolved to the one thing the row renders: its text and its clamp. `previewLines`
    // is clamped rather than trusted — it comes from a user setting, and a number outside 0-4 has no
    // class to render, which would silently drop the clamp and print the whole note into the rail.
    const previewLines = Math.max(0, Math.min(4, Math.trunc(item.previewLines ?? 1)))
    const previewText = item.preview?.trim() ?? ""
    const preview =
      previewLines > 0 && previewText !== ""
        ? { text: previewText, clamp: PREVIEW_CLAMP[previewLines] }
        : null
    return (
      <button
        type="button"
        data-htd-row
        // The icon-only strips, marked so the touch-row rule in styles/components.css can size
        // them from what they hold — the icon alone, and for a collapsed strip the `py-1.5`
        // below. Read as a labelled row, a collapsed strip grew 8% on a touch screen instead
        // of 30% and sat its icon off-centre, and a covered one grew 38%.
        data-htd-strip={centered ? "collapsed" : iconOnly ? "covered" : undefined}
        data-blocked={item.blocked ? "true" : undefined}
        disabled={item.disabled}
        onClick={() => {
          // Covered lists pure-SELECT: a click only CHANGES the selection — it never toggles/unselects,
          // and is a no-op if this row is already selected. Selecting clears the descendant lists and
          // shows the chosen item's detail (onSelect's job). Uncovered lists keep the package's toggle
          // (re-click a selected row to deselect).
          if (covered && active) return
          onSelect(item.id)
        }}
        // Never ARM on the row that is already open: a prefetch is a guess about where the user is
        // going, and this item's read has already happened. Warming it again re-reads it behind the
        // pane the user is looking at, and the read spins this very list. The DISARM handlers stay
        // unconditional — they only ever cancel a timer another row armed.
        onPointerEnter={onPrefetch && !active ? () => armPrefetch(item.id) : undefined}
        onPointerLeave={onPrefetch ? disarmPrefetch : undefined}
        onFocus={onPrefetch && !active ? () => armPrefetch(item.id) : undefined}
        onBlur={onPrefetch ? disarmPrefetch : undefined}
        aria-current={active ? "true" : undefined}
        // Icon-only rows have no visible text → carry the label as the accessible name, plus the
        // blocked state the amber dot conveys visually (the sr-only span below can't do it here —
        // aria-label replaces the element's content for AT).
        aria-label={
          hideLabel ? (item.blocked ? `${item.label}, needs attention` : item.label) : undefined
        }
        className={cn(
          // .settings-nav-item: mono, 0.8rem, tracking 0.02em.
          "relative flex w-full border-l-2 border-transparent bg-transparent transition-colors",
          // A row that is one or two lines tall centres its icon against them; a row carrying a
          // preview is mostly preview, so centring would float the icon down beside the body text
          // instead of beside the name it labels.
          preview ? "items-start" : "items-center",
          "[&_svg]:h-4 [&_svg]:w-4 [&_svg]:shrink-0",
          centered
            ? "justify-center py-1.5"
            : cn(
                // `pl-2` is the leading gap from the list's edge to the row's ICON — half the
                // original inset, so rows sit closer to the edge and a covered list's 40px peek
                // shows more of its icon. The root's selection dash below is sized to fit inside it.
                // In batch mode the checkbox is a SIBLING sitting in that gap (a box cannot nest in
                // the row button), so the gap widens to hold it rather than the label sliding under it.
                "gap-2 pt-1 pb-0.5 text-left font-mono text-[0.8rem] tracking-[0.02em]",
                checkable && !hideLabel ? "pl-8" : "pl-2",
                deletable ? "pr-9" : "pr-3",
              ),
          item.disabled
            ? "cursor-default text-apt-text-dim"
            : active
              ? // "marker" selection (the hierarchical covered stack): no gold bar — selection shows as
                // the leading dash (root) + the connector line from the parent (drawn by the stack).
                // "bar" selection (standalone TopicDetail, the minimized stack): the classic gold left
                // bar, since those have no connector overlay to convey selection.
                selectionStyle === "marker"
                ? "text-apt-gold"
                : "border-l-apt-gold text-apt-gold"
              : cn("cursor-pointer text-apt-text", hoverBar && "hover:border-l-apt-text"),
        )}
      >
        {/* Root list, marker style: the selected row is marked by a FULL-HEIGHT vertical bar flush
            with the row's left edge (Mike — replaces the old horizontal dash that sat in the `pl-2`
            leading gap). Drawn as an element rather than the row's `border-l` because the border is
            the hover affordance's channel and a marker rail must not depend on that. */}
        {active && isRoot && !centered && selectionStyle === "marker" && (
          // `-left-0.5`, not `left-0`: the row carries a 2px transparent `border-l` (the hover
          // affordance's channel), and an absolute child resolves against the PADDING box — so
          // `left-0` would sit 2px inside the row's real edge. The negative offset backs it onto the
          // border box, flush with the column edge.
          <span aria-hidden className="absolute inset-y-0 -left-0.5 w-0.5 bg-apt-gold" />
        )}
        {/* Decorative: the label (text or aria-label) is the name, so the icon is hidden from AT. */}
        {!hideIcon && (
          <span aria-hidden data-htd-icon className="relative flex shrink-0">
            {icon}
            {/* The blocked marker rides the ICON rather than the trailing accessory slot, because
                the accessory is dropped in the collapsed / covered icon strips — exactly the modes
                where the user can't read the label and most needs to see WHICH topic is holding
                Save down. The ring punches it out of whatever the row sits on. */}
            {item.blocked && (
              <span
                data-htd-blocked
                className="absolute -top-0.5 -right-1 h-1.5 w-1.5 rounded-full bg-apt-orange ring-2 ring-apt-nav"
              />
            )}
          </span>
        )}
        {/* No icon to ride, so the marker stands on its own. `hideItemIcons` is about
            IDENTITY — a level saying its rows need no leading glyph to tell them apart — and
            `blocked` is STATE, which no level asked to hide. Dropping the dot with the icon
            left the sr-only announcement below with nothing visible behind it: a row that
            reads "needs attention" and looks exactly like its neighbours. */}
        {hideIcon && item.blocked && (
          <span
            aria-hidden
            data-htd-blocked
            className="h-1.5 w-1.5 shrink-0 rounded-full bg-apt-orange"
          />
        )}
        {!hideLabel && (
          <span
            data-htd-label
            className={cn(
              "min-w-0",
              ((item.inlineSublabel && item.sublabel) || item.labelSuffix) && "flex-1",
            )}
          >
            {item.inlineSublabel && item.sublabel ? (
              // Single-line row: label + dim sublabel share one line. The label grows and
              // truncates first (it's the identifier that matters); the sublabel shrinks and
              // truncates after it so a long secondary string can't crowd the label out.
              <span className="flex min-w-0 items-baseline gap-2">
                <span className="min-w-0 flex-1 truncate">{item.label}</span>
                {item.labelSuffix && (
                  <span className="min-w-0 shrink-0 truncate">{item.labelSuffix}</span>
                )}
                <span className="min-w-0 shrink truncate text-[0.7rem] text-apt-text-dim">
                  {item.sublabel}
                </span>
              </span>
            ) : item.labelSuffix ? (
              <span className="flex min-w-0 items-baseline gap-2">
                <span className="min-w-0 shrink truncate">{item.label}</span>
                <span className="min-w-0 shrink-0 truncate">{item.labelSuffix}</span>
              </span>
            ) : (
              <>
                <span className="block truncate">{item.label}</span>
                {item.sublabel && (
                  <span className="block truncate text-[0.7rem] text-apt-text-dim">
                    {item.sublabel}
                  </span>
                )}
              </>
            )}
            {/* The content preview sits under whichever headline shape the row uses, so a list can
                opt into it without also giving up its inline sublabel. `whitespace-pre-line` keeps
                the source's own line breaks — a note previewed as one run-on paragraph reads
                nothing like the note. */}
            {preview && (
              <span
                data-htd-preview
                className={cn(
                  "mt-0.5 block whitespace-pre-line text-[0.7rem] leading-snug text-apt-text-dim",
                  preview.clamp,
                )}
              >
                {preview.text}
              </span>
            )}
          </span>
        )}
        {/* Colour alone is not a signal. The dot lives inside the aria-hidden icon, so the row's
            accessible name carries the state instead — appended AFTER the label here (an
            accessible name is content order), and folded into `aria-label` when the label is
            hidden, since aria-label REPLACES the content and would silence this span.

            Gated on !hideLabel but NOT on hideIcon, and that is now correct: a level setting
            hideItemIcons still draws the standalone dot above, so this announcement always has
            a visible counterpart. (It used to have none — the dot was nested inside the icon
            span, so hideItemIcons hid state along with identity.) */}
        {item.blocked && !hideLabel && <span className="sr-only">, needs attention</span>}
        {!hideLabel && (item.trailing || rowDisclosure) && (
          // `data-htd-trailing`: the stack's selection connector leaves the row from this slot's
          // right edge, so the line never draws over a count or badge (see `rowExitEl`).
          <span data-htd-trailing className="ml-auto flex shrink-0 items-center gap-1 pl-1.5">
            {item.trailing}
            {rowDisclosure && !item.disabled && (
              <ChevronRight size={14} aria-hidden className="shrink-0 text-apt-text-dim" />
            )}
          </span>
        )}
      </button>
    )
  }

  return (
    <TooltipProvider>
      {/* min-h-full lets a `spacerAfter` flex spacer push trailing items (e.g. a
          bottom-pinned Settings) to the rail's bottom when the list is shorter than it. */}
      <ul className="m-0 flex min-h-full list-none flex-col p-0">
        {/* Optional leading rail slot (a custom header / control). Rendered ONLY when a railSlot is
            supplied — an absent slot reserves no space, so the first topic sits at the list's top
            padding. Carries the gold selection bar when nothing is focused (railSlotActive). */}
        {railSlot !== undefined && (
          <li
            className={cn(
              "flex min-h-[2.15rem] items-center border-l-2 border-transparent",
              collapsed && "justify-center",
              railSlotActive && "border-l-apt-gold",
            )}
          >
            {typeof railSlot === "function" ? railSlot(!!collapsed) : railSlot}
          </li>
        )}
        {items.length === 0 && (
          <li>
            <p
              className={cn(
                "font-mono text-apt-text-dim",
                collapsed ? "px-1 py-2 text-center text-[0.7rem]" : "px-2 py-2 text-[0.8rem]",
              )}
            >
              {emptyLabel}
            </p>
          </li>
        )}
        {items.map((item) => {
          const active = item.id === selectedId
          const button = itemButton(item, active)
          const deletable = !!item.onDelete && !iconOnly
          const checkboxed = checkable && !iconOnly
          return (
            <Fragment key={item.id}>
              <li>
                {collapsed ? (
                  // Collapsed to an icon-only strip: the row's label is no longer visible, so a
                  // hover/focus tooltip names it (replaces the native title — themed, with a delay).
                  <Tooltip>
                    <TooltipTrigger render={button} />
                    <TooltipContent side="right" arrow={false} className="max-w-none whitespace-nowrap">
                      {item.label}
                    </TooltipContent>
                  </Tooltip>
                ) : deletable || checkboxed ? (
                  // The row and its accessories render as SIBLINGS (neither a checkbox nor a button
                  // can nest inside the row button). The trash carries `data-htd-delete` so the
                  // hierarchical stack's connector overlay breaks the selection line around it (a
                  // computed gap — the overlay paints above the rail, so occlusion is not possible).
                  <div className="group/htd-row relative">
                    {checkboxed && (
                      // Sits in the leading gap the row's `pl-8` opened. Above the row (`z-10`) so
                      // the tick lands on the box rather than changing the single selection — the
                      // whole point of batch mode is acting on rows OTHER than the open one.
                      <span
                        data-htd-check
                        className="absolute top-1/2 left-2 z-10 flex -translate-y-1/2 items-center"
                      >
                        <Checkbox
                          checked={checkedIds?.has(item.id) ?? false}
                          onCheckedChange={() => onToggleChecked?.(item.id)}
                          disabled={item.disabled || item.checkDisabled}
                          aria-label={item.label}
                        />
                      </span>
                    )}
                    {button}
                    {deletable && (
                    <button
                      type="button"
                      data-htd-delete
                      aria-label={`Delete ${item.deleteLabel ?? item.label}`}
                      title={`Delete ${item.deleteLabel ?? item.label}`}
                      onClick={(e) => {
                        e.stopPropagation()
                        setPendingDelete(item)
                      }}
                      className={cn(
                        "absolute top-1/2 right-[3px] z-10 flex size-[19px] -translate-y-1/2 items-center justify-center rounded",
                        "bg-apt-nav text-apt-text-dim opacity-0 outline-none transition-opacity",
                        "hover:text-apt-red focus-visible:opacity-100 focus-visible:ring-2 focus-visible:ring-apt-red/40 group-hover/htd-row:opacity-100",
                      )}
                    >
                      <Trash2 size={14} aria-hidden />
                    </button>
                    )}
                  </div>
                ) : (
                  button
                )}
              </li>
              {item.dividerAfter && (
                <li
                  role="separator"
                  aria-label={item.dividerLabel}
                  className={cn("my-1 h-px bg-apt-border", collapsed ? "mx-2" : "mx-3")}
                />
              )}
              {item.dividerAfter && item.dividerLabel && !iconOnly && (
                <li
                  aria-hidden
                  className="px-3 pt-1 pb-1 font-mono text-[0.6875rem] tracking-wide text-apt-text-muted uppercase"
                >
                  {item.dividerLabel}
                </li>
              )}
              {item.spacerAfter && <li aria-hidden className="min-h-4 flex-1" />}
            </Fragment>
          )
        })}
      </ul>
      {/* One confirm dialog per list; the target row is captured on trash-click. Destructive =
          red action, keyboard shortcuts off, initial focus on Cancel — so a delete is never a
          one-keystroke accident. `busy` shows a spinner and blocks dismissal during an async delete. */}
      <AlertModal
        open={pendingDelete != null}
        destructive
        title={`Delete ${deleteTarget?.deleteLabel ?? deleteTarget?.label ?? ""}?`}
        description={deleteTarget?.deleteConfirm ?? "This action can't be undone."}
        confirmLabel="Delete"
        cancelLabel="Cancel"
        busy={deleting}
        onConfirm={runDelete}
        onCancel={() => {
          if (!deleting) setPendingDelete(null)
        }}
      />
    </TooltipProvider>
  )
}

/**
 * One topic-list column: the darker `.settings-nav` aside with the disclosure toggle,
 * the scrollable list, and a trailing-border drag handle. Width is owned by the PARENT
 * (a CSS grid column), so this is reused as-is both as `TopicDetail`'s single rail and as
 * one of the flat sibling columns in `HierarchicalTopicDetail`. The drag handle measures
 * relative to this column's own left edge and reports a raw width up via `onResize`; the
 * parent clamps/snaps and decides collapse.
 */
export function TopicRail({
  items,
  selectedId,
  onSelect,
  emptyLabel,
  railSlot,
  railSlotActive,
  onNew,
  newLabel,
  newActive,
  titleActions,
  collapsed,
  onToggle,
  onResize,
  onResizeStart,
  onResizeEnd,
  footer,
  backSlot,
  leftControl,
  coveredShadow = false,
  showToggle = true,
  title,
  busy = false,
  railLabel,
  covered = false,
  isRoot = false,
  selectionStyle = "bar",
  headerSlot,
  className,
  rowDisclosure = false,
  onClose,
  closeLabel,
  denseBottom = false,
  hoverBar = true,
  hideItemIcons = false,
  onPrefetch,
  checkable = false,
  checkedIds,
  onToggleChecked,
  onFit,
  search,
  reserveToolbar = false,
}: {
  items: TopicDetailItem[]
  selectedId: string | null
  onSelect: (id: string) => void
  emptyLabel: ReactNode
  /** Optional leading row above the topics (a custom header / control). Rendered only when provided. */
  railSlot?: RailSlot
  /** Move the gold selection bar onto the rail slot (nothing in the list selected). */
  railSlotActive?: boolean
  /** Create affordance: when set, a `+` fires it — first in the list TOOLBAR of a titled rail,
   *  in the bare control strip of an untitled one. */
  onNew?: () => void
  /** Accessible name + tooltip for the `+` (e.g. "New Persona"). Defaults to "New". */
  newLabel?: string
  /** Tint the `+` gold to signal an in-progress create (nothing selected in the list). */
  newActive?: boolean
  /** Operations on the LIST (a tool menu, a gear of options, an Auto Configure), right-justified
   *  in the list toolbar. Only rendered with a `title`d, un-collapsed header. Named for where
   *  they used to ride — the title row — which every consumer across the fleet still spells. */
  titleActions?: ReactNode
  /** Make this list searchable — see {@link TopicListSearch}. Titled, un-collapsed rails only. */
  search?: TopicListSearch
  /** Render the (possibly empty) list toolbar even with no tools in it, so this rail's rows line
   *  up with a sibling rail that has one. The hierarchical stacks set it on every level once any
   *  visible level has a toolbar. */
  reserveToolbar?: boolean
  collapsed: boolean
  /** The click event is forwarded so the hierarchical stack can read its modifier keys (⌘/Ctrl-click
   *  = toggle every list). Callers that don't need it take no argument. */
  onToggle: (e: ReactMouseEvent<HTMLButtonElement>) => void
  /** Drag of the trailing border reports the column's new pixel width (raw — the parent
   *  clamps to FULL and snaps to collapsed below a third). Omit to hide the drag
   *  handle (fixed-width rails like the theme editor's property columns). */
  onResize?: (widthPx: number) => void
  onResizeStart?: () => void
  onResizeEnd?: () => void
  /** Pinned below the list (border-t) — e.g. a "New…" affordance at the rail's foot. */
  footer?: ReactNode
  /** Optional leading affordance pinned top-left (e.g. a drill-down "Back" button). */
  backSlot?: ReactNode
  /** Optional control pinned top-left of THIS rail (the "covered" style's `«`/`»` cover
   *  toggle, which lives on the child rail rather than its parent). Renders in place of the
   *  top strip's contents; mutually used with `showToggle=false` to drop the desktop collapse
   *  toggle the covered style doesn't use. */
  leftControl?: ReactNode
  /** Cast a subtle LEFT drop-shadow on this rail (the "covered" style uses it on a child whose
   *  parent is covered, so the stack reads as physically layered). Default off. */
  coveredShadow?: boolean
  /** Extra classes on the rail root. The rail sizes to its ROWS by default, which is right in a grid
   *  cell (the hierarchical stack's columns stretch it) and wrong in a flex pane that IS the whole
   *  screen — there it must be told to fill (`flex-1`), or the page shows through under the last row.
   *  Also the seam for dropping the trailing border when the rail spans the full width. */
  className?: string
  /** Show the desktop collapse toggle (the minimized style's `«` icon-strip toggle). Default
   *  true; the covered style passes false and supplies its own `leftControl` instead. */
  showToggle?: boolean
  /** A left-aligned heading naming the list (e.g. "Workspaces"), with a divider beneath. The control
   *  slot (covered `«`/`»` or a Back) sits where item ICONS start and the title where item LABELS
   *  start, so every titled list reserves the same header height and rows align vertically across
   *  lists. Omit (standalone TopicDetail) to keep the bare control strip with no header/divider. */
  title?: string
  /** A read is in flight for this list — its rows, or the item currently selected in it. Shows a
   *  small spinner immediately before the title. One spinner covers BOTH reads: from the user's
   *  side there is one list and one wait, and two spinners in one header would be noise. */
  busy?: boolean
  /** Accessible name for this rail's `<aside>` landmark. Defaults to "Topic list", which every
   *  rail in the fleet shares — override only where a reader navigates to this surface BY
   *  landmark and needs it told apart from the sibling rails open beside it. Deliberately not
   *  derived from `title`: that would rename every existing rail at once. */
  railLabel?: string
  /** This list is covered (peeking) in the "covered" style: rows render as a left-aligned icon
   *  strip. The covered stack reveals the whole list on hover by re-layering the real rail
   *  full-width above its neighbours (there is no per-row/header popover). */
  covered?: boolean
  /** This is the ROOT (outermost) list — its selected row shows the leading gold dash (marker style). */
  isRoot?: boolean
  /** Selected-row marking: `"bar"` (classic gold bar; default) or `"marker"` (dash + connector). */
  selectionStyle?: "bar" | "marker"
  /** Full-width row between the titled header and the list — the hook for the shared
   *  `ListHeader` (filter + actions) when an entity list lives inside the stack.
   *  Hidden while the rail is collapsed to an icon strip. */
  headerSlot?: ReactNode
  /** Trailing chevron on every selectable row (narrow/nav-stack mode's disclosure hint — see
   *  {@link TopicList}'s doc). Default off. */
  rowDisclosure?: boolean
  /** A right-justified CLOSE (✕) button in the list HEADER. The hierarchical stacks pass it on
   *  every CHILD menu (never the root): clicking it dismisses the menu and clears the selection in
   *  the parent list that opened it. Omit to render no close button. */
  onClose?: () => void
  /** Accessible name + tooltip for the close button. Defaults to "Close". */
  closeLabel?: string
  /** Tighten the list's BOTTOM padding (the gap under the last row). Default false keeps the
   *  generous scroll breathing room; the cascade menus pass true so a short, hugging menu doesn't
   *  trail dead space under its last item. */
  denseBottom?: boolean
  /** Whether hovering an unselected row previews the left bar. Default true; the cascade menus pass
   *  false (see TopicList's `hoverBar`). */
  hoverBar?: boolean
  /** Drop the leading row icon in the EXPANDED list (see TopicList). Forwarded verbatim. */
  hideItemIcons?: boolean
  /** Warm a row before it is clicked — see {@link TopicList}'s `onPrefetch`. Forwarded straight
   *  through; this component neither calls it nor knows what it warms (data, a route, or both).
   *  It cannot: warming a ROUTE needs a router, and this package owns no router instance. */
  onPrefetch?: (id: string) => void
  /** BATCH MODE for this rail's rows — see {@link TopicList}'s `checkable`. Forwarded verbatim. */
  checkable?: boolean
  checkedIds?: ReadonlySet<string>
  onToggleChecked?: (id: string) => void
  /**
   * Report the width this rail's ROWS and its titled HEADER actually want — whichever is
   * wider — in px, already clamped to [MIN_FIT_RAIL, MAX_FIT_RAIL].
   *
   * WHY THE RAIL MEASURES ITSELF. Only this component knows what a row is made of — an icon,
   * a gap, a two-line preview, a trailing status dot, a trash button that appears on hover —
   * and all of it moves with the theme's font. Anything measuring from outside would be
   * re-deriving that from the row markup and would fall out of date the first time a row
   * gained a badge. So the parent asks "how wide do you want to be", not "how many
   * characters is your longest label".
   *
   * The measurement is of INTRINSIC content width (`max-content`), which is independent of
   * the width the parent then gives back — so this cannot oscillate. Omit the prop for a
   * fixed-width rail; a collapsed rail (icon strip) never reports.
   */
  onFit?: (widthPx: number) => void
}) {
  const asideRef = useRef<HTMLElement>(null)
  const listRef = useRef<HTMLDivElement>(null)
  const headerRef = useRef<HTMLDivElement>(null)
  const listId = useId()
  const draggingRef = useRef(false)
  const onDragStart = (e: PointerEvent<HTMLDivElement>) => {
    e.preventDefault()
    e.currentTarget.setPointerCapture(e.pointerId)
    draggingRef.current = true
    onResizeStart?.()
  }
  const onDragMove = (e: PointerEvent<HTMLDivElement>) => {
    if (!draggingRef.current || !asideRef.current) return
    onResize?.(e.clientX - asideRef.current.getBoundingClientRect().left)
  }
  const onDragEnd = (e: PointerEvent<HTMLDivElement>) => {
    draggingRef.current = false
    onResizeEnd?.()
    e.currentTarget.releasePointerCapture?.(e.pointerId)
  }

  // The list's SEARCH state; its pop-over lives in the toolbar, below. Declared ahead of the
  // auto-fit, which has to know when the rows on screen are a subset the rail filtered itself.
  const [ownQuery, setOwnQuery] = useState("")
  const [searchOpen, setSearchOpen] = useState(false)
  const controlledQuery = search?.query !== undefined
  const query = search ? (controlledQuery ? (search.query ?? "") : ownQuery) : ""
  // A controlled host filters before it passes `items`, so as far as this rail can tell its rows
  // are always the whole list; only an uncontrolled query hides rows the rail was given.
  const selfFiltering = !!search && !controlledQuery && query.trim() !== ""

  /**
   * MEASURE THE ROWS, before paint.
   *
   * The list box is briefly given `width: max-content` — which asks the layout engine the one
   * question worth asking, "how wide would you be if nothing constrained you" — read, and put
   * back inside the same layout effect, so no frame is ever painted with it. Reading
   * `scrollWidth` alone would only ever say "the content OVERFLOWS", never "the content has
   * room to spare", so it could widen a rail and never narrow one.
   *
   * Each measurement costs ONE forced layout — every write, the list's and the header's, lands
   * before the first read (see `measure`) — and a run measures twice, now and again when the
   * fonts land: two forced reflows per rail per run, which is what the notes on `sig` and
   * `onFitRef` below are counting.
   *
   * `sig` deliberately does not include the labels: a row keeps its identity when its label
   * is re-rendered, and the alternative — re-measuring on every render that rebuilt an equal
   * array — costs two forced reflows per rail for a width that did not move.
   */
  const sig = items.map((it) => it.id).join("\u0000")
  // The header's share of the answer moves when its title or its riders do. A non-string title
  // (a node) cannot be compared cheaply, so it re-measures only when the rows or riders change.
  // The toolbar's tools are NOT riders: they sit on their own row, which never outgrows a rail.
  const headerSig = `${typeof title === "string" ? title : ""}|${!!onClose}|${!!showToggle}`
  // Held in a ref, and NOT a dependency: a parent that passes an inline arrow would otherwise
  // re-run this on every render, and every run costs two forced reflows for a width that has
  // not moved.
  const onFitRef = useRef(onFit)
  onFitRef.current = onFit
  useLayoutEffect(() => {
    const el = listRef.current
    const report = onFitRef.current
    // A collapsed rail is an icon strip whose width is COLLAPSED_RAIL by definition, and
    // measuring one would report the width of icons — so the last real answer stands.
    // The same while the rail FILTERS ITS OWN ROWS: the box holds only the matches, and a width
    // taken from them outlived the query. A Personas rail searched while its `+` added a persona
    // (a new id, so a re-measure) kept the width of the matching rows after the query cleared,
    // ellipsising the full list, because clearing a query changed nothing this effect keyed on.
    // `selfFiltering` is a dependency, so the full list is measured again the moment it clears.
    if (!report || collapsed || !el || selfFiltering) return
    const measure = () => {
      // THE HEADER COUNTS TOO. A rail sized to its rows alone truncated its own title whenever
      // the title plus its riders (`+`, the right-hand controls, the ✕) outgrew the rows — a
      // two-row "Appearance" list whose header read "Appea…" (Mike: "wide enough for their
      // contents and their headers both"). Same `max-content` question, asked of the header:
      // its title is `truncate`, whose max-content contribution is the whole string. The busy
      // spinner is left out on purpose: it comes and goes with every read, and a rail that
      // widened and narrowed under it would shift every list to its right each time.
      const header = headerRef.current
      const busy = header?.querySelector<HTMLElement>("[data-htd-busy]") ?? null
      // EVERY write, then every read, then every restore — so the first read below forces the
      // one layout this measurement costs and every later read finds it clean. The header used
      // to ask its question in a helper of its own (write, read, restore) in the middle of the
      // list's reads, which forced a second layout on every call and doubled what the comments
      // above count. Batching changes no answer: the header is a no-wrap `shrink-0` row and
      // the aside does not clip, so a header wider than the rail overhangs it for the instant
      // it is measured and moves nothing the list's reads depend on.
      const restoreList = el.style.width
      const restoreHeader = header?.style.width ?? ""
      const restoreBusy = busy?.style.display ?? ""
      el.style.width = "max-content"
      if (header) header.style.width = "max-content"
      if (busy) busy.style.display = "none"
      // The gutter a vertical scrollbar takes out of the box (0 with overlay scrollbars).
      const scrollbar = el.offsetWidth - el.clientWidth
      // What we measure is the LIST; what we report is the RAIL, and the rail is border-box
      // with a hairline right border the list never gets. Reporting the list's width hands
      // the list one pixel less than it asked for, and the longest label ellipsises — the
      // whole rail looks a hair too narrow for exactly one row. So add back the aside's OWN
      // box: its borders and its padding.
      //
      // NOT `aside.offsetWidth - el.offsetWidth`, which is what this used to read. The list is
      // `max-content` at this instant while the aside is still at its CURRENT width, so that
      // difference is the SLACK between the two — and `natural` then came out identically equal
      // to the width the rail already had. Every rail reported back the answer it was given, the
      // shared max never moved off its first-render fallback, and no rail ever resized. Measured
      // live on a two-row rail: content 72px, slack 168px, reported 240px — FULL_RAIL exactly.
      const box = asideRef.current
      const boxStyle = box ? getComputedStyle(box) : null
      const chrome =
        box && boxStyle
          ? box.offsetWidth -
            box.clientWidth + // its borders (plus any scrollbar gutter of the aside itself)
            parseFloat(boxStyle.paddingLeft || "0") +
            parseFloat(boxStyle.paddingRight || "0")
          : 0
      // The FRACTIONAL width, not `scrollWidth` alone: `scrollWidth` is an integer rounded
      // DOWN from the text's real advance, so a label measuring 126.47px got a 126px box and
      // ellipsized — "Consultant Regist…" in the hub's Hub rail, in a rail that had been sized
      // to it. The bounding rect keeps the fraction (and, as a border box, the scrollbar
      // gutter); `Math.ceil` below rounds it UP to the pixel that holds the whole label.
      const rows = Math.max(el.scrollWidth + scrollbar, el.getBoundingClientRect().width)
      const headerWidth = header
        ? Math.max(header.scrollWidth, header.getBoundingClientRect().width)
        : 0
      el.style.width = restoreList
      if (header) header.style.width = restoreHeader
      if (busy) busy.style.display = restoreBusy
      const natural = Math.max(rows, headerWidth) + Math.max(0, chrome)
      // A box with no layout measures 0 — a rail rendered inside a `display:none` ancestor,
      // and every rail under jsdom. Zero is not an answer, and clamping it up to the floor
      // would dress it as one: say nothing and leave the caller's own width standing.
      if (natural <= 0) return
      // The range is written against a 16px root; this document may not have one.
      report(
        Math.max(
          railPx(MIN_FIT_RAIL),
          Math.min(railPx(MAX_FIT_RAIL), Math.ceil(natural)),
        ),
      )
    }
    measure()
    // Rows are measured in a font that may still be loading, and a fallback face is a
    // different width. One re-measure when the real one lands; `document.fonts` is absent in
    // jsdom, so the optional chain is the test environment as much as an old browser.
    let live = true
    void document.fonts?.ready.then(() => {
      if (live) measure()
    })
    return () => {
      live = false
    }
  }, [collapsed, sig, headerSig, selfFiltering])

  // The create affordance: a compact `+` (replaces the old leading "New…" rail row). On a titled
  // rail it sits first in the list toolbar under the header (see `toolbar`); an untitled or
  // collapsed rail carries it in its bare control strip instead. Gold while a create is in
  // progress (`newActive`). Icon-only, so its label rides as the accessible name + native tooltip.
  const newButton = onNew ? (
    <ListToolButton label={newLabel ?? "New"} active={newActive} onClick={onNew}>
      <Plus size={16} aria-hidden />
    </ListToolButton>
  ) : null

  const collapseToggle = (
    <CollapseToggle collapsed={collapsed} onToggle={onToggle} label="topic list" controls={listId} />
  )

  // A right-justified close (✕) in the header — the hierarchical stacks put it on every CHILD menu to
  // dismiss the menu and clear its selection in the parent list. Icon-only, so its label rides as the
  // accessible name + native tooltip.
  const closeButton = onClose ? (
    <ListToolButton label={closeLabel ?? "Close"} onClick={onClose}>
      <X size={16} aria-hidden />
    </ListToolButton>
  ) : null

  // Right-justified header control: in the minimized style, the desktop collapse toggle (`«`). The
  // New `+` and `titleActions` are NOT here — on a titled rail they live in the list toolbar under
  // the header (see `toolbar`); only the untitled header branches below render the `+` on their own.
  // The covered style passes `showToggle=false` and supplies its own `leftControl` instead.
  const rightControls = showToggle ? (
    <span className="ml-auto flex shrink-0 items-center gap-1">
      <span className="max-md:hidden">{collapseToggle}</span>
    </span>
  ) : null

  // ── The list toolbar ──────────────────────────────────────────────────────────────────────
  // Operations on THIS list, on a row of their own under the titled header: `+` first (sitting in
  // the icon column, like the header's control slot), then search, then the list's own tools
  // right-justified. They used to crowd the title row, where a narrow rail truncated its title to
  // make room for them, and the list's filter lived in a page-wide strip above every rail — far
  // from the list it filtered. The search state they read is declared above, with the auto-fit.
  const searchTriggerRef = useRef<HTMLButtonElement>(null)
  const toolbarRef = useRef<HTMLDivElement>(null)
  const setQuery = (q: string) => {
    if (!controlledQuery) setOwnQuery(q)
    search?.onQueryChange?.(q)
  }
  // Escape, Enter and ✕ all close through here, and each hands focus BACK to the magnifier:
  // closing unmounts the field that has focus, and focus used to fall to <body>, dropping a
  // keyboard user out of the rail altogether.
  const closeSearch = (clear: boolean) => {
    if (clear) setQuery("")
    setSearchOpen(false)
    searchTriggerRef.current?.focus()
  }
  const shownItems =
    search && !controlledQuery ? filterTopicItems(items, query, selectedId) : items
  const titled = title !== undefined && !collapsed
  // The same question the stacks ask of every level before they set `reserveToolbar`, asked here
  // through the same function: two spellings of it could drift, and a rail that answered it
  // differently would step its rows down out of line with its siblings'.
  const hasTools = hasListTools({ onNew, search, titleActions })
  const showToolbar = titled && (hasTools || reserveToolbar)
  // The pop-over is on screen exactly when this holds. The effect below keys on it, not on
  // `searchOpen`: a collapse takes the toolbar away with the field still open, and the toolbar
  // that comes back is a new element to measure and observe.
  const searchShown = showToolbar && !!search && searchOpen
  // How far the pop-over may reach before an ancestor clips it; null = nothing clips it. See
  // `horizontalClipOf`. Measured before paint on every open, and again whenever the toolbar or
  // the clipping box resizes — the covered stack's reveal WIPES a column's box open around a
  // rail whose own width never moves, so watching the toolbar alone would keep the cap it had
  // when the field opened mid-wipe.
  const [searchRoom, setSearchRoom] = useState<number | null>(null)
  useLayoutEffect(() => {
    const bar = toolbarRef.current
    if (!searchShown || !bar) return
    const clip = horizontalClipOf(bar)
    if (!clip) {
      setSearchRoom(null)
      return
    }
    const measure = () => {
      const room = clip.getBoundingClientRect().right - bar.getBoundingClientRect().left
      // A box with no layout (a `display:none` ancestor, jsdom) measures nothing, not zero room.
      const next = room > 0 ? room : null
      setSearchRoom((prev) => (prev === next ? prev : next))
    }
    measure()
    const ro = typeof ResizeObserver !== "undefined" ? new ResizeObserver(measure) : null
    ro?.observe(bar)
    ro?.observe(clip)
    window.addEventListener("resize", measure)
    return () => {
      ro?.disconnect()
      window.removeEventListener("resize", measure)
    }
  }, [searchShown])
  const queryActive = query.trim() !== ""
  const searchLabel = search?.placeholder ?? "Search"
  const toolbar = showToolbar ? (
    <div
      ref={toolbarRef}
      data-htd-toolbar
      role="toolbar"
      aria-label={typeof title === "string" ? `${title} tools` : "List tools"}
      // Same `pl-2.5` + `w-4` slot + `gap-2` geometry as the header, so the `+` sits over the row
      // icons and the rails' first rows still line up.
      className="relative flex min-h-[2rem] shrink-0 items-center gap-2 border-b border-apt-border pr-2 pl-2.5"
    >
      <div className="flex w-4 shrink-0 items-center justify-center">{newButton}</div>
      {search && (
        <ListToolButton
          ref={searchTriggerRef}
          label={searchLabel}
          title={queryActive ? `${searchLabel}: “${query}”` : searchLabel}
          aria-expanded={searchOpen}
          onClick={() => setSearchOpen((o) => !o)}
          // Gold while a query is narrowing the list with the field closed — otherwise a short
          // list would look like all there is.
          active={queryActive}
        >
          <Search size={15} aria-hidden />
        </ListToolButton>
      )}
      <div className="min-w-0 flex-1" />
      {titleActions && <span className="flex shrink-0 items-center gap-1">{titleActions}</span>}
      {search && searchOpen && (
        <div
          data-htd-search
          // Pops OVER the list at a readable width, spilling past a narrow rail wherever the layout
          // lets it (`z-30` lifts it above the neighbouring rail it then overlaps), but never past
          // the nearest box that clips it: `searchRoom` caps it there (see `horizontalClipOf`), so
          // the ✕ and the end of the query are never cut off.
          className="absolute top-0 left-0 z-30 flex h-full w-[max(100%,16rem)] items-center gap-1.5 border border-apt-border bg-apt-surface pr-1.5 pl-2.5 shadow-lg"
          style={searchRoom === null ? undefined : { maxWidth: searchRoom }}
          // Closes when focus LEAVES the pop-over, not when it moves inside it: the field's own
          // blur used to close it on Tab onto ✕, unmounting ✕ in the instant it took focus, so
          // Clear was unreachable from the keyboard. Leaving keeps the query (the icon stays gold);
          // only Escape or ✕ clears it.
          onBlur={(e) => {
            if (!e.currentTarget.contains(e.relatedTarget)) setSearchOpen(false)
          }}
        >
          <Search size={14} aria-hidden className="shrink-0 text-apt-text-muted" />
          <input
            // The field exists only because the user just asked to type into it.
            autoFocus
            type="search"
            value={query}
            placeholder={searchLabel}
            aria-label={searchLabel}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Escape") {
                e.stopPropagation()
                closeSearch(true)
              } else if (e.key === "Enter") {
                // Closing hands focus to the magnifier BEFORE this keystroke's `keypress`, which
                // goes to whatever holds focus by then — and a button takes Enter's keypress as a
                // click, reopening the field it just closed. A cancelled keydown sends no keypress.
                e.preventDefault()
                closeSearch(false)
              }
            }}
            className="min-w-0 flex-1 bg-transparent font-mono text-[0.8rem] text-apt-text outline-none placeholder:text-apt-text-dim"
          />
          <ListToolButton
            label="Clear search"
            // Keep focus in the field through the click. Safari never focuses a clicked button, so
            // the field's blur would carry a null `relatedTarget` — focus leaving the pop-over, as
            // far as the check above can tell — and close it before this click lands.
            onMouseDown={(e) => e.preventDefault()}
            onClick={() => closeSearch(true)}
          >
            <X size={14} aria-hidden />
          </ListToolButton>
        </div>
      )}
    </div>
  ) : null

  // The titled header's inner content. The control slot is a fixed width matching where item icons
  // start; the title is LEFT-JUSTIFIED on the column where item labels start;
  // The read indicator, in two parts on purpose.
  //
  // This is the VISUAL half, and it is decoration: `aria-hidden`, because the live region mounted
  // on the column below already says the same thing, and two sources for one fact announce twice.
  // Defined once because it appears in every header shape — a rail the user collapsed to an icon
  // strip is still reading, and a strip that shows nothing while it reads makes the click that
  // started the read look like it did nothing.
  const busyIcon = <Loader2 className="size-3 animate-spin text-apt-text-muted" aria-hidden />
  // The ANNOUNCEMENT half. ALWAYS mounted, with its TEXT as the thing that changes: assistive tech
  // announces a live region's mutations, not its arrival, so a region inserted into the DOM at the
  // same instant it fills conveys nothing at all — which is what a `{busy && <span role="status">}`
  // amounts to. It sits on the column rather than in the header because every header shape can be
  // busy, including the two that have no title to hang the icon beside.
  const busyAnnouncement = (
    <span role="status" aria-live="polite" className="sr-only">
      {busy ? "Loading" : ""}
    </span>
  )

  // the toggle/close controls are right-justified.
  const headerInner = (
    <>
      {/* THE TITLE IS LEFT-JUSTIFIED, AND ITS LEADING EDGE LANDS ON THE COLUMN WHERE THE ROW
          LABELS START (Mike). A row is [10px inset][16px icon][8px gap][label…], so the header is
          built out of the same three pieces: `pl-2.5` on the header, a `w-4` control slot, and the
          header's own `gap-2`. The control then sits concentric with the row icons and the title
          sits exactly over `data-htd-label` — every rail in a cascade reads down one left edge
          instead of each finding its own centre. */}
      <div className="flex w-4 shrink-0 items-center justify-center">{leftControl ?? backSlot ?? null}</div>
      {title !== undefined && (
        <span className="pointer-events-none flex min-w-0 items-center font-mono text-[0.8rem] tracking-[0.02em] text-apt-text-muted">
          {/* Both riders sit AFTER the title, in flow. They used to hang out of flow off either
              edge because a CENTRED title moved sideways whenever one appeared; anchored on the
              left there is nothing to protect, and in-flow siblings cannot be clipped by the
              `truncate` box the way absolutely-positioned ones had to escape it. */}
          <span className="truncate">{title}</span>
          {busy && (
            <span data-htd-busy className="ml-1.5 flex shrink-0 items-center">
              {busyIcon}
            </span>
          )}
        </span>
      )}
      {/* Eats the row so the trailing controls stay right-justified. */}
      <div className="min-w-0 flex-1" />
      {rightControls}
      {closeButton}
    </>
  )
  return (
    // .settings-nav: darker column, divider on the right, no left inset so the selection bar
    // sits flush against the edge.
    <aside
      ref={asideRef}
      aria-label={railLabel ?? "Topic list"}
      // A left drop-shadow (covered style) reads against `--color-shadow` (a token, not a raw
      // colour) so the child casts a physical edge over its covered parent. Referenced via a CSS
      // var so the project-guidelines colour checker stays clean (no raw hex / rgb()).
      className={cn(
        "relative flex min-h-0 flex-col border-r border-apt-border bg-apt-nav",
        coveredShadow && "shadow-[-10px_0_22px_-8px_var(--color-shadow)]",
        className,
      )}
    >
      {busyAnnouncement}
      {/* Drag handle on the trailing border (desktop): resize the column; the parent snaps to
          undisclosed below a third, full past the natural width. Fixed-width rails
          (no onResize) render no handle. */}
      {onResize && (
        <div
          role="separator"
          aria-orientation="vertical"
          aria-label="Resize topic list"
          onPointerDown={onDragStart}
          onPointerMove={onDragMove}
          onPointerUp={onDragEnd}
          className="absolute top-0 right-0 z-10 h-full w-1.5 translate-x-1/2 cursor-col-resize touch-none bg-transparent transition-colors hover:bg-apt-gold/40 max-md:hidden"
        />
      )}
      {/* Top of the list. With a `title` (and not collapsed to an icon strip) this is the titled
          HEADER: a fixed control slot (the covered `«`/`»` or a minimized Back) where item icons
          start, the left-aligned title where item labels start, the right-justified collapse
          toggle, and a divider beneath — so every titled list reserves the same header height and
          their rows line up. (Its New `+` and list tools ride the list toolbar just below it.)
          Without a title (standalone TopicDetail) or when collapsed, fall back to
          the bare control strip (priority: leftControl → backSlot → toggle/`+` → busy alone → nothing).
          EVERY shape carries the busy icon: collapsing a rail to make room for the detail pane is a
          first-class gesture, and the read a click starts is exactly as invisible in an icon strip as
          it is in a titled header — more so, since the strip has no title for it to sit beside. */}
      {title !== undefined && !collapsed ? (
        <div
          ref={headerRef}
          data-htd-header
          // `pl-2.5` + the `w-4` slot + `gap-2` land the title's leading edge on the row-label
          // column (34px); see `headerInner`.
          className="relative flex min-h-[2.15rem] shrink-0 items-center gap-2 border-b border-apt-border pr-2 pl-2.5"
        >
          {headerInner}
        </div>
      ) : leftControl ? (
        <div data-htd-header className="flex shrink-0 items-center justify-between px-1.5 pt-1.5">
          {leftControl}
          <span className="flex items-center gap-1">
            {busy && <span data-htd-busy>{busyIcon}</span>}
            {newButton}
            {closeButton}
          </span>
        </div>
      ) : backSlot ? (
        <div data-htd-header className="flex shrink-0 items-center justify-between px-1.5 pt-1.5">
          {backSlot}
          <span className="flex items-center gap-1">
            {busy && <span data-htd-busy>{busyIcon}</span>}
            {newButton}
            {showToggle && <span className="max-md:hidden">{collapseToggle}</span>}
          </span>
        </div>
      ) : showToggle || newButton ? (
        <div
          className={cn(
            "flex shrink-0 items-center gap-1 pt-1.5",
            // Collapsed icon strip (~48px): stack the `+` above the toggle. Else right-justify the row.
            collapsed ? "flex-col" : "justify-end pr-1.5",
            // Without a `+`, the strip is just the desktop-only collapse toggle — hidden on mobile.
            // The busy icon overrides that: a read in progress is worth showing on mobile too.
            !newButton && !busy && "max-md:hidden",
          )}
        >
          {busy && <span data-htd-busy>{busyIcon}</span>}
          {newButton}
          {showToggle && <span className={cn(newButton && "max-md:hidden")}>{collapseToggle}</span>}
        </div>
      ) : busy ? (
        // No title and no controls at all — a bare list that is nonetheless reading.
        <div
          data-htd-busy
          className={cn(
            "flex shrink-0 items-center pt-1.5",
            collapsed ? "justify-center" : "justify-end pr-1.5",
          )}
        >
          {busyIcon}
        </div>
      ) : null}
      {/* The shared list-header hook (filter + actions) for entity lists hosted in the
          stack — full-width under the titled header, above the rows. Hidden when the
          rail is collapsed to an icon strip (no room for a filter field). */}
      {toolbar}
      {headerSlot !== undefined && !collapsed && (
        <div className="shrink-0 border-b border-apt-border">{headerSlot}</div>
      )}
      <div
        id={listId}
        ref={listRef}
        className={cn(
          "min-h-0 flex-1 overflow-y-auto",
          denseBottom ? "pb-2" : "pb-8",
          collapsed ? "pl-0 pr-1 pt-2" : "pl-0 pr-4 pt-2",
        )}
      >
        <TopicList
          items={shownItems}
          selectedId={selectedId}
          onSelect={onSelect}
          // Only a rail that filters its own rows knows WHY none are left. A controlled host's
          // empty list may still be LOADING the new query's read — the notebook and research panes
          // showed "Nothing matches" over their own "Loading…" until it landed — so its label stands.
          emptyLabel={selfFiltering && shownItems.length === 0 ? `Nothing matches “${query.trim()}”.` : emptyLabel}
          railSlot={railSlot}
          railSlotActive={railSlotActive}
          collapsed={collapsed}
          covered={covered}
          isRoot={isRoot}
          selectionStyle={selectionStyle}
          hoverBar={hoverBar}
          hideItemIcons={hideItemIcons}
          rowDisclosure={rowDisclosure}
          onPrefetch={onPrefetch}
          checkable={checkable}
          checkedIds={checkedIds}
          onToggleChecked={onToggleChecked}
        />
      </div>
      {footer && <div className="shrink-0 border-t border-apt-border p-2">{footer}</div>}
    </aside>
  )
}

/**
 * The reusable two-pane primitive: a selectable [topic list] on the left and a
 * [detail pane] on the right — exactly the adh.com/home rail | content split.
 * That is ALL it is — no title row, no action bar. Compose those from other
 * blocks (see FocusedTopicDetail). Fills its container; give it a height.
 *
 * The rail is ALWAYS collapsible (a core part of the site design, not a config
 * flag): a top-right toggle (desktop only) shrinks the topic list to an icon-only
 * strip for more pane room — each topic stays clickable as its icon, the active
 * icon keeps the gold selection bar, and the header `+` stays put.
 */
/**
 * Where a selected row's connector leaves it: the right edge of whatever the row shows last — its
 * trailing accessory (a count, a badge, the disclosure chevron) when it has one, else its label,
 * else its icon (a collapsed icon strip). Shared by every stack that draws selection connectors.
 */
export function rowExitEl(row: Element): Element | null {
  return (
    row.querySelector("[data-htd-trailing]") ??
    row.querySelector("[data-htd-label]") ??
    row.querySelector("[data-htd-icon]")
  )
}

export function TopicDetail({
  items,
  selectedId,
  onSelect,
  emptyLabel = "Nothing here yet.",
  railSlot,
  railSlotActive,
  onNew,
  newLabel,
  newActive,
  hideItemIcons,
  panePadding = true,
  collapsed: collapsedProp,
  onCollapsedChange,
  defaultCollapsed = false,
  railWidth: railWidthProp = FULL_RAIL,
  children,
}: {
  items: TopicDetailItem[]
  selectedId: string | null
  onSelect: (id: string) => void
  emptyLabel?: ReactNode
  /** Optional leading row above the topics (a custom header / control). Rendered only when provided;
   *  an absent slot reserves no space. Distinct from the header `+` create affordance (`onNew`). */
  railSlot?: RailSlot
  /** Move the gold selection bar onto the rail slot (nothing in the list selected). */
  railSlotActive?: boolean
  /** Create affordance: when set, a `+` fires it. This rail is untitled, so there is no list
   *  toolbar: the `+` sits in the rail's bare control strip, right-justified beside the collapse
   *  toggle (stacked above it on the icon strip). */
  onNew?: () => void
  /** Accessible name + tooltip for the `+` (e.g. "New Topic"). Defaults to "New". */
  newLabel?: string
  /** Tint the `+` gold to signal an in-progress create (nothing selected in the list). */
  newActive?: boolean
  /** Drop the leading row icon in the expanded list — for lists whose rows carry no identity
   *  icon (see TopicList.hideItemIcons). */
  hideItemIcons?: boolean
  /** Default true: the pane carries the standard content inset (px-6 py-4 +
   *  gap-6). Pass false for edge-to-edge content (hub's .settings-content has
   *  no inset — each row carries its own, e.g. a ButtonBar) so consumers never
   *  need negative-margin hacks. */
  panePadding?: boolean
  /** Controlled collapse: pass with `onCollapsedChange` to drive the rail's
   *  collapsed state from outside (HierarchicalTopicDetail auto-minimizes
   *  ancestor rails this way). Omit for the default self-managed toggle. */
  collapsed?: boolean
  onCollapsedChange?: (collapsed: boolean) => void
  /** Initial collapsed state in uncontrolled mode (ignored when `collapsed` is set). */
  defaultCollapsed?: boolean
  /** The rail's natural (full) width in px; the drag handle clamps to it.
   *  Default FULL_RAIL (240) — the standard hub rail. Widen for rails whose
   *  rows are long identifiers (URLs). */
  railWidth?: number
  children: ReactNode
}) {
  const [internalCollapsed, setInternalCollapsed] = useState(defaultCollapsed)
  // Standard controllable pattern: `collapsed` wins when provided, else local state.
  const collapsed = collapsedProp ?? internalCollapsed
  const setCollapsedState = (next: boolean) => {
    if (collapsedProp === undefined) setInternalCollapsed(next)
    onCollapsedChange?.(next)
  }
  const toggleCollapsed = () => setCollapsedState(!collapsed)

  // Drag-to-resize the rail by its trailing border (desktop). The width drives a `--rail-w`
  // CSS var; the transition is suppressed while dragging so the rail tracks the pointer live.
  const [railWidth, setRailWidth] = useState(railWidthProp)
  const [dragging, setDragging] = useState(false)
  const onResize = (w: number) => {
    if (w < railWidthProp / 3) {
      // Narrower than a third → animate to undisclosed.
      if (!collapsed) setCollapsedState(true)
      return
    }
    // Dragging out of (or within) the disclosed range; past FULL snaps back to full.
    if (collapsed) setCollapsedState(false)
    setRailWidth(Math.min(w, railWidthProp))
  }
  return (
    <div
      // The rail column width is driven by the `--rail-w` CSS var (collapsed → the icon strip,
      // else the dragged width); the var changes animate via the transition. The global
      // accessibility CSS (data-reduce-motion / OS pref) zeroes transition durations, so this
      // honours the user's "reduce animation" setting. Transition is off while dragging so the
      // rail tracks the pointer live.
      style={{ "--rail-w": collapsed ? `${COLLAPSED_RAIL}px` : `${railWidth}px` } as CSSProperties}
      className={cn(
        "grid min-h-0 min-w-0 flex-1 grid-cols-1 grid-rows-[minmax(0,1fr)] md:[grid-template-columns:var(--rail-w)_minmax(0,1fr)]",
        !dragging && "md:transition-[grid-template-columns] md:duration-[calc(200ms*var(--apt-anim-scale,1))] md:ease-out",
      )}
    >
      <TopicRail
        items={items}
        selectedId={selectedId}
        onSelect={onSelect}
        emptyLabel={emptyLabel}
        railSlot={railSlot}
        railSlotActive={railSlotActive}
        onNew={onNew}
        newLabel={newLabel}
        newActive={newActive}
        hideItemIcons={hideItemIcons}
        collapsed={collapsed}
        onToggle={toggleCollapsed}
        onResize={onResize}
        onResizeStart={() => setDragging(true)}
        onResizeEnd={() => setDragging(false)}
      />
      {/* .settings-content: the surface panel for the whole right side. `overflow-auto` so a
          leaf detail with a minimum width scrolls horizontally here (rather than being crushed)
          when its column is narrower than that minimum; intermediate panes hold a shrinking grid
          so they never overflow. */}
      <section
        className={cn(
          "flex min-w-0 flex-col overflow-auto bg-apt-surface",
          panePadding && "gap-6 px-6 py-4",
        )}
      >
        {children}
      </section>
    </div>
  )
}
