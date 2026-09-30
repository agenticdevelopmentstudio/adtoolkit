"use client"

import type { ReactNode } from "react"
import { CircleHelp } from "lucide-react"

import { cn } from "../lib/utils"
import { quietControlClass } from "../lib/quiet-control"
import {
  Popover,
  PopoverTrigger,
  PopoverContent,
} from "../components/popover"
import { useDetailTitle } from "./detail-title"

// The /home content header: a gold-mono title (e.g. "All ecosystems"), an
// optional right-aligned "?" help popover, and an optional actions slot. Matches
// hub's FeatureTitle.
//
// `paneTitle` marks the header that NAMES THE PANE (not one of several sections inside it): inside
// a detail stack its title then moves up into the stack's detail strip (see detail-title.tsx —
// Mike: "the title should not be in the details pane"), leaving the eyebrow, actions and help here.
// Opt-in, because a pane like Authentication heads two sections with this same component.
export function SectionHeader({
  eyebrow,
  title,
  help,
  actions,
  className,
  paneTitle = false,
}: {
  eyebrow?: ReactNode
  title: ReactNode
  help?: ReactNode
  actions?: ReactNode
  className?: string
  paneTitle?: boolean
}) {
  const { hoisted, portal } = useDetailTitle(paneTitle ? title : null)
  if (hoisted && !eyebrow && !help && !actions) return portal
  return (
    <div className={cn("flex items-start justify-between gap-4", className)}>
      {portal}
      <div className="space-y-1">
        {eyebrow && (
          <div className="font-mono text-[0.65rem] uppercase tracking-wider text-apt-text-dim">
            {eyebrow}
          </div>
        )}
        {!hoisted && (
          <h2 className="font-mono text-sm font-medium tracking-wide text-apt-gold">
            {title}
          </h2>
        )}
      </div>
      <div className="flex shrink-0 items-center gap-2">
        {actions}
        {help && (
          <Popover>
            <PopoverTrigger
              aria-label="About this section"
              className={quietControlClass}
            >
              <CircleHelp size={16} />
            </PopoverTrigger>
            <PopoverContent side="bottom" align="end" className="w-72">
              {help}
            </PopoverContent>
          </Popover>
        )}
      </div>
    </div>
  )
}
