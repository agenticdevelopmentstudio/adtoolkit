import { parseErrorsTarget, parsePlatformHealthTarget, type Problem } from '../board';
import type { LiveSnapshot } from '../monitor/live-types';
import type { DeploymentDTO, IntegrationsResponse, UptimeResponse } from '../monitor/types';
import type { CompactSnapshot } from '../routes/reads';
import type { AnalyticsRange } from '../telemetry/dashboard/ranges';
import type { DashboardSection } from '../telemetry/dashboard/sectioned-dashboard';
import type {
  AnalyticsDashboardResponse,
  ErrorIssue,
  ErrorsDashboardResponse,
  SiteHealthRow,
} from '../telemetry/dashboard/types';
import type { RuntimeErrorGroup, RuntimeErrorsReport } from '../telemetry/types';
import { isFailureRateHigh } from '../telemetry/dashboard/views';
import {
  REPORT_SCHEMA,
  REPORT_SOURCES,
  SEVERITIES,
  type AnalyticsReportSection,
  type DeploysReportSection,
  type ErrorsReportSection,
  type FailingDeploy,
  type Finding,
  type IntegrationsReportSection,
  type MonitorReportSection,
  type ReportResponse,
  type ReportSections,
  type ReportSourceId,
  type ReportVerdict,
  type RuntimeErrorsReportSection,
  type Severity,
  type SourceCoverage,
  type UptimeReportSection,
} from './types';

// ---------------------------------------------------------------------------
// The report's business logic: every rule that turns the sources into a verdict, findings and
// coverage. PURE — no I/O, no clock (`now` is an input) — so each rule is tested with fixtures;
// `report-gather.ts` does the reading and hands each source in as a payload OR the reason it
// could not be had.
//
// Two rules carry the rest:
//  - A missing source is never a healthy source. A source that failed, a dashboard section that
//    errored or is still refreshing, a monitor that stopped cycling: each lands in coverage
//    (`error` / `notes`) and makes `complete` false, so "no findings" with `complete: false`
//    reads "don't know", not "all good". A provider with no credentials is listed under
//    `unconfigured` instead and does NOT clear `complete` — a standing fact about the
//    deployment, and a flag that is always false teaches the reader to ignore it.
//  - Every finding says where it came from (`source`) and, where there is one, where to look
//    next (`link`, `issueKey`).
// ---------------------------------------------------------------------------

/** Below this uptime percent over the window, a service is worth a finding. */
export const UPTIME_FLOOR = 99.5;
/** Active GlitchTip issues listed as findings; the rest are counted in one "N more" finding. */
export const ERROR_ISSUE_CAP = 15;
/** Vercel runtime error groups listed as findings; the rest are counted in one "N more" finding. */
export const RUNTIME_GROUP_CAP = 15;
/** PostHog sites considered for a finding (most errors+failures first). */
export const SITE_ROW_CAP = 10;
/** A runtime 5xx group seen at least this often in the window is major, not minor. */
export const RUNTIME_5XX_MAJOR_COUNT = 5;

/** One source: its payload, or why there is none. */
export type SourceRead<T> = { ok: true; data: T } | { ok: false; error: string };

export interface MonitorInput {
  /** `/snapshot` — the rollup and services; its `openIssues` are what `issues show` searches. */
  snapshot: CompactSnapshot;
  /** Every board problem, error problems included (unlike `snapshot.openIssues`). */
  problems: Problem[];
  /** When the loop last completed a cycle (or, with no loop in this process, the newest probe). */
  lastCycleAt: string | null;
  /** The scheduler's own stale rule (`cycleStale`, or `defaultStaleAfterMs` with no loop here). */
  stale: boolean;
}

/** One failing deployment's build log, read with `logs=1`. */
export type DeployLogTail = { tail: string[]; lines: number } | { error: string };

export interface DeploysInput {
  live: LiveSnapshot;
  /** With `logs=1`: the log tail per failing deployment id. */
  logs?: Record<string, DeployLogTail>;
}

export interface RuntimeErrorsInput {
  /** A Vercel token is present, so the runtime-log poll runs at all. */
  configured: boolean;
  report: RuntimeErrorsReport;
  /**
   * The latest reads failed: how many in a row, and when the last one was. Null when the latest
   * read succeeded. A failed read saves nothing, so `report` is still the last good read.
   */
  failing: { streak: number; atMs: number } | null;
}

