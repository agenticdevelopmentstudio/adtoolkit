"use client"

import {
  Component,
  createRef,
  useCallback,
  useEffect,
  useLayoutEffect,
  useReducer,
  useRef,
  useState,
  type CSSProperties,
  type Dispatch,
  type MouseEvent as ReactMouseEvent,
  type PointerEvent as ReactPointerEvent,
  type ReactElement,
  type ReactNode,
  type RefObject,
  type SetStateAction,
} from "react"
import { createPortal } from "react-dom"

import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight } from "lucide-react"

import { cn } from "../lib/utils"
import { getSlowAnimations, SLOW_ANIM_FACTOR } from "./debug-options"
import { hlog } from "./htdv-log"
import { UnsavedChangesAlert } from "../components/unsaved-changes-alert"
import { useExitGate, type PaneExitGuard } from "../hooks/useExitGate"
import { useSwipeBackClaim } from "../hooks/useSwipeBackClaim"
import { useSeededBackStack } from "../hooks/useSeededBackStack"
import {
  TopicRail,
  FULL_RAIL,
  COLLAPSED_RAIL,
  rootFontPx,
  type TopicDetailItem,
  type RailSlot,
  type TopicListSearch,
  hasListTools,
  rowExitEl,
} from "./topic-detail"
import { TopicSelectHint } from "./topic-select-hint"
import { CoverAllControl } from "./cover-all-control"
import { detailStripTitle, DetailTitleProvider, useDetailTitleHost, type DetailStripTitle } from "./detail-title"
import { DETAIL_PANE_ATTR } from "../lib/detail-pane"
import { deepestSelectedLevel, selectedTopicLabel } from "./stack-frontier"

/** A leaf editor's unsaved-work guard. The package consults `isDirty()` before any select that
 *  clears or replaces the open detail (Back / breadcrumb-up / re-click / shallower select / a
 *  sibling swap at the deepest level) and, if dirty, raises the platform's discard alert.
 *
 *  Declared in `hooks/useExitGate` (one owner for the gate and the type it gates on) and
 *  re-exported here under its original name — every consumer imports it from this block via the
 *  `blocks` barrel. */
export type { PaneExitGuard }

/** How a select should enter history, for the levels whose `onSelect` NAVIGATES (a router push).
 *  Passed only when the BLOCK chose rather than the user — today that is a level's
 *  `defaultSelectedId` — so an auto-applied default lands where a click would have, without
 *  leaving a Back stop on the state it immediately redirected away from. Ignored by levels that
 *  select in memory; a click never carries it, so a chosen row is always its own history entry. */
export interface TopicSelectOptions {
  replace?: boolean
}

// The enclosing frame for a hierarchy of topic/detail rails — the generalisation
// of the adh.com/home nesting (`[workspaces] | [features] | [content]`). Instead
// of hand-nesting TopicDetail inside TopicDetail, a consumer passes a flat
// `levels` array; this block:
//   1. renders a button bar (toolbar) + a breadcrumb trail UNDER it, and
//   2. nests the rails (each level's selection scopes the next) — every rail stays
//      available (expanded) by default. Optional auto-minimise (`maxExpanded`, OFF
//      by default) can collapse ancestors to their icon strip; the per-rail collapse
//      toggle is always available regardless.
// The `children` are the innermost detail content, computed by the consumer from
// the current selection; this block drops them into the deepest open rail's pane.

export interface TopicLevel {
  /** Stable key for the level (also its collapse-override + React key). */
  id: string
  /** Left-aligned heading naming this list (e.g. "Workspaces", "Ecosystems"), shown above the rows
   *  with a divider beneath. Every level should set one so the lists' rows align vertically. */
  title?: string
  /** Accessible name for the rail's landmark, when "Topic list" (the fleet-wide default) is not
   *  enough to tell it apart. A stack renders one landmark per open level, all called "Topic
   *  list", so a surface a reader jumps to BY LANDMARK — one that used to own a named sidebar of
   *  its own — names itself here. Not defaulted to `title`, which would rename ~50 existing rails
   *  at once; this is opt-in per level. */
  railLabel?: string
  items: TopicDetailItem[]
  selectedId: string | null
  /** Default answer for every row in this list: does choosing one lead to another topic LIST, or
   *  to the DETAIL (a final choice)? A row's own `leadsTo` overrides it; unset on both means
   *  `"detail"`. Declare `"list"` on levels whose rows disclose deeper lists (a workspaces list, a
   *  features list) so the cascading view can hold the detail pane through intermediate selects
   *  (hold-the-detail-until-the-final-choice). */
  leadsTo?: "list" | "detail"
  /** OPT-IN landing selection: the item to select the moment this level APPEARS with nothing chosen
   *  — i.e. when the parent topic that opens this list is picked (Work Items → List). It fires this
   *  level's own `onSelect`, so the consumer's state/URL owns the selection exactly as if the row had
   *  been clicked, and everything downstream (breadcrumb, detail, deep link) follows for free.
   *
   *  It arms once per APPEARANCE: a manual deselect INSIDE the same visit sticks (the default must
   *  never fight the user), while leaving the parent topic and coming back re-applies it. Deliberately
   *  narrow — selecting a row still NEVER auto-selects anything at a deeper level unless that level
   *  asks for it here. Omit for the platform default: nothing is chosen for the user.
   *
   *  WIDE ONLY, always: it applies while the lists are disclosed beside the detail and NEVER in the
   *  narrow stack (a phone, or a window too narrow to hold a list beside the detail). There the
   *  list is a screen of its own, and choosing for the user would push straight past it, so a
   *  phone would open onto the default and have to go Back to see the list it came for. A list
   *  shown narrow is not spent: widen the window while it shows nothing chosen and the default
   *  applies then, as it would have had the list appeared wide. */
  defaultSelectedId?: string
  /** The AUTOMATIC no-selection detail (default on): while this level is the frontier with
   *  nothing selected, the pane stays almost empty — one quiet, centered nudge to select
   *  something (`TopicSelectHint`), named as specifically as this level allows (see
   *  `itemNoun` / `overviewHelp`). Pass `false` ONLY where the pane is already holding a real
   *  editor with nothing selected — the inline CREATE form (`useMasterDetailLevel`),
   *  which the nudge would otherwise cover. Never to hang a landing page there: an
   *  unselected frontier is the nudge and nothing else, which is why there is no longer a
   *  card-grid opt-in: a grid of the rows the rail is already showing IS a second surface
   *  beside the rail. */
  overview?: boolean
  /** Singular noun for one row ("workspace", "site", "work item") — the select nudge names
   *  it: "Select a workspace …". Omit to fall back to the level's `title` ("Select an item
   *  from Workspaces …"), or to the fully generic line when neither is set. */
  itemNoun?: string
  /** Bespoke nudge copy: WHAT one of these rows is and WHY to choose one (a string or
   *  richer nodes), shown under the "Select …" line. With an EMPTY list it shows alone —
   *  the blurb still explains what belongs here while the rail shows `emptyLabel`. Ignored
   *  when `overview` is `false`. */
  overviewHelp?: ReactNode
  /** Make `id` the selection at THIS level, keeping ancestors and clearing descendants.
   *  Pure navigation — the package decides WHEN to call it (a click on a not-yet-selected
   *  row, or this level's `defaultSelectedId` when the list appears). `opts` says HOW: the
   *  default-select path passes `{ replace: true }` (see {@link TopicSelectOptions}), a click
   *  passes nothing. A routing implementation should honour it; an in-memory one may ignore it. */
  onSelect: (id: string, opts?: TopicSelectOptions) => void
  /** Clear THIS level and everything below it, keeping ancestors. Pure navigation. The
   *  package calls it for re-click-deselect, breadcrumb up-navigation, and Back. `opts` says HOW,
   *  exactly as for `onSelect`: the package passes `{ replace: true }` only when the browser has
   *  ALREADY moved to this level's `clearHref` (a Back through the seeded history — see
   *  `clearHref`), so the host must land there without adding an entry. A click passes nothing.
   *
   *  It MUST leave this level with nothing selected. A host whose "cleared" address still shows a
   *  row chosen here — a landing that opens on a first row, an "Overview" row that is the parent's
   *  own address — makes every Back, swipe-back and breadcrumb a navigation to the page already
   *  showing: dead controls with nothing on screen saying why. `clearHref` lets the package catch
   *  it. */
  onClear: (opts?: TopicSelectOptions) => void
  /** The ADDRESS `onClear` goes to, for a host that routes: the URL at which this level is open
   *  with NOTHING selected. Optional, and everything below works without it; given, it buys three
   *  things the package can only do with a real address in hand:
   *
   *   - **The breadcrumbs are links.** A crumb is an `<a href>` to the address it clears to, so it
   *     can be opened in a new tab, long-pressed on iOS, and read by a crawler — a plain click still
   *     runs through `onClear` (and the unsaved-work guard) instead of a page load.
   *   - **The browser's own Back walks up the stack.** Loaded straight onto a selection (a deep
   *     link, a shared URL), a page has no history behind it, so iOS Safari's Back button and its
   *     edge swipe — which are the BROWSER's and never reach the page — left the site instead of
   *     unselecting anything. With every selected level's `clearHref` known, the package seeds one
   *     history entry per level behind the page, so each Back clears exactly one level, the same
   *     as the in-page Back and the swipe (see `useSeededBackStack`).
   *   - **A dead clear is loud.** A selected level whose `clearHref` is the page already showing is
   *     reported on the console, because its `onClear` cannot do what it is for. */
  clearHref?: string
  /** This level ALWAYS has a selection — its `onClear` lands on a default row rather than on
   *  nothing (Settings: there is no "no section" pane). In the NARROW stack that made the list
   *  unreachable: Back cleared the level, the host re-selected the default, and the detail came
   *  straight back — a phone could never see the section list. With this set, narrow Back
   *  REVEALS this level's list without calling `onClear` (the current row stays marked) — also
   *  when that Back is pressed on a revealed list below, so a run of persistent levels is walked
   *  up list by list with none of them cleared. Tapping the marked row goes back down one pane
   *  (the list below, or the detail); any other row selects as usual. Wide layouts are
   *  unaffected: the list is on screen there anyway. */
  persistentSelection?: boolean
  emptyLabel?: string
  /** A read is in flight for this level — its rows, or the item selected in it. Draws a spinner
   *  immediately before the level's title, without moving it. */
  busy?: boolean
  /** Warm a row before it is clicked. Called with the row's id once the pointer or keyboard focus
   *  has rested on it briefly. The level decides WHAT to warm — the item's data
   *  (`useResourceItemPrefetch`), the route it leads to (`router.prefetch`), or both;
   *  `TopicDetailItem.leadsTo` already says which kind of row it is. Fire-and-forget. */
  onPrefetch?: (id: string) => void
  /** Create affordance: when set, a `+` fires it — first in the list toolbar under this level's
   *  titled header, over the rows' icons; in the control strip when the level is collapsed to
   *  icons (replaces the old leading "New…" rail row). */
  onNew?: () => void
  /** Accessible name + tooltip for the `+` (e.g. "New Persona"). Defaults to "New". */
  newLabel?: string
  /** Tint the `+` gold to signal an in-progress create (nothing selected in the list). */
  newActive?: boolean
  /** Operations on this level's list (e.g. the Sites list's Auto Configure), right-justified in
   *  its list toolbar, after the `+` and the magnifier. Named for the title row they used to
   *  ride. Keep them compact — the toolbar is one line. */
  titleActions?: ReactNode
  /** Make this level's list searchable: a magnifier in its toolbar pops a query field over the
   *  rows. `{}` lets the rail filter on label + sublabel; pass `query` to own the filtering. */
  search?: TopicListSearch
  /** Fixed rail width in px for THIS level. Leave it unset: the rail then AUTO-FITS to its rows
   *  and header (`useRailFit`). Setting it turns auto-fit OFF for this level, for a rail whose
   *  width is a deliberate choice rather than a consequence of its rows. Covered style. */
  width?: number
  /** An optional leading ROW above this level's topics (scrolls with them, can carry
   *  the selection bar) — e.g. a "New…" affordance. Omit for a plain list. */
  railSlot?: RailSlot
  /** A pinned full-width strip between this level's title header and its rows (does
   *  NOT scroll with them) — the hook for the shared `ListHeader` (filter field +
   *  actions) when an entity list lives inside the stack. */
  headerSlot?: ReactNode
  /** Drop the LEADING icon from this level's rows in the expanded list. For a list whose rows
   *  have no identity icon to show — where the shared fallback `Circle` is noise and a state
   *  badge in the icon slot would duplicate the row's `trailing` mark. Ignored in the collapsed
   *  icon strip, which has nothing but the icon. This prop also currently suppresses the
   *  blocked marker — see the trap documented at the sr-only announcement in topic-detail.tsx. */
  hideItemIcons?: boolean
  /** BATCH MODE for this level's rows: show a checkbox on each, so several can be acted on at
   *  once from the stack's `toolbar`. The single selection underneath is untouched — ticking a
   *  box never opens or closes a detail, which is the whole point (the user is picking rows to
   *  Delete or Transfer, not rows to look at). Drive it with `useBatchSelect`, whose one job is
   *  that leaving the mode clears the ticks; ignored while this level is collapsed or covered to
   *  an icon strip, where a box has nothing visible to belong to. */
  checkable?: boolean
  /** Which of this level's rows are ticked. Read-only — rows call {@link onToggleChecked}. */
  checkedIds?: ReadonlySet<string>
  onToggleChecked?: (id: string) => void
}

/** The top bar: a breadcrumb trail (leading root, then each selected level, then any
 *  non-interactive trailing crumbs) on the left, an optional `help` affordance right-
 *  justified on the breadcrumb bar, and an optional toolbar (e.g. a "New…" button) above. */
/** One crumb of the trail. `href` is where it leads when the level it clears declares a
 *  `clearHref`; without one the crumb is a button. */
type Crumb = { levelIndex: number | null; label: string; interactive: boolean; href?: string }

/** A click the browser should keep: a new tab or window, a download, a non-primary button. Only a
 *  plain primary click is the stack's to handle in place. */
function isModifiedClick(e: ReactMouseEvent): boolean {
  return e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey
}

function TopBar({
  rootLabel,
  rootHref,
  crumbs,
  onNavigate,
  toolbar,
  help,
  showBreadcrumb,
}: {
  rootLabel?: string
  /** Where the root crumb leads: level 0's `clearHref`, when it has one. */
  rootHref?: string
  /** Selected-item labels in order, deepest last. Each `onNavigate`-able crumb carries the
   *  level it deselects-down-to; a trailing crumb (e.g. an in-pane leaf) has no levelIndex. */
  crumbs: Crumb[]
  /** `null` = the root crumb (deselect everything); else navigate to that level
   *  (deselect everything deeper). Omit a handler to render a static trail. */
  onNavigate?: (levelIndex: number | null) => void
  toolbar?: ReactNode
  /** Right-justified affordance on the breadcrumb bar (e.g. a help "?" describing the view). */
  help?: ReactNode
  showBreadcrumb: boolean
}) {
  // The whole trail; the last entry is current. The leading root deselects everything.
  const trail: Crumb[] = showBreadcrumb
    ? [
        ...(rootLabel !== undefined
          ? [{ levelIndex: null as number | null, label: rootLabel, interactive: true, href: rootHref }]
          : []),
        ...crumbs,
      ]
    : []
  const hasCrumbs = trail.length > 0
  if (!hasCrumbs && !toolbar) return null
  return (
    // Two stacked bars: the button bar (toolbar) on top, then the breadcrumb trail
    // UNDER it — not in the same row.
    <>
      {/* The strip is a plain flex row: alignment belongs to the toolbar content, which is the
          only thing that knows whether it is one right-hand button or a full-width bar with a
          flexible space in it. A `justify-end` here would make the second shape impossible.

          Both strips are sized by `--adh-chrome-bar-height` rather than by what they hold, so
          every bar under the workspace chooser is exactly as tall as every other one — see the
          token's note in `adh-components.css`. `min-h` and `py-1` rather than a fixed height:
          the breadcrumb `ol` wraps, and a wrapped trail must grow its bar instead of being cut
          off by it. */}
      {toolbar && (
        // AN EMPTY PORTAL SLOT COLLAPSES THE WHOLE STRIP. A host that publishes a slot for feature
        // toolbars (`RailHostRegistry.toolbarSlot`) has to mount the slot node unconditionally —
        // there is no node to portal into until it is in the DOM, and nothing tells the host
        // whether any feature will ever use it. So `toolbar` is always truthy there, and without
        // this every feature that portals nothing would gain a blank bordered bar. Marked by
        // `data-adh-toolbar-slot` rather than matched on `:empty` alone, so a caller passing real
        // content that merely happens to render nothing this frame is untouched.
        <div className="flex min-h-[var(--adh-chrome-bar-height,2.75rem)] shrink-0 items-center gap-2 border-b border-apt-border bg-apt-bg px-4 py-1 has-[[data-adh-toolbar-slot]:empty]:hidden">
          {toolbar}
        </div>
      )}
      {hasCrumbs && (
        <div className="flex min-h-[var(--adh-chrome-bar-height,2.75rem)] min-w-0 shrink-0 items-center gap-3 border-b border-apt-border bg-apt-nav px-4 py-1">
          <nav aria-label="Breadcrumb" className="min-w-0 flex-1">
            <ol className="flex min-w-0 flex-wrap items-center gap-x-1 gap-y-0.5">
              {trail.map((c, i) => {
                const last = i === trail.length - 1
                return (
                  <li key={`${i}-${c.label}`} className="flex min-w-0 items-center gap-1">
                    {/* Drawn before EVERY crumb, the root included. A trail of one — which is what
                        a feature's landing shows before anything is selected — read as a plain
                        heading without a leading mark; the chevron is what says "this is a path,
                        and there is more of it below". aria-hidden as the separators between
                        crumbs always were, so nothing changes for a screen reader. */}
                    <ChevronRight size={12} aria-hidden className="shrink-0 text-apt-text-dim" />
                    {last || !c.interactive || !onNavigate ? (
                      <span
                        aria-current={last ? "page" : undefined}
                        className={cn(
                          "truncate font-mono text-xs tracking-[0.02em]",
                          last ? "text-apt-gold" : "text-apt-text-muted",
                        )}
                      >
                        {c.label}
                      </span>
                    ) : c.href !== undefined ? (
                      // A real link to the address the crumb clears to, so it behaves as one
                      // everywhere a link does (new tab, long-press, copy). A plain click is still
                      // the stack's: it runs `onClear` through the unsaved-work guard rather than
                      // loading the page again.
                      <a
                        href={c.href}
                        onClick={(e) => {
                          if (isModifiedClick(e)) return
                          e.preventDefault()
                          onNavigate(c.levelIndex)
                        }}
                        className={CRUMB_LINK}
                      >
                        {c.label}
                      </a>
                    ) : (
                      <button type="button" onClick={() => onNavigate(c.levelIndex)} className={CRUMB_LINK}>
                        {c.label}
                      </button>
                    )}
                  </li>
                )
              })}
            </ol>
          </nav>
          {help && <div className="flex shrink-0 items-center">{help}</div>}
        </div>
      )}
    </>
  )
}

