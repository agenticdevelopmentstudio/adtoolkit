"use client"

import {
  createContext,
  useCallback,
  useContext,
  useId,
  useMemo,
  useState,
  type ReactElement,
  type ReactNode,
  type ReactPortal,
} from "react"
import { createPortal } from "react-dom"

import { useIsomorphicLayoutEffect } from "../hooks/useIsomorphicLayoutEffect"
import { deepestSelectedLevel, selectedTopicLabel } from "./stack-frontier"

/**
 * THE DETAIL TITLE: a pane's title belongs in its stack's detail strip, not in the pane.
 *
 * Mike: "the title for each details pane just be left justified next to the new <<< | >>>
 * control, the title should not be in the details pane, this should be part of the shared code,
 * please fix this in all the detail panes". So the stacks (HTDV, HMDV) own the slot, and the
 * shared title drawers (`FeatureTitle`, `ButtonBar`'s title, a pane-title `SectionHeader`,
 * `ComingSoon`) hand their title to it through {@link useDetailTitle} instead of drawing it.
 *
 * A PORTAL, not a published value. The previous transport (`useDetailTitle(string)` in the
 * resource package, a host-side registry, a `detailTitle` prop) could carry only a string,
 * because a `ReactNode` is a new object every render and an effect keyed on one re-publishes
 * forever. Registering only the publisher's ID and portalling the node into the strip carries any
 * node, and no host has to plumb anything: the stack provides the context itself, so every host
 * of every stack gets it for free.
 *
 * One title at a time: when several are registered, the LAST to register wins (the old
 * registry's rule). The others draw inline as before, so a second title is never lost.
 */

interface Registrar {
  register: (id: string) => void
  unregister: (id: string) => void
}

interface Target {
  slot: HTMLElement | null
  activeId: string | undefined
}

// Split in two so a publisher's registration effect depends only on the STABLE registrar. With one
// context, every slot or winner change would hand publishers a new value, re-run their effects,
// and — unregister then register — re-append each one, reshuffling who wins on every render.
const RegistrarContext = createContext<Registrar | null>(null)
const TargetContext = createContext<Target>({ slot: null, activeId: undefined })

/** What a stack holds to provide the title slot: see {@link useDetailTitleHost}. */
export interface DetailTitleHost {
  registrar: Registrar
  target: Target
  /** True while any pane is handing the strip a title, so the stack can draw the strip. */
  published: boolean
  /** Callback ref for the element the title portals into. */
  slotRef: (el: HTMLElement | null) => void
}

/** The stack side: registration state plus the slot element. Pair with {@link DetailTitleProvider}. */
export function useDetailTitleHost(): DetailTitleHost {
  const [ids, setIds] = useState<readonly string[]>([])
  const [slot, setSlot] = useState<HTMLElement | null>(null)
  const register = useCallback((id: string) => {
    setIds((prev) => (prev.includes(id) ? prev : [...prev, id]))
  }, [])
  const unregister = useCallback((id: string) => {
    setIds((prev) => (prev.includes(id) ? prev.filter((x) => x !== id) : prev))
  }, [])
  const registrar = useMemo(() => ({ register, unregister }), [register, unregister])
  const activeId = ids.at(-1)
  const target = useMemo(() => ({ slot, activeId }), [slot, activeId])
  return { registrar, target, published: ids.length > 0, slotRef: setSlot }
}

/** Makes `host`'s slot the title target for every {@link useDetailTitle} below it. */
export function DetailTitleProvider({
  host,
  children,
}: {
  host: DetailTitleHost
  children: ReactNode
}): ReactElement {
  return (
    <RegistrarContext.Provider value={host.registrar}>
      <TargetContext.Provider value={host.target}>{children}</TargetContext.Provider>
    </RegistrarContext.Provider>
  )
}

/**
 * Withdraws every title registered below while `when` holds — for a pane the stack keeps MOUNTED but
 * hidden (under the "Select a …" overview, or behind HMDV's held node): it must stay mounted, but the
 * strip must not name what is not on screen (code review: the hidden MilestonesPane's title replaced
 * the selected-topic fallback above the hint). Always rendered, whatever `when` is, so toggling it
 * never re-parents — and so never remounts — the children; a null registrar just unregisters them.
 */
export function DetailTitleSuppressed({
  when,
  children,
}: {
  when: boolean
  children: ReactNode
}): ReactElement {
  const registrar = useContext(RegistrarContext)
  return <RegistrarContext.Provider value={when ? null : registrar}>{children}</RegistrarContext.Provider>
}

