import type { ReactElement, ReactNode } from 'react'

/**
 * A titled group of links in the drawer, for `NavChrome`'s `sections` or its foot: a small
 * caption over the host's own anchors. Give an anchor `lp-nav` to draw it as a drawer row;
 * in the foot, a plain anchor reads as the foot's links do. Not a client module: it holds no
 * state, so a server host can render it too.
 */
export function NavSection({ title, children }: { title: string; children: ReactNode }): ReactElement {
  return (
    <section className="lp-nav-section" aria-label={title}>
      <h2 className="lp-nav-heading">{title}</h2>
      {children}
    </section>
  )
}