const CRUMB_LINK =
  "truncate rounded font-mono text-xs tracking-[0.02em] text-apt-text-muted outline-none hover:text-apt-text focus-visible:ring-2 focus-visible:ring-apt-gold/40"

/**
 * What the stack looks like right now, as opposed to what it is showing: the per-list `«`/`»` pins,
 * and the list whose branch the pointer currently holds open.
 */
type SurfaceState = {
  pins: Record<string, boolean>
  hoverId: string | null
  /** NARROW mode: the pane index the stack was last PAINTED at. The slide animates from here to
   *  wherever the new selection puts the top pane — and since selecting is a route change that
   *  remounts everything, a pane would otherwise mount already at its final position with nothing to
   *  transition FROM, which is why the push and pop never animated in the app. `null` = never painted
   *  (a fresh load lands where it lands; there is nothing to slide from). */
  narrowTop: number | null
  /** Per level: the appearance its `defaultSelectedId` has already been applied for (see the frame).
   *  Remembering this is what lets a manual clear stick — and it must outlive the mount for the same
   *  reason everything else here does: clearing the row IS a route change, so a per-instance memory
   *  would forget it was ever fired and immediately re-select the row the user just cleared. */
  autoSelected: Record<string, string>
}

/** How long one detail crossfades into the next. Brief on purpose — it reads as a swap, not a scene
 *  change; matches HMDV's detail fade. Stretched by the dev slow-animations switch. */
const DETAIL_CROSSFADE_MS = 220

/** Token changes inside this window don't fade: they are the settle cascade of one gesture (levels
 *  registering on mount, a default selection applying), not the user swapping details. */
const DETAIL_CROSSFADE_DEBOUNCE_MS = 300

/** How long an unmount-time snapshot stays adoptable by the next mount. A selection that remounts
 *  the subtree (a route param nav) swaps within a frame or two; anything older is a real departure
 *  and must not ghost back in. */
const DETAIL_CROSSFADE_STASH_MS = 1000

/** What the crossfade remembers per SURFACE, deliberately OUTSIDE React (like `surfaceStates`
 *  below, and for the same reason: selecting inside the stack is a route change that can REMOUNT
 *  the whole subtree). `token`/`tokenAt` = the selection the detail last painted and when — so a
 *  remount can tell "became a different detail" from "same detail, fresh mount", and a genuine
 *  first paint (no entry) shows instantly with no unasked-for intro. `clone`/`cloneAt` = the
 *  outgoing pane's DOM snapshot taken on the way out of an unmounting instance, so the swap can
 *  still crossfade across the remount. */
const detailSwapMemory = new Map<
  string,
  { token: string; tokenAt: number; clone: HTMLElement | null; cloneAt: number }
>()

/**
 * Drop every snapshot past its adoption window — the containment sweep, run on each mount and on
 * a timer set by each unmount. A `clone` is a deep copy of one pane's rendered DATA, so the map
 * must never be a place where a departed surface's data waits around: past
 * {@link DETAIL_CROSSFADE_STASH_MS} no mount may adopt it, and from here on none HOLDS it either.
 * `token`/`tokenAt` are kept — they are a selection id and a timestamp, and they are what tells a
 * returning surface "you were already showing this" so it doesn't fade in over itself.
 */
function forgetStaleSnapshots(now: number): void {
  for (const [key, mem] of detailSwapMemory) {
    if (mem.clone && now - mem.cloneAt >= DETAIL_CROSSFADE_STASH_MS)
      detailSwapMemory.set(key, { ...mem, clone: null, cloneAt: 0 })
  }
}

/**
 * THE DETAIL SWAP (Mike): when a selection replaces what the detail pane shows, the two contents
 * CROSSFADE briefly — the outgoing pane dissolves over the incoming one — instead of a hard cut.
 * When nothing was showing yet (the surface's first paint), the content simply appears: no fade,
 * no intro. The pane's GEOMETRY never animates on selection either way (see
 * `useInPlaceOnStructureChange`); this component is only about the content inside it.
 *
 * The outgoing half is a `cloneNode` DOM snapshot, inert and hidden from AT, removed the moment
 * the fade ends. Its twin (HMDV's `DetailContent`) deliberately fades only the incoming half,
 * because a clone copies markup, not pixels — a canvas or an editor viewport clones empty. That
 * limitation is real and accepted here: for the panes this stack swaps (forms, lists, cards) the
 * clone IS the picture, and the block's owner asked for the dissolve.
 *
 * A class component because the outgoing DOM only exists BEFORE React commits the new content, and
 * `getSnapshotBeforeUpdate` is the one hook that runs there. The unmount path (`snapshot` in
 * `componentWillUnmount`, adopted by the next instance's `componentDidMount` via the module memory
 * above) covers the selections that remount the subtree instead of updating it.
 */
class DetailCrossfade extends Component<{
  /** WHAT THIS PANE IS A PANE OF — the whole containment story, so read the note on
   *  `detailSwapMemory` before changing it. Two mounts share a stashed snapshot if and only if
   *  they pass the same string, so this must name the CONTENT, not just the widget: the owner
   *  (`surfaceScope`), the root list's id, and a fingerprint of the rows that list is showing. */
  memoryKey: string
  /** What the detail is showing: the per-level selection signature. A change = a swap. */
  token: string
  children: ReactNode
}> {
  private contentRef = createRef<HTMLDivElement>()
  private overlayRef = createRef<HTMLDivElement>()
  private anims: Animation[] = []
  /** Deadline that drops an unadopted snapshot (see `componentWillUnmount`). */
  private stashTimer: ReturnType<typeof setTimeout> | null = null

  /** A static, inert copy of the pane as it looks RIGHT NOW — null when nothing is showing. */
  private snapshotContent(): HTMLElement | null {
    const el = this.contentRef.current
    if (!el || el.offsetWidth === 0 || el.offsetHeight === 0 || el.childElementCount === 0) return null
    const clone = el.cloneNode(true) as HTMLElement
    // The copy is deep and includes the pane element itself, so it arrives wearing the `live`
    // marker too. Re-stamp it: exactly one `live` pane exists at any instant, mid-fade included.
    clone.setAttribute(DETAIL_PANE_ATTR, "ghost")
    return clone
  }

  /**
   * Stop any fade in flight AND empty the overlay — always both. The overlay is emptied only by the
   * fade-out's "finish", and a CANCELLED animation never fires "finish", so cancelling alone strands
   * the outgoing snapshot on top of the live pane at full opacity (a cancelled fade also drops its
   * opacity keyframes). That is exactly what shipped: StrictMode runs mount → unmount → mount on the
   * SAME DOM, the unmount cancelled the fade the first mount started, and every settings topic you
   * switched to was drawn over the one you left — two titles garbled into each other, two tables
   * interleaved. Any path that cancels comes through here.
   */
  private stopFade(): void {
    this.anims.forEach((a) => a.cancel())
    this.anims = []
    this.overlayRef.current?.replaceChildren()
  }

  private crossfade(outgoing: HTMLElement): void {
    const content = this.contentRef.current
    const overlay = this.overlayRef.current
    // No WAAPI (jsdom under test, or a browser too old): land instantly. The fade is decoration —
    // never make the swap depend on being able to animate it.
    if (!content || !overlay || typeof content.animate !== "function") return
    // A fast second swap: drop the in-flight pair (cancelled animations never fire "finish", so
    // the old cleanup can't wipe the overlay we are about to fill).
    this.stopFade()
    overlay.replaceChildren(outgoing)
    const ms = DETAIL_CROSSFADE_MS * (getSlowAnimations() ? SLOW_ANIM_FACTOR : 1)
    const opts: KeyframeAnimationOptions = { duration: ms, easing: "ease-in-out" }
    const fadeOut = overlay.animate([{ opacity: 1 }, { opacity: 0 }], opts)
    const fadeIn = content.animate([{ opacity: 0 }, { opacity: 1 }], opts)
    this.anims = [fadeOut, fadeIn]
    fadeOut.addEventListener("finish", () => {
      if (this.anims[0] !== fadeOut) return // a newer fade owns the overlay now
      overlay.replaceChildren()
      this.anims = []
    })
  }

  override componentDidMount(): void {
    const { memoryKey, token } = this.props
    const mem = detailSwapMemory.get(memoryKey)
    const now = Date.now()
    forgetStaleSnapshots(now)
    detailSwapMemory.set(memoryKey, {
      token,
      tokenAt: mem?.token === token ? mem.tokenAt : now,
      clone: null,
      cloneAt: 0,
    })
    if (!mem || mem.token === token) return // first paint, or a remount of the same detail
    // The remount half of a swap: fade from the stashed outgoing pane — but only when the swap was
    // quick enough to read as one gesture, and the outgoing detail had actually settled on screen.
    if (
      mem.clone &&
      now - mem.cloneAt < DETAIL_CROSSFADE_STASH_MS &&
      now - mem.tokenAt > DETAIL_CROSSFADE_DEBOUNCE_MS
    )
      this.crossfade(mem.clone)
  }

  override getSnapshotBeforeUpdate(prevProps: this["props"]): HTMLElement | null {
    // The one moment the OUTGOING pane's DOM still exists: after the new render, before React
    // commits its mutations. (A layout effect is already too late — the old pixels are gone.)
    if (prevProps.memoryKey !== this.props.memoryKey || prevProps.token === this.props.token)
      return null
    return this.snapshotContent()
  }

  override componentDidUpdate(
    prevProps: this["props"],
    _prevState: never,
    snapshot: HTMLElement | null,
  ): void {
    const { memoryKey, token } = this.props
    if (prevProps.memoryKey === memoryKey && prevProps.token === token) return
    const mem = detailSwapMemory.get(memoryKey)
    const now = Date.now()
    const settled = !mem || now - mem.tokenAt > DETAIL_CROSSFADE_DEBOUNCE_MS
    detailSwapMemory.set(memoryKey, { token, tokenAt: now, clone: null, cloneAt: 0 })
    // No snapshot = nothing was showing (or a surface change, which is a fresh start): just show
    // the new content. `settled` keeps the mount-time registration cascade from fading.
    if (snapshot && settled && prevProps.memoryKey === memoryKey) this.crossfade(snapshot)
  }

  override componentWillUnmount(): void {
    this.stopFade()
    if (this.stashTimer !== null) clearTimeout(this.stashTimer)
    // The DOM is still attached here — stash the pane for the remount half of a swap. The stash
    // is adoptable only for {@link DETAIL_CROSSFADE_STASH_MS}, and it is DROPPED at that deadline
    // rather than merely refused: a departure that never comes back must not leave a picture of
    // its data sitting in a module map waiting for whoever mounts next.
    const key = this.props.memoryKey
    const mem = detailSwapMemory.get(key)
    const at = Date.now()
    detailSwapMemory.set(key, {
      token: this.props.token,
      tokenAt: mem?.token === this.props.token ? mem.tokenAt : at,
      clone: this.snapshotContent(),
      cloneAt: at,
    })
    this.stashTimer = setTimeout(() => forgetStaleSnapshots(Date.now()), DETAIL_CROSSFADE_STASH_MS)
  }

  override render(): ReactElement {
    return (
      <div className="relative flex min-h-0 min-w-0 flex-1 flex-col">
        <div
          ref={this.contentRef}
          {...{ [DETAIL_PANE_ATTR]: "live" }}
          className="flex min-h-0 min-w-0 flex-1 flex-col"
        >
          {this.props.children}
        </div>
        {/* The outgoing snapshot's home, above the content. A static clone: no listeners, no React,
            out of the AT tree and the pointer's way; empty except while a fade runs. */}
        <div
          ref={this.overlayRef}
          aria-hidden
          inert
          className="pointer-events-none absolute inset-0 flex flex-col overflow-hidden"
        />
      </div>
    )
  }
}

/**
 * That state per SURFACE, keyed by the stack's root level id — deliberately OUTSIDE React.
 *
 * Selecting a row inside the stack is a route change, and a route change REMOUNTS the page subtree
 * (Next re-creates it on a param nav). Anything the frame held in component state was therefore
 * destroyed by the user's own click, which produced two bugs that look unrelated and are the same
 * one: the lists you had just opened all snapped shut under you, and a revealed branch collapsed
 * the instant you picked a row inside it — with the pointer still sitting in it, so nothing would
 * reopen it. None of this belongs to a mount: it
 * belongs to the SURFACE the user is looking at, and it has to outlive the click.
 *
 * Module scope gives exactly that lifetime. It does NOT survive a reload, which is the right seam —
 * a fresh load is a deliberate fresh start, and it keeps the frame free of storage and hydration
 * concerns. Writes only ever happen in event handlers, so SSR never touches this map.
 */
const surfaceStates = new Map<string, SurfaceState>()