/**
 * The strip's DEFAULT title — {@link selectedTopicLabel} — held steady while the pane still shows
 * the row. The selected row can drop out of its level while it stays open (a notes search or tag
 * filter that excludes the open note: the backend-filtered level loses it, the selection and the
 * editor stay), and the bare lookup then blanked the strip while the crumb beside it fell back to
 * the raw id (code review). So: the label last seen for this exact selection, else — like the crumb
 * — the id itself (a deep link before its list loads). Undefined only when nothing is selected.
 */
export function useSelectedTopicLabel(
  levels: readonly { selectedId: string | null; items: readonly { id: string; label: string }[] }[],
): string | undefined {
  const depth = deepestSelectedLevel(levels)
  const id = levels[depth]?.selectedId ?? undefined
  const live = selectedTopicLabel(levels)
  // Keyed on depth AND id: the same id one level down is a different topic.
  const key = id === undefined ? undefined : `${depth}\u0000${id}`
  const [seen, setSeen] = useState<{ key: string; label: string } | null>(null)
  // Derived during render (React's "adjust state on a prop change" pattern), not in an effect: an
  // effect would paint the blank strip once before correcting it.
  if (key !== undefined && live !== undefined && (seen?.key !== key || seen?.label !== live)) {
    setSeen({ key, label: live })
  }
  if (id === undefined) return undefined
  return live ?? (seen && seen.key === key ? seen.label : id)
}

/** What a stack hands the strip atop its detail: whether to draw a titled strip at all, and the
 *  title cell to put in it. */
export interface DetailStripTitle {
  titled: boolean
  cell: ReactNode
}

/**
 * The strip's title for a stack whose host may ALSO pass a title as a prop (`fallback` — the
 * stack's `detailTitle`, still how a host that owns the whole detail names it). A pane's own
 * title wins: it is the more specific name for what is on screen.
 *
 * The slot is its own `display: contents` span so the portal's nodes never share a parent with
 * nodes React renders here — the fallback text is a sibling, not a co-tenant.
 *
 * The cell IS the pane's heading (level 2, what the title drawers drew inline before they handed
 * their title here): hoisting the title out of an `<h2>` into a plain span took every pane's
 * accessible heading with it — screen-reader heading navigation and the hub e2e's
 * `getByRole("heading", { name: "Profile", level: 2 })` both lost it (code review). A role rather
 * than an `<h2>` so the slot element never changes type, and only while something is titled, so an
 * empty strip announces no empty heading. `fallback` null/false is a host's opt-out: no title.
 */
export function detailStripTitle(host: DetailTitleHost, fallback: ReactNode): DetailStripTitle {
  const titled =
    host.published || (fallback !== undefined && fallback !== null && fallback !== false)
  return {
    titled,
    cell: (
      <span
        data-htd-detail-title
        role={titled ? "heading" : undefined}
        aria-level={titled ? 2 : undefined}
        className="min-w-0 flex-1 truncate font-mono text-[0.8rem] tracking-[0.02em] text-apt-text-muted"
      >
        <span ref={host.slotRef} className="contents" />
        {host.published ? null : fallback}
      </span>
    ),
  }
}

/**
 * The pane side. Hand the stack's strip `title` (null/undefined/false = no title). Render the
 * returned `portal` somewhere in the pane — it is null unless the title is in the strip — and draw
 * the title yourself only when `hoisted` is false: outside any stack, while another pane holds the
 * strip, and on the server (the slot is DOM, so server HTML keeps the inline title for crawlers and
 * no-JS readers; the layout effect moves it before the first client paint).
 */
export function useDetailTitle(title: ReactNode): { hoisted: boolean; portal: ReactPortal | null } {
  const registrar = useContext(RegistrarContext)
  const { slot, activeId } = useContext(TargetContext)
  const id = useId()
  const has = title !== null && title !== undefined && title !== false
  // Keyed on `has`, never on `title`: a node is a new object every render (see the module doc).
  useIsomorphicLayoutEffect(() => {
    if (!registrar || !has) return
    registrar.register(id)
    return () => registrar.unregister(id)
  }, [registrar, id, has])
  const hoisted = has && registrar !== null && slot !== null && activeId === id
  return { hoisted, portal: hoisted && slot ? createPortal(title, slot) : null }
}
