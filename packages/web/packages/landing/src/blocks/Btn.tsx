import type { ReactElement, ReactNode } from 'react'

/**
 * A pill-shaped call-to-action link. `primary` (the default) is filled with
 * `--lp-accent` and the one the page wants clicked first; `ghost` is outlined
 * only.
 *
 * `size="lg"` is for a button that IS the page's point — a download, say —
 * rather than one route among several; it is bigger in every direction, not
 * just wider. `detail` is a second, smaller line under the label for the one
 * fact a reader wants before clicking (a file size, a format), so it is read
 * as part of the button rather than hunted for in the prose around it. Like
 * the label it is uppercased by the stylesheet, so a host must keep product
 * names out of both.
 */
export function Btn({
  href,
  variant = 'primary',
  size = 'md',
  detail,
  children,
}: {
  href: string
  variant?: 'primary' | 'ghost'
  size?: 'md' | 'lg'
  detail?: ReactNode
  children: ReactNode
}): ReactElement {
  const cls = [
    'lp-btn',
    `lp-btn--${variant}`,
    size === 'lg' ? 'lp-btn--lg' : '',
    detail !== undefined ? 'lp-btn--detailed' : '',
  ]
    .filter(Boolean)
    .join(' ')
  return (
    <a className={cls} href={href}>
      {detail !== undefined ? (
        <>
          <span className="lp-btn__label">{children}</span>
          <span className="lp-btn__detail">{detail}</span>
        </>
      ) : (
        children
      )}
    </a>
  )
}