export function HierarchicalTopicDetail({
  levels,
  rootLabel,
  trailingCrumbs,
  toolbar,
  help,
  showBreadcrumb = true,
  minDetailWidth: minDetailWidthProp = MIN_DETAIL_DEFAULT,
  detailWidth,
  detailTitle,
  exitGuard = null,
  manualCollapse = true,
  disclosureStyle = "covered",
  layoutMode = "auto",
  ssrDetail = false,
  surfaceScope,
  children,
}: {
  /** The rail levels, outermost first. Each level's selection scopes the next. */
  levels: TopicLevel[]
  /**
   * WHOSE stack this is — the id of the account, workspace, org or tenant whose data the levels
   * describe. It is not decoration: this component keeps per-surface memory OUTSIDE React (see
   * `surfaceStates` and `detailSwapMemory`, both of which have to outlive the remount that a
   * selection causes), and that memory is keyed by what it is told. Given two stacks that differ
   * only in whose rows they list — the same feature under two workspaces — a key built from the
   * level ids alone is the SAME key, and the second stack inherits the first's memory.
   *
   * Pass it wherever a surface can be looked at under more than one owner, and pass the owner's
   * id, not its name. Omitting it is right only for a stack there is exactly one of.
   */
  surfaceScope?: string
  /** Leading breadcrumb (e.g. the feature/workspace name); its crumb deselects
   *  everything (clears level 0). Omit to start the trail at the first selection. */
  rootLabel?: string
  /** Extra non-interactive crumbs appended after the level crumbs (e.g. an in-pane
   *  master/detail leaf label the package doesn't own). */
  trailingCrumbs?: { label: string }[]
  /** Content for the full-width strip above the breadcrumb — a feature's own bar (search,
   *  filters, a primary action) or a lone "New…" button. The strip is a flex row with no
   *  justification of its own, so this node places itself (`w-full` + a flexible space to
   *  reach the right edge).
   *
   *  A PORTAL SLOT — a node a host mounts for features to portal their bars into — must carry
   *  `data-adh-toolbar-slot`, which is what lets the strip collapse on the (common) frame where
   *  nothing has portalled anything. See the comment at the strip. */
  toolbar?: ReactNode
  /** Right-justified affordance on the breadcrumb bar (e.g. a help "?" for the view). */
  help?: ReactNode
  /** Show the breadcrumb trail (default true). Pass false when an enclosing chrome
   *  renders the breadcrumb instead (the rails then carry no top bar of their own). */
  showBreadcrumb?: boolean
  /** Minimum width of the leaf detail pane (CSS length). The floor of the whole shrink sequence:
   *  the lists collapse, then the detail shrinks TO this, then the lists slide off-screen — and
   *  only when the detail can't hold this width even alone does the stack go NARROW (where the
   *  detail is simply the device's width, which is also why phones need no value here). Default
   *  {@link MIN_DETAIL_DEFAULT}: deliberately small for a desktop but clearly wider than a phone. */
  minDetailWidth?: string
  /** A FIXED width for the leaf detail pane in the wide layouts (CSS length), instead of the
   *  default of filling whatever the lists leave. For a detail that is a document to read rather
   *  than a workspace to fill — a measure that does not change as the window does, and content
   *  that can lay itself out to that one width. The room to its right stays empty.
   *
   *  It is also the pane's minimum (it replaces `minDetailWidth`): the lists collapse and slide
   *  off until the pane has this width, and it narrows only when it could not have it even alone
   *  — then the stack goes NARROW, where the detail is the device's width as always. */
  detailWidth?: string
  /** A title shown in the detail (leaf) pane's top strip, aligned with the rail
   *  headers — names what the pane is showing (covered style). */
  detailTitle?: ReactNode
  /** The leaf editor's unsaved-work guard. When dirty, Back / breadcrumb-up / re-click /
   *  selecting a shallower row / swapping to a sibling at the deepest level first raise the
   *  platform's discard alert (Discard / Stay). Omit for no guard. */
  exitGuard?: PaneExitGuard | null
  /** Keep the per-rail manual disclosure toggle (the `«` icon strip). Default true. A
   *  manually-collapsed list counts as its icon width in the fit math, then slides
   *  off-screen if there is still no room. (Minimized style only.) */
  manualCollapse?: boolean
  /** How ancestor lists yield room to the detail as the window narrows. Default `"covered"`.
   *   - `"minimized"` — the leftmost lists shrink to icon strips, then slide off-screen; a
   *      top-left Back walks back up.
   *   - `"covered"` — the lists stay FULL width; the leftmost slide LEFT *under* their child
   *      (covered), with a `«`/`»` cover toggle on each child and a left drop-shadow making the
   *      stack read as physically layered. No Back button. */
  disclosureStyle?: "minimized" | "covered"
  /** WIDE (lists beside the detail, `disclosureStyle` above) vs NARROW (one full-width pane at a
   *  time, pushed/popped like an iOS `UINavigationController`). Default `"auto"`: narrow once the
   *  wide layout's whole shrink sequence is exhausted — every list collapsed, the detail at
   *  `minDetailWidth`, every collapsible list slid off-screen — or when the browser is a phone (a
   *  phone therefore starts and stays narrow). The threshold does not depend on what is selected, so
   *  the mode never flips under a click. `"wide"` / `"narrow"` force one (a showcase, a test). */
  layoutMode?: "auto" | "wide" | "narrow"
  /**
   * SERVER-RENDER the detail pane as well as portaling it. Default false, which is this stack's
   * historical behaviour: the detail exists only inside the client-created portal host, so it is
   * absent from the server's HTML entirely and arrives at hydration.
   *
   * That default is right for a stack whose detail is a data browser, a form or anything behind
   * auth — there is nothing to render on the server and nothing that wants indexing. It is wrong
   * for a stack whose detail IS the page's content: a documentation or topic browser that renders
   * no prose on the server is invisible to a crawler and blank without JavaScript, and no test
   * catches it because a client-side render always populates the host.
   *
   * When true, the detail also renders as ordinary children of the active stack's detail slot for
   * exactly as long as the portal host does not exist — the server pass and the hydrating client
   * render, which produce identical markup. The layout effect then creates the host, this seed
   * unmounts, and the portal takes over the same DOM position. The handoff is invisible: it lands
   * in the commit BEFORE the browser paints, and it remounts {@link DetailCrossfade} with an
   * unchanged token, which that component reads as "a remount of the same detail" and does not
   * fade.
   *
   * It is opt-in rather than the default because the seed's one visible consequence — content in
   * the pre-hydration paint — is an improvement for a topic browser and a regression for a pane
   * that would rather show nothing until it is live.
   *
   * THE CONTRACT IT PUTS ON `children`: the handoff is a real unmount and remount, not a move. React
   * has no way to relocate a subtree between parents while preserving it, so on the commit after
   * mount the detail runs cleanup and then setup AGAIN — effects re-fire, `useState` initialisers
   * re-run, refs are re-attached, a `<video>` restarts, an uncontrolled `<input>` loses what was
   * typed. That is harmless for content read out of props, which is what a topic browser's detail
   * is; it is not harmless for a detail that initialises anything in a mount effect (opening a
   * socket, starting a timer, POSTing an analytics event — which fires twice) or that keeps state
   * only in itself. Such a detail should either lift that state to the owner, so the remount is a
   * re-read rather than a reset, or leave `ssrDetail` off. This is invisible in development,
   * where StrictMode double-invokes mount effects anyway and so hides the extra pass.
   */
  ssrDetail?: boolean
  /** Innermost detail content for the current selection (lands in the rightmost
   *  detail pane). */
  children: ReactNode
}) {
  // Frontier = the deepest rendered rail: the first level with no selection, else the last level.
  // Rails 0..frontier render as flat sibling columns; `children` are the rightmost (detail) column.
  const firstUnselected = levels.findIndex((l) => l.selectedId == null)
  const frontier = firstUnselected === -1 ? levels.length - 1 : firstUnselected
  const rendered = levels.slice(0, frontier + 1)
  // The deepest SELECTED level (whose detail is showing): the frontier if every level is selected,
  // else one above it; -1 when nothing is selected. Back clears exactly this level.
  const deepestSelected = deepestSelectedLevel(levels)

  // The unsaved-work gate: every action that would clear a level (Back, re-click-deselect,
  // breadcrumb up-nav, selecting a shallower row) runs through here. The policy lives in the
  // shared hook so this block and HMDV cannot drift apart again.
  const { attemptExit, exitAlertProps } = useExitGate(exitGuard)

  // The browser's own Back (iOS Safari's button and edge swipe) walks up the stack like the in-page
  // Back does, for a host that routes and says where each level clears to (`clearHref`).
  useSeededBackStack(levels)

  // Each selected level contributes a crumb; clicking it deselects EVERYTHING DEEPER — i.e. it
  // clears the next level down (`levels[i+1].onClear()`), leaving this level's selection in place.
  // The package owns this so consumers write no breadcrumb-up logic. Trailing crumbs (e.g. an
  // in-pane leaf label) are appended non-interactively.
  const crumbs: Crumb[] = [
    ...levels
      .map((l, i): Crumb | null =>
        l.selectedId == null
          ? null
          : {
              levelIndex: i,
              label: l.items.find((it) => it.id === l.selectedId)?.label ?? l.selectedId,
              interactive: true,
              // A level crumb clears the level BELOW it, so it leads where that one clears to.
              href: levels[i + 1]?.clearHref,
            },
      )
      .filter((c): c is Crumb => c !== null),
    ...(trailingCrumbs ?? []).map((c) => ({ levelIndex: null, label: c.label, interactive: false })),
  ]

  // Breadcrumb navigation, package-owned via onClear (gated by the exit guard): the root crumb
  // clears level 0 (deselect all); a level crumb clears the level below it (deselect deeper).
  const onCrumbNavigate = (levelIndex: number | null) =>
    attemptExit(() => (levelIndex === null ? levels[0]?.onClear() : levels[levelIndex + 1]?.onClear()))

  // Disclosure INTENT, owned here so both layouts share one contract (they differ only in how a
  // hidden list is drawn — a peek vs an icon strip): `pins` is per-level user intent from the
  // `«`/`»` toggles (true = keep hidden, false = keep disclosed). Width pressure may still hide a
  // list the user pinned open — there is no room — but never discloses one they pinned shut.
  // Absent a pin a list is DISCLOSED; the standing auto-hide intent that used to cover every
  // ancestor by default is parked (see the note above `IN_PLACE_SETTLE_MS`).
  //
  // These live in the module store (see `surfaceStates`), NOT in component state, because a click in
  // the stack is a route change and a route change remounts this whole subtree — component state
  // would be destroyed by the very click that must not disturb it. Keyed by the ROOT list, the one
  // level a surface keeps across its own navigations. The key resolves late where a host registers
  // its levels in an effect (the first render has none), which is harmless: there is nothing to
  // toggle or hover before the stack exists.
  // ...and scoped by `surfaceScope`, so "the same surface" means the same LIST OF THE SAME
  // OWNER'S rows. Without that, switching workspace hands the next workspace's stack everything
  // this one remembered, up to and including the outgoing detail pane's DOM (found live).
  const rootLevelId = levels[0]?.id ?? ""
  const surfaceKey = rootLevelId ? `${surfaceScope ?? ""}::${rootLevelId}` : ""
  // The DETAIL pane's memory is keyed harder still, because what it stashes across a remount is a
  // copy of rendered data rather than a pin or a hover: the root list's actual rows join the key,
  // so a snapshot can only ever be adopted by a stack showing THE SAME ROWS. A scope someone
  // forgot to pass therefore still cannot leak a pane between two different lists — and the
  // fingerprint is the ids themselves, never a hash of them, because a hash collision here would
  // be precisely the bug this key exists to make impossible.
  const detailMemoryKey = `${surfaceKey}::${levels[0]?.items.map((it) => it.id).join(",") ?? ""}`
  const [, bumpSurface] = useReducer((n: number) => n + 1, 0)
  const surface = surfaceStates.get(surfaceKey) ?? {
    pins: {},
    hoverId: null,
    narrowTop: null,
    autoSelected: {},
  }
  const { pins, hoverId } = surface
  // Always patch from what is IN the store, never from the render's snapshot: a remount replays this
  // component around state that outlived it, so a closed-over `surface` can be a render behind.
  const patchSurface = useCallback(
    (update: (prev: SurfaceState) => SurfaceState) => {
      if (!surfaceKey) return
      const prev = surfaceStates.get(surfaceKey) ?? {
        pins: {},
        hoverId: null,
        narrowTop: null,
        autoSelected: {},
      }
      surfaceStates.set(surfaceKey, update(prev))
      bumpSurface()
    },
    [surfaceKey],
  )
  const setPins: Dispatch<SetStateAction<Record<string, boolean>>> = useCallback(
    (update) =>
      patchSurface((p) => ({
        ...p,
        pins: typeof update === "function" ? update(p.pins) : update,
      })),
    [patchSurface],
  )
  const setHoverId = useCallback(
    (id: string | null) => patchSurface((p) => ({ ...p, hoverId: id })),
    [patchSurface],
  )
  const setNarrowTop = useCallback(
    (i: number) => patchSurface((p) => (p.narrowTop === i ? p : { ...p, narrowTop: i })),
    [patchSurface],
  )

  // ONE measurement of the row, owned by the frame: it decides WIDE vs NARROW, and the covered stack
  // reuses it for its fit math (so there is still a single disclosure controller). `useLayoutEffect`
  // inside takes the first measurement before paint, so a narrow container never flashes the wide
  // layout on its first frame.
  const rowRef = useRef<HTMLDivElement>(null)
  const containerW = useContainerWidth(rowRef)
  const phone = usePhoneUserAgent()
  // NARROW = the wide layout has nothing left to trade: the shrink sequence (cover the lists, shrink
  // the detail to its minimum, slide the covered lists off-screen one at a time — see the stacks
  // below) has hidden every list it may hide and the container STILL can't fit what remains, which
  // is the detail at its minimum beside the last list's strip. Below that the strip goes too and the
  // stack becomes a navigation controller: ONE full-width pane at a time, exactly one topic list OR
  // the detail, pushed and popped like an iOS `UINavigationController`. A phone is always narrow
  // regardless of the box it is given. Until the first measurement lands (containerW === 0) we
  // assume wide — the layout effect corrects it pre-paint.
  //
  // The floor is deliberately BELOW the old `minDetail + FULL_RAIL` one, which flipped the stack to
  // narrow while the wide layout still had lists to cover progressively — so every list vanished at
  // once as the window shrank, and the one-strip-at-a-time drill-down never ran (Mike).
  //
  // And it does NOT vary with the selection, which it used to: an unselected frontier claims no
  // detail minimum (its pane is only a landing, so the fit math must never squeeze the list the user
  // is choosing from), and reading that exemption as a lower NARROW floor let the wide layout run
  // all the way down to a bare 240px rail — leaving a full list beside a detail sliver a few dozen
  // pixels wide, which is neither usable nor one-thing-at-a-time. The exemption belongs to the fit
  // math, not to the mode. Selection-independent also makes the mode STABLE across a navigation:
  // a selection-dependent floor could flip the stack on the click itself, and the lost selection
  // then lowered the floor the decision was re-made on and bounced it straight back to wide.
  //
  // The floor is also never allowed BELOW phone width, whatever the host asked for. `minDetailWidth`
  // is a request about the DETAIL pane; read as the whole mode's threshold it let a host declare,
  // without meaning to, that two panes side by side are fine at 320px. shipr passing `24rem` (288px
  // at this family's 12px root, +32 strip = 320) is exactly that: a floor narrower than any phone,
  // so the stack stayed wide all the way down and the site was unusable on an iPhone — rescued only
  // by the user-agent check, and a desktop window dragged to phone width has no user agent to
  // rescue it (Mike: "this completely breaks the site on iPhone").
  // A fixed detail width is also its floor: the fit math must clear room for all of it.
  const minDetailWidth = detailWidth ?? minDetailWidthProp
  const stripPx = disclosureStyle === "minimized" ? COLLAPSED_RAIL : COVERED_PEEK
  const wideFloor = Math.max(minDetailPx(minDetailWidth) + stripPx, PHONE_FLOOR)
  const narrow =
    layoutMode === "narrow" ||
    (layoutMode === "auto" && (phone || (containerW > 0 && containerW < wideFloor)))

  // A level's OPT-IN `defaultSelectedId`: select it for the user the moment the list appears with
  // nothing chosen. Fired as the level's own `onSelect`, so it is indistinguishable from a click —
  // except in HISTORY: it goes out with `{ replace: true }`, because the state it replaces is one
  // the user never asked for and never sees. Push it and every visit costs TWO Back presses, the
  // first landing on the bare parent that instantly re-applies the default and bounces forward.
  //
  // Armed per APPEARANCE, which is the whole subtlety. The arming key is the ancestor selections that
  // produced this list, remembered per level (in the surface store, because applying or clearing the
  // selection is itself a route change that remounts this component — a per-instance memory would
  // forget it had fired and re-select the row the user just cleared, making the row undeselectable):
  //   - the list is not rendered at all (its parent is unselected) → DISARM, so the next visit fires;
  //   - already fired for this key and the user has since cleared the row → stay disarmed. The
  //     default may choose FOR the user, never argue WITH them;
  //   - the list appeared ALREADY selected (a deep link into a view) → spend the visit without
  //     firing, so that same clear-stands rule covers the deep-linked entry too.
  // A default naming an item the list doesn't have (yet) is simply not applied — an async list arms
  // when its rows land, and a stale default never selects a phantom row.
  //
  // Never in the narrow stack (see `defaultSelectedId`), and not until the layout is KNOWN, not
  // merely rendered: before the row is measured the stack draws wide, and firing on that guess
  // would select for a phone. The phone test is read live, not from `phone` — that state lands in
  // an effect that runs after this one.
  useEffect(() => {
    const layoutKnown = layoutMode !== "auto" || containerW > 0
    const wideNow = layoutKnown && !narrow && !(layoutMode === "auto" && phoneUserAgent())
    levels.forEach((level, i) => {
      const wanted = level.defaultSelectedId
      if (wanted == null) return
      if (i > frontier) {
        // The list is gone (its parent is unselected): re-arm it for the next visit.
        if (surface.autoSelected[level.id] !== undefined) {
          patchSurface((p) => {
            const next = { ...p.autoSelected }
            delete next[level.id]
            return { ...p, autoSelected: next }
          })
        }
        return
      }
      const key = `${levels
        .slice(0, i)
        .map((l) => l.selectedId ?? "")
        .join("|")}::${wanted}`
      if (level.selectedId != null) {
        // The list appeared with a selection ALREADY in place — a deep link straight to a view,
        // or the default's own select landing. Nothing to apply, but the visit must still count as
        // spent: leave it unrecorded and a later manual clear looks exactly like "the list just
        // appeared with nothing chosen", so the default re-fires and the row cannot be deselected.
        if (surface.autoSelected[level.id] !== key) {
          patchSurface((p) => ({ ...p, autoSelected: { ...p.autoSelected, [level.id]: key } }))
        }
        return
      }
      if (!level.items.some((it) => it.id === wanted)) return
      // Not now, and not spent: a list seen narrow gets its default once it is seen wide.
      if (!wideNow) return
      if (surface.autoSelected[level.id] === key) return // fired for this visit; a manual clear stands
      patchSurface((p) => ({ ...p, autoSelected: { ...p.autoSelected, [level.id]: key } }))
      level.onSelect(wanted, { replace: true })
    })
  })

  // ONE DETAIL HOST that survives every stack flip. The three stacks are different component
  // types, and React reconciles by tree position — rendering the detail as a stack's child would
  // REMOUNT it on every wide↔narrow or covered↔minimized flip, resetting whatever state lives in
  // `children` (a data browser's schema/table choice, a half-typed form) and unregistering any
  // levels those children publish. That loss is what the flip must never cause: back when
  // `wideFloor` still varied with the selection it even bounced the mode straight back to wide (the
  // lost selection lowered the floor the narrow decision was made on). So the detail renders through a
  // PORTAL into this frame-owned, layout-neutral (`display: contents`) element, and the layout
  // effect below re-slots that element into whichever stack is active: the flip MOVES the
  // detail's DOM, React state intact.
  //
  // The host is created in a LAYOUT EFFECT and not in a `useState` initializer, because a lazy
  // initializer runs during RENDER: `typeof document` is undefined on the server and defined on the
  // very first client render, so the hydration pass would already be rendering the portal. React
  // does NOT skip portals while hydrating — it descends into the container and expects to find
  // markup matching the portal's children there. This container was created microseconds earlier
  // and is empty, so the trees diverge and React throws away the entire server tree and regenerates
  // it on the client. That is expensive, and it re-creates every host node the document already
  // had — including any <script> in the consumer's <head>, which React refuses to create
  // client-side ("Encountered a script tag while rendering React component"). An effect runs AFTER
  // the commit, so the first client render returns the same `null` the server did and hydration
  // matches.
  //
  // Layout, not passive, so the extra render is flushed before the browser paints and the detail is
  // on screen in the frame it always was. The ref makes the element itself survive StrictMode's
  // double-invoke — re-running bare would strand the first host inside the slot.
  const detailHostRef = useRef<HTMLDivElement | null>(null)
  const [detailHost, setDetailHost] = useState<HTMLDivElement | null>(null)
  useLayoutEffect(() => {
    if (!detailHostRef.current) {
      const el = document.createElement("div")
      el.className = "contents"
      detailHostRef.current = el
    }
    setDetailHost(detailHostRef.current)
  }, [])
  const [detailSlotEl, setDetailSlotEl] = useState<HTMLDivElement | null>(null)
  useLayoutEffect(() => {
    if (detailHost && detailSlotEl) detailSlotEl.appendChild(detailHost)
  }, [detailHost, detailSlotEl])

  // LAYOUT LOG — the mode decision, on change only, with the width it was made at (htdv-log.ts).
  const modeSig = `${narrow}|${wideFloor}|${phone}|${layoutMode}`
  const loggedModeSig = useRef<string | null>(null)
  useEffect(() => {
    if (loggedModeSig.current === modeSig) return
    loggedModeSig.current = modeSig
    hlog(surfaceKey || "htdv", "mode", {
      mode: narrow ? "narrow" : "wide",
      w: containerW,
      floor: wideFloor,
      phone,
      layout: layoutMode,
    })
  })

  // THE AUTOMATIC FRONTIER DETAIL: while the frontier list has no selection, the detail pane is
  // owned by the package — an almost-empty centered nudge to select something (TopicSelectHint),
  // named for the level (`itemNoun` → `title` → generic) and carrying the level's bespoke
  // `overviewHelp` blurb, instead of whatever placeholder the host passed as children. A level
  // whose unselected pane already holds a real editor — the inline CREATE form, the one case —
  // opts out entirely (`overview: false`), never to hang a landing page there. It exists ONLY in
  // that state: the moment the frontier gains a selection the host's real detail (children) shows.
  // There is exactly ONE shape here, by rule: a card grid of the same rows the rail is already
  // showing is a second surface beside the rail.
  const frontierLevel = firstUnselected === -1 ? null : levels[firstUnselected]
  const overview =
    // The nudge names the level's rows as specifically as it can (itemNoun → title → generic)
    // and carries the level's bespoke overviewHelp blurb. An EMPTY list with a blurb still shows
    // the blurb alone (it explains what belongs here); empty without one renders nothing — the
    // host's own children placeholder stands.
    frontierLevel &&
    frontierLevel.overview !== false &&
    (frontierLevel.items.length > 0 || frontierLevel.overviewHelp != null) ? (
      <TopicSelectHint
        noun={frontierLevel.itemNoun}
        listTitle={frontierLevel.title}
        selectable={frontierLevel.items.length > 0}
      >
        {frontierLevel.overviewHelp}
      </TopicSelectHint>
    ) : null
  // `children` stay MOUNTED under the overview AND in the SAME tree position: in a merged stack
  // the deeper levels are PUBLISHED by components living in children (StackLevels), so unmounting
  // them would unregister the very frontier level this overview is for. The wrapper is therefore
  // ALWAYS present and only its visibility toggles — conditionally re-parenting children into it
  // IS a remount (React reconciles by position), which resets their state and unregisters their
  // levels, looping the stack between the two states (a mount/fetch storm, found live). Inline
  // display (not the `hidden` attribute) so the flex utility class can't override it.
  // The pane's title rides the detail strip, not the pane (see detail-title.tsx). The
  // provider wraps the detail itself so it reaches the content wherever the frame mounts it.
  // With neither a pane's title nor the host's, the strip names the selected topic.
  const titleHost = useDetailTitleHost()
  const stripTitle = detailStripTitle(titleHost, detailTitle ?? selectedTopicLabel(levels))
  const detail = (
    // The swap wrapper: a selection replacing the pane's content crossfades briefly; a first paint
    // just shows. Keyed on the SELECTION signature — the one thing that changes what this pane is
    // showing from the stack's point of view.
    <DetailTitleProvider host={titleHost}>
    <DetailCrossfade
      memoryKey={detailMemoryKey}
      token={levels.map((l) => l.selectedId ?? "·").join("|")}
    >
      {overview}
      <div
        style={overview ? { display: "none" } : undefined}
        className="flex min-h-0 min-w-0 flex-1 flex-col"
      >
        {children}
      </div>
    </DetailCrossfade>
    </DetailTitleProvider>
  )

  // THE SERVER SEED (`ssrDetail`). The portal above contributes NOTHING until a layout effect has
  // built its host, so on the server — and on the hydrating render that has to match it — the pane
  // is empty. For a stack whose detail is the page's content that is the whole page missing from
  // the HTML. So the same `detail` also renders as ordinary children of the active stack's slot for
  // exactly the window in which the host does not exist, and the two renders that must agree (the
  // server's and hydration's) both see `detailHost === null` and emit it identically.
  //
  // It is the SAME element in the same DOM position, so the handoff is a remount, not a move: the
  // seed unmounts as the portal mounts, in the commit the host-creating layout effect schedules —
  // before paint. `DetailCrossfade` sees a remount carrying an unchanged token and treats it as
  // "the same detail", so nothing fades. Deliberately NOT `display: none`-ed while it waits: a
  // hidden seed would satisfy a crawler and still leave the page blank without JavaScript, which is
  // half the reason to render it at all.
  const detailSeed = ssrDetail && !detailHost ? detail : null

  // The layouts share the same selection / breadcrumb / exit-guard semantics above and differ ONLY in
  // how the lists yield room to the detail — so each is its own subcomponent owning its layout state
  // (kept distinct so any one can evolve or be deleted independently).
  const stackProps = {
    rendered,
    deepestSelected,
    firstUnselected,
    frontier,
    minDetailWidth,
    detailWidth,
    detailTitle: stripTitle,
    attemptExit,
    pins,
    setPins,
    hoverId,
    setHoverId,
    narrowTop: surface.narrowTop,
    setNarrowTop,
    containerW,
    detailSlot: setDetailSlotEl,
    detailSeed,
  }

  return (
    // The dev-only animation scale is applied to <html> by the host app, not here: portaled
    // dialogs/menus escape this subtree, so a container-level variable could never reach them.
    //
    // The view is MEASURED, not flowed: every stack under here is `min-h-0 flex-1`, and so is
    // this root, so the whole block sizes itself to whatever height it is given and scrolls
    // internally. A root that could outgrow that height (a flex item's default `min-height:
    // auto` is its content's height) would push the page past the viewport instead of
    // scrolling its own panes.
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <TopBar
        rootLabel={rootLabel}
        rootHref={levels[0]?.clearHref}
        crumbs={crumbs}
        onNavigate={onCrumbNavigate}
        toolbar={toolbar}
        help={help}
        showBreadcrumb={showBreadcrumb}
      />
      {/* The measured row. Every stack fills it, so ONE ResizeObserver here is the whole view's
          width signal — the mode decision above and the covered stack's fit math below.
          `data-htd-layout` says which mode won, so a host's CSS can fit its detail to the narrow
          pane (tighter gutters on a phone) off the same decision rather than a guessed breakpoint. */}
      <div
        ref={rowRef}
        data-htd-layout={narrow ? "narrow" : "wide"}
        className="flex min-h-0 min-w-0 flex-1 flex-col"
      >
        {narrow ? (
          <NarrowStack {...stackProps} levels={levels} />
        ) : disclosureStyle === "minimized" ? (
          <MinimizedStack {...stackProps} levels={levels} manualCollapse={manualCollapse} />
        ) : (
          <CoveredStack {...stackProps} />
        )}
        {/* The detail content, mounted ONCE regardless of which stack is active (see detailHost
            above). The portal contributes no node here — the content lives in the host element,
            which the placement effect keeps inside the active stack's detail slot. */}
        {detailHost ? createPortal(detail, detailHost) : null}
      </div>

      {/* Unsaved-work guard: the platform's one discard alert. Discard → run the held exit;
          Stay → keep the dirty editor. It never saves — that is the editor's own affordance. */}
      <UnsavedChangesAlert {...exitAlertProps} />
    </div>
  )
}

