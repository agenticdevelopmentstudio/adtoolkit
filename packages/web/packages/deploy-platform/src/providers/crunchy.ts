import { noteRateLimited, rateLimitedUntil } from "../cooldown/provider-cooldown.js";

/** One Crunchy Bridge cluster as `/clusters` returns it — the fields the deploy rows and
 *  the project enumeration read, nothing more. */
export interface CrunchyCluster {
  id: string;
  name: string;
  state: string;
  is_suspended?: boolean;
  environment?: string | null;
  created_at?: string | null;
}

/**
 * List EVERY cluster in the team (testing/staging/prod plus any future cluster or
 * replica). The ONE call both the deploy poll (`fetch-crunchy`) and the project
 * enumeration make, so a cluster the poll writes rows for is always one Auto Configure
 * can see. The raw `cbkey_` key is a direct Bearer token (no exchange).
 *
 * Null on ANY failure — a non-2xx, a network error, a malformed body, or a 429 cooldown
 * still running — so a caller can never read a failed listing as "no clusters". An abort
 * is the caller's own time box and is not logged here, the same rule as
 * `listRailwayProjects`.
 */
export async function listCrunchyClusters(token: string, signal: AbortSignal): Promise<CrunchyCluster[] | null> {
  if (rateLimitedUntil("crunchy")) return null; // cooling down after a 429
  try {
    const res = await fetch("https://api.crunchybridge.com/clusters", {
      headers: { Authorization: `Bearer ${token}` },
      signal,
    });
    if (!res.ok) {
      if (res.status === 429) noteRateLimited("crunchy", res.headers.get("retry-after"));
      console.error(`Crunchy /clusters ${res.status}`);
      return null;
    }
    const body = (await res.json()) as { clusters?: CrunchyCluster[] };
    return (body.clusters ?? []).filter((c) => c.id && c.name);
  } catch (err) {
    if (!signal.aborted) {
      console.error(`Crunchy /clusters fetch failed: ${err instanceof Error ? err.message : String(err)}`);
    }
    return null;
  }
}
