import type { ReactElement } from 'react'

/**
 * A horizontal rule drawn in the accent, slowly breathing — the hairline under a hero's name.
 * blocks.css's `.lp-pulse-rule` draws it; `--lp-pulse-rule-period` and `--lp-pulse-rule-floor`
 * slow it or deepen it, set on the element.
 *
 * `className` is appended, not replaced: placement (width, margins) is the caller's, how the rule
 * LOOKS is this component's. A server component — the breathing is a CSS animation.
 */
export function PulseRule({ className }: { className?: string }): ReactElement {
  return <hr className={className ? `lp-pulse-rule ${className}` : 'lp-pulse-rule'} />
}