// Covered (stacked) style: how much of a covered list still peeks out on the left under its child —
// a PARTIAL cover, so the stack reads as physically layered cards (not a full cover / off-screen).
// FULL_RAIL / COLLAPSED_RAIL are imported from topic-detail (the one authoritative home).

/**
 * Each rail's own answer to "how wide do my rows want to be", collected from `TopicRail`'s
 * `onFit` (which measures and clamps — see there), and kept PER RAIL.
 *
 * WHY PER RAIL. This used to pool the answers and render every rail at the widest one any of
 * them had given, to stop columns moving under the pointer. The cost turned out to be the
 * thing you actually see: shipr's `Projects` rail holds `adh` and `sites`, wants 73px, and was
 * drawn at 217px because a sibling rail full of `agenticdeveloperhub…` had once asked for that
 * — 144px of slack on a two-word column, on every rail, forever, because the pool was also
 * sticky and an unmounted rail still counted. Auto-sizing that never sizes anything down is
 * not auto-sizing (Mike).
 *
 * The movement it was buying against is smaller than it looks. Rails lay out left to right, so
 * a rail changing width moves only the rails to its RIGHT — which are exactly the lists that
 * just changed because of the selection that resized it. Everything left of the selection, the
 * part already read, holds still.
 *
 * A `width` on the level still wins, for rails whose width is a deliberate choice rather than a
 * consequence of their rows.
 */
function useRailFit() {
  const [fit, setFit] = useState<Record<string, number>>({})
  // Same-value writes are dropped rather than re-rendering: the measurement re-runs whenever
  // a list's rows change, and most of those changes do not move the width. Dropping them also
  // keeps `fit`'s identity stable, so it is safe as an effect dependency.
  const onFit = useCallback(
    (id: string, px: number) => setFit((f) => (f[id] === px ? f : { ...f, [id]: px })),
    [],
  )
  return { fit, onFit }
}
//
// 32, not the 40 this shipped with: the peek must show each row's ICON and nothing after it. A row
// is [10px padding][16px icon][gap][label…], so a 40px window reached ~6px INTO the label and every
// covered list showed a column of sliced first letters at its right edge (Mike). At 32 the covering
// list sits those few points further left and the slice is covered; the icon (ending at ~26px)
// keeps a little air after it.
const COVERED_PEEK = 32

// Suffix on a `pins` key that names a list's pin WHILE IT IS THE CHOOSING FRONTIER — kept apart
// from the list's ordinary pin so neither leaks into the other state (see CoveredStack's `pinKey`).
// A NUL can never appear in a level id a host writes, so the two keys cannot collide.
const FRONTIER_PIN = "\u0000frontier"

/** The width at or below which a container is phone-shaped and the stack is ALWAYS narrow, however
 *  little the host claims its detail pane needs. Above the widest phone in portrait (~430) and well
 *  below any window someone reads two panes in. Deliberately a raw CSS px count and not scaled by
 *  the root font: it is a statement about the DEVICE, and a device does not get narrower because a
 *  theme chose a smaller type size. */
const PHONE_FLOOR = 480

// The z-floor of a hover-revealed branch: its members lift to REVEAL_Z + i so the whole cascade
// floats over the detail. The connector overlay rides just above the highest member (see below), so
// the gold selection chain still crosses the branch it links.
const REVEAL_Z = 50

// The card edges of the covered stack — the boundary a clipped peek's own `border-r` cannot draw.
// (Colour via a CSS var so the no-raw-hex colour checker stays clean.)
const SHADOW_RIGHT = "8px 0 24px -6px var(--color-shadow)"
const SHADOW_LEFT = "-10px 0 22px -8px var(--color-shadow)"

/** The default `minDetailWidth` — the floor the shrink sequence (cover, then slide off-screen)
 *  drives toward on a DESKTOP. 36rem (576px): fairly small for a desktop pane, but clearly wider than a phone
 *  (~390-430px) — a desktop detail squeezed to phone width reads as broken, not compact. Phones
 *  never consult it: a phone is always NARROW, where the detail is the device's full width. */
const MIN_DETAIL_DEFAULT = "36rem"

/** Parse `minDetailWidth` (a CSS length) to px for the fit math. Handles the units that make sense
 *  for a fixed minimum — `rem`/`em` (× the document's root size, see `rootFontPx`) and `px`.
 *  Viewport/percent units (`vw`/`%`/`vh`/`ch`) can't be resolved to a fixed px here, so they fall
 *  back to the default rather than being silently mis-read as raw px. */
function minDetailPx(minDetailWidth: string): number {
  const rem = rootFontPx()
  const fallback = 36 * rem // MIN_DETAIL_DEFAULT, in this document's units
  const s = minDetailWidth.trim()
  const n = parseFloat(s)
  if (Number.isNaN(n)) return fallback // unparseable → the default
  if (s.endsWith("rem") || s.endsWith("em")) return n * rem
  if (s.endsWith("px") || /^\d*\.?\d+$/.test(s)) return n // explicit px or a bare number
  return fallback // a relative/viewport unit we can't resolve to fixed px → the default
}

/** The measured width of `ref`'s element, tracked by a ResizeObserver. `useLayoutEffect` (not
 *  `useEffect`) takes the FIRST measurement before the browser paints, so a layout gated on the width
 *  — the wide/narrow mode, the covered stack's fit math — never flashes a wrong first frame.
 *
 *  Note what this width does NOT feed: the detail pane's WIDTH. Every animated value in the stacks is
 *  discrete (a rail is full or a peek; a list is on-screen or slid off) — the only thing that has to
 *  follow the container continuously is the detail's right edge, and that is pinned in CSS
 *  (`right: 0`), not computed here. Deriving it from this measurement instead put a JS value one
 *  commit behind the container into a 300ms transition, so during a drag the pane chased a target
 *  that kept moving and its width visibly wandered. */
function useContainerWidth(ref: RefObject<HTMLDivElement | null>): number {
  const [width, setWidth] = useState(0)
  useLayoutEffect(() => {
    const el = ref.current
    if (!el) return
    const measure = () => setWidth((prev) => (prev === el.clientWidth ? prev : el.clientWidth))
    measure()
    const ro = new ResizeObserver(measure)
    ro.observe(el)
    return () => ro.disconnect()
  }, [ref])
  return width
}

/** A phone browser — iOS or Android. Phones take the NARROW layout at any width: the wide layout's
 *  peeks and cover toggles are pointer affordances, and a phone has no pointer. Tablets and desktops
 *  are NOT phones (iPadOS reports a desktop UA anyway) — they go by width, so a narrow window on a
 *  big screen behaves like a phone and a wide one doesn't.
 *
 *  Read AFTER mount (not during render): the server has no user agent, so branching the first render
 *  on it would be a hydration mismatch. Width alone already picks NARROW on a phone-sized viewport,
 *  so the post-mount flip is only for the odd phone with a wide layout viewport. */
function usePhoneUserAgent(): boolean {
  const [phone, setPhone] = useState(false)
  useEffect(() => {
    setPhone(phoneUserAgent())
  }, [])
  return phone
}

/** Whether this browser is a phone, by its user agent. Client-only — false on the server. */
function phoneUserAgent(): boolean {
  if (typeof navigator === "undefined") return false
  const ua = navigator.userAgent
  return /iPhone|iPod/.test(ua) || (/Android/.test(ua) && /Mobile/.test(ua))
}

/** The selection wiring shared by both stacks. Any select that would clear or replace
 *  the open deeper detail is exit-guarded: re-clicking the selected row (deselects this
 *  level), AND selecting a DIFFERENT row in a level that already has a selection —
 *  whether an ancestor (clears everything below) or the deepest selected level itself
 *  (a sibling swap that replaces the open leaf editor). Only a forward drill-down into a
 *  not-yet-selected level (`selectedId == null`) is unguarded: there is no open detail to
 *  lose. Because selections are contiguous from the top, `selectedId != null` is exactly
 *  "this level is at or above the deepest selection".
 *
 *  RE-CLICKING A SELECTED ROW POPS ONE LEVEL, NOT ALL OF THEM (Mike). Clicking `adh` while
 *  `adh > backend` is open used to clear `adh` itself and collapse the whole path in one go,
 *  which is the opposite of what the click looks like: the row you clicked is the one you
 *  meant to keep. So it deselects the CHILD first, and only a second click on the (now leaf)
 *  row deselects the row itself — the same walk back up the path the Back button makes, driven
 *  from the row under the pointer. */
function railOnSelect(
  level: TopicLevel,
  attemptExit: (action: () => void) => void,
  child?: TopicLevel,
) {
  return (id: string) =>
    id === level.selectedId
      ? attemptExit(() => (child?.selectedId != null ? child.onClear() : level.onClear()))
      : level.selectedId != null
        ? attemptExit(() => level.onSelect(id))
        : level.onSelect(id)
}

interface StackProps {
  rendered: TopicLevel[]
  deepestSelected: number
  firstUnselected: number
  frontier: number
  minDetailWidth: string
  /** The frame's `detailWidth`: when set, the wide detail pane is exactly this wide (and
   *  `minDetailWidth` already equals it). */
  detailWidth?: string
  /** The strip's title: a pane's own (see detail-title.tsx), else the frame's `detailTitle`. */
  detailTitle: DetailStripTitle
  attemptExit: (action: () => void) => void
  /** Hide every list but the leaf-most, even when there is room (see HierarchicalTopicDetail). */
  /** Per-level user intent from the `«`/`»` toggles: true = pinned hidden, false = pinned disclosed. */
  pins: Record<string, boolean>
  setPins: (next: Record<string, boolean> | ((prev: Record<string, boolean>) => Record<string, boolean>)) => void
  /** The covered list whose BRANCH the pointer is holding open (the reveal's root), or null. Owned by
   *  the frame's surface store, not by the stack, so a selection — which remounts this subtree — can't
   *  yank the branch shut from under a pointer that is still inside it. */
  hoverId: string | null
  setHoverId: (id: string | null) => void
  /** NARROW mode's animation origin — the pane index last painted (see `SurfaceState.narrowTop`), and
   *  the setter that records the pane the stack has now settled on. */
  narrowTop: number | null
  setNarrowTop: (i: number) => void
  /** The row's measured width (the frame's single ResizeObserver); 0 until the first measurement. */
  containerW: number
  /** Ref callback for the stack's detail slot: the innermost detail wrapper each stack renders
   *  EMPTY. The frame moves its one persistent detail host (a `display: contents` portal target)
   *  into whichever slot is mounted, so the detail's React subtree survives stack flips. */
  detailSlot: (el: HTMLDivElement | null) => void
  /** What the detail slot renders as ORDINARY children, which is nothing at all unless the frame
   *  was asked to server-render its detail (`ssrDetail`) and the portal host does not exist yet.
   *  See the seed comment beside `detail` in the frame. */
  detailSeed: ReactNode
}

/* PARKED — the AUTO-HIDE mode and its root-list toggle button were removed here (Mike: "remove the
 * auto-collapse mode and the button for it for now"). It was a standing INTENT that every list above
 * the frontier stay covered even when there was room, seeded from an `autoHideTopics` prop, flipped
 * by an `AutoHideToggle` (PanelLeftClose/PanelLeftOpen) in the root list's `leftControl`, and stored
 * per surface so it survived the route change a selection causes. Bringing it back = restore that
 * one intent term in each stack's `pinned` predicate, plus the button.
 *
 * What did NOT go with it: the per-list `«`/`»` pins, and the WIDTH PRESSURE that covers lists and
 * slides them off-screen as the window narrows. Those are the shrink sequence, not this mode — a
 * list is now covered because there is no room for it, never because a mode says so. */

/** How long transitions stay OFF after a structural change (see below). Longer than any settle
 *  cascade (level registrations, measured rail widths landing over a few commits), and by the time
 *  it expires the geometry is at rest, so re-enabling transitions cannot animate anything. */
const IN_PLACE_SETTLE_MS = 350