export interface ReportInputs {
  now: Date;
  monitorVersion: string | null;
  monitor: SourceRead<MonitorInput>;
  deploys: SourceRead<DeploysInput>;
  integrations: SourceRead<IntegrationsResponse>;
  /** `refreshing` still true here means it was still refreshing at the wait deadline. */
  errors: SourceRead<ErrorsDashboardResponse>;
  runtimeErrors: SourceRead<RuntimeErrorsInput>;
  /** `refreshing` still true here means it was still refreshing at the wait deadline. */
  analytics: SourceRead<AnalyticsDashboardResponse>;
  uptime: SourceRead<UptimeResponse>;
}

const RANK: Record<Severity, number> = { critical: 0, major: 1, minor: 2 };
const VERDICT: Record<Severity, ReportVerdict> = { critical: 'down', major: 'degraded', minor: 'attention' };

/** The first non-empty line, trimmed and cut to `width`. */
export function firstLine(text: string | null | undefined, width = 160): string | null {
  if (!text) return null;
  const line = String(text).trim().split(/\r?\n/)[0]?.trim() ?? '';
  if (!line) return null;
  return line.length > width ? `${line.slice(0, width - 1)}…` : line;
}

interface FindingExtra {
  detail?: string | null;
  since?: string | null;
  link?: string | null;
  issueKey?: string | null;
}

function finding(severity: Severity, source: string, title: string, extra: FindingExtra = {}): Finding {
  const out: Finding = { severity, source, title };
  const detail = firstLine(extra.detail);
  if (detail) out.detail = detail;
  if (extra.since) out.since = extra.since;
  if (extra.link) out.link = extra.link;
  if (extra.issueKey) out.issueKey = extra.issueKey;
  return out;
}

const worse = (a: Severity, b: Severity): Severity => (RANK[a] <= RANK[b] ? a : b);
const words = (...parts: (string | null | undefined)[]): string => parts.filter((p) => p).join(' ');
const byText = (a: string, b: string): number => (a < b ? -1 : a > b ? 1 : 0);

/** One source's digest: its coverage admissions, its findings, its section. */
interface Digest<S> {
  notes: string[];
  unconfigured: string[];
  findings: Finding[];
  section: S;
  updatedAt?: string | null;
}

/** The note a dashboard section earns when its latest attempt failed. */
function sectionNote<T>(label: string, section: DashboardSection<T>): string | null {
  if (!section.error) return null;
  return `${label}: ${section.error}${section.data !== null ? ' (showing older data)' : ''}`;
}

const presentNotes = (notes: (string | null)[]): string[] => notes.filter((n): n is string => n !== null);

// ── monitor ──────────────────────────────────────────────────────────────────

/**
 * The key `adh-status issues show` accepts for each open issue, by target. That command
 * searches `/snapshot`'s `openIssues` for the first whose target OR name equals the key, so a
 * name is a safe key only when no other open issue shares it; the target always is. Error
 * problems are not in `/snapshot`, so they get no key.
 */
export function issueKeys(openIssues: CompactSnapshot['openIssues']): Map<string, string> {
  const names = new Map<string, number>();
  for (const i of openIssues) names.set(i.name, (names.get(i.name) ?? 0) + 1);
  return new Map(openIssues.map((i) => [i.target, i.name && names.get(i.name) === 1 ? i.name : i.target]));
}

interface MonitorContext {
  /**
   * The GlitchTip issue list is current (see glitchtipListCurrent), so it lists the errors the
   * board summarizes per project and the board's errors problems would count them twice.
   */
  glitchtipListed: boolean;
  /** Provider health from the deploys source, when it was read. */
  providers: LiveSnapshot['providers'] | null;
}

