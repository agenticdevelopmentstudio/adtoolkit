import { and, eq, inArray, or } from "drizzle-orm";
import type { SQL } from "drizzle-orm";
import { deployments } from "../schema";
import type { OwnedProjects } from "../../storage/ports";

// Shared between `board-store.ts` (the activity/deploy-event reads) and
// `deploy-store.ts` (`listRecentOwned`, the Deployments-tab feed) — both need
// the SAME SQL pre-filter over `deployments` for "does some live site monitor
// this row's project", so it lives once, here, rather than as two copies of
// the same WHERE clause drifting apart.

/** The raw platform spellings each canonical platform can appear under in `deployments`. */
const PLATFORM_SPELLINGS: [canon: string, raw: string[]][] = [
  ["vercel", ["vercel"]],
  ["railway", ["railway"]],
  ["cloudflare", ["cloudflare", "cloudflare-pages"]],
];

/**
 * A SQL PRE-FILTER that narrows `deployments` to rows some live site monitors. Not an
 * optimisation — a poll upserts a row for EVERY project the tokens can see, most
 * monitored by no site, so a limit spent before this narrowing can strand the newest
 * event for an owned target outside the window entirely.
 *
 * Deliberately a SUPERSET, not the authoritative rule: it matches EITHER spelling of a
 * monitored project's identity (provider id or name), because a row written before a
 * rename carries the old name and one written after carries the new one, and both
 * belong to the same monitored project. The TypeScript ownership rule (`board/ownership.ts`)
 * runs afterwards and is what actually decides; this only bounds what gets read.
 *
 * Crunchy clusters aren't site-bound and are always included.
 */
export function ownedDeploysWhere(projects: OwnedProjects): SQL | undefined {
  // A FLAT OR of (platform, project) pairs, one arm per spelling, rather than
  // `platform in … and (name in … or id in …)`. Same rows; but each flat arm is exactly
  // the prefix of one index (`idx_deploy_project_created`, `idx_deploy_provider_created`),
  // so SQLite seeks every arm and unions them instead of walking `idx_deploy_created`
  // past every unowned row until the limit fills.
  const clauses: SQL[] = [eq(deployments.platform, "crunchy")];
  for (const [canon, raw] of PLATFORM_SPELLINGS) {
    const bucket = projects.get(canon);
    if (!bucket) continue;
    if (bucket.names.size > 0) {
      clauses.push(and(inArray(deployments.platform, raw), inArray(deployments.projectName, [...bucket.names]))!);
    }
    if (bucket.ids.size > 0) {
      clauses.push(and(inArray(deployments.platform, raw), inArray(deployments.providerProjectId, [...bucket.ids]))!);
    }
  }
  return or(...clauses);
}