/**
 * True from a STRUCTURAL change — a level appearing/disappearing or any level's selection changing —
 * until {@link IN_PLACE_SETTLE_MS} after the LAST such change. Both stacks use it to drop their
 * `left`/`width`/`grid` transitions across that window, so choosing a topic lands the new geometry
 * IN PLACE (instantly) instead of sliding the detail pane in from the left edge as the lists
 * re-cover behind it. Width-driven changes (a window resize, a cover toggle, the hover reveal)
 * still animate: they don't touch this signature.
 *
 * A TIME window, not the one changed render this used to be. The single-render version bumped in a
 * layout effect, which flushes BEFORE the browser paints — so the transition classes were back on
 * the elements by first paint, and the browser animated the new geometry against the previously
 * painted frame anyway: precisely the slide-in this hook exists to prevent (Mike, live on the hub).
 * The window also covers the trailing commits a selection causes (levels registering, measured
 * widths landing), which share the painted-frame problem without touching the signature themselves.
 */
function useInPlaceOnStructureChange(signature: string): boolean {
  const prev = useRef(signature)
  // Seeded to a HELD window, not 0: selecting a row in the app is a route change, which REMOUNTS
  // this stack (see NarrowStack's `narrowTop` note). On that fresh mount `prev` initialises to the
  // already-selected signature, so the comparison below can never fire — transitions were live at
  // first paint and the measured rail widths landing over the next few commits animated `left`,
  // sliding the detail in from the edge. A mount is exactly the case this hook exists to cover, so
  // it starts held; by the time the window expires the geometry is at rest and re-enabling
  // transitions cannot animate anything.
  const holdUntil = useRef(Date.now() + IN_PLACE_SETTLE_MS)
  const [, bump] = useState(0)
  // Render-time detection, deliberately: the commit that APPLIES the new geometry must go to the
  // browser without the transition classes — an effect is already too late (see above). The ref
  // writes are idempotent, so a re-render or StrictMode double-render is harmless.
  if (prev.current !== signature) {
    prev.current = signature
    holdUntil.current = Date.now() + IN_PLACE_SETTLE_MS
  }
  const inPlace = Date.now() < holdUntil.current
  // Re-render once the hold expires, so the transition classes return for the NEXT width-driven
  // change. The geometry is settled by then, so nothing moves on the re-render itself.
  useEffect(() => {
    if (!inPlace) return
    const t = setTimeout(() => bump((n) => n + 1), holdUntil.current - Date.now() + 30)
    return () => clearTimeout(t)
  }, [inPlace, signature])
  return inPlace
}

/** The signature {@link useInPlaceOnStructureChange} watches: the level count + every selection. */
function structureSignature(rendered: TopicLevel[]): string {
  return `${rendered.length}::${rendered.map((l) => l.selectedId ?? "").join("|")}`
}

/**
 * Selection connectors, shared by BOTH stacks: a gold elbow from each selected PARENT row to its
 * selected CHILD row. Every coordinate is measured from the DOM in one snapshot (parent exit = the
 * end of its trailing accessory, else its label, else its ICON when collapsed, per `rowExitEl`;
 * child entry = just before its icon; the bend = the child column's left edge), so collapsed/peeking columns work and the parts never
 * disagree. Columns are matched by `data-htd-col`; the selected row by `aria-current`. The lists slide
 * over ~0.3s, so re-measure on a short rAF loop; a scroll re-measures once via the returned `onScroll`
 * (no re-render). `sig` is the caller's layout+selection signature; when connectors are impossible
 * (fewer than two columns, or nothing selected) the loop is skipped entirely.
 */
function useSelectionConnectors(
  containerRef: RefObject<HTMLDivElement | null>,
  levelCount: number,
  sig: string,
  possible: boolean,
): { connectors: string[]; onScroll: () => void } {
  const [connectors, setConnectors] = useState<string[]>([])
  const measureRef = useRef<() => void>(() => {})
  useLayoutEffect(() => {
    const cont = containerRef.current
    if (!cont) return
    let raf = 0
    const measure = () => {
      const crect = cont.getBoundingClientRect()
      const anchor = (i: number) => {
        const sel = cont.querySelector(`[data-htd-col="${i}"] [aria-current="true"]`)
        if (!sel) return null
        const r = sel.getBoundingClientRect()
        const iconEl = sel.querySelector("[data-htd-icon]")
        const end = rowExitEl(sel)
        // A deletable row's trash button is a sibling of the row button; the connector breaks around
        // it — but ONLY while the trash is actually REVEALED (the row is hovered, or the trash has
        // keyboard focus), not merely because the slot is reserved. The stack re-measures on pointer /
        // focus activity (see the container handlers), so the gap opens and closes with the button.
        const delEl = sel.parentElement?.querySelector("[data-htd-delete]") ?? null
        const delShown =
          !!delEl && ((sel.parentElement?.matches(":hover") ?? false) || delEl.matches(":focus-visible"))
        const delRect = delShown && delEl ? delEl.getBoundingClientRect() : null
        return {
          y: r.top + r.height / 2 - crect.top,
          rightX: (end ? end.getBoundingClientRect().right : r.right) - crect.left,
          iconLeft: (iconEl ? iconEl.getBoundingClientRect().left : r.left) - crect.left,
          left: r.left - crect.left,
          delLeft: delRect ? delRect.left - crect.left : null,
          delRight: delRect ? delRect.right - crect.left : null,
        }
      }
      const next: string[] = []
      for (let i = 0; i < levelCount - 1; i++) {
        const p = anchor(i)
        const c = anchor(i + 1)
        // A connector joins a selected PARENT row to a selected CHILD row — nothing else. A child
        // rail that is open with NOTHING selected gets NO line into it (spec:
        // connect-selected-rows-only — an unselected list's landing is the topic overview,
        // and a line pointing at whatever row happens to sit at the parent's height reads as a
        // phantom selection).
        if (!p || !c) continue
        if (p.rightX < 0 || c.left > crect.width) continue // an endpoint drilled off-screen
        const boundary = c.left // the child column's current left edge (the bend)
        const startX = Math.min(p.rightX + 6, boundary - 4) // just past the parent's visible content
        // The elbow after the parent's horizontal run: to the child column's edge (the bend), down/up
        // to the child row, then in to just before its icon.
        const elbow = `L ${boundary} ${p.y} L ${boundary} ${c.y} L ${Math.max(c.iconLeft - 6, boundary + 2)} ${c.y}`
        // Break the horizontal run around a deletable parent row's trash button, so the line never
        // crosses it (the overlay paints above the rail, so this gap — not occlusion — is the break).
        if (p.delLeft != null && p.delRight != null && p.delRight > startX && p.delLeft < boundary) {
          const gapL = Math.max(p.delLeft - 4, startX)
          const gapR = Math.min(p.delRight + 4, boundary)
          if (gapL > startX + 0.5) next.push(`M ${startX} ${p.y} L ${gapL} ${p.y}`)
          next.push(`M ${gapR} ${p.y} ${elbow}`)
        } else {
          next.push(`M ${startX} ${p.y} ${elbow}`)
        }
      }
      setConnectors((prev) =>
        prev.length === next.length && prev.every((d, k) => d === next[k]) ? prev : next,
      )
    }
    measureRef.current = measure // a scroll re-measures once via this ref (no re-render)
    if (!possible) {
      setConnectors((prev) => (prev.length === 0 ? prev : []))
      return
    }
    const start = performance.now()
    const loop = () => {
      measure()
      if (performance.now() - start < 400) raf = requestAnimationFrame(loop)
    }
    loop()
    return () => cancelAnimationFrame(raf)
  }, [containerRef, levelCount, sig, possible])
  return { connectors, onScroll: () => measureRef.current() }
}

/**
 * The SVG overlay that draws the measured connector paths above the columns (pointer-transparent).
 * `zIndex` must beat EVERY column it crosses: the default clears the ordinary stack, but a covered
 * stack whose hover-revealed branch is z-lifted over the detail has to lift the overlay with it —
 * otherwise the branch paints over its own connectors and the selection chain vanishes on hover.
 */
function SelectionConnectorOverlay({ paths, zIndex = 30 }: { paths: string[]; zIndex?: number }) {
  if (paths.length === 0) return null
  return (
    <svg
      aria-hidden
      data-htd-connectors
      style={{ zIndex }}
      className="pointer-events-none absolute inset-0 h-full w-full overflow-visible"
    >
      {paths.map((d, i) => (
        <path
          key={i}
          d={d}
          fill="none"
          className="stroke-apt-gold"
          strokeWidth={1.5}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      ))}
    </svg>
  )
}

// NOTE — nothing in this component is gated on `prefers-reduced-motion`, per a standing instruction
// from this block's owner to ignore that setting until further notice. It is NOT a claim about
// anyone's OS configuration; keep it that way unless he lifts the instruction. This block used to
// gate three of its transitions on `motion-reduce` while its twin (HierarchicalMenuDetail) gated
// none — which mattered the moment one flag started choosing between them, because a view switch
// would have silently doubled as a reduced-motion switch.

/**
 * The "minimized" disclosure style (unchanged from the original single-layout block): the lists are
 * flat grid columns; as the window narrows the leftmost shrink to icon strips (auto), then slide
 * off-screen (hidden), and a top-left Back walks back up.
 */
function MinimizedStack({
  rendered,
  deepestSelected,
  firstUnselected,
  frontier,
  minDetailWidth,
  detailWidth,
  detailTitle,
  attemptExit,
  pins,
  setPins,
  levels,
  manualCollapse,
  detailSlot,
  detailSeed,
}: Omit<StackProps, "containerW"> & { levels: TopicLevel[]; manualCollapse: boolean }) {
  // `pins` (from the frame) is this stack's manual collapse-to-icon-strip intent; width pressure
  // adds collapses on top of it — the same two layers the covered stack uses, drawn as an icon strip
  // instead of a peek. `widths` is a dragged column width (≤ FULL).
  const [widths, setWidths] = useState<Record<string, number>>({})
  const [dragging, setDragging] = useState(false)
  const { fit, onFit } = useRailFit()
  const override = pins
  const setOverride = setPins

  // ONE ResizeObserver over the WHOLE row (not one per nested rail) is the single disclosure /
  // drill-down controller. The leaf minimum is parsed from `minDetailWidth`.
  const minPx = minDetailPx(minDetailWidth)
  const containerRef = useRef<HTMLDivElement>(null)
  // Window auto-disclosure, in TWO PHASES as the window shrinks (recomputed in the single
  // ResizeObserver from container width, before paint):
  //   auto   — ids UNDISCLOSED to their icon strip (general→specific). This is the FIRST response:
  //            collapse the leftmost lists to icons until everything fits, or every list is an icon.
  //   hidden — how many leftmost lists are then slid OFF-SCREEN. The LAST resort, reached only once
  //            every list is already an icon strip and they + the detail minimum STILL don't fit.
  const [auto, setAuto] = useState<Set<string>>(new Set())
  const [hidden, setHidden] = useState(0)

  // A width the user DRAGGED wins over a width the caller CHOSE, which wins over the width the
  // rows measured to; FULL_RAIL is only what is left when a rail has told us nothing at all
  // (the frame before the first measurement, and a rail with no rows to measure).
  const naturalWidth = (level: TopicLevel) =>
    widths[level.id] ?? level.width ?? fit[level.id] ?? FULL_RAIL
  // Intent: the user's pin (`«`) if they set one, else disclosed. Width pressure (`auto`) only ever
  // ADDS a collapse on top of this.
  const pinned = (level: TopicLevel) => override[level.id] ?? false
  // A list shows as its icon strip when intent says so OR the window auto-undisclosed it (`auto`).
  // Off-screen drilling (`hidden`) is separate and applied last.
  const isCollapsed = (level: TopicLevel) => pinned(level) || auto.has(level.id)
  // The visible width a list occupies in the fit math: 0 if slid off-screen, its icon strip if
  // collapsed, else its full/dragged width.
  const visibleWidth = (level: TopicLevel, i: number) =>
    i < hidden ? 0 : isCollapsed(level) ? COLLAPSED_RAIL : naturalWidth(level)

  // Recompute the window auto-disclosure for the current container width — the spec's TWO-PHASE
  // response, planned from scratch each time (so growing the window re-discloses then re-shows, in
  // reverse). Computed in the observer (pre-paint) so a narrow first render starts correct (no flash).
  const recompute = useCallback(() => {
    const el = containerRef.current
    if (!el) return
    const width = el.clientWidth
    if (width <= 0) return
    const cols = rendered
    // Keep the FRONTIER list visible while it has no selection (its "detail" is only a landing
    // placeholder, so the user needs the list to pick from). Once every level is selected the detail
    // is real content, so every list may slide off (a phone shows the detail full-width).
    const maxHide = firstUnselected === -1 ? cols.length : frontier

    const collapsed = new Set<string>() // window-undisclosed (icon strip) ids
    let h = 0 // off-screen count
    const shown = (l: TopicLevel) => collapsed.has(l.id) || pinned(l)
    const widthOf = (l: TopicLevel, i: number) =>
      i < h ? 0 : shown(l) ? COLLAPSED_RAIL : naturalWidth(l)
    const total = () => cols.reduce((s, l, i) => s + widthOf(l, i), 0) + minPx

    // PHASE 1 — UNDISCLOSE: collapse the leftmost still-full list to its icon strip (general→specific)
    // until everything fits, or every list is already an icon strip.
    while (total() > width) {
      const target = cols.find((l) => !shown(l))
      if (!target) break
      collapsed.add(target.id)
    }
    // PHASE 2 — OFF-SCREEN: only now — every list an icon strip and they + the detail minimum STILL
    // don't fit — slide the leftmost icon strips off the left edge, until the detail fits (≤ maxHide).
    while (total() > width && h < maxHide) h++

    setAuto((prev) =>
      prev.size === collapsed.size && [...collapsed].every((id) => prev.has(id)) ? prev : collapsed,
    )
    setHidden((prev) => (prev === h ? prev : h))
  }, [rendered, frontier, firstUnselected, override, widths, fit, minPx])

  // Re-run on container resize (the window) and whenever the rendered lists / manual collapse change.
  useEffect(() => {
    const el = containerRef.current
    if (!el) return
    recompute()
    const ro = new ResizeObserver(() => recompute())
    ro.observe(el)
    return () => ro.disconnect()
  }, [recompute])

  // The `«`/`»` toggle pins this list to the state it is moving TO. Holding the platform's
  // multi-select modifier (⌘ on macOS, Ctrl elsewhere) applies that state to EVERY list at once. The
  // fit rules still run on top, so an "expand all" only discloses the lists that actually fit.
  const setCollapse = (i: number, e: ReactMouseEvent) => {
    const level = rendered[i]!
    const target = !isCollapsed(level)
    hlog(rendered[0]?.id ?? "htdv", "collapse-toggle", {
      list: level.id,
      to: target ? "collapsed" : "open",
      all: e.metaKey || e.ctrlKey,
    })
    if (e.metaKey || e.ctrlKey) {
      setOverride(Object.fromEntries(rendered.map((l) => [l.id, target])))
      return
    }
    setOverride((o) => ({ ...o, [level.id]: target }))
  }

  // Drag of a column's trailing border: narrower than a third snaps to the icon strip (override),
  // else sets its width and clears any collapse override.
  const onResizeLevel = (level: TopicLevel, w: number) => {
    if (w < FULL_RAIL / 3) {
      if (manualCollapse && override[level.id] !== true) setOverride((o) => ({ ...o, [level.id]: true }))
      return
    }
    setWidths((wd) => ({ ...wd, [level.id]: Math.min(w, FULL_RAIL) }))
    if (override[level.id]) setOverride((o) => ({ ...o, [level.id]: false }))
  }

  // Drill-down Back: shown iff at least one rail is hidden AND something is selected. It clears the
  // deepest selected level (re-disclosing one parent); repeated Back walks up to root.
  const showBack = hidden > 0 && deepestSelected >= 0
  const onBack = () => attemptExit(() => levels[deepestSelected]?.onClear())
  // The Back button lives on the LEFTMOST-VISIBLE pane: the first rail that isn't hidden, or the
  // detail when every rail is hidden (phone width). `backOnRail` = that rail's index, else -1 → detail.
  const backOnRail = showBack && hidden < rendered.length ? hidden : -1
  const backButton = (
    <button
      type="button"
      onClick={onBack}
      aria-label="Back"
      className="flex items-center gap-1 rounded px-1.5 py-1 font-mono text-xs tracking-[0.02em] text-apt-text-muted outline-none hover:text-apt-text focus-visible:ring-2 focus-visible:ring-apt-gold/40"
    >
      <ChevronLeft size={14} aria-hidden className="shrink-0" />
      <span>Back</span>
    </button>
  )

  // The flat grid template: one column per rendered rail (0 if slid off-screen, icon strip if
  // manually collapsed, else its width), then the detail column. Held in a CSS var so changes
  // animate via the single grid transition (reduce-motion honoured by the global accessibility CSS).
  // The detail takes what the lists leave — or, given a fixed `detailWidth`, that and no more.
  const detailCol = detailWidth ? `minmax(0,${detailWidth})` : "minmax(0,1fr)"
  const cols = [...rendered.map((l, i) => `${visibleWidth(l, i)}px`), detailCol].join(" ")

  // LAYOUT LOG — the fit pass's discrete outcome (icon strips + off-screen count), on change only
  // (htdv-log.ts).
  const fitSig = `${rendered.map((l) => (isCollapsed(l) ? "c" : "o")).join("")}|${hidden}`
  const loggedFitSig = useRef<string | null>(null)
  useEffect(() => {
    if (loggedFitSig.current === fitSig) return
    loggedFitSig.current = fitSig
    hlog(rendered[0]?.id ?? "htdv", "fit", {
      style: "minimized",
      w: containerRef.current?.clientWidth ?? 0,
      minPx,
      lists: rendered.length,
      collapsed: rendered.filter((l) => isCollapsed(l)).map((l) => l.id),
      hidden,
    })
  })

  // Choosing a topic must land the detail IN PLACE, never slide it in as the columns re-flow behind
  // it; every other change — a manual toggle, and the width pressure that collapses a list to its
  // icon strip or slides it off-screen as the window narrows — animates the grid.
  const inPlace = useInPlaceOnStructureChange(structureSignature(rendered))
  const animate = !dragging && !inPlace

  // Selection connectors (shared with the covered stack). The signature is the per-level selection
  // plus the grid template (column widths) and off-screen count — everything that moves a row.
  const connectorSig = `${rendered.map((l) => l.selectedId ?? "").join("|")}::${cols}::${hidden}`
  const connectorsPossible = rendered.length >= 2 && rendered.some((l) => l.selectedId != null)
  const { connectors, onScroll } = useSelectionConnectors(
    containerRef,
    rendered.length,
    connectorSig,
    connectorsPossible,
  )

  return (
    <div
      ref={containerRef}
      // `onScroll` is the connector re-measure trigger; fire it on pointer / focus movement too so
      // the gap around a row's trash button tracks the button's hover / keyboard-focus reveal.
      onScrollCapture={onScroll}
      onPointerOver={onScroll}
      onPointerOut={onScroll}
      onFocus={onScroll}
      onBlur={onScroll}
      style={{ "--cols": cols } as CSSProperties}
      className={cn(
        // Drill-down applies at EVERY width (it IS the small-screen layout): the lists are grid
        // columns and the leftmost slide off-screen when the detail can't fit — so a phone shows
        // the deepest pane full-width from first paint, with Back to walk up. No `md:` gate.
        // `relative` anchors the absolute selection-connector overlay.
        "relative grid min-h-0 min-w-0 flex-1 grid-rows-[minmax(0,1fr)] [grid-template-columns:var(--cols)]",
        animate && "transition-[grid-template-columns] duration-[calc(200ms*var(--apt-anim-scale,1))] ease-out",
      )}
    >
      {rendered.map((level, i) => {
        const offscreen = i < hidden
        return (
          // A hidden rail is slid off-screen (0-width column): inert + aria-hidden + no pointer
          // events so it is fully out of the tab order / AT tree while it animates away.
          <div
            key={level.id}
            data-htd-col={i}
            className={cn(
              "grid min-h-0 min-w-0 [grid-template-columns:minmax(0,1fr)]",
              offscreen && "pointer-events-none overflow-hidden",
            )}
            aria-hidden={offscreen || undefined}
            // React 19 types `inert` as a boolean prop; `undefined` (not false) omits the attribute.
            inert={offscreen || undefined}
          >
            <TopicRail
              title={level.title}
              busy={level.busy}
              onPrefetch={level.onPrefetch}
              railLabel={level.railLabel}
              isRoot={i === 0}
              // Selection is shown by the dash (root) + the connector overlay, matching the covered
              // stack — not the gold bar (which standalone TopicDetail keeps).
              selectionStyle="marker"
              items={level.items}
              selectedId={level.selectedId}
              onSelect={railOnSelect(level, attemptExit, rendered[i + 1])}
              emptyLabel={level.emptyLabel ?? "Nothing here yet."}
              onNew={level.onNew}
              newLabel={level.newLabel}
              newActive={level.newActive}
              titleActions={level.titleActions}
              railSlot={level.railSlot}
              headerSlot={level.headerSlot}
              search={level.search}
              reserveToolbar={rendered.some(hasListTools)}
              hideItemIcons={level.hideItemIcons}
              checkable={level.checkable}
              checkedIds={level.checkedIds}
              onToggleChecked={level.onToggleChecked}
              collapsed={isCollapsed(level)}
              onToggle={manualCollapse ? (e) => setCollapse(i, e) : () => {}}
              onResize={(w) => onResizeLevel(level, w)}
              onResizeStart={() => setDragging(true)}
              onResizeEnd={() => setDragging(false)}
              onFit={(w) => onFit(level.id, w)}
              // Nothing rides the root rail's leading slot any more (the auto-hide toggle was the
              // only tenant); Back lands on the leftmost VISIBLE rail via `backSlot` below.
              leftControl={undefined}
              // The drill-down Back lands top-left of the leftmost-visible rail.
              backSlot={i === backOnRail ? backButton : undefined}
            />
          </div>
        )
      })}
      {/* Selection connectors: gold elbows linking each selected parent row to its selected child. */}
      <SelectionConnectorOverlay paths={connectors} />
      {/* The detail (leaf) column — ALWAYS the rightmost sibling with a stable key, so it mounts
          once and never remounts as the rail count changes. When every rail is hidden (phone
          width) the Back button rides the top of this pane. The inner div holds a minimum width so
          the pane scrolls horizontally rather than crushing when its column is narrower. */}
      <section
        key="__detail__"
        // A fixed-width pane ends short of the container: the border is its edge.
        className={cn("flex min-w-0 flex-col overflow-auto bg-apt-surface", detailWidth && "border-r border-apt-border")}
      >
        {(detailTitle.titled || (backOnRail === -1 && showBack)) && (
          <div className="flex min-h-[2.15rem] shrink-0 items-center gap-2 border-b border-apt-border bg-apt-nav px-2">
            {backOnRail === -1 && showBack && backButton}
            {detailTitle.cell}
          </div>
        )}
        {/* Hold the leaf to its min width so it scrolls rather than crushing — but never wider than
            the viewport, so on a phone (where every list has drilled off) the form reflows to the
            full width instead of forcing a horizontal scroll. Rendered EMPTY — the frame slots its
            persistent detail host in here (see StackProps.detailSlot) — except for the window
            before that host exists, when `detailSeed` may hold the server-rendered detail. */}
        <div
          ref={detailSlot}
          className="flex min-h-0 w-full flex-1 flex-col"
          style={{ minWidth: `min(${minDetailWidth}, 100%)` }}
        >
          {detailSeed}
        </div>
      </section>
    </div>
  )
}

