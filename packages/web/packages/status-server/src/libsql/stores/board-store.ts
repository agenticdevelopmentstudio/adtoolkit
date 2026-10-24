import {
  and, desc, eq, getTableColumns, gte, inArray, isNotNull, isNull, lt, lte, or, sql,
} from "drizzle-orm";
import type { SQL } from "drizzle-orm";
import type { Db } from "../client";
import {
  deployProjectMeta, deployments, errors, issues, monitoredEndpoints, monitoredSites, platformHealthState,
  vercelProdState,
} from "../schema";
import { outcomeBinSql } from "../../monitor/deploy-status";
import type { BuildPhase, DeployPhase } from "../../monitor/deploy-status";
import type { IssueSource } from "../../monitor/issue-sources";
import { ownedDeploysWhere } from "./owned-deploys";
import { MAX_ACTIVITY_ROWS, MAX_ERROR_FACTS } from "../../board/types";
import type {
  DeployFact, ErrorFact, IssueEvent, LedgerEntry, PlatformFact, RosterEntry, StaleProdFact,
} from "../../board/types";
import type { BoardStore, OwnedProjects, PageCursor, SourcePage } from "../../storage/ports";

// The libSQL implementation of `BoardStore`. Bodies moved verbatim from
// `board/facts.ts` — the query halves only; the pure fold logic (`binByOutcome`,
// `deriveBoard`, `deriveActivity`, `monitoredTargets`) stays in `src/board/` and
// calls these methods for its facts.

/** The two outcome bins — see `outcomeBinSql`, which also defines the partial index each
 *  one seeks (`idx_deploy_concluded_latest`, `idx_deploy_inflight_latest`). */
const CONCLUDED = sql.raw(outcomeBinSql("concluded"));
const IN_FLIGHT = sql.raw(outcomeBinSql("in-flight"));

/** A Vercel row with no environment target is a PREVIEW/branch build — see
 *  `isRealEnvDeployRow` (`monitor/deploy-view.ts`), spelled for the planner. */
const NOT_PREVIEW = sql`not (${deployments.platform} = 'vercel' and (${deployments.environment} is null or ${deployments.environment} = ''))`;

/**
 * The newest row of every (platform, project, environment) group in one outcome bin, in
 * ascending group order — what `GROUP BY platform, project_name, environment` with
 * `max(created_at)` returned, without reading every row the bin holds.
 *
 * A skip scan over the bin's partial index, which is keyed (platform, project_name,
 * environment, created_at, id): walking it DESCENDING, the first entry of each group is
 * that group's newest row, and the next group is found by seeking strictly below the
 * current one. Each step is one `limit 1` seek, so a read costs one seek per deploy target
 * (plus at most two misses) however much history the table keeps; the GROUP BY it replaces
 * read all of it, on every board read. Within a group, rows tied on `created_at` resolve
 * to the larger id.
 *
 * `environment` is nullable and NULL sorts LAST descending, so below a non-null
 * environment the same project still has its NULL-environment group to visit.
 */
async function latestPerTarget(db: Db, bin: SQL): Promise<(typeof deployments.$inferSelect)[]> {
  const newest = async (...below: SQL[]) =>
    (
      await db
        .select()
        .from(deployments)
        .where(and(bin, ...below))
        .orderBy(
          desc(deployments.platform), desc(deployments.projectName), desc(deployments.environment),
          desc(deployments.createdAt), desc(deployments.id),
        )
        .limit(1)
    )[0];
  const out: (typeof deployments.$inferSelect)[] = [];
  let row = await newest();
  while (row) {
    out.push(row);
    const { platform: p, projectName: n, environment: e } = row;
    const sameProject = [eq(deployments.platform, p), eq(deployments.projectName, n)];
    row =
      (e !== null ? await newest(...sameProject, lt(deployments.environment, e)) : undefined) ??
      (e !== null ? await newest(...sameProject, isNull(deployments.environment)) : undefined) ??
      (await newest(eq(deployments.platform, p), lt(deployments.projectName, n))) ??
      (await newest(lt(deployments.platform, p)));
  }
  return out.reverse();
}

/** One `deployments` row → one `DeployFact`. */
function toDeployFact(d: typeof deployments.$inferSelect): DeployFact {
  return {
    deploymentId: d.id,
    platform: d.platform,
    providerProjectId: d.providerProjectId,
    projectName: d.projectName,
    environment: d.environment,
    branch: d.branch,
    buildPhase: d.buildPhase as BuildPhase | null,
    deployPhase: d.deployPhase as DeployPhase,
    createdAtMs: d.createdAt.getTime(),
    commitHash: d.commitHash,
    commitMessage: d.commitMessage,
    commitRepo: d.commitRepo,
    errorText: d.errorText,
    sourceUrl: d.url,
    liveUrl: d.liveHost ? `https://${d.liveHost}` : null,
  };
}

