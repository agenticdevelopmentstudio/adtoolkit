"use client"

import { useSyncExternalStore } from "react"

const subscribe = () => () => {}

/**
 * An inline script that belongs to the document load: emitted in the server's HTML, where the
 * browser runs it before first paint, and absent from any tree React mounts on the client.
 *
 * A pre-paint script only does its job in the document the server sent. A layout React mounts
 * on a client navigation (the hub's route group, entered from the site template's `/`) would
 * otherwise create the `<script>` element anyway, where it never executes, and React reports it
 * ("Encountered a script tag while rendering React component"). The client-side half of that job
 * belongs to whoever runs then; for the appearance prefs that is `AppearanceScope`.
 *
 * The server snapshot answers `true` for the server render and for hydration, so the hydrated
 * node matches the HTML; the client snapshot answers `false`, so a fresh mount renders nothing,
 * and after hydration the already-run script leaves the tree.
 *
 * Trusted, static code only: `code` goes into the page as-is.
 */
export function DocumentLoadScript({ code }: { code: string }) {
  const inServerHtml = useSyncExternalStore(subscribe, () => false, () => true)
  return inServerHtml ? <script dangerouslySetInnerHTML={{ __html: code }} /> : null
}
