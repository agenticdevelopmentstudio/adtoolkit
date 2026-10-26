import type { ReactElement, ReactNode } from 'react'

/**
 * One tile in a `Cards` grid: a heading and whatever prose follows it.
 *
 * The optional `kicker` is the small label above the heading. It is a separate
 * slot rather than part of `title` because it does a different job: the heading
 * names the thing, the kicker says what KIND of thing it is — "Preview", "The
 * gate", "23 specialists". Folding one into the other sets them at the same
 * weight, which is the distinction the label exists to make.
 *
 * `icon` is an image URL drawn inside the `<h3>`, before the title. Its `alt`
 * is empty: the title beside it already names the thing, and a screen reader
 * would otherwise read the name twice.
 */
export function Card({
  kicker,
  icon,
  title,
  children,
}: {
  kicker?: ReactNode
  icon?: string
  title: ReactNode
  children: ReactNode
}): ReactElement {
  return (
    <div className="lp-card">
      {kicker === undefined ? null : <span className="lp-card__kicker">{kicker}</span>}
      <h3>
        {icon === undefined ? null : <img className="lp-card__icon" src={icon} alt="" />}
        {title}
      </h3>
      {children}
    </div>
  )
}