/** One `issues` row → one `IssueEvent`. */
function toIssueEvent(r: typeof issues.$inferSelect): IssueEvent {
  return {
    id: r.id,
    target: r.target,
    source: r.source as IssueSource,
    name: r.name,
    environment: r.environment,
    state: r.state,
    severity: r.severity as IssueEvent["severity"],
    detail: r.detail,
    sourceUrl: r.sourceUrl,
    liveUrl: r.liveUrl,
    commitHash: r.commitHash,
    commitMessage: r.commitMessage,
    commitRepo: r.commitRepo,
    openedAtMs: r.openedAt.getTime(),
    resolvedAtMs: r.resolvedAt?.getTime() ?? null,
    resolvedReason: r.resolvedReason === "recovered" || r.resolvedReason === "unmonitored" ? r.resolvedReason : null,
  };
}

/** One paged source read, with the tie group its LIMIT cut through completed — see
 *  `board/facts.ts`'s original doc comment on `readSourcePage` for the full reasoning. */
async function readSourcePage<T>(spec: {
  limit: number;
  page: T[];
  tsOf: (row: T) => number;
  readInstant: (ms: number) => Promise<T[]>;
}): Promise<SourcePage<T>> {
  const { limit, page, tsOf, readInstant } = spec;
  if (page.length < limit) return { rows: page, floorMs: null };
  const boundary = tsOf(page[page.length - 1]!);
  const complete = await readInstant(boundary);
  return { rows: [...page.filter((r) => tsOf(r) > boundary), ...complete], floorMs: boundary };
}

/** `PageCursor` → the `lt`/`lte` predicate on one timestamp column, or undefined when
 *  the cursor is the start of the feed. `strict` mirrors the empty-id sentinel a
 *  stalled page mints: no real row can satisfy `<` at its own instant, so a strict
 *  cursor excludes the whole tied second instead of re-serving it forever. */
function beforePredicate(
  col: typeof deployments.createdAt | typeof issues.openedAt | typeof issues.resolvedAt,
  cursor: PageCursor,
): SQL | undefined {
  if (cursor.beforeMs == null) return undefined;
  const before = new Date(cursor.beforeMs);
  return cursor.strict ? lt(col, before) : lte(col, before);
}