export function digestMonitor(input: MonitorInput, ctx: MonitorContext): Digest<MonitorReportSection> {
  const { snapshot, problems } = input;
  const notes: string[] = [];
  const findings: Finding[] = [];
  const keys = issueKeys(snapshot.openIssues);

  for (const p of problems) {
    // Count GlitchTip errors once: the errors source lists the issues themselves, so the
    // board's per-project error problem is a finding only when that list could not be read.
    if (parseErrorsTarget(p.target) !== null && ctx.glitchtipListed) continue;
    // An unreachable deploy provider is the provider rule's finding.
    const platform = parsePlatformHealthTarget(p.target);
    if (platform !== null && ctx.providers && Object.prototype.hasOwnProperty.call(ctx.providers, platform)) continue;
    // The board's severity is the verdict: it already makes a stale production deploy major
    // and keeps staging and testing ones minor on purpose.
    findings.push(
      finding(p.severity, `monitor:${p.source}`, `${words(p.name, p.environment)}: ${words(p.source, p.state)}`, {
        detail: p.detail,
        since: p.since,
        link: p.sourceUrl ?? p.liveUrl,
        issueKey: keys.get(p.target),
      }),
    );
  }

  // Board problems are the only monitor findings. A non-healthy service with no problem is
  // one the board holds back on purpose (monitorHttp off, a degraded probe not yet past its
  // confirm window); raising it here would grade it before, and harder than, the board does.
  // section.byStatus still counts it.

  if (input.stale) {
    const detail = input.lastCycleAt
      ? `last completed cycle at ${input.lastCycleAt}`
      : 'no cycle has completed since the loop started';
    notes.push(`monitor data is stale: ${detail}`);
    findings.push(finding('major', 'monitor', 'status monitor has stopped probing', { detail }));
  } else if (input.lastCycleAt === null) {
    notes.push('monitor has not completed a probe cycle');
  }

  const byStatus: Record<string, number> = {};
  for (const s of [...snapshot.services].sort((a, b) => byText(a.status, b.status))) {
    byStatus[s.status] = (byStatus[s.status] ?? 0) + 1;
  }
  return {
    notes,
    unconfigured: [],
    findings,
    updatedAt: input.lastCycleAt,
    section: {
      overall: snapshot.overall,
      checkedAt: snapshot.generatedAt,
      lastCycleAt: input.lastCycleAt,
      stale: input.stale,
      services: snapshot.services.length,
      byStatus,
      openIssues: snapshot.openIssues.length,
      unprobed: snapshot.services.filter((s) => s.status === 'unknown').map((s) => s.name).sort(byText),
    },
  };
}

// ── deploys ──────────────────────────────────────────────────────────────────

/**
 * The newest deployment per deploy target — (platform, provider project id ?? name, tier) — so
 * a failure already fixed by a later build is history, not a problem.
 */
export function newestPerTarget<D extends DeploymentDTO>(deployments: D[]): D[] {
  const latest = new Map<string, D>();
  for (const d of deployments) {
    const key = JSON.stringify([d.platform, d.providerProjectId ?? d.projectName, d.tier ?? d.environment]);
    const held = latest.get(key);
    if (!held || Date.parse(held.createdAt) < Date.parse(d.createdAt)) latest.set(key, d);
  }
  return [...latest.values()];
}

/** A board deploy problem, which always names the deployment it judged. */
export type DeployProblem = Problem & { deployment: NonNullable<Problem['deployment']> };

/**
 * The deploys the board holds as failed: its deploy problems in state `failed`, newest build
 * first. This is the board's per-target verdict. The newest row of the `/live` feed is not: it
 * may be a canceled or queued build that proves nothing, a preview the board ignores, or
 * missing because newer rows across the fleet pushed the failure out of the feed's window.
 */
export function failingDeployProblems(problems: readonly Problem[]): DeployProblem[] {
  return problems
    .filter((p): p is DeployProblem => p.state === 'failed' && p.deployment !== undefined)
    .sort(
      (a, b) =>
        Date.parse(b.deployment.createdAt) - Date.parse(a.deployment.createdAt) || byText(a.deployment.id, b.deployment.id),
    );
}

/**
 * `boardProblems` is the monitor source's problem list, or null when it could not be read:
 * then the failing list is empty and a note says why, rather than guessing from the feed.
 */
