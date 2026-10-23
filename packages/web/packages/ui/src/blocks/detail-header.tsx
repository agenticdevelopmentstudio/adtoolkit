"use client"

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useId,
  useMemo,
  useState,
  type ReactNode,
} from "react"
import { createPortal } from "react-dom"
import { CircleHelp, Code2 } from "lucide-react"

import { Button } from "../components/button"
import { quietControlClass } from "../lib/quiet-control"
import { cn } from "../lib/utils"
import type { DetailStripTitle } from "./detail-title"

/** Why the header's API button is grey: the one sentence every disabled instance carries. */
export const NO_API_ENDPOINT = "This view has no API endpoint"

/** Why a header's "?" is grey: the view has no help written for it. */
export const NO_HELP = "No help for this view"

/**
 * The header's API button when there is nothing to open: the same outline "API" button the
 * api-explorer draws, disabled, with a tooltip saying why. The enabled one belongs to whoever
 * knows the endpoint and portals in through {@link DetailHeaderPortal}.
 */
export function DisabledApiButton({ reason = NO_API_ENDPOINT }: { reason?: string }) {
  return (
    // A disabled <button> swallows pointer events, so the tooltip lives on a wrapper.
    <span title={reason} className="inline-flex">
      <Button type="button" variant="outline" size="xs" disabled aria-label={`API — ${reason}`}>
        <Code2 size={14} aria-hidden />
        API
      </Button>
    </span>
  )
}

/**
 * The "?" a details header draws when its view has no help — present and disabled, so every
 * header keeps the same [API][?] shape on its right and says why there is nothing to open.
 */
export function DisabledHelpButton({
  reason = NO_HELP,
  triggerClassName,
}: {
  reason?: string
  triggerClassName?: string
}) {
  return (
    <span title={reason} className="inline-flex">
      <button
        type="button"
        disabled
        aria-label={`About this section — ${reason}`}
        className={cn(quietControlClass, "cursor-not-allowed opacity-40 hover:text-apt-text-muted", triggerClassName)}
      >
        <CircleHelp size={16} />
      </button>
    </span>
  )
}

/** Which of the detail header's two controls a pane is claiming. */
export type DetailHeaderKind = "api" | "help"

/**
 * The detail header's two portal slots and who holds each. Every details view's header carries
 * the view's API button and, on the far right, its "?" help; the pane that knows the endpoint and
 * the help text is several components below the stack that draws the header, so it CLAIMS a slot
 * and portals its control in (see {@link DetailHeaderPortal}).
 *
 * Keyed by claimant, and the LAST claimant of a kind wins — the same rule as the detail title: a
 * claimant's unmount withdraws only its own claim, so a closing pane never strips the header out
 * from under the pane now open. With no claimant the header draws the fallback: a disabled API
 * button (this view has no endpoint) and the stack's own help, else a disabled "?".
 */
export interface DetailHeaderHost {
  apiSlot: HTMLElement | null
  helpSlot: HTMLElement | null
  apiOwner: string | null
  helpOwner: string | null
  claim: (id: string, kind: DetailHeaderKind, claimed: boolean) => void
}

interface DetailHeaderState {
  host: DetailHeaderHost
  setApiSlot: (el: HTMLDivElement | null) => void
  setHelpSlot: (el: HTMLDivElement | null) => void
  fallbackHelp: ReactNode
  actions: ReactNode
}

const DetailHeaderContext = createContext<DetailHeaderState | null>(null)

/**
 * The header a stack owns for its detail. Both stacks (HTDV and HMDV) mount one around everything
 * they draw, so EVERY details header — the hub shell's, a feature site's, a dialog's, a console's —
 * carries the same [API][?] pair, and a pane inside claims the nearest stack's slots. The slots are
 * STATE, not refs: a ref lands during commit without a re-render, so the provider would publish
 * `null` on the mount that matters and every claimant would stay invisible.
 */
export function DetailHeaderProvider({
  fallbackHelp,
  actions,
  children,
}: {
  /** The stack's own help, in the "?" slot while no pane claims it. */
  fallbackHelp?: ReactNode
  /** Controls about the whole view, drawn just left of the [API][?] pair on every header row the
   *  stack draws (the REST API help's Download OpenAPI JSON). Not a claimable slot: the stack that
   *  owns the view owns these, so no pane below can displace them. */
  actions?: ReactNode
  children: ReactNode
}) {
  const [apiSlot, setApiSlot] = useState<HTMLDivElement | null>(null)
  const [helpSlot, setHelpSlot] = useState<HTMLDivElement | null>(null)
  const [claims, setClaims] = useState<Readonly<Record<DetailHeaderKind, readonly string[]>>>({
    api: [],
    help: [],
  })
  const claim = useCallback((id: string, kind: DetailHeaderKind, claimed: boolean) => {
    setClaims((prev) => {
      const had = prev[kind].includes(id)
      if (had === claimed) return prev
      const ids = claimed ? [...prev[kind], id] : prev[kind].filter((x) => x !== id)
      return { ...prev, [kind]: ids }
    })
  }, [])
  const apiOwner = claims.api.at(-1) ?? null
  const helpOwner = claims.help.at(-1) ?? null
  const host = useMemo<DetailHeaderHost>(
    () => ({ apiSlot, helpSlot, apiOwner, helpOwner, claim }),
    [apiSlot, helpSlot, apiOwner, helpOwner, claim],
  )
  const state = useMemo(
    () => ({ host, setApiSlot, setHelpSlot, fallbackHelp, actions }),
    [host, fallbackHelp, actions],
  )
  return <DetailHeaderContext.Provider value={state}>{children}</DetailHeaderContext.Provider>
}

