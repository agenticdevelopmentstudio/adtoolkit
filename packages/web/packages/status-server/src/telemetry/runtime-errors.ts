import { createHash } from "node:crypto";
import type { RuntimeErrorsStore } from "../storage/ports";
import type { RuntimeErrorGroup, RuntimeErrorsRead, RuntimeErrorsReport, RuntimeLogEntry } from "./types";

// The rules for Vercel runtime errors, kept apart from the fetcher (network) and the store (SQL)
// so each is testable alone: which events count, how they group, and how the report is ordered.
// The store and the route both call these, so there is one copy of each rule.
//
// Each read asks Vercel's Observability events API for the last 24 hours and the store REPLACES
// its groups with the result, so a group's count is its count in that window and nothing has to
// be deduplicated across reads.

/** The window one read covers, and `GET /errors/runtime` reports. */
export const RUNTIME_ERROR_WINDOW_MS = 24 * 60 * 60_000;
/** At most this many groups in a report; `total` still counts them all. */
export const RUNTIME_ERROR_REPORT_CAP = 200;
const MESSAGE_MAX = 200;

/** Vercel's log levels, worst first. */
export const RUNTIME_LEVELS = ["fatal", "error", "warning", "info", "debug", "trace"] as const;
const LEVEL_RANK: Record<string, number> = Object.fromEntries(
  RUNTIME_LEVELS.map((level, i) => [level, RUNTIME_LEVELS.length - 1 - i]),
);

/** Higher is worse. An unknown level sorts below every known one. */
export function levelRank(level: string | null | undefined): number {
  return Object.hasOwn(LEVEL_RANK, level ?? "") ? LEVEL_RANK[level ?? ""]! : -1;
}

/** The worse of two levels. */
export function worseLevel(a: string, b: string): string {
  return levelRank(b) > levelRank(a) ? b : a;
}

/** Where an event's project id points: its name and the domain people call it by. */
export interface RuntimeProject {
  name: string;
  domain: string | null;
}

/** One `vercel.log` or `vercel.proxy_response` event, with the fields the fetcher selects. */
export interface RawRuntimeEvent {
  timestamp?: unknown;
  projectId?: unknown;
  deploymentId?: unknown;
  requestId?: unknown;
  requestPath?: unknown;
  requestMethod?: unknown;
  domain?: unknown;
  requestHostname?: unknown;
  // vercel.log
  source?: unknown;
  level?: unknown;
  message?: unknown;
  // vercel.proxy_response
  httpStatus?: unknown;
}

const str = (v: unknown): string | null => (typeof v === "string" && v !== "" ? v : null);
const num = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);

