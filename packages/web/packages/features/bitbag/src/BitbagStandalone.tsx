'use client'

import { BitbagDock, type BitbagDockProps } from './BitbagDock'

export type BitbagStandaloneProps = BitbagDockProps

/** The class bitbag-dock.css parks the standalone mount by. Exported for the test. */
export const STANDALONE_CLASS = 'bb-dock--standalone'

/**
 * bitbag on a page that has NO bar of its own — the mounting for anywhere the adh
 * footer isn't.
 *
 * He has two homes and they have to agree. In the adh footer (`FooterChatInner`)
 * the bar keeps a slot for his resting face and parks him in it, lifted a little
 * so he reads as sitting in the bar; on a page without the footer there is no bar,
 * no slot and nothing to measure — but he must end up in the SAME place on the
 * screen, or a site whose pages mix the two (fishlamp.com: its marketing page bare,
 * its app pages on the footer) shows a bitbag who shifts between pages. A bare
 * `BitbagDock` doesn't do that: its rest is the neutral one, flush to the edge, and
 * the lift is the footer's to add.
 *
 * So this is where that lift is applied for a footerless page — by ONE class,
 * `.bb-dock--standalone`, whose rule in bitbag-dock.css reads the same
 * `--bb-dock-parked-lift` the footer reads. The number lives in that stylesheet,
 * once; neither mounting states it. Horizontally he rests at the centre, which is
 * the dock's own fallback and where the footer puts him too when its bar has room.
 *
 * Everything else is `BitbagDock`'s, passed straight through: theme, backend, size,
 * rest, and a `className` of the host's own alongside this one. Mount it client-only
 * from the host's side (`next/dynamic` with `ssr: false` on a Next.js site): the
 * chat stamps dates and ids at render time and the avatar runs gsap timelines,
 * neither of which survives hydration. That loader is the host's, because this
 * package has no framework dependency to put it in.
 */
export function BitbagStandalone({ className, ...dock }: BitbagStandaloneProps) {
  return <BitbagDock {...dock} className={[STANDALONE_CLASS, className].filter(Boolean).join(' ')} />
}
