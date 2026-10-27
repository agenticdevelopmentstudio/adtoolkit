'use client'

import type { ReactElement } from 'react'
import dynamic from 'next/dynamic'
// ONE sheet: it parks the dock (fixed, bottom-centred, riding `--kb-inset`), paints the scrim
// behind an engaged chat, and `@import`s the persona-chat sheets itself.
import '@agentic-toolkit/bitbag/css/bitbag-dock.css'

// Client-only. The chat stamps each message with the time and mints ids at render, so a
// server render bakes the BUILD time into the transcript and hydration throws on the mismatch;
// the avatar runs gsap timelines that have no server-render value either. `BitbagStandalone`
// is bitbag's mounting for a page with no adh footer, and `next/dynamic` is the loader his own
// docs leave to the host — the template is that host for every content site.
const BitbagStandalone = dynamic(
  () => import('@agentic-toolkit/bitbag').then((m) => m.BitbagStandalone),
  { ssr: false },
)

/**
 * bitbag, docked at the foot of the window. The same on every content site, so the frame owns
 * him: a site mounts this once, beside the frame rather than inside `<main>`, because he is
 * fixed to the viewport and belongs to the page rather than to its content.
 */
export function SiteBitbag(): ReactElement {
  return <BitbagStandalone />
}
