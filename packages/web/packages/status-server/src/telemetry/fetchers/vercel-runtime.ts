import type { Fetcher, FetchResult } from "../ports";
import {
  logEventToEntry,
  responseEventToEntry,
  RUNTIME_ERROR_WINDOW_MS,
  type RawRuntimeEvent,
  type RuntimeProject,
} from "../runtime-errors";
import type { RuntimeLogEntry } from "../types";
import {
  isProductionProject,
  listProjects,
  productionDomain,
  VercelHttpError,
  vercelGet,
  vercelRequest,
  type VercelEnv,
} from "../vercel-api";

// Vercel runtime errors, for what a site's server side throws and the browser never sees
// (GlitchTip only hears from the browser). Each read asks Vercel's Observability events API for
// the last 24 hours of every production project, twice:
//
//   POST /v1/observability/events   event: vercel.log             error/fatal log lines
//   POST /v1/observability/events   event: vercel.proxy_response  5xx responses
//
// Both queries are filtered and paged on Vercel's side, so a read is the whole window, not a
// sample of it. A read that could not be whole says so (`complete: false`): a query that hit the
// page cap, or one Vercel answered with excluded intervals. A read that failed returns `ok: false`
// and the store keeps the snapshot it had. PURE w.r.t. storage.

export interface VercelRuntimeOptions {
  /** How long the whole read may take. */
  overallBudgetMs?: number;
  /** Pages per query, of up to {@link MAX_PAGE_SIZE} events each. */
  maxPages?: number;
  /** The clock, for tests. */
  now?: () => number;
}

const OVERALL_BUDGET_MS = 45_000;
const MAX_PAGES = 10;
export const MAX_PAGE_SIZE = 1000;
const QUERY_REASON = { "x-vercel-observability-query-reason": "adh-status/runtime-errors" };

const LOG_SELECT = [
  "timestamp",
  "projectId",
  "deploymentId",
  "requestId",
  "requestPath",
  "requestMethod",
  "source",
  "level",
  "message",
  "domain",
];
const RESPONSE_SELECT = [
  "timestamp",
  "projectId",
  "deploymentId",
  "requestId",
  "requestPath",
  "requestMethod",
  "httpStatus",
  "requestHostname",
];
// `environment:"production"` also matches the staging and testing projects' own production
// environments; those are dropped by project id afterwards.
const LOG_FILTER = 'environment:"production" AND level:(error OR fatal) AND NOT source:ci';
const RESPONSE_FILTER = 'environment:"production" AND httpStatus >= 500 AND NOT pathType:"background_func"';

interface EventsBody {
  events?: unknown;
  pagination?: { hasMore?: unknown; nextCursor?: unknown };
  meta?: { excludedIntervals?: unknown };
}

interface Query {
  event: string;
  select: string[];
  filter: string;
}

interface QueryResult {
  events: RawRuntimeEvent[];
  /** Every matching event is in `events`. */
  whole: boolean;
}

const isResultTooLarge = (err: unknown): boolean =>
  err instanceof VercelHttpError && err.status === 413 && err.body.includes("result_too_large");

/**
 * One query's events, newest first, page by page. A page too large for Vercel to answer is asked
 * again at half the size, which then holds for the rest of the query.
 */
async function runQuery(
  env: VercelEnv,
  ownerId: string,
  projectIds: string[],
  range: { start: string; end: string },
  query: Query,
  maxPages: number,
  signal: AbortSignal,
): Promise<QueryResult> {
  const events: RawRuntimeEvent[] = [];
  let pageSize = MAX_PAGE_SIZE;
  let cursor: string | undefined;
  let whole = true;
  for (let page = 0; ; page++) {
    if (page === maxPages) return { events, whole: false };
    let body: EventsBody;
    for (;;) {
      try {
        const res = await vercelRequest(env, "/v1/observability/events", { teamId: ownerId }, signal, {
          headers: QUERY_REASON,
          json: {
            event: query.event,
            scope: { ownerId, projectIds },
            timeRange: range,
            select: query.select,
            filter: query.filter,
            order: "desc",
            limit: pageSize,
            ...(cursor ? { cursor } : {}),
          },
        });
        body = (await res.json()) as EventsBody;
        break;
      } catch (err) {
        if (!isResultTooLarge(err) || pageSize === 1) throw err;
        pageSize = Math.max(1, Math.floor(pageSize / 2));
      }
    }
    if (!Array.isArray(body.events)) throw new Error(`Vercel ${query.event}: no events in the answer`);
    events.push(...(body.events as RawRuntimeEvent[]));
    const excluded = body.meta?.excludedIntervals;
    if (Array.isArray(excluded) && excluded.length > 0) whole = false;
    const next = typeof body.pagination?.nextCursor === "string" ? body.pagination.nextCursor : null;
    if (body.pagination?.hasMore !== true) return { events, whole };
    // More matched but there is no usable cursor: stop rather than ask for the same page again.
    if (!next || next === cursor) return { events, whole: false };
    cursor = next;
  }
}

