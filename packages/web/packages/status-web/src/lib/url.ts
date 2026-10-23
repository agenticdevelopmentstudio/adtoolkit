import { endpointHasUrl } from "@agentic-toolkit/deploy-platform/engine";

export function hostOf(url: string): string {
  try {
    return new URL(url).host;
  } catch {
    return url;
  }
}

/** What to call a monitored endpoint on screen: its host, or — for a deploy-only monitor,
 *  whose URL is a placeholder with no host — its name, marked as such. */
export function endpointLabel(e: { url: string; name: string }): string {
  return endpointHasUrl(e.url) ? hostOf(e.url) : `${e.name} · deploys only`;
}

/** The name a 1:1 site takes from its endpoint's URL — the host — or null for a
 *  deploy-only monitor, whose site keeps its project name (renaming it to the
 *  placeholder would leave a site called "https://"). */
export function siteNameForUrl(url: string): string | null {
  return endpointHasUrl(url) ? hostOf(url) : null;
}