export function createBoardStore(db: Db): BoardStore {
  return {
    async readRoster(): Promise<RosterEntry[]> {
      return db
        .select({
          endpointId: monitoredEndpoints.id,
          label: monitoredSites.name,
          platform: monitoredEndpoints.platform,
          projectName: monitoredEndpoints.deployProject,
          providerProjectId: monitoredEndpoints.deployProjectId,
          environment: monitoredEndpoints.environment,
          isActive: monitoredEndpoints.isActive,
          monitorHttp: monitoredEndpoints.monitorHttp,
          monitorDeploys: monitoredEndpoints.monitorDeploys,
          ignoreProjectWarning: monitoredEndpoints.ignoreProjectWarning,
          url: monitoredEndpoints.url,
        })
        .from(monitoredEndpoints)
        .innerJoin(monitoredSites, eq(monitoredEndpoints.siteId, monitoredSites.id));
    },

    async readDeployOutcomeCandidates(): Promise<DeployFact[]> {
      // Two indexed pre-filters (concluded vs. in-flight), concatenated — `binByOutcome`
      // (pure, in `board/facts.ts`) re-derives the authoritative partition from
      // `combinedStatus` itself, so these predicates only decide what is worth READING.
      const concludedRows = await latestPerTarget(db, CONCLUDED);
      const inFlightRows = await latestPerTarget(db, IN_FLIGHT);
      return [...concludedRows.map(toDeployFact), ...inFlightRows.map(toDeployFact)];
    },

    async readDeployEvents(sinceMs: number, owned: OwnedProjects): Promise<DeployFact[]> {
      const ownership = ownedDeploysWhere(owned);
      if (!ownership) return [];
      const rows = await db
        .select()
        .from(deployments)
        .where(and(gte(deployments.createdAt, new Date(sinceMs)), NOT_PREVIEW, ownership))
        .orderBy(desc(deployments.createdAt))
        .limit(MAX_ACTIVITY_ROWS);
      return rows.map(toDeployFact);
    },

    async readIssueEvents(sinceMs: number): Promise<IssueEvent[]> {
      const rows = await db
        .select()
        .from(issues)
        .where(or(gte(issues.openedAt, new Date(sinceMs)), gte(issues.resolvedAt, new Date(sinceMs))))
        .orderBy(desc(sql`max(${issues.openedAt}, coalesce(${issues.resolvedAt}, 0))`))
        .limit(MAX_ACTIVITY_ROWS);
      return rows.map(toIssueEvent);
    },

    async readOpenIssueTargets(): Promise<LedgerEntry[]> {
      const rows = await db
        .select({ target: issues.target, openedAt: issues.openedAt })
        .from(issues)
        .where(isNull(issues.resolvedAt));
      return rows.map((r) => ({ target: r.target, openedAtMs: r.openedAt.getTime() }));
    },

    async readPlatformFacts(): Promise<PlatformFact[]> {
      const rows = await db.select().from(platformHealthState);
      return rows.map((p) => ({
        source: p.source as IssueSource,
        configured: p.configured,
        ok: p.reachable,
        streak: p.consecutiveFailures,
        sampledAtMs: p.updatedAt.getTime(),
      }));
    },

    async readStaleProdFacts(): Promise<StaleProdFact[]> {
      const rows = await db
        .select({ s: getTableColumns(vercelProdState), branch: deployProjectMeta.gitBranch })
        .from(vercelProdState)
        .leftJoin(
          deployProjectMeta,
          and(eq(deployProjectMeta.platform, "vercel"), eq(deployProjectMeta.projectName, vercelProdState.projectName)),
        )
        .where(eq(vercelProdState.stale, true));
      return rows.map(({ s, branch }) => ({
        platform: "vercel",
        providerProjectId: null,
        projectName: s.projectName,
        environment: null,
        branch,
        detail: s.detail,
        sourceUrl: s.sourceUrl,
        liveUrl: s.liveUrl,
      }));
    },

    async readErrorFacts(): Promise<ErrorFact[]> {
      const rows = await db
        .select()
        .from(errors)
        .where(eq(errors.resolved, false))
        .orderBy(desc(errors.lastSeen), desc(errors.issueKey))
        .limit(MAX_ERROR_FACTS);
      return rows.map((r) => ({
        issueKey: r.issueKey,
        project: r.project,
        title: r.title,
        culprit: r.culprit,
        level: r.level,
        count: r.count,
        userCount: r.userCount,
        firstSeenMs: r.firstSeen?.getTime() ?? null,
        lastSeenMs: r.lastSeen?.getTime() ?? null,
        permalink: r.permalink,
      }));
    },

    async readDeployActivityPage(cursor: PageCursor, owned: OwnedProjects): Promise<SourcePage<DeployFact>> {
      const ownership = ownedDeploysWhere(owned);
      if (!ownership) return { rows: [], floorMs: null };
      const deployOwnership = and(NOT_PREVIEW, ownership);
      const page = await db
        .select()
        .from(deployments)
        .where(and(beforePredicate(deployments.createdAt, cursor), deployOwnership))
        .orderBy(desc(deployments.createdAt))
        .limit(cursor.limit);
      const { rows, floorMs } = await readSourcePage({
        limit: cursor.limit,
        page,
        tsOf: (r) => r.createdAt.getTime(),
        readInstant: (ms) =>
          db.select().from(deployments).where(and(eq(deployments.createdAt, new Date(ms)), deployOwnership)),
      });
      return { rows: rows.map(toDeployFact), floorMs };
    },

    async readIssueOpenedPage(cursor: PageCursor, targets: string[]): Promise<SourcePage<IssueEvent>> {
      const issueOwnership: SQL = targets.length > 0 ? inArray(issues.target, targets) : sql`0`;
      const page = await db
        .select()
        .from(issues)
        .where(and(beforePredicate(issues.openedAt, cursor), issueOwnership))
        .orderBy(desc(issues.openedAt))
        .limit(cursor.limit);
      const { rows, floorMs } = await readSourcePage({
        limit: cursor.limit,
        page,
        tsOf: (r) => r.openedAt.getTime(),
        readInstant: (ms) => db.select().from(issues).where(and(eq(issues.openedAt, new Date(ms)), issueOwnership)),
      });
      return { rows: rows.map(toIssueEvent), floorMs };
    },

    async readIssueResolvedPage(cursor: PageCursor, targets: string[]): Promise<SourcePage<IssueEvent>> {
      const issueOwnership: SQL = targets.length > 0 ? inArray(issues.target, targets) : sql`0`;
      const page = await db
        .select()
        .from(issues)
        .where(and(isNotNull(issues.resolvedAt), beforePredicate(issues.resolvedAt, cursor), issueOwnership))
        .orderBy(desc(issues.resolvedAt))
        .limit(cursor.limit);
      const { rows, floorMs } = await readSourcePage({
        limit: cursor.limit,
        page,
        tsOf: (r) => r.resolvedAt!.getTime(),
        readInstant: (ms) => db.select().from(issues).where(and(eq(issues.resolvedAt, new Date(ms)), issueOwnership)),
      });
      return { rows: rows.map(toIssueEvent), floorMs };
    },
  };
}