/** Whose events these are: the team, or, with no team configured, the token's own account. */
async function ownerIdOf(env: VercelEnv, signal: AbortSignal): Promise<string> {
  if (env.VERCEL_TEAM_ID) return env.VERCEL_TEAM_ID;
  const body = (await vercelGet(env, "/v2/user", {}, signal)) as { user?: { id?: unknown } };
  const id = body.user?.id;
  if (typeof id !== "string" || id === "") throw new Error("Vercel /v2/user: no user id");
  return id;
}

export function vercelRuntimeFetcher(env: VercelEnv, opts: VercelRuntimeOptions = {}): Fetcher<RuntimeLogEntry> {
  const overallBudgetMs = opts.overallBudgetMs ?? OVERALL_BUDGET_MS;
  const maxPages = opts.maxPages ?? MAX_PAGES;
  const now = opts.now ?? Date.now;
  return {
    async fetch(): Promise<FetchResult<RuntimeLogEntry>> {
      if (!env.VERCEL_API_TOKEN) return { ok: true, items: [] };
      // Every call of the read shares this one deadline, the project list included.
      const signal = AbortSignal.timeout(overallBudgetMs);
      try {
        const projects = new Map<string, RuntimeProject>();
        for (const p of await listProjects(env, signal)) {
          if (p.id && p.name && isProductionProject(p)) {
            projects.set(p.id, { name: p.name, domain: productionDomain(p) });
          }
        }
        if (projects.size === 0) return { ok: true, items: [], complete: true };
        const ownerId = await ownerIdOf(env, signal);
        const endMs = now();
        const range = {
          start: new Date(endMs - RUNTIME_ERROR_WINDOW_MS).toISOString(),
          end: new Date(endMs).toISOString(),
        };
        const ids = [...projects.keys()];
        // One after the other, not at once: they share the token's quota with the deploy poll.
        const logs = await runQuery(
          env,
          ownerId,
          ids,
          range,
          { event: "vercel.log", select: LOG_SELECT, filter: LOG_FILTER },
          maxPages,
          signal,
        );
        // The responses query can fail on its own (a 402 without Observability Plus, a 429, the
        // deadline) after the logs have arrived. Keep the logs and call the read incomplete, rather
        // than throwing away the half that worked.
        let responses: Awaited<ReturnType<typeof runQuery>>;
        try {
          responses = await runQuery(
            env,
            ownerId,
            ids,
            range,
            { event: "vercel.proxy_response", select: RESPONSE_SELECT, filter: RESPONSE_FILTER },
            maxPages,
            signal,
          );
        } catch (err) {
          console.error("[telemetry] Vercel 5xx responses read failed; keeping the runtime logs", err);
          responses = { events: [], whole: false };
        }
        const items: RuntimeLogEntry[] = [];
        for (const raw of logs.events) {
          const entry = logEventToEntry(raw, projects);
          if (entry) items.push(entry);
        }
        for (const raw of responses.events) {
          const entry = responseEventToEntry(raw, projects);
          if (entry) items.push(entry);
        }
        return { ok: true, items, complete: logs.whole && responses.whole };
      } catch (err) {
        // A 429 (VercelRateLimited), the deadline, or any other failure: nothing is saved, so the
        // last whole snapshot stands and the report says how old it is.
        console.error("[telemetry] Vercel runtime errors read failed", err);
        return { ok: false, items: [] };
      }
    },
  };
}
