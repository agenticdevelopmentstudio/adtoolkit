"use client"

import type { ReactElement } from "react"

import { ChevronLeft, ChevronRight } from "lucide-react"

import { cn } from "../lib/utils"

/** Three chevrons, overlapped so they read as one `<<<` / `>>>` glyph (lucide has no triple). */
function TripleChevron({ dir }: { dir: "left" | "right" }): ReactElement {
  const Icon = dir === "left" ? ChevronLeft : ChevronRight
  return (
    <span aria-hidden className="flex items-center">
      <Icon size={14} className="shrink-0" />
      <Icon size={14} className="-ml-2 shrink-0" />
      <Icon size={14} className="-ml-2 shrink-0" />
    </span>
  )
}

const half =
  "flex items-center px-1 py-0.5 text-apt-text-muted outline-none hover:text-apt-text focus-visible:ring-2 focus-visible:ring-apt-gold/40 disabled:cursor-default disabled:opacity-35 disabled:hover:text-apt-text-muted"

/**
 * The two-part `<<< | >>>` control a wide stack's detail header carries beside its `«`/`»` cover
 * toggle: `<<<` covers every list, `>>>` uncovers every list. Each half is enabled only when
 * clicking it would visibly change the stack (Mike: "each should only be enabled if clicking the
 * button will produce a result") — the stack decides that, since only it knows which covers are
 * the user's pins and which are width pressure a click cannot lift.
 */
export function CoverAllControl({
  canCollapse,
  canExpand,
  onCollapseAll,
  onExpandAll,
}: {
  canCollapse: boolean
  canExpand: boolean
  onCollapseAll: () => void
  onExpandAll: () => void
}): ReactElement {
  return (
    <div
      role="group"
      aria-label="Collapse or expand all lists"
      data-htd-cover-all
      className="flex shrink-0 items-center rounded border border-apt-border"
    >
      <button
        type="button"
        onClick={onCollapseAll}
        disabled={!canCollapse}
        aria-label="Collapse all lists"
        title="Collapse all lists"
        className={cn(half, "rounded-l")}
      >
        <TripleChevron dir="left" />
      </button>
      <span aria-hidden className="h-4 w-px bg-apt-border" />
      <button
        type="button"
        onClick={onExpandAll}
        disabled={!canExpand}
        aria-label="Expand all lists"
        title="Expand all lists"
        className={cn(half, "rounded-r")}
      >
        <TripleChevron dir="right" />
      </button>
    </div>
  )
}
