"use client"

import * as React from "react"
import { Input } from "@agenticdevelopertoolkit/ui/components/input"
import { Label } from "@agenticdevelopertoolkit/ui/components/label"
import { cn } from "@agenticdevelopertoolkit/ui/lib/utils"

/** An inclusive calendar-day range, both ends `YYYY-MM-DD`. */
export interface DateRange {
  from: string
  to: string
}

export interface DateRangePickerProps {
  value: DateRange
  onChange: (range: DateRange) => void
  /** Earliest selectable day (`YYYY-MM-DD`). */
  min?: string
  /** Latest selectable day (`YYYY-MM-DD`). */
  max?: string
  className?: string
}

/**
 * Two native date fields, From and To. Native rather than a calendar popover: the
 * browser's own picker is keyboard- and screen-reader-complete for free. Each end
 * bounds the other (`from` can't pass `to`), so the range can't be inverted from
 * the UI; a cleared field is ignored rather than reported as an empty day.
 */
export function DateRangePicker({ value, onChange, min, max, className }: DateRangePickerProps) {
  const id = React.useId()
  const set = (end: keyof DateRange) => (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.value === "") return
    onChange({ ...value, [end]: e.target.value })
  }
  return (
    <div className={cn("flex flex-wrap items-end gap-3", className)}>
      <div className="flex flex-col gap-1.5">
        <Label htmlFor={`${id}-from`}>From</Label>
        <Input
          id={`${id}-from`}
          type="date"
          className="w-auto"
          value={value.from}
          min={min}
          max={value.to}
          onChange={set("from")}
        />
      </div>
      <div className="flex flex-col gap-1.5">
        <Label htmlFor={`${id}-to`}>To</Label>
        <Input
          id={`${id}-to`}
          type="date"
          className="w-auto"
          value={value.to}
          min={value.from}
          max={max}
          onChange={set("to")}
        />
      </div>
    </div>
  )
}
