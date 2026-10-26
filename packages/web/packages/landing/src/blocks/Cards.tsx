import type { ReactElement, ReactNode } from 'react'

/**
 * The grid a `Card` sits in. `pair` and `trio` swap the shared `auto-fit` floor
 * for an explicit two- or three-column track once the caller has exactly the
 * item count that wants it — see the `--pair` rule in css/blocks.css for why
 * that has to be an explicit count rather than a wider floor. `trio` is the
 * same argument at nine items: `auto-fit` lays nine cards out as 4 + 4 + 1 at
 * the full measure, and a trailing row of one reads as something having gone
 * wrong rather than as the ninth item.
 *
 * `wide` is one card per row at every width, for cards whose bodies run to a
 * paragraph or more: at a third of the measure such a body is a narrow column
 * many times taller than its neighbours' headings.
 *
 * Passing more than one is a caller error, not a cascade puzzle: all three set
 * the same property, so which one won would depend on stylesheet order.
 */
export function Cards({
  children,
  pair,
  trio,
  wide,
  className,
}: {
  children: ReactNode
  pair?: boolean
  trio?: boolean
  wide?: boolean
  className?: string
}): ReactElement {
  if ([pair, trio, wide].filter((f) => f === true).length > 1) {
    throw new Error('Cards: `pair`, `trio` and `wide` set the same column track — pass at most one')
  }
  const cls = [
    'lp-cards',
    pair === true ? 'lp-cards--pair' : '',
    trio === true ? 'lp-cards--trio' : '',
    wide === true ? 'lp-cards--wide' : '',
    className,
  ]
    .filter(Boolean)
    .join(' ')
  return <div className={cls}>{children}</div>
}