/**
 * The "covered" disclosure style. The lists stay FULL width and are laid out left→right; the detail
 * fills the remaining width down to `minDetailWidth`. As the window narrows, the leftmost lists are
 * COVERED — each slides LEFT *under* its child (the next list, or the detail), which sits in front
 * (higher z-index) casting a left drop-shadow so the stack reads as physically layered. The cover
 * toggle lives on each CHILD's top-left: `«` covers the child's parent, `»` uncovers it. No Back
 * button; the breadcrumb is the navigation.
 */
function CoveredStack({
  rendered,
  firstUnselected,
  frontier,
  minDetailWidth,
  detailWidth,
  detailTitle,
  attemptExit,
  pins,
  setPins,
  hoverId,
  setHoverId,
  containerW,
  detailSlot,
  detailSeed,
}: StackProps) {
  const minPx = minDetailPx(minDetailWidth)
  // Per-level rail width: a DRAGGED width (the trailing-border handle) wins, else the level's own
  // `width`, else FULL_RAIL. The covered style has no icon strip, so a rail resizes FREELY within a
  // readable range (widening a rail to read long rows is the point) — unlike the minimized style,
  // which snaps a narrow drag to an icon strip and caps at FULL_RAIL.
  const MIN_DRAG_RAIL = 160
  const MAX_DRAG_RAIL = 640
  const [widths, setWidths] = useState<Record<string, number>>({})
  // True mid-drag, so the left/width transitions are suppressed (the rail tracks the pointer 1:1
  // instead of easing) and restored on release.
  const [dragging, setDragging] = useState(false)
  const { fit, onFit } = useRailFit()
  const railWidth = (l: TopicLevel) => widths[l.id] ?? l.width ?? fit[l.id] ?? FULL_RAIL
  const onResizeLevel = (level: TopicLevel, w: number) =>
    setWidths((wd) => ({ ...wd, [level.id]: Math.max(MIN_DRAG_RAIL, Math.min(w, MAX_DRAG_RAIL)) }))
  const containerRef = useRef<HTMLDivElement>(null)
  // Whole-BRANCH hover reveal: hovering a covered (peeking) list opens it AND every list below it —
  // the hovered list and its children, side by side, floating over the detail. `hoverId` names the
  // list the pointer opened (the reveal's ROOT); the group is that list and everything to its right.
  //
  // Revealing the hovered list ALONE (what this used to do) showed a list whose children were still
  // covered behind it — you could see the rows you were choosing between, but not what choosing one
  // would show you. The branch is the unit the user is actually looking at, so the branch is what
  // opens. It is pointer-only on purpose: a FOCUS reveal would keep the group open after a click (the
  // clicked button holds focus), jamming the auto-cover as the window shrinks.
  //
  // `hoverId` is the FRAME's (see `surfaceStates`), not this component's: selecting a row inside the
  // branch is a route change, which remounts this subtree — local state would be destroyed by the
  // click, collapsing the branch under a pointer that never left it and that no event will reopen it
  // with (the pointer hasn't moved, so nothing re-enters). Held above the mount, the branch survives
  // the selection and closes on the one thing that should close it: the pointer leaving.

  // The frontier list stays uncovered while it has no selection (its "detail" is only a landing, so
  // the user needs the list to pick from), and is never shifted off-screen for it
  // (not-hide-frontier-choosing-list).
  const coverableCount = firstUnselected === -1 ? rendered.length : frontier
  // THE DETAIL'S MINIMUM IS FIXED — the same in every state, so the covering is a pure function of
  // the width. It used to be claimed only once every level was selected (0 while the frontier was
  // still being chosen from), and that made the layout jump on the CLICK rather than on the resize:
  // with nothing chosen no parent ever covered and the landing was crushed to a sliver (372px of a
  // 576px minimum in settings), then choosing a topic claimed the full minimum at once and snapped
  // every parent shut together (Mike: "the details pane for htdv should have a fixed min width
  // everywhere so the progressive auto collapse works smoothly, right now it looks terrible").
  // The frontier's exemption survives where it belongs — in `coverableCount` above, and in the
  // squeeze below, which never narrows the choosing list to make room for a landing hint.
  const detailMin = minPx

  // COVER LAYER 1 — intent. A list is covered here only because the user pinned it (`«`); absent a
  // pin it is disclosed and it is WIDTH PRESSURE below that decides whether it can stay that way.
  //
  // Covering the list the user JUST clicked in is not this layer's problem: the click roots the
  // branch reveal at that list (see the rail's onSelect below), so a freshly covered parent stays
  // open under the pointer — its new child floating over the detail — until the pointer leaves.
  //
  // A pin reaches EVERY list, the unselected frontier included. `coverableCount` exempts the
  // frontier from WIDTH PRESSURE (the machine must never cover the list being chosen from), not
  // from the user: gating the pin on it made the `«` on an empty detail a dead button — it flipped
  // the pin, logged the toggle, and nothing slid (Mike: "clicking the << button on an empty
  // details view should slide it over, it doesn't"). A covered frontier is still one hover away.
  //
  // The frontier's pin is its OWN key, not the list's: a pin set on a list while it held a
  // selection must not follow it back into the choosing state when that selection is cleared —
  // there it would hide the very list the user now has to choose from, which the old gate
  // guaranteed never happened (not-hide-frontier-choosing-list). Only a `«` clicked while the list
  // IS the choosing frontier covers it there, and completing the path hands it back to the
  // list's ordinary pin and width pressure, exactly as before.
  const pinKey = (i: number): string =>
    i >= coverableCount ? `${rendered[i]!.id}${FRONTIER_PIN}` : rendered[i]!.id
  const pinned = (i: number): boolean => pins[pinKey(i)] ?? false

  // COVER LAYER 2 — width pressure. Cover MORE lists, leftmost-first (general → specific), until the
  // detail keeps its minimum. This layer only ever ADDS a cover: it may take the room back from a
  // list the user pinned open (there is none to give), but never discloses one they pinned shut.
  const pressureFor = (isPinned: (i: number) => boolean): number => {
    let n = 0
    if (containerW <= 0) return n
    const listsWidth = (k: number) =>
      rendered.reduce((w, l, i) => w + (isPinned(i) || i < k ? COVERED_PEEK : railWidth(l)), 0)
    while (n < coverableCount && listsWidth(n) + detailMin > containerW) n++
    return n
  }
  const pressure = pressureFor(pinned)
  const isCovered = (i: number) => pinned(i) || i < pressure
  // `>>>` can only lift the USER's covers — width pressure takes back the room it would free — so it
  // is live only when some list covered now would be open with every pin cleared.
  const openPressure = pressureFor(() => false)
  const canExpandAll = rendered.some((_l, i) => isCovered(i) && i >= openPressure)
  const canCollapseAll = rendered.some((_l, i) => !isCovered(i))
  // The width a list wants before the last-resort squeeze below.
  const rawWidth = (i: number) => (isCovered(i) ? COVERED_PEEK : railWidth(rendered[i]!))

  // PHASE 2 — OFF-SCREEN. Every list is down to its peek and they STILL don't leave the detail its
  // minimum: slide the leftmost list off the left edge and shift the whole stack by exactly THAT
  // list's width, repeating until the detail fits (or only the frontier is left). Quantised to whole
  // lists on purpose — a continuous shift would park a list half off the edge, which reads as a
  // clipped rail rather than a drilled-down one.
  let hidden = 0
  let offshift = 0
  if (containerW > 0) {
    const widthFrom = (h: number) =>
      rendered.reduce((w, _l, i) => (i < h ? w : w + rawWidth(i)), 0) + detailMin
    while (hidden < coverableCount && widthFrom(hidden) > containerW) {
      offshift += rawWidth(hidden)
      hidden++
    }
  }

  // PHASE 3 — SQUEEZE THE LAST OPEN RAIL. Both phases above stop at `coverableCount`, which excludes
  // the FRONTIER list: while it has no selection the user is choosing from it, so it is never
  // covered and never slid off. When that one list is what does not fit, its own WIDTH is the only
  // thing left to give — and uncapped it simply ran past the container's right edge, where the
  // stack's `overflow-hidden` sliced it. A rail cut in half reads as a broken layout; a narrower
  // rail whose rows ellipsize reads as a tight one (Mike: "the automatic sizing of the HTDV is not
  // working"). Never below a peek: by that width the frame has already flipped to the narrow
  // one-pane layout (`wideFloor`), so there is nothing under it to fall through to.
  const lastOpen = rendered.reduce((k, _l, i) => (i < hidden || isCovered(i) ? k : i), -1)
  let squeeze = 0
  if (containerW > 0 && lastOpen >= 0) {
    // An unselected frontier is the list being chosen from; its pane is only a landing hint, which
    // gives up its width before the list does (the hint reflows; a squeezed list ellipsizes rows).
    const squeezeMin = firstUnselected === -1 ? detailMin : 0
    const laid = rendered.reduce((w, _l, i) => (i < hidden ? w : w + rawWidth(i)), 0) + squeezeMin
    squeeze = Math.max(0, Math.min(laid - containerW, rawWidth(lastOpen) - COVERED_PEEK))
  }
  const widthOf = (i: number) => rawWidth(i) - (i === lastOpen ? squeeze : 0)

  // Layout pass (running x): each list's natural left. A covered list advances x only by its PEEK (it
  // stays visible as a stacked-card edge under its child), so the next list / the detail slides left
  // to PARTIALLY cover it. `offshift` then slides the whole row left over the hidden lists.
  const left: number[] = []
  let x = 0
  rendered.forEach((_l, i) => {
    left.push(x)
    x += widthOf(i)
  })
  const restingDetailLeft = Math.max(0, x - offshift)

  // THE REVEAL GROUP — the root list and every list below it (its BRANCH), never its parents.
  // A pointer ENTER on a covered list roots it there; so does the covering CLICK (the root exists
  // so the clicked list doesn't snap shut under the pointer). Two earlier shapes were wrong: an
  // enter that opened EVERY on-screen list sprang the whole hierarchy open under a pointer asking
  // about one list (Mike: "the whole hierarchy of menus is disclosing I only want one at a time
  // disclosing"), and opening the hovered list alone hid what choosing in it would show (Mike:
  // "mouse into a collapsed topic list should disclose that topic list and any child topic list").
  // Walking onto a shallower peek re-roots the branch there; a parent never opens on its own.
  // Members lay out side by side at full width, floating over the detail. Nothing under the group
  // moves; the detail keeps its geometry and is simply overlapped, and dropping the group (pointer
  // out) animates every member straight back to the layout above. Off-screen (drilled-down) lists
  // stay out of the group — Back is their affordance.
  //
  // A reveal that reveals NOTHING is dropped: when no member is covered, the revealed geometry IS
  // the resting layout — but the z-lift and the floating card's shadows are not, and a stack at
  // rest must not cast them. A select roots a reveal blindly (at click time the fit pass for the new
  // selection has not run, so it cannot know whether the click covers the list it landed in — see
  // the rail's onSelect); this is where a blind root that ended up covering nothing becomes the
  // no-op it should be.
  const hoverRoot = hoverId === null ? -1 : rendered.findIndex((l) => l.id === hoverId)
  const hoverIndex =
    hoverRoot >= 0 && rendered.some((_, i) => i >= hoverRoot && isCovered(i)) ? hoverRoot : -1
  const effectiveHoverId = hoverIndex >= 0 ? hoverId : null
  const groupStart = hoverIndex
  const inGroup = (i: number) => hoverIndex >= 0 && i >= groupStart

  // The group is lifted above the detail (z-50+) so it floats OVER the UI. On CLOSE the lift must
  // LINGER for the wipe-shut transition (z-index can't animate) — else the lists would drop behind
  // the detail mid-close and the wipe would be invisible. `zLiftId` tracks the OPEN reveal but
  // trails it by the transition duration when clearing. It SEEDS from the open reveal so a remount
  // mid-hover re-lifts the branch on its first frame instead of flashing it behind the detail.
  const [zLiftId, setZLiftId] = useState<string | null>(effectiveHoverId)
  useEffect(() => {
    if (effectiveHoverId !== null) {
      setZLiftId(effectiveHoverId)
      return
    }
    const t = setTimeout(() => setZLiftId(null), 300)
    return () => clearTimeout(t)
  }, [effectiveHoverId])
  // The lifted group for z-index only — it TRAILS the open reveal on close (see `zLiftId`). The
  // lift region trails with it: capture the group start alongside the id so the wipe-shut lifts
  // exactly the members that were open, whichever mode rooted them.
  const zRoot = zLiftId === null ? -1 : rendered.findIndex((l) => l.id === zLiftId)
  const [zStart, setZStart] = useState<number>(groupStart)
  useEffect(() => {
    if (groupStart >= 0) setZStart(groupStart)
  }, [groupStart])
  const zFrom = zRoot === -1 ? -1 : zStart >= 0 ? zStart : zRoot
  const revealLeft: number[] = []
  if (hoverIndex >= 0) {
    // The group opens in place: chain full widths from its root's resting left.
    let rx = left[groupStart] ?? 0
    for (let i = groupStart; i < rendered.length; i++) {
      revealLeft[i] = rx
      rx += railWidth(rendered[i]!)
    }
  }
  // A member's geometry: revealed → full rail width, chained from the hovered list; else the covered
  // layout above (a COVERED_PEEK-wide (32px) peek, or its full width when disclosed).
  const leftOf = (i: number) => (inGroup(i) ? revealLeft[i]! : left[i]!) - offshift
  const boxWidth = (i: number) => (inGroup(i) ? railWidth(rendered[i]!) : widthOf(i))

  // The reveal FLOATS OVER THE DETAIL; the detail never moves for it. v1.13.1 pushed the detail's
  // left edge out to the open group's right edge instead, and that made a hover a layout change:
  // every pass of the pointer over a peek slid the whole pane aside and back, clipping it at the
  // container's edge on deep stacks. A covered list is a glance, so it is drawn over the pane in
  // place and the pane stays exactly where it was (Mike: "do not move the details pane, instead
  // show the parent topic list OVER the details pane in the current position"). The group's
  // z-lift, opaque background and trailing shadow are what make it read as a card on top.
  const detailLeft = restingDetailLeft

  // THE SEED'S LEFT EDGE. `restingDetailLeft` is the fit pass's answer, and the fit pass does not
  // run without a measurement: both loops above are inside `if (containerW > 0)`, so before the
  // ResizeObserver's first callback `pressure`, `hidden` and `offshift` are all 0 and this resolves
  // to the sum of every rail's FULL width — a number that assumes room the container may not have.
  //
  // With JavaScript that state lasts less than a frame. Without it, it is the finished page: the
  // seed is the only detail there will ever be, and it was being placed several hundred pixels
  // inside a container that is `relative overflow-hidden`, so on a phone its resolved width was 0
  // and the prose was clipped out of sight entirely. In the bytes, invisible on screen — which
  // satisfies a crawler and fails the reader `ssrDetail` exists for.
  //
  // So while the seed is what is showing, the detail owns the whole box. That is also the only
  // honest layout for it: the rails beside it are driven by `onSelect` handlers, so with no
  // JavaScript they are decoration, and giving the page's content the width instead of the dead
  // navigation is what the pane would do anyway if it had been measured. The handoff to the portal
  // does not slide, because `useInPlaceOnStructureChange` seeds its hold window at MOUNT precisely
  // so measurement-driven `left` changes in the first commits are not animated.
  const paneLeft = detailSeed ? 0 : detailLeft

  // LAYOUT LOG — the fit pass's discrete outcome (who is covered, how many slid off), on change
  // only, with the width and detail geometry it resolved at (htdv-log.ts).
  const fitSig = `${rendered.map((_l, i) => (isCovered(i) ? "c" : "o")).join("")}|${hidden}|${offshift}`
  const loggedFitSig = useRef<string | null>(null)
  useEffect(() => {
    if (containerW <= 0 || loggedFitSig.current === fitSig) return
    loggedFitSig.current = fitSig
    hlog(rendered[0]?.id ?? "htdv", "fit", {
      style: "covered",
      w: containerW,
      minPx,
      lists: rendered.length,
      covered: rendered.filter((_l, i) => isCovered(i)).map((l) => l.id),
      pressure,
      hidden,
      offshift,
      detailLeft: restingDetailLeft,
      detailW: containerW - restingDetailLeft,
    })
  })

  // Closing the group is a property of the GROUP, not of one list: moving the pointer from the
  // hovered list into one of its revealed children must NOT collapse it. So a leave only closes when
  // the pointer landed outside every member — `relatedTarget` (the element being entered) is not in a
  // column at or below the hovered one. Leaving the window entirely gives a null target → close.
  //
  // Only THIS stack's columns count. `data-htd-col` is every stack's attribute, and the hub nests
  // them — the HTDV sits in the workspace menu's detail, beside the menu's own columns. An unscoped
  // `closest` read the menu's list 0 as this stack's list 0, so a pointer leaving the revealed list
  // for the menu was "still in the branch" and the list never went back (Mike: "should move to the
  // back again when the mouse exits the topic list to the left top right bottom"). So walk out
  // past any foreign column to the first one that is a direct child of this container.
  const columnIndexOf = (target: EventTarget | null): number => {
    if (!(target instanceof Element)) return -1
    for (let col = target.closest("[data-htd-col]"); col; col = col.parentElement?.closest("[data-htd-col]") ?? null) {
      if (col.parentElement === containerRef.current) return Number(col.getAttribute("data-htd-col"))
    }
    return -1
  }
  const onGroupPointerLeave = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (hoverIndex < 0) return
    if (inGroup(columnIndexOf(e.relatedTarget))) return // still inside the revealed branch
    setHoverId(null)
  }

  // The group leave above fires from the COLUMNS, which only works while the pointer is over the
  // columns it opened. Since the branch now outlives the mount (`surfaceStates`), it can also outlive
  // the pointer: leave a surface with the pointer resting in an open branch, come back with the mouse
  // somewhere else, and no column would ever fire a leave to close it. So the open branch also
  // watches the document: a pointer that turns up ANYWHERE OUTSIDE THE COLUMNS is proof it is not in
  // the branch, and closes it. Only armed while a branch IS open.
  //
  // "Outside the columns" — not "outside the group". The columns own what happens between themselves:
  // entering a shallower covered list must RE-ROOT the branch there (that is how you walk the stack
  // leftwards, each list joining the cascade), and this listener runs last, on the document, so a
  // group test here would overrule that enter and collapse everything the user was walking through.
  //
  // Armed on the RAW `hoverId`, not the open reveal: a blind root that revealed nothing (see above)
  // must still be cleared when the pointer turns up elsewhere — left to linger, a later width squeeze
  // could cover its list and spring the branch open with no pointer anywhere near it.
  useEffect(() => {
    if (hoverId === null) return
    const onPointerOver = (e: PointerEvent) => {
      if (columnIndexOf(e.target) < 0) setHoverId(null)
    }
    document.addEventListener("pointerover", onPointerOver)
    return () => document.removeEventListener("pointerover", onPointerOver)
    // Only re-subscribe when the hovered root appears/clears (the guard above turns on `null`);
    // `columnIndexOf` is a stateless DOM reader and `setHoverId` is stable, so neither needs to be
    // a dependency — leaving them out keeps this from re-binding the document listener every render.
  }, [hoverId])

  // The `«`/`»` toggle sets a list's pin to the state it is moving TO. Holding the platform's
  // multi-select modifier (⌘ on macOS, Ctrl elsewhere) applies that same state to EVERY list at once
  // — one click to collapse the whole ancestry, or to open all of it. The fit rules still run on top,
  // so "open all" only discloses the lists that actually fit.
  const setCover = (parentIndex: number, e: ReactMouseEvent) => {
    const target = !isCovered(parentIndex) // the state the clicked button moves that list TO
    hlog(rendered[0]?.id ?? "htdv", "cover-toggle", {
      list: rendered[parentIndex]!.id,
      to: target ? "covered" : "open",
      all: e.metaKey || e.ctrlKey,
    })
    // The toggle must SHOW its work on the click: while a reveal is open the group renders at
    // full width regardless of pins, so a pin flip alone changes nothing until the pointer
    // happens to leave — the click reads as dead and its effect "turns up later". Dropping the
    // reveal settles the stack to the new pin state immediately; the pointer hasn't moved, so
    // no enter re-opens it (apply-disclosure-toggles-immediately).
    setHoverId(null)
    if (e.metaKey || e.ctrlKey) {
      // Every list's ordinary pin, as always — the choosing frontier's own pin only when the click
      // came from ITS toggle (the empty detail's), so a ⌘-click on a parent never hides the list
      // being chosen from.
      const all: Record<string, boolean> = Object.fromEntries(rendered.map((l) => [l.id, target]))
      if (parentIndex >= coverableCount) all[pinKey(parentIndex)] = target
      setPins(all)
      return
    }
    setPins((prev) => ({ ...prev, [pinKey(parentIndex)]: target }))
  }

  // `<<<` / `>>>` beside the detail's toggle: every list, the choosing frontier included (its own
  // key — this sits next to ITS toggle, exactly like a ⌘-click on it), to one state. Drops the
  // reveal for the same reason `setCover` does.
  const setCoverAll = (target: boolean) => {
    hlog(rendered[0]?.id ?? "htdv", "cover-all", { to: target ? "covered" : "open" })
    setHoverId(null)
    setPins(Object.fromEntries(rendered.map((_l, i) => [pinKey(i), target])))
  }
  const coverAllControl = (
    <CoverAllControl
      canCollapse={canCollapseAll}
      canExpand={canExpandAll}
      onCollapseAll={() => setCoverAll(true)}
      onExpandAll={() => setCoverAll(false)}
    />
  )

  // The `«`/`»` cover control for a CHILD whose parent is rendered list `parentIndex`. `«` (parent
  // not covered) covers the parent; `»` (parent covered) uncovers it. Purely presentational layout —
  // it never changes selection.
  const coverControl = (parentIndex: number) => {
    const parent = rendered[parentIndex]
    if (!parent) return undefined
    const parentCovered = isCovered(parentIndex)
    const label = parentCovered
      ? "Uncover previous list (⌘/Ctrl-click: uncover all)"
      : "Cover previous list (⌘/Ctrl-click: cover all)"
    return (
      <button
        type="button"
        onClick={(e) => setCover(parentIndex, e)}
        aria-label={label}
        title={label}
        className="rounded px-1 font-mono text-apt-text-muted outline-none hover:text-apt-text focus-visible:ring-2 focus-visible:ring-apt-gold/40"
      >
        {parentCovered ? (
          <ChevronsRight size={16} aria-hidden className="shrink-0" />
        ) : (
          <ChevronsLeft size={16} aria-hidden className="shrink-0" />
        )}
      </button>
    )
  }

  // Choosing a topic must land the detail IN PLACE — never slide it in from the left edge as the
  // lists re-cover behind it. EVERYTHING else animates, and deliberately so: a list sliding onto or
  // off its parent (width pressure covering it, or the `«`/`»` toggle) and a list sliding off the
  // left edge are the moves that make the stack read as physically layered rather than teleporting.
  // They are all discrete — a rail is full or a peek, a list is on-screen or gone — so they animate
  // cleanly even mid-drag; nothing here eases toward a moving target (see `useContainerWidth`).
  const inPlace = useInPlaceOnStructureChange(structureSignature(rendered))
  const animate = !dragging && !inPlace

  // Selection connectors (shared with the minimized stack). The signature is everything that moves a
  // selected row: the per-level selection and the column layout (left edges + off-screen shift +
  // width + the reveal group, which slides its members); scroll is NOT in it (it re-measures once via
  // `onScroll`).
  const connectorSig = `${rendered.map((l) => l.selectedId ?? "").join("|")}::${left.join(",")}::${offshift}::${containerW}::${hoverIndex}`
  const connectorsPossible = rendered.length >= 2 && rendered.some((l) => l.selectedId != null)
  const { connectors, onScroll } = useSelectionConnectors(
    containerRef,
    rendered.length,
    connectorSig,
    connectorsPossible,
  )

  return (
    // Absolute-positioned stack: lists overlap their children, z-index increases left→right, the
    // detail highest. The lists' `left` and the detail's `left`/`width` animate over 0.3s (the global
    // accessibility CSS zeroes the duration under reduce-motion).
    <div
      ref={containerRef}
      // `onScroll` is the connector re-measure trigger; fire it on pointer / focus movement too so
      // the gap around a row's trash button tracks the button's hover / keyboard-focus reveal.
      onScrollCapture={onScroll}
      onPointerOver={onScroll}
      onPointerOut={onScroll}
      onFocus={onScroll}
      onBlur={onScroll}
      className="relative min-h-0 min-w-0 flex-1 overflow-hidden"
    >
      {rendered.map((level, i) => {
        const covered = isCovered(i)
        // Slid off the left edge (phase 2). It stays MOUNTED (so it slides back in when the window
        // grows) but is fully out of the tab order / AT tree while it is gone.
        const offscreen = i < hidden
        // The covered list directly under THIS one (its parent is covered) → cast a left shadow on
        // THIS child so the overlap reads as physical. Index 0 has no parent.
        const parentCovered = i > 0 && isCovered(i - 1)
        // A covered list is rendered at its FULL width but its wrapper is clipped (`overflow-hidden`)
        // to a COVERED_PEEK-wide box, so only the leading icon of each row shows — the 32px peek.
        // Revealing WIPES the box open to the full rail width (the `width` transition); the inner rail
        // keeps a fixed railWidth so its rows never reflow as the box widens.
        const revealed = inGroup(i) && !offscreen
        // The lift is a property of the group: while it is open every member floats above the detail;
        // on close the lift LINGERS (zLiftId trails hoverId) so the wipe-shut happens over the UI
        // instead of behind it. The members keep their relative order (left → right) inside the lift.
        const zLifted = !offscreen && zFrom >= 0 && i >= zFrom
        // The group floats as ONE card over the UI, so BOTH its outer edges are edges: its trailing
        // edge shadows the detail it covers, and its LEADING edge shadows the peek stack it slid out
        // of (a peek's own `border-r` is clipped away with the rest of its rail, so that shadow IS
        // the boundary — without it the opened list bleeds into the icon strip behind it). Members
        // inside the group abut each other and are separated by their own rail borders.
        const groupTrailing = revealed && i === rendered.length - 1
        const groupLeading = revealed && i === groupStart && i > 0
        return (
          <div
            key={level.id}
            data-htd-col={i}
            // Entering a COVERED list opens the branch rooted at it. Entering a list already inside the
            // open branch keeps it (the pointer is walking the cascade, not opening a new one);
            // entering a disclosed list outside the branch closes it.
            onPointerEnter={() => {
              if (inGroup(i)) return
              setHoverId(covered && !offscreen ? level.id : null)
            }}
            // Closing is the GROUP's business (see onGroupPointerLeave): a leave into a revealed child
            // must not collapse the branch the pointer is still inside.
            onPointerLeave={onGroupPointerLeave}
            aria-hidden={offscreen || undefined}
            // React 19 types `inert` as a boolean prop; `undefined` (not false) omits the attribute.
            inert={offscreen || undefined}
            style={{
              left: leftOf(i),
              width: boxWidth(i),
              gridTemplateColumns: `${railWidth(level)}px`,
              zIndex: zLifted ? REVEAL_Z + i : i + 1,
              // Shadows ride the WRAPPER (its own box-shadow isn't clipped by its overflow, unlike a
              // child's). They compose — a one-list group is both the leading and the trailing edge of
              // its card — which is why this is an inline `boxShadow` and not two utility classes
              // (the second would just overwrite the first).
              boxShadow:
                [
                  groupTrailing && SHADOW_RIGHT,
                  (groupLeading || (parentCovered && !revealed)) && SHADOW_LEFT,
                ]
                  .filter(Boolean)
                  .join(", ") || undefined,
            }}
            className={cn(
              "absolute top-0 bottom-0 grid overflow-hidden",
              offscreen && "pointer-events-none",
              animate &&
                "transition-[left,width,box-shadow] duration-[calc(300ms*var(--apt-anim-scale,1))] ease-in-out",
              // The rail's own `bg-apt-nav` is 96% opaque — right for a nav sitting on the page, wrong
              // for a branch FLOATING over the detail, which ghosts the detail's text through it. A
              // lifted member gets the page background under its rail, so the card is opaque while it
              // floats and composites exactly as it does at rest.
              zLifted && "bg-apt-bg",
            )}
          >
            <TopicRail
              title={level.title}
              busy={level.busy}
              onPrefetch={level.onPrefetch}
              railLabel={level.railLabel}
              // Rows are ALWAYS full (never an icon strip): the wrapper's clip makes the peek, and the
              // hover wipe reveals the labels — so there is no covered↔full content swap to jar the wipe.
              covered={false}
              isRoot={i === 0}
              // Selection is shown by the dash (root) + connector overlay, not the gold bar.
              selectionStyle="marker"
              items={level.items}
              selectedId={level.selectedId}
              // Selecting does NOT close the branch: the pointer is still inside it, and collapsing
              // under the cursor yanks the rows away mid-gesture — you cannot pick a parent and then
              // pick its child, which is the whole point of revealing the branch. The reveal is
              // pointer-scoped, so it collapses when (and only when) the pointer leaves it.
              //
              // And a select from a list at REST roots a branch here itself: a select can COVER the
              // very list it landed in, with the pointer still inside it — exactly the state
              // pointer-enter names, except the pointer never moved, so no enter will ever fire.
              // Usually that is a select that COMPLETES the path: a complete path is what makes the
              // detail claim its full minimum, and paying for it is what squeezes the lists into
              // peeks. (A select that only pushes another choosing list can do it too, but that pane
              // is a landing and claims nothing, so it takes a very deep stack.) Without this the
              // list snaps shut under the cursor on the very click and nothing reopens it; with it,
              // it stays open floating over the detail and the stack settles when the pointer
              // leaves. The root is planted BLIND — the fit pass has not run at click time — so one
              // that ends up covering nothing is dropped as meaningless (see the reveal group above).
              onSelect={(id) => {
                if (!inGroup(i)) setHoverId(level.id)
                railOnSelect(level, attemptExit, rendered[i + 1])(id)
              }}
              emptyLabel={level.emptyLabel ?? "Nothing here yet."}
              onNew={level.onNew}
              newLabel={level.newLabel}
              newActive={level.newActive}
              titleActions={level.titleActions}
              railSlot={level.railSlot}
              headerSlot={level.headerSlot}
              search={level.search}
              reserveToolbar={rendered.some(hasListTools)}
              hideItemIcons={level.hideItemIcons}
              checkable={level.checkable}
              checkedIds={level.checkedIds}
              onToggleChecked={level.onToggleChecked}
              // (#4) ONLY the TOPMOST (frontier) menu gets a right-justified close (✕) in its header —
              // not every child. It dismisses that menu and clears the selection in the PARENT list
              // that opened it (the root never qualifies). Drop any open reveal so the stack settles
              // at once, and route the clear through the exit guard like every other de-selection.
              onClose={
                i === frontier && i !== 0
                  ? () => {
                      setHoverId(null)
                      attemptExit(() => rendered[i - 1]!.onClear())
                    }
                  : undefined
              }
              closeLabel={`Close ${level.title ?? "menu"}`}
              // Covered lists never shrink to an icon strip (no toggle) — but the trailing-border
              // handle DOES resize the rail: drag it to widen/narrow the column.
              collapsed={false}
              onToggle={() => {}}
              onResize={(w) => onResizeLevel(level, w)}
              onResizeStart={() => setDragging(true)}
              onResizeEnd={() => setDragging(false)}
              onFit={(w) => onFit(level.id, w)}
              showToggle={false}
              // The header's leading control slot: the `«`/`»` that covers/uncovers THIS list's
              // PARENT (the list to its left). The ROOT list has no parent, so it carries nothing.
              leftControl={i === 0 ? undefined : coverControl(i - 1)}
              // The layered-card left shadow rides the wrapper (the rail's own shadow would be clipped
              // by the wrapper's overflow), so the rail doesn't draw one.
              coveredShadow={false}
            />
          </div>
        )
      })}
      {/* Selection connectors: gold elbows linking each selected parent row to its selected child
          row, drawn above the lists (so they bridge the list boundary) but pointer-transparent. While
          a branch is z-lifted (hover reveal, and the lingering lift as it wipes shut) the overlay
          rides above the whole lift — the chain is exactly what you are reading when you open the
          branch, so the branch must never paint over it. */}
      <SelectionConnectorOverlay
        paths={connectors}
        zIndex={zFrom >= 0 ? REVEAL_Z + rendered.length : undefined}
      />
      {/* The detail (leaf) pane — rightmost, highest z-index, fills to the container's right edge
          down to `minDetailWidth`. Its top-left carries the cover toggle for the frontier list. The
          left shadow turns on when its parent (the frontier list) is covered, so the overlap reads
          as physical (token colour via a CSS var, so the colour checker stays clean).

          Its right edge is PINNED (`right: 0`), not computed: a JS `containerW - detailLeft` width
          is a measurement from the previous commit, so while the window is being dragged the pane
          is always one frame behind the edge it is supposed to sit on — the width visibly wanders.
          Anchoring both edges makes the browser solve `width` from the live container on every
          frame, for free and exactly. `left` is still the only animated edge; width follows it.

          `paneLeft`, not `detailLeft`, precisely because of that pinned right edge: an unmeasured
          `left` past the container's own width solves to a width of ZERO, and this box is inside an
          `overflow-hidden` — so the pre-measurement render doesn't merely sit wrong, it disappears.
          See the `paneLeft` definition for why that window is the whole page without JavaScript.

          A fixed `detailWidth` is a `maxWidth` on top of the pinned edges: over-constrained, the box
          keeps its `left` and drops `right`, so it is that wide wherever there is room and still
          ends at the container's edge where there is not. */}
      <section
        key="__detail__"
        // Not `data-htd-col`: that attribute means "this box IS list N" to the pointer→index lookup
        // (`colFromTarget`), and the detail is not a list.
        data-htd-detail
        style={{ left: paneLeft, right: 0, maxWidth: detailWidth, zIndex: rendered.length + 1 }}
        className={cn(
          "absolute top-0 bottom-0 flex flex-col overflow-auto bg-apt-surface",
          // A fixed-width pane ends short of the container: the border is its edge.
          detailWidth && "border-r border-apt-border",
          animate && "transition-[left] duration-[calc(300ms*var(--apt-anim-scale,1))] ease-in-out",
          rendered.length > 0 && isCovered(rendered.length - 1) && "shadow-[-10px_0_22px_-8px_var(--color-shadow)]",
        )}
      >
        {/* The frontier list is the detail's "parent": its cover toggle rides the detail's top-left.
            The strip is the rails' titled-header height (2.15rem) EITHER WAY, so the top row aligns
            across every column; the title (a pane's own, or the frame's detailTitle) sits beside the toggles. Without a
            title this used to fall back to a compact `py-1.5` strip, which left the detail's header
            visibly shorter than the list headers beside it — the one column that didn't line up. */}
        {rendered.length > 0 && (
          <div className="flex min-h-[2.15rem] shrink-0 items-center gap-2 border-b border-apt-border bg-apt-nav pr-2">
            <div className="flex w-8 shrink-0 items-center justify-center">{coverControl(rendered.length - 1)}</div>
            {coverAllControl}
            {detailTitle.cell}
          </div>
        )}
        {/* Hold the leaf to its min width so it scrolls rather than crushing — but never wider than
            the viewport, so on a phone the form reflows to the full width instead of scrolling.
            Rendered EMPTY — the frame slots its persistent detail host in here (see
            StackProps.detailSlot) — except for the window before that host exists, when
            `detailSeed` may hold the server-rendered detail. */}
        <div
          ref={detailSlot}
          className="flex min-h-0 w-full flex-1 flex-col"
          style={{ minWidth: `min(${minDetailWidth}, 100%)` }}
        >
          {detailSeed}
        </div>
      </section>
    </div>
  )
}