/** The nearest stack's detail header, or null outside any stack. */
export function useDetailHeader(): DetailHeaderHost | null {
  return useContext(DetailHeaderContext)?.host ?? null
}

/** Whether a stack's detail header is mounted above — false on a bare page, where a view's header
 *  controls render inline instead. */
export function useHasDetailHeader(): boolean {
  return useContext(DetailHeaderContext) !== null
}

/**
 * Put `children` (one of the detail header's controls) in the nearest stack's detail header, in
 * the slot for `kind`. It claims that slot and portals in while it holds the claim — nothing at all
 * while a later claimant holds it, so one header never shows two API buttons. Outside any stack it
 * renders `children` inline, where it was declared.
 */
export function DetailHeaderPortal({ kind, children }: { kind: DetailHeaderKind; children: ReactNode }) {
  const header = useDetailHeader()
  const claim = header?.claim
  const id = useId()
  useEffect(() => {
    if (!claim) return
    claim(id, kind, true)
    return () => claim(id, kind, false)
  }, [claim, id, kind])
  if (!header) return <>{children}</>
  const owner = kind === "api" ? header.apiOwner : header.helpOwner
  const slot = kind === "api" ? header.apiSlot : header.helpSlot
  return owner === id && slot ? createPortal(children, slot) : null
}

/** The header's right-hand group: the stack's own `actions` (if any), the API slot, then the help
 *  slot on the far right — the pair always drawn, each holding its fallback until a pane claims it. */
function DetailHeaderSlots() {
  const state = useContext(DetailHeaderContext)
  if (!state) {
    return (
      <>
        <DisabledApiButton />
        <DisabledHelpButton />
      </>
    )
  }
  const { host, setApiSlot, setHelpSlot, fallbackHelp, actions } = state
  return (
    <>
      {/* Its own box, not a bare sibling: a host's server-rendered node arrives here as a child of
          a client component, and React flagged it as a keyless list child beside the two slots. */}
      {actions !== undefined && actions !== null && actions !== false && (
        <div data-adh-detail-actions="" className="flex items-center gap-1">
          {actions}
        </div>
      )}
      <div data-adh-detail-api-slot="" ref={setApiSlot} className="flex items-center">
        {host.apiOwner === null && <DisabledApiButton />}
      </div>
      <div data-adh-detail-help-slot="" ref={setHelpSlot} className="flex items-center">
        {host.helpOwner === null && (fallbackHelp ?? <DisabledHelpButton />)}
      </div>
    </>
  )
}

/**
 * The detail pane's top strip — the ONE header row of a details view, level with the rails'
 * titled headers. Left to right: the stack's own control for the detail (a cover toggle or Back)
 * and its other controls, the detail's title, then the view's API button and its "?" help on the far right. The pair is
 * always there: a pane portals its own in (see {@link DetailHeaderPortal}), and what nothing has
 * claimed is drawn disabled.
 */
export function DetailHeaderRow({
  lead,
  leadCell = false,
  tools,
  title,
}: {
  /** The stack's control for the detail: a cover toggle or a Back button. */
  lead?: ReactNode
  /** Seat `lead` in a fixed square cell, so a cover toggle lines up with the rails' toggles. */
  leadCell?: boolean
  /** The stack's other controls for the detail, beside `lead` (the `<<< | >>>` cover-all). */
  tools?: ReactNode
  /** Names what the detail is showing: the stack's strip title (detail-title.tsx `detailStripTitle`), whose
   *  cell is a pane's hoisted title or the stack's own. */
  title?: DetailStripTitle
}) {
  const hasLead = lead !== undefined && lead !== null && lead !== false
  return (
    <div
      data-slot="detail-header"
      className={cn(
        "flex min-h-[2.15rem] shrink-0 items-center gap-2 border-b border-apt-border bg-apt-nav",
        leadCell && hasLead ? "pr-2" : "px-2",
      )}
    >
      {hasLead &&
        (leadCell ? <div className="flex w-8 shrink-0 items-center justify-center">{lead}</div> : lead)}
      {tools}
      {/* The cell is always mounted when given — it holds the slot a pane's title portals into. */}
      {title ? title.cell : <span className="min-w-0 flex-1" />}
      <div className="flex shrink-0 items-center gap-1">
        <DetailHeaderSlots />
      </div>
    </div>
  )
}