const cleanPath = (v: unknown): string | null => {
  const path = str(v);
  return path === null ? null : path.split(/[?#]/)[0] || "/";
};

/**
 * The fields every event shares, or null if it can't be placed: no timestamp, or a project that
 * is not one of `projects` (a staging or testing project's own production environment).
 */
function common(raw: RawRuntimeEvent, projects: ReadonlyMap<string, RuntimeProject>) {
  const timestampMs = Date.parse(str(raw.timestamp) ?? "");
  const projectId = str(raw.projectId);
  const project = projectId !== null && projects.has(projectId) ? projects.get(projectId)! : null;
  if (!Number.isFinite(timestampMs) || project === null) return null;
  return {
    project: project.name,
    deploymentId: str(raw.deploymentId) ?? "",
    domain: str(raw.domain) ?? project.domain ?? str(raw.requestHostname),
    requestId: str(raw.requestId),
    timestampMs,
    method: str(raw.requestMethod),
    path: cleanPath(raw.requestPath),
  };
}

/** A `vercel.log` event as an entry: kept when it is an `error` or `fatal` line. */
export function logEventToEntry(
  raw: RawRuntimeEvent,
  projects: ReadonlyMap<string, RuntimeProject>,
): RuntimeLogEntry | null {
  const level = str(raw.level) ?? "info";
  if (level !== "error" && level !== "fatal") return null;
  const at = common(raw, projects);
  if (!at) return null;
  return {
    ...at,
    level,
    source: str(raw.source) ?? "unknown",
    status: null,
    message: typeof raw.message === "string" ? raw.message : "",
  };
}

/** A `vercel.proxy_response` event as an entry: kept when it answered 5xx. */
export function responseEventToEntry(
  raw: RawRuntimeEvent,
  projects: ReadonlyMap<string, RuntimeProject>,
): RuntimeLogEntry | null {
  const status = num(raw.httpStatus);
  if (status === null || status < 500) return null;
  const at = common(raw, projects);
  if (!at) return null;
  return { ...at, level: "error", source: "response", status, message: `HTTP ${status}` };
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const HEX = /^[0-9a-f]{12,}$/i;

function isIdSegment(seg: string): boolean {
  if (/^\d+$/.test(seg) || UUID.test(seg)) return true;
  if (HEX.test(seg) && /\d/.test(seg)) return true;
  // A long token mixing letters and digits (a base64/nanoid id or a content hash).
  return seg.length >= 20 && /^[A-Za-z0-9_-]+$/.test(seg) && /\d/.test(seg) && /[A-Za-z]/.test(seg);
}

/** `/posts/123/edit` and `/posts/456/edit` are one route: id-like segments read `:id`. */
export function normalizePath(path: string | null): string | null {
  if (path === null) return null;
  return path
    .split("/")
    .map((seg) => (seg !== "" && isIdSegment(seg) ? ":id" : seg))
    .join("/");
}

function firstLine(message: string): string {
  return (message.split(/\r?\n/)[0] ?? "").trim();
}

/** The first line of a message, at most 200 characters. */
export function messageHead(message: string): string {
  return firstLine(message).slice(0, MESSAGE_MAX);
}

/**
 * A message head with the values that vary per occurrence taken out, so `Order 8231 not found`
 * and `Order 8270 not found` are one error: id-like tokens (a UUID, a hex hash, a long mixed
 * token — the path-segment test) read `:id`, and any run of digits (an id, a count, a duration,
 * a timestamp part) reads `#`.
 */
export function messageShape(head: string): string {
  return head
    .replace(/[A-Za-z0-9_-]+/g, (tok) => (!/^\d+$/.test(tok) && isIdSegment(tok) ? ":id" : tok))
    .replace(/\d+/g, "#");
}

/**
 * The grouping fields of an entry, and their stable hash. The key uses the message's shape;
 * `message` is the head as written, for a group to show as its sample.
 *
 * The shape is taken from the whole first line and only then cut, never from the cut head: a
 * number of varying length, or an id crossing the cut, would otherwise move where the cut lands
 * and split one error into a group per occurrence.
 */
export function groupIdentity(e: RuntimeLogEntry): {
  key: string;
  path: string | null;
  message: string;
} {
  const path = normalizePath(e.path);
  const message = messageHead(e.message);
  const key = createHash("sha256")
    .update(
      JSON.stringify([e.project, e.source, e.method, path, e.status, messageShape(firstLine(e.message)).slice(0, MESSAGE_MAX)]),
    )
    .digest("hex")
    .slice(0, 32);
  return { key, path, message };
}

/** Fold one read's entries into its groups. The newest event supplies deployment, domain and sample. */
export function groupRuntimeEntries(entries: RuntimeLogEntry[]): RuntimeErrorGroup[] {
  type Acc = Omit<RuntimeErrorGroup, "firstSeen" | "lastSeen"> & { firstSeenMs: number; lastSeenMs: number };
  const groups = new Map<string, Acc>();
  for (const e of entries) {
    const { key, path, message } = groupIdentity(e);
    const g = groups.get(key);
    if (!g) {
      groups.set(key, {
        key,
        project: e.project,
        deploymentId: e.deploymentId,
        domain: e.domain,
        source: e.source,
        method: e.method,
        path,
        status: e.status,
        level: e.level,
        message,
        count: 1,
        firstSeenMs: e.timestampMs,
        lastSeenMs: e.timestampMs,
        sampleRequestId: e.requestId,
      });
      continue;
    }
    g.count++;
    g.level = worseLevel(g.level, e.level);
    g.firstSeenMs = Math.min(g.firstSeenMs, e.timestampMs);
    if (e.timestampMs >= g.lastSeenMs) {
      g.lastSeenMs = e.timestampMs;
      g.deploymentId = e.deploymentId;
      g.domain = e.domain ?? g.domain;
      g.sampleRequestId = e.requestId ?? g.sampleRequestId;
    }
  }
  return [...groups.values()].map(({ firstSeenMs, lastSeenMs, ...g }) => ({
    ...g,
    firstSeen: new Date(firstSeenMs).toISOString(),
    lastSeen: new Date(lastSeenMs).toISOString(),
  }));
}

/** Report order: worst level first, then most frequent, then most recent. */
export function compareRuntimeGroups(a: RuntimeErrorGroup, b: RuntimeErrorGroup): number {
  return (
    levelRank(b.level) - levelRank(a.level) ||
    b.count - a.count ||
    b.lastSeen.localeCompare(a.lastSeen) ||
    a.key.localeCompare(b.key)
  );
}

/**
 * The report over the stored snapshot. The groups are NOT re-windowed against `nowMs`: they are
 * the 24 hours before `read.readAtMs`, and `readAt` says so, so a reader whose reads are failing
 * sees old groups dated as old rather than watching them quietly disappear.
 */
export function runtimeErrorsReport(
  groups: RuntimeErrorGroup[],
  read: RuntimeErrorsRead | null,
  nowMs: number,
): RuntimeErrorsReport {
  const sorted = [...groups].sort(compareRuntimeGroups);
  return {
    generatedAt: new Date(nowMs).toISOString(),
    window: "24h",
    readAt: read ? new Date(read.readAtMs).toISOString() : null,
    complete: read?.complete ?? true,
    total: sorted.length,
    groups: sorted.slice(0, RUNTIME_ERROR_REPORT_CAP),
  };
}

/** The report, read from the store: what `GET /errors/runtime` and the dashboard serve. */
export async function loadRuntimeErrorsReport(
  store: Pick<RuntimeErrorsStore, "load" | "lastRead">,
  nowMs: number = Date.now(),
): Promise<RuntimeErrorsReport> {
  const [groups, read] = await Promise.all([store.load(), store.lastRead()]);
  return runtimeErrorsReport(groups, read, nowMs);
}