export function digestDeploys(input: DeploysInput, boardProblems: readonly Problem[] | null): Digest<DeploysReportSection> {
  const { live } = input;
  const notes: string[] = [];
  const unconfigured: string[] = [];
  const findings: Finding[] = [];

  if (live.configDegraded) notes.push(`monitor config fell back to the static list: ${live.configReason ?? 'reason unknown'}`);
  for (const [name, health] of Object.entries(live.providers).sort(([a], [b]) => byText(a, b))) {
    if (!health.configured) unconfigured.push(name);
    else if (!health.ok) {
      // The board grades an unreachable platform (minor: the deploys it watches are not down), and
      // this finding replaces the board's problem, so it keeps the board's grade rather than
      // inventing a worse one.
      const board = boardProblems?.find((p) => parsePlatformHealthTarget(p.target) === name);
      findings.push(finding(board?.severity ?? 'minor', `provider:${name}`, `${name} API unreachable from the monitor`));
    }
  }

  const latest = newestPerTarget(live.deployments);
  if (boardProblems === null) notes.push('failing deploys come from the board, which could not be read');
  const failing: FailingDeploy[] = failingDeployProblems(boardProblems ?? []).map((p) => {
      const out: FailingDeploy = {
        id: p.deployment.id,
        platform: p.source,
        project: p.name,
        tier: p.environment,
        branch: p.branch,
        createdAt: p.deployment.createdAt,
        commit: firstLine(p.commitMessage, 80),
        error: firstLine(p.errorText),
        url: p.sourceUrl,
      };
      const log = input.logs?.[p.deployment.id];
      if (log && 'error' in log) out.logError = log.error;
      else if (log) {
        out.logTail = log.tail;
        out.logLines = log.lines;
      }
      return out;
    });

  // A failing deploy and a stale production deploy are findings through their BOARD problem
  // (the monitor source); listing them here as well would count each twice.
  return {
    notes,
    unconfigured,
    findings,
    updatedAt: live.lastCycleAt,
    section: {
      deployTargets: latest.length,
      // The SAME demotion `/live` applies (effectiveStatus): an in-flight phase nothing has
      // re-confirmed is not counted as a build in progress.
      inFlight: latest.filter((d) => d.effectiveStatus === 'building' || d.effectiveStatus === 'queued').length,
      failing,
      staleProd: live.staleProd,
      providers: live.providers,
    },
  };
}

// ── integrations ─────────────────────────────────────────────────────────────

export function digestIntegrations(data: IntegrationsResponse): Digest<IntegrationsReportSection> {
  const unconfigured: string[] = [];
  const findings: Finding[] = [];
  for (const check of data.checks) {
    const label = check.label || check.id;
    // State first: a check that says 'error' is broken, configured or not. checkCloudflare
    // returns configured:false + error when the account can't be discovered, and so does the
    // fallback for a check that threw. An unset integration is configured:false + warn.
    if (!check.configured && check.state !== 'error') {
      const missing = check.missingEnv ?? [];
      unconfigured.push(missing.length ? `${label} (unset: ${missing.join(', ')})` : label);
      continue;
    }
    if (check.state === 'error' || check.state === 'warn') {
      findings.push(
        finding(check.state === 'error' ? 'major' : 'minor', `integration:${check.id}`, `${label} integration ${check.state}`, {
          detail: check.detail,
        }),
      );
    }
  }
  return {
    notes: [],
    unconfigured,
    findings,
    updatedAt: data.generatedAt,
    section: {
      overall: data.overall,
      checks: data.checks.map((c) => ({
        id: c.id,
        label: c.label,
        configured: c.configured,
        state: c.state,
        detail: firstLine(c.detail),
      })),
    },
  };
}

// ── errors (GlitchTip + PostHog site health) ─────────────────────────────────

/** Fatal first, so the finding cap can never hide one behind a noisy warning; then by count. */
export function activeIssueOrder(a: ErrorIssue, b: ErrorIssue): number {
  const fatal = Number(b.level === 'fatal') - Number(a.level === 'fatal');
  if (fatal !== 0) return fatal;
  if (b.count !== a.count) return b.count - a.count;
  return byText(a.title, b.title);
}

const siteTrouble = (r: SiteHealthRow): number => (r.errors ?? 0) + (r.failures ?? 0);

/**
 * A site is a finding when its client errors and failed requests together reach the dashboard's
 * own failure-rate line (FAILURE_RATE_HIGH in views.ts, 5% of its requests), so one aborted request in a
 * month of traffic is not "attention". Errors with no requests to weigh them against still count.
 */