/**
 * The NARROW layout — the stack as an iOS `UINavigationController`.
 *
 * When the wide layout is exhausted (a phone, or a window narrowed past the last collapsed strip
 * beside a `minDetailWidth` detail — see the frame's `wideFloor`), the
 * side-by-side model has nothing left to trade: peeks, cover toggles and the hover reveal are all
 * pointer affordances on room that no longer exists. So the view stops being a row of columns and
 * becomes a NAVIGATION STACK — exactly one FULL-WIDTH pane at a time:
 *
 *   [ Regions ]  →  [ Ecosystems ]  →  [ Topics ]  →  [ detail ]
 *
 * The visible pane is the deepest one the selection reaches: the FRONTIER list while it is still
 * being chosen from, and the detail once every level is selected. Selecting **pushes** the next pane
 * in from the right; **Back** (top-left of every pane but the root) pops it back out, clearing exactly
 * the deepest selected level — the same `onClear` the breadcrumb and the wide layout's Back use, so
 * the unsaved-work guard applies identically. The page's swipe-back gesture, offered to the stack
 * under the finger (lib/swipe-back.ts), runs that same Back whenever one is showing. The pane
 * behind the top one parallaxes a little (as iOS does) and is `inert` + `aria-hidden`, so only the
 * visible pane is reachable.
 *
 * Panes are rendered for EVERY level (not just the ones in the current path), so a pane exists to
 * slide in from the right before it becomes the top — and a popped pane slides back OUT instead of
 * vanishing. `anim` lags `top` by one frame for the same reason: a pane that mounts already at its
 * final position cannot transition, so we paint it off-screen once, then move it.
 */
