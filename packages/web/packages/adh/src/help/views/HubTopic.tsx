'use client'

import { siteProdUrl, siteUrl } from '@agentic-toolkit/adh-registry'

import { useClientHost } from '../../header/useClientHost'

// The Hub Features help topic, as shown in the MODAL. The document itself is the help site's own
// surface (help.adh.com/hub): it is built there, with content-buildr, out of a content tree that
// lives in that site's repo and is read by nothing in this package. So from the modal (mounted on
// every site) we link out to it rather than carry a second copy of a document this package cannot
// build. On the SSR help site the same `hub` topic is served by the site's `/hub` route.
//
// The link follows the visitor's environment the way the header's cross-site links do (same
// `useClientHost` seam): a staging or local-dev visitor lands on THEIR help site, not production's.
// Until the host is known the production URL stands in, so the server and first client render agree.
const HUB_PATH = '/hub'

export function HubTopic() {
  const host = useClientHost()
  // `useClientHost` returns host:port on local dev; siteUrl wants the bare hostname.
  const hostname = host?.split(':')[0]
  const href = hostname ? siteUrl('hub-help', HUB_PATH, hostname) : siteProdUrl('hub-help', HUB_PATH)
  return (
    <div className="adh-help-topic adh-help-topic--hub">
      <div className="flex flex-col items-center gap-2 text-center">
        <p>Every feature of the Agentic Developer Hub, described one at a time.</p>
        <a href={href} target="_blank" rel="noreferrer" className="adh-help-topic__link">
          Open Hub Features →
        </a>
      </div>
    </div>
  )
}