export function siteTroubled(r: SiteHealthRow): boolean {
  const trouble = siteTrouble(r);
  if ((r.requests ?? 0) === 0) return trouble > 0;
  return isFailureRateHigh(trouble, r.requests);
}

/**
 * True only when the GlitchTip issue list can stand in for the board's per-project errors
 * problems: it was read, its last refresh did not fail, no GlitchTip refresh was still running
 * at the deadline, and it was read to the end. A cached list from before a new crash would
 * otherwise hide that crash from every finding. A PostHog refresh says nothing about the list,
 * so it does not count: a slow PostHog would otherwise put every crash in twice.
 */
export function glitchtipListCurrent(data: ErrorsDashboardResponse): boolean {
  const { issues } = data.sections;
  return (
    issues.data !== null && issues.error === null && !data.refreshingSources.glitchtip && issues.data.summary.complete
  );
}

export function digestErrors(data: ErrorsDashboardResponse): Digest<ErrorsReportSection> {
  const notes: string[] = [];
  const unconfigured: string[] = [];
  const findings: Finding[] = [];
  if (!data.configured.glitchtip) unconfigured.push('glitchtip');
  if (!data.configured.posthog) unconfigured.push('posthog');
  if (data.refreshing) notes.push('errors dashboard still refreshing at the deadline');

  const { issues, sites, detail } = data.sections;
  notes.push(
    ...presentNotes([
      sectionNote('glitchtip issues', issues),
      sectionNote('posthog site health', sites),
      sectionNote('posthog error detail', detail),
    ]),
  );

  const summary = issues.data?.summary ?? null;
  if (summary && !summary.complete) notes.push('glitchtip issue list could not be read to the end');
  const active = (issues.data?.issues ?? []).filter((i) => i.active).sort(activeIssueOrder);
  for (const issue of active.slice(0, ERROR_ISSUE_CAP)) {
    findings.push(
      finding(issue.level === 'fatal' ? 'major' : 'minor', 'glitchtip', `${issue.project}: ${firstLine(issue.title, 100) ?? issue.id}`, {
        detail: `${issue.count} events, ${issue.userCount} users${issue.source ? `, in ${issue.source}` : ''}`,
        since: issue.firstSeen,
        link: issue.permalink,
      }),
    );
  }
  if (active.length > ERROR_ISSUE_CAP) {
    // As bad as the worst issue it hides: a cap must never turn a fatal into a minor.
    const hiddenSeverity = active
      .slice(ERROR_ISSUE_CAP)
      .reduce<Severity>((s, i) => worse(s, i.level === 'fatal' ? 'major' : 'minor'), 'minor');
    findings.push(
      finding(hiddenSeverity, 'glitchtip', `${active.length - ERROR_ISSUE_CAP} more active GlitchTip issues not listed`, {
        detail: 'all are in sections.errors.active',
      }),
    );
  }

  const siteRows = [...(sites.data ?? [])].sort((a, b) => siteTrouble(b) - siteTrouble(a) || byText(a.host, b.host));
  for (const row of siteRows.slice(0, SITE_ROW_CAP)) {
    if (!siteTroubled(row)) continue;
    findings.push(
      finding('minor', 'posthog', `${row.host}: ${row.errors ?? 0} client errors, ${row.failures ?? 0} failed of ${row.requests ?? 0} requests`, {
        detail: row.p95Ms !== null ? `p95 ${row.p95Ms}ms` : null,
      }),
    );
  }

  return {
    notes,
    unconfigured,
    findings,
    updatedAt: issues.updatedAt ?? sites.updatedAt,
    section: {
      summary,
      active,
      sites: siteRows,
      siteErrors: detail.data?.errors ?? [],
      failedRequests: detail.data?.requests ?? [],
    },
  };
}

// ── Vercel runtime errors ────────────────────────────────────────────────────

/** `fatal`, or a 5xx seen at least {@link RUNTIME_5XX_MAJOR_COUNT} times, is major; the rest minor. */
export function runtimeSeverity(g: RuntimeErrorGroup): Severity {
  if (g.level === 'fatal') return 'major';
  if (g.status !== null && g.status >= 500 && g.count >= RUNTIME_5XX_MAJOR_COUNT) return 'major';
  return 'minor';
}