/**
 * A history TRAVERSAL (Back / Forward, and iOS Safari's edge swipe) is in flight: set on `popstate`,
 * spent by the narrow stack once it has landed on the pane that traversal chose, or by the next
 * touch or click. Module scope because the traversal usually REMOUNTS the stack (a route change),
 * and the new instance must still know how it got there.
 *
 * Why it matters: Safari's edge swipe draws its OWN slide — the previous page's snapshot sliding in
 * under the finger — and only then fires `popstate`. A stack that then slid from the pane it last
 * painted to the one the traversal chose played the pop a second time over the finished gesture:
 * the page blinked and redrew. After a traversal the stack lands at once.
 */
let traversalPending = false
if (typeof window !== "undefined") {
  window.addEventListener("popstate", () => {
    traversalPending = true
  })
  const spend = () => {
    traversalPending = false
  }
  window.addEventListener("pointerdown", spend, { capture: true, passive: true })
  window.addEventListener("keydown", spend, { capture: true, passive: true })
}

function NarrowStack({
  levels,
  firstUnselected,
  frontier,
  deepestSelected,
  detailTitle,
  attemptExit,
  narrowTop,
  setNarrowTop,
  detailSlot,
  detailSeed,
}: StackProps & { levels: TopicLevel[] }) {
  // The `persistentSelection` list Back has popped to (see TopicLevel.persistentSelection): the
  // selection is still there, so the stack is told to show that list instead of what lies below
  // it. It holds only for the selection it was made at — the moment the selection moves, the stack
  // shows the pick like any other.
  //
  // Stored WITH that selection, in state, and compared during render — never a ref advanced during
  // render. React can render a selection change, throw that render away (a transition that
  // suspends, or that an urgent update interrupts) and render it again from the last committed
  // state. A ref written by the discarded render survives it; a state reset made during it does
  // not. So when this remembered "the selection I last saw" in a ref, the discarded render used the
  // change up, the render that committed saw no change, and the revealed list stayed on top of the
  // row just picked. Derived from the pair instead, the answer is right in every render, whichever
  // of them commits.
  const [reveal, setReveal] = useState<{ index: number; sig: string } | null>(null)
  const selectionSig = levels.map((l) => l.selectedId ?? "").join("\u0000")
  const revealed = reveal !== null && reveal.sig === selectionSig ? reveal.index : null
  // Forget a reveal the selection has moved past (store-and-adjust during render), so a selection
  // that later comes BACK to the old one — history, a host reset — cannot resurrect it.
  if (reveal !== null && revealed === null) setReveal(null)
  const revealList = (i: number) => setReveal({ index: i, sig: selectionSig })
  // Where the selection alone puts the top of the navigation stack: the detail (index
  // `levels.length`) once every level is selected, else the frontier list — the one with nothing
  // chosen in it yet. A revealed list sits above it.
  const selectedTop = firstUnselected === -1 ? levels.length : frontier
  const top = revealed ?? selectedTop
  // The position the panes are RENDERED at. It catches up to `top` one frame later, so the pane being
  // pushed is painted off-screen FIRST and its move to centre is a transition rather than a jump — an
  // element that mounts at its final transform has nothing to animate from.
  //
  // It seeds from the pane the stack was last painted at, which is why this lives in the surface store
  // (see `SurfaceState.narrowTop`) rather than in this component: pushing a pane means selecting a row
  // means a route change means a REMOUNT, so a fresh `useState(top)` would start every push already
  // finished. On a genuinely fresh load there is no previous pane and nothing to slide from, so the
  // first paint simply lands.
  //
  // After a history traversal it does not slide at all (see `traversalPending`): the browser has
  // already shown that move, and `instant` drops the transition for the frame the stack lands in.
  const [anim, setAnim] = useState(() => (traversalPending ? top : (narrowTop ?? top)))
  const [instant, setInstant] = useState(() => traversalPending)
  useLayoutEffect(() => {
    if (anim === top) {
      setNarrowTop(top) // settled: this is what the next push/pop animates FROM
      if (instant) {
        traversalPending = false
        const id = requestAnimationFrame(() => setInstant(false))
        return () => cancelAnimationFrame(id)
      }
      return
    }
    if (traversalPending) {
      setInstant(true)
      setAnim(top)
      return
    }
    const id = requestAnimationFrame(() => setAnim(top))
    return () => cancelAnimationFrame(id)
  }, [anim, top, instant, setNarrowTop])

  // LAYOUT LOG — every push/pop of the navigation stack (htdv-log.ts).
  const loggedTop = useRef<number | null>(null)
  useEffect(() => {
    if (loggedTop.current === top) return
    const from = loggedTop.current
    loggedTop.current = top
    hlog(levels[0]?.id ?? "htdv", "narrow-nav", {
      top,
      from: from ?? "first-paint",
      pane: top === levels.length ? "detail" : (levels[top]?.id ?? top),
    })
  })

  // Back pops one pane: clear the deepest SELECTED level (exit-guarded, like every other clear) —
  // or, for a `persistentSelection` level, just reveal its list. From a revealed list, Back goes
  // one level further up by the same rule: the parent's list is revealed if the parent is
  // persistent too, and only a parent that is not gets cleared. Clearing a persistent parent is
  // what this used to do, and its `onClear` re-selects the default row — so the host swapped the
  // parent's selection and pushed a detail instead of showing the parent's list.
  const onBack = () => {
    const pop = revealed !== null ? revealed - 1 : deepestSelected
    const level = levels[pop]
    if (!level) return
    if (level.persistentSelection) attemptExit(() => revealList(pop))
    else attemptExit(() => level.onClear())
  }
  // The top pane shows a Back exactly when it is not the root list (a list pane `i > 0` carries it
  // in its `backSlot`, the detail in its header) and there is a selection for it to pop.
  const showsBack = top > 0 && deepestSelected >= 0

  // THE SWIPE-BACK GESTURE (lib/swipe-back.ts). The page's flick-right handler offers the gesture
  // at the element under the finger before falling back to `history.back()`. While this stack
  // SHOWS a Back it claims the gesture and runs exactly what that Back runs — every kind of Back,
  // the ordinary selection-clearing one included, because the fallback is wrong for all of them:
  // `history.back()` skips the unsaved-work guard, leaves the page outright when the host keeps
  // its selection in memory, and on a routed host lands on whatever entry happens to precede this
  // one rather than one pane up (a deep link, or a default select that replaced its entry). One
  // gesture, one visible Back. HOW it claims — subscribed once, running the Back the commit
  // showed rather than one a discarded render wrote (the lesson of `reveal` above), and never over
  // a stack nested inside this one — is hooks/useSwipeBackClaim.ts, shared with HMD's stack.
  const rootRef = useRef<HTMLDivElement>(null)
  useSwipeBackClaim(rootRef, showsBack ? onBack : null)

  const backButton = deepestSelected >= 0 && (
    <button
      type="button"
      onClick={onBack}
      aria-label="Back"
      title="Back"
      className="flex shrink-0 items-center rounded p-0.5 text-apt-text-muted outline-none hover:text-apt-text focus-visible:ring-2 focus-visible:ring-apt-gold/40"
    >
      <ChevronLeft size={18} aria-hidden />
    </button>
  )

  // A pane's place in the animation: the top one fills the view; the ones behind it parallax left (an
  // iOS push reveals the pane underneath moving at a fraction of the speed); the ones ahead of it wait
  // off the right edge. Deeper panes stack ABOVE shallower ones, so the incoming pane covers its parent.
  const paneStyle = (i: number): CSSProperties => ({
    transform:
      i === anim ? "translateX(0)" : i < anim ? "translateX(-30%)" : "translateX(100%)",
    zIndex: i + 1,
  })
  // Every pane — the topic lists AND the detail — slides on the same transition: EASE-IN-OUT, so the
  // push and the pop both accelerate out of rest and settle back into it rather than snapping to a
  // stop. Deliberately NOT gated on `motion-reduce` — see the note on this file's disclosure styles.
  const paneClass = (i: number) =>
    cn(
      "absolute inset-0 flex flex-col",
      !instant && "transition-transform duration-[calc(300ms*var(--apt-anim-scale,1))] ease-in-out",
      i !== anim && "pointer-events-none",
    )

  return (
    <div ref={rootRef} className="relative min-h-0 min-w-0 flex-1 overflow-hidden">
      {levels.map((level, i) => (
        <div
          key={level.id}
          data-htd-col={i}
          style={paneStyle(i)}
          className={paneClass(i)}
          aria-hidden={i !== anim || undefined}
          inert={i !== anim || undefined}
        >
          <TopicRail
            title={level.title}
            busy={level.busy}
            onPrefetch={level.onPrefetch}
            railLabel={level.railLabel}
            isRoot={i === 0}
            // The pane IS the screen here, so the rail must FILL it. Left to itself the rail sizes to
            // its rows — right in the wide stack, where each list is a stretched grid cell, but in a
            // flex pane it leaves everything under the last row transparent: you see straight through
            // to the parallaxed pane behind it and then to the page. Its trailing border goes too —
            // at full width it is a hairline down the edge of the screen, separating nothing.
            className="min-h-0 flex-1 border-r-0"
            // No connector overlay in this layout (there is never a parent list on screen to connect
            // FROM), so selection falls back to the primitive's own gold bar — visible again when Back
            // pops you onto the parent list.
            selectionStyle="bar"
            // Every row here — the topic lists AND (implicitly, by never reaching this component) not
            // the leaf detail — pushes the NEXT pane on select; a trailing chevron is the only hint of
            // that a full-width pane can give (there's no peeking sibling column left to imply it).
            rowDisclosure
            items={level.items}
            selectedId={level.selectedId}
            // A revealed persistent list's CURRENT row goes back down ONE pane, retracing the Backs
            // that got here: to the list below it while that one is revealed too, else to where the
            // selection puts the top. Jumping straight to the detail would skip lists the user
            // walked up through; re-click-deselect would only re-select the default, which is not
            // what a tap on a visible row means.
            onSelect={
              revealed === i
                ? (id) => {
                    if (id !== level.selectedId) railOnSelect(level, attemptExit)(id)
                    else if (i + 1 < selectedTop) revealList(i + 1)
                    else setReveal(null)
                  }
                : railOnSelect(level, attemptExit, levels[i + 1])
            }
            emptyLabel={level.emptyLabel ?? "Nothing here yet."}
            onNew={level.onNew}
            newLabel={level.newLabel}
            newActive={level.newActive}
            titleActions={level.titleActions}
            railSlot={level.railSlot}
            headerSlot={level.headerSlot}
            search={level.search}
            reserveToolbar={levels.some(hasListTools)}
            hideItemIcons={level.hideItemIcons}
            checkable={level.checkable}
            checkedIds={level.checkedIds}
            onToggleChecked={level.onToggleChecked}
            // Nothing to disclose, cover or resize: the pane IS the whole view.
            collapsed={false}
            onToggle={() => {}}
            showToggle={false}
            backSlot={i > 0 ? backButton : undefined}
          />
        </div>
      ))}
      {/* The detail — the last pane. Its Back pops the deepest selection, which lands you back on the
          list you chose from. Full width by definition, so no `minDetailWidth` and no horizontal scroll. */}
      <section
        key="__detail__"
        data-htd-col={levels.length}
        style={paneStyle(levels.length)}
        className={cn(paneClass(levels.length), "overflow-auto bg-apt-surface")}
        aria-hidden={levels.length !== anim || undefined}
        inert={levels.length !== anim || undefined}
      >
        {(backButton || detailTitle.titled) && (
          <div className="flex min-h-[2.15rem] shrink-0 items-center gap-2 border-b border-apt-border bg-apt-nav px-1.5">
            {backButton}
            {detailTitle.cell}
          </div>
        )}
        {/* Rendered EMPTY — the frame slots its persistent detail host in here (see
            StackProps.detailSlot), which is how the deep detail SURVIVES the flip into narrow.
            `detailSeed` is the one exception: the server-rendered detail, held only until the
            host exists. */}
        <div ref={detailSlot} className="flex min-h-0 w-full flex-1 flex-col">
          {detailSeed}
        </div>
      </section>
    </div>
  )
}