export function digestRuntimeErrors(input: RuntimeErrorsInput): Digest<RuntimeErrorsReportSection> {
  const { report } = input;
  const findings: Finding[] = [];
  // Majors first so the cap never hides one; within a severity, the store's own order
  // (worst level, then most frequent).
  const ranked = report.groups
    .map((g, i) => ({ g, i, severity: runtimeSeverity(g) }))
    .sort((a, b) => RANK[a.severity] - RANK[b.severity] || a.i - b.i);
  const shown = ranked.slice(0, RUNTIME_GROUP_CAP);
  for (const { g, severity } of shown) {
    const where = words(g.method, g.path) || g.source;
    findings.push(
      finding(severity, 'vercel-runtime', `${g.project}: ${where}${g.status !== null ? ` → ${g.status}` : ''}`, {
        detail: `${g.count}× ${g.level}: ${g.message}`,
        since: g.firstSeen,
        link: g.domain ? `https://${g.domain}` : null,
      }),
    );
  }
  // `total` counts every group in the window; `groups` may already be capped below it.
  const hidden = Math.max(report.total, report.groups.length) - shown.length;
  if (hidden > 0) {
    // As bad as the worst group it hides. Groups past the report's own cap are not here to
    // judge; they sort after every listed one, so they are no worse than the last listed.
    const hiddenSeverity = ranked
      .slice(RUNTIME_GROUP_CAP)
      .reduce<Severity>((s, r) => worse(s, r.severity), 'minor');
    findings.push(
      finding(hiddenSeverity, 'vercel-runtime', `${hidden} more Vercel runtime error groups not listed`, {
        detail: 'see sections.runtimeErrors.groups',
      }),
    );
  }
  const notes: string[] = [];
  if (input.configured) {
    if (report.readAt === null) notes.push('vercel runtime errors not read yet');
    else if (!report.complete) notes.push('vercel runtime read was cut short; there may be more groups than listed');
    if (input.failing) {
      const reads = input.failing.streak === 1 ? 'read' : 'reads';
      notes.push(
        `last ${input.failing.streak} vercel runtime ${reads} failed (latest ${new Date(input.failing.atMs).toISOString()})` +
          (report.readAt ? `; these groups are from the read at ${report.readAt}` : ''),
      );
    }
  }
  return {
    notes,
    unconfigured: input.configured ? [] : ['vercel'],
    findings,
    // When the groups were read from Vercel, not when this report was built.
    updatedAt: input.configured ? report.readAt : null,
    section: {
      window: report.window,
      readAt: report.readAt,
      complete: report.complete,
      total: report.total,
      groups: report.groups,
    },
  };
}

// ── analytics ────────────────────────────────────────────────────────────────

export function digestAnalytics(data: AnalyticsDashboardResponse): Digest<AnalyticsReportSection> {
  const notes: string[] = [];
  const unconfigured: string[] = [];
  if (!data.configured.posthog) unconfigured.push('posthog');
  if (!data.configured.vercel) unconfigured.push('vercel');
  if (data.refreshing) notes.push('analytics dashboard still refreshing at the deadline');

  const s = data.sections;
  notes.push(
    ...presentNotes([
      sectionNote('posthog traffic', s.traffic),
      sectionNote('posthog dimensions', s.dimensions),
      sectionNote('posthog paths', s.paths),
      sectionNote('posthog web vitals', s.vitals),
      sectionNote('posthog site health', s.health),
      sectionNote('vercel web analytics', s.vercel),
    ]),
  );
  const vercel = s.vercel.data;
  if (vercel && vercel.failed > 0) notes.push(`vercel web analytics: ${vercel.failed} projects could not be read`);

  return {
    notes,
    unconfigured,
    findings: [],
    updatedAt: s.traffic.updatedAt ?? s.vercel.updatedAt,
    section: {
      range: data.range,
      posthog: {
        totals: s.traffic.data?.totals ?? null,
        sites: (s.traffic.data?.sites ?? [])
          .map(({ host, pageviews, sessions }) => ({ host, pageviews, sessions }))
          .sort((a, b) => b.pageviews - a.pageviews || byText(a.host, b.host)),
      },
      vercel: {
        totals: vercel?.totals ?? null,
        projectsTotal: vercel?.projectsTotal ?? null,
        projectsEnabled: vercel?.projectsEnabled ?? null,
        failed: vercel?.failed ?? null,
        projects: (vercel?.projects ?? [])
          .map(({ project, domain, pageviews, visitors }) => ({ project, domain, pageviews, visitors }))
          .sort((a, b) => b.pageviews - a.pageviews || byText(a.project, b.project)),
      },
      vitals: s.vitals.data ?? [],
    },
  };
}

// ── uptime ───────────────────────────────────────────────────────────────────

export function digestUptime(data: UptimeResponse): Digest<UptimeReportSection> {
  const low = data.services
    .flatMap((s) => (s.uptimePercent !== null && s.uptimePercent < UPTIME_FLOOR ? [{ ...s, pct: s.uptimePercent }] : []))
    .sort((a, b) => a.pct - b.pct);
  return {
    notes: [],
    unconfigured: [],
    findings: low.map((s) => finding('minor', 'uptime', `${s.name}: ${s.pct.toFixed(2)}% up over ${data.days}d`)),
    section: {
      days: data.days,
      floor: UPTIME_FLOOR,
      services: data.services.map((s) => ({
        slug: s.slug,
        name: s.name,
        uptimePercent: s.uptimePercent,
        totalChecks: s.totalChecks,
      })),
    },
  };
}

// ── the report ───────────────────────────────────────────────────────────────

export function compareFindings(a: Finding, b: Finding): number {
  return RANK[a.severity] - RANK[b.severity] || byText(a.source, b.source) || byText(a.title, b.title);
}

type Digested = { [K in ReportSourceId]: Digest<NonNullable<ReportSections[K]>> | { error: string } };

function digestOr<T, S>(read: SourceRead<T>, fn: (data: T) => Digest<S>): Digest<S> | { error: string } {
  return read.ok ? fn(read.data) : { error: read.error };
}

export function buildReport(inputs: ReportInputs): ReportResponse {
  const ctx: MonitorContext = {
    glitchtipListed: inputs.errors.ok && glitchtipListCurrent(inputs.errors.data),
    providers: inputs.deploys.ok ? inputs.deploys.data.live.providers : null,
  };
  const digested: Digested = {
    monitor: digestOr(inputs.monitor, (d) => digestMonitor(d, ctx)),
    deploys: digestOr(inputs.deploys, (d) => digestDeploys(d, inputs.monitor.ok ? inputs.monitor.data.problems : null)),
    integrations: digestOr(inputs.integrations, digestIntegrations),
    errors: digestOr(inputs.errors, digestErrors),
    runtimeErrors: digestOr(inputs.runtimeErrors, digestRuntimeErrors),
    analytics: digestOr(inputs.analytics, digestAnalytics),
    uptime: digestOr(inputs.uptime, digestUptime),
  };

  const coverage = {} as Record<ReportSourceId, SourceCoverage>;
  const sections = {} as Record<ReportSourceId, unknown>;
  const findings: Finding[] = [];
  for (const name of REPORT_SOURCES) {
    const out = digested[name];
    if ('error' in out) {
      coverage[name] = { ok: false, error: out.error };
      sections[name] = null;
      findings.push(finding('major', 'report', `could not read ${name}`, { detail: out.error }));
      continue;
    }
    const cov: SourceCoverage = { ok: true };
    if (out.notes.length) cov.notes = out.notes;
    if (out.unconfigured.length) cov.unconfigured = out.unconfigured;
    if (out.updatedAt !== undefined) cov.updatedAt = out.updatedAt;
    coverage[name] = cov;
    sections[name] = out.section;
    findings.push(...out.findings);
  }

  findings.sort(compareFindings);
  const complete = REPORT_SOURCES.every((s) => coverage[s].ok && !coverage[s].notes?.length);
  const counts = Object.fromEntries(SEVERITIES.map((s) => [s, 0])) as Record<Severity, number>;
  for (const f of findings) counts[f.severity] += 1;
  const worst = findings[0]?.severity;

  return {
    schema: REPORT_SCHEMA,
    generatedAt: inputs.now.toISOString(),
    monitorVersion: inputs.monitorVersion,
    verdict: worst ? VERDICT[worst] : complete ? 'healthy' : 'unknown',
    complete,
    counts,
    coverage,
    findings,
    sections: sections as unknown as ReportSections,
  };
}
