import { describe, expect, it } from "vitest";
import type { Problem } from "../src/board";
import type { LiveDeploymentDTO, LiveSnapshot } from "../src/monitor/live-types";
import type { IntegrationsResponse, ServiceStatusDTO, UptimeResponse } from "../src/monitor/types";
import type { CompactSnapshot } from "../src/routes/reads";
import type { DashboardSection } from "../src/telemetry/dashboard/sectioned-dashboard";
import type {
  AnalyticsDashboardResponse,
  ErrorIssue,
  ErrorsDashboardResponse,
  RuntimeErrorGroup,
  RuntimeErrorsReport,
} from "../src/telemetry/dashboard/types";
import {
  buildReport,
  ERROR_ISSUE_CAP,
  glitchtipListCurrent,
  issueKeys,
  RUNTIME_GROUP_CAP,
  type MonitorInput,
  type ReportInputs,
  type RuntimeErrorsInput,
} from "../src/report/report-rules";
import { REPORT_SCHEMA } from "../src/report/types";
import { analyticsViews, errorsViews } from "../src/telemetry/dashboard/views";

// The rules worth pinning are the ones an agent's "all good?" depends on: a failed or
// still-filling source is never read as healthy, an unconfigured provider is disclosed without
// poisoning `complete`, a deploy failure fixed by a later build is not a finding, and GlitchTip
// errors (which /snapshot strips) still surface — once. Ported from the adh-status CLI digest
// (adh-tools 58d26da), which these rules replace.

const NOW = new Date("2026-11-06T12:00:00Z");

const section = <T>(data: T | null, error: string | null = null): DashboardSection<T> => ({
  data,
  error,
  updatedAt: "2026-11-06T11:59:00Z",
});

function service(over: Partial<ServiceStatusDTO>): ServiceStatusDTO {
  return {
    slug: "hub",
    group: "g",
    name: "Hub",
    url: "https://hub.dev",
    environment: "production",
    platform: null,
    deployProject: null,
    status: "healthy",
    responseTimeMs: 10,
    statusCode: 200,
    error: null,
    lastCheckedAt: "2026-11-06T11:59:00Z",
    slow: false,
    ...over,
  };
}

function problem(over: Partial<Problem>): Problem {
  return {
    target: "vercel|prj_1|",
    source: "vercel",
    name: "zork",
    environment: "production",
    severity: "major",
    state: "failed",
    statusCode: null,
    detail: null,
    sourceUrl: null,
    liveUrl: null,
    commitHash: null,
    commitMessage: null,
    commitRepo: null,
    branch: null,
    errorText: null,
    since: "2026-11-06T10:00:00Z",
    ...over,
  };
}

function openIssue(p: Problem): CompactSnapshot["openIssues"][number] {
  return {
    target: p.target,
    source: p.source,
    name: p.name,
    environment: p.environment,
    severity: p.severity,
    state: p.state,
    detail: p.detail,
    openedAt: p.since,
    sourceUrl: p.sourceUrl,
    liveUrl: p.liveUrl,
    commitHash: null,
    commitMessage: null,
    commitRepo: null,
  };
}

function deployment(over: Partial<LiveDeploymentDTO>): LiveDeploymentDTO {
  const row = {
    id: "d",
    platform: "vercel",
    projectName: "zork",
    providerProjectId: "p",
    status: "success",
    buildPhase: null,
    deployPhase: "ready",
    environment: "production",
    tier: "production",
    commitHash: null,
    commitMessage: null,
    branch: "main",
    commitRepo: null,
    url: null,
    errorText: null,
    liveHost: null,
    createdAt: "2026-11-06T11:00:00Z",
    phaseConfirmedAt: "2026-11-06T11:00:00Z",
    ...over,
  };
  return { ...row, effectiveStatus: over.effectiveStatus ?? row.status } as LiveDeploymentDTO;
}

const SNAPSHOT: CompactSnapshot = {
  generatedAt: "2026-11-06T11:59:00Z",
  overall: "healthy",
  services: [service({})],
  openIssues: [],
};

const MONITOR: MonitorInput = { snapshot: SNAPSHOT, problems: [], lastCycleAt: "2026-11-06T11:59:00Z", stale: false };

const LIVE: LiveSnapshot = {
  generatedAt: "2026-11-06T12:00:00Z",
  lastCycleAt: "2026-11-06T11:59:00Z",
  probeIntervalMs: 60_000,
  monitorVersion: "abc123",
  services: [],
  deployments: [],
  staleProd: [],
  providers: {
    vercel: { configured: true, ok: true },
    "cloudflare-pages": { configured: false, ok: false },
    railway: { configured: true, ok: true },
    crunchy: { configured: true, ok: true },
  },
  configDegraded: false,
  configReason: null,
  freshness: { state: "fresh", asOf: null },
  blind: false,
  platformSummary: [],
  staleMonitors: { thresholdDays: 7, monitors: [] },
};

const INTEGRATIONS: IntegrationsResponse = {
  generatedAt: "2026-11-06T11:59:00Z",
  overall: "ok",
  checks: [{ id: "glitchtip", label: "GlitchTip", configured: true, ok: true, state: "ok", detail: "fine" }],
  selfCheck: null,
};

function errorsDashboard(over: Partial<ErrorsDashboardResponse["sections"]> = {}): ErrorsDashboardResponse {
  const sections: ErrorsDashboardResponse["sections"] = {
    issues: section({
      buckets: [],
      issues: [],
      summary: { active: 0, backlog: 0, events: 0, resolved: 0, complete: true, byType: [], newPerDay: [] },
    }),
    sites: section([]),
    detail: section({ buckets: [], days: [], errors: [], requests: [], truncated: false }),
    runtime: section<RuntimeErrorsReport>(null),
    ...over,
  };
  return {
    generatedAt: "x",
    refreshing: false,
    refreshingSources: { glitchtip: false, posthog: false },
    configured: { glitchtip: true, posthog: true, vercel: true },
    sections,
    views: errorsViews(sections, { posthog: true }),
  };
}

function analyticsDashboard(): AnalyticsDashboardResponse {
  const sections = {
      traffic: section({
        buckets: [],
        totals: { pageviews: 10, sessions: 4 },
        pageviews: [],
        sessions: [],
        sites: [{ host: "a.dev", pageviews: 10, sessions: 4, series: [] }],
      }),
      dimensions: section({ rows: [], truncated: false }),
      paths: section([]),
      vitals: section([]),
      health: section([]),
      vercel: section({
        buckets: [],
        projectsTotal: 2,
        projectsEnabled: 1,
        failed: 0,
        incomplete: 0,
        roster: [],
        totals: { pageviews: 7, visitors: 3 },
        pageviews: [],
        visitors: [],
        projects: [],
      }),
    } as AnalyticsDashboardResponse["sections"];
  return {
    generatedAt: "x",
    refreshing: false,
    range: "24h",
    configured: { posthog: true, vercel: true },
    sections,
    views: analyticsViews(sections, { posthog: true, vercel: true }),
  };
}

const RUNTIME: RuntimeErrorsInput = {
  configured: true,
  report: {
    generatedAt: "2026-11-06T11:59:00Z",
    window: "24h",
    readAt: "2026-11-06T11:50:00Z",
    complete: true,
    total: 0,
    groups: [],
  },
  failing: null,
};

const UPTIME: UptimeResponse = {
  days: 7, overallUptimePercent: null, overallUptimeTone: "unknown",
  services: [{ slug: "hub", name: "Hub", uptimePercent: 100, totalChecks: 99 } as UptimeResponse["services"][number]],
};

const ok = <T>(data: T) => ({ ok: true as const, data });

function build(over: Partial<ReportInputs> = {}) {
  return buildReport({
    now: NOW,
    monitorVersion: "abc123",
    monitor: ok(MONITOR),
    deploys: ok({ live: LIVE }),
    integrations: ok(INTEGRATIONS),
    errors: ok(errorsDashboard()),
    runtimeErrors: ok(RUNTIME),
    analytics: ok(analyticsDashboard()),
    uptime: ok(UPTIME),
    ...over,
  });
}

function issue(over: Partial<ErrorIssue>): ErrorIssue {
  return {
    id: "1",
    shortId: null,
    title: "Err",
    type: null,
    source: null,
    level: "error",
    count: 1,
    userCount: 1,
    firstSeen: null,
    lastSeen: null,
    release: null,
    project: "web",
    permalink: null,
    active: true,
    ...over,
  };
}

function group(over: Partial<RuntimeErrorGroup>): RuntimeErrorGroup {
  return {
    key: "k",
    project: "shop",
    deploymentId: "dpl",
    domain: "shop.dev",
    source: "serverless",
    method: "GET",
    path: "/api/cart",
    status: 500,
    level: "error",
    message: "boom",
    count: 1,
    firstSeen: "2026-11-06T10:00:00Z",
    lastSeen: "2026-11-06T11:00:00Z",
    sampleRequestId: null,
    ...over,
  };
}

describe("buildReport — ported digest rules", () => {
  it("a healthy fleet is healthy and complete", () => {
    const report = build();
    expect(report.verdict).toBe("healthy");
    expect(report.complete).toBe(true);
    expect(report.findings).toEqual([]);
    expect(report.schema).toBe(REPORT_SCHEMA);
    expect(report.counts).toEqual({ critical: 0, major: 0, minor: 0 });
    expect(report.monitorVersion).toBe("abc123");
    expect(report.generatedAt).toBe(NOW.toISOString());
  });

  it("an unconfigured provider is disclosed but does not clear complete", () => {
    const report = build();
    expect(report.coverage.deploys.unconfigured).toEqual(["cloudflare-pages"]);
    expect(report.complete).toBe(true);
  });

  it("a failed source is never healthy", () => {
    const report = build({ errors: { ok: false, error: "GlitchTip timed out" } });
    expect(report.complete).toBe(false);
    expect(report.coverage.errors).toEqual({ ok: false, error: "GlitchTip timed out" });
    expect(report.sections.errors).toBeNull();
    expect(report.verdict).toBe("degraded");
    expect(report.findings).toContainEqual({
      severity: "major",
      source: "report",
      title: "could not read errors",
      detail: "GlitchTip timed out",
    });
  });

  it("a failed dashboard section makes the report incomplete", () => {
    const report = build({ errors: ok(errorsDashboard({ issues: { data: null, error: "GlitchTip 500", updatedAt: null } })) });
    expect(report.complete).toBe(false);
    expect(report.coverage.errors.notes).toContain("glitchtip issues: GlitchTip 500");
    expect(report.verdict).toBe("unknown");
  });

  it("open issues become findings with the issues-show key", () => {
    const p = problem({ detail: "Build failed\nmore", sourceUrl: "https://vercel.com/x" });
    const report = build({
      monitor: ok({ ...MONITOR, snapshot: { ...SNAPSHOT, overall: "degraded", openIssues: [openIssue(p)] }, problems: [p] }),
    });
    expect(report.findings).toEqual([
      {
        severity: "major",
        source: "monitor:vercel",
        title: "zork production: vercel failed",
        detail: "Build failed",
        since: "2026-11-06T10:00:00Z",
        link: "https://vercel.com/x",
        issueKey: "zork",
      },
    ]);
    expect(report.verdict).toBe("degraded");
  });

  it("a down endpoint is critical through the board's problem", () => {
    const snapshot = { ...SNAPSHOT, services: [service({ slug: "s", name: "Shop", status: "down", error: "timeout" })] };
    const down = problem({ target: "s", source: "http", name: "Shop", severity: "critical", state: "down", detail: "timeout" });
    const report = build({ monitor: ok({ ...MONITOR, snapshot, problems: [down] }) });
    expect(report.verdict).toBe("down");
    expect(report.findings).toHaveLength(1);
    expect(report.findings[0]).toMatchObject({ severity: "critical", source: "monitor:http", title: "Shop production: http down", detail: "timeout" });
  });

  it("a non-healthy service the board holds back is counted, not a finding", () => {
    // monitorHttp off reads 'down'; a slow probe inside its confirm window reads 'degraded'.
    const snapshot = {
      ...SNAPSHOT,
      services: [
        service({ slug: "off", name: "Off", status: "down", error: "timeout" }),
        service({ slug: "slow", name: "Slow", status: "degraded" }),
      ],
    };
    const report = build({ monitor: ok({ ...MONITOR, snapshot }) });
    expect(report.findings).toEqual([]);
    expect(report.verdict).toBe("healthy");
    expect(report.sections.monitor!.byStatus).toEqual({ degraded: 1, down: 1 });
  });

  it("failing deploys are the board's failed deploy problems, newest build first", () => {
    const problems = [
      problem({ target: "a", name: "a", deployment: { id: "d1", createdAt: "2026-11-06T09:00:00Z" } }),
      problem({
        target: "b",
        name: "b",
        environment: "staging",
        branch: "staging",
        commitMessage: "fix: thing\nbody",
        errorText: "Type error\nstack",
        sourceUrl: "https://vercel.com/x/b",
        deployment: { id: "d2", createdAt: "2026-11-06T10:00:00Z" },
      }),
      // Stuck is not failed; a problem with no deployment is not a deploy.
      problem({ target: "c", state: "stuck", deployment: { id: "d3", createdAt: "2026-11-06T11:00:00Z" } }),
      problem({ target: "s", source: "http", state: "down", severity: "critical" }),
    ];
    const report = build({ monitor: ok({ ...MONITOR, problems }) });
    const failing = report.sections.deploys!.failing;
    expect(failing.map((d) => d.id)).toEqual(["d2", "d1"]);
    expect(failing[0]).toEqual({
      id: "d2",
      platform: "vercel",
      project: "b",
      tier: "staging",
      branch: "staging",
      createdAt: "2026-11-06T10:00:00Z",
      commit: "fix: thing",
      error: "Type error",
      url: "https://vercel.com/x/b",
    });
  });

  it("the feed's newest row does not decide what is failing", () => {
    // The board holds d1's failure. In the feed a NEWER canceled row sits on its target,
    // and a failed preview the board ignores is the newest row of another; neither moves
    // the list, and a failure the feed no longer holds at all is still listed.
    const live = {
      ...LIVE,
      deployments: [
        deployment({ id: "d9", status: "canceled", createdAt: "2026-11-06T11:30:00Z" }),
        deployment({ id: "d1", status: "failed", createdAt: "2026-11-06T10:00:00Z" }),
        deployment({ id: "pv", projectName: "pv", providerProjectId: "ppv", environment: null, tier: null, status: "failed", createdAt: "2026-11-06T11:40:00Z" }),
      ],
    };
    const problems = [
      problem({ target: "zork", deployment: { id: "d1", createdAt: "2026-11-06T10:00:00Z" } }),
      problem({ target: "old", name: "old", deployment: { id: "d0", createdAt: "2026-11-01T10:00:00Z" } }),
    ];
    const report = build({ monitor: ok({ ...MONITOR, problems }), deploys: ok({ live }) });
    expect(report.sections.deploys!.failing.map((d) => d.id)).toEqual(["d1", "d0"]);
    expect(report.sections.deploys!.deployTargets).toBe(2);
  });

  it("with no board to read, nothing is listed as failing and a note says why", () => {
    const live = { ...LIVE, deployments: [deployment({ id: "d1", status: "failed" })] };
    const report = build({ monitor: { ok: false, error: "monitor down" }, deploys: ok({ live }) });
    expect(report.sections.deploys!.failing).toEqual([]);
    expect(report.coverage.deploys.notes).toContain("failing deploys come from the board, which could not be read");
  });

  it("an unconfirmed in-flight deploy is not counted as in flight (the /live demotion)", () => {
    const live = {
      ...LIVE,
      deployments: [
        deployment({ id: "a", projectName: "a", providerProjectId: "pa", status: "building" }),
        deployment({ id: "b", projectName: "b", providerProjectId: "pb", status: "building", effectiveStatus: "unknown" }),
      ],
    };
    expect(build({ deploys: ok({ live }) }).sections.deploys!.inFlight).toBe(1);
  });

  it("a stalled monitor is a major finding and incomplete", () => {
    const report = build({ monitor: ok({ ...MONITOR, lastCycleAt: "2026-11-06T11:00:00Z", stale: true }) });
    expect(report.complete).toBe(false);
    expect(report.coverage.monitor.notes?.[0]).toMatch(/^monitor data is stale/);
    expect(report.findings).toContainEqual(
      expect.objectContaining({ severity: "major", source: "monitor", title: "status monitor has stopped probing" }),
    );
    expect(report.sections.monitor!.stale).toBe(true);
  });

  it("active GlitchTip issues surface, fatal first, and are capped", () => {
    const issues = Array.from({ length: 20 }, (_, n) => issue({ id: String(n), title: `Err ${n}`, count: n }));
    issues.push(issue({ id: "x", title: "Quiet", active: false }));
    issues.push(issue({ id: "f", title: "Fatal", project: "api", level: "fatal" }));
    const base = errorsDashboard();
    const report = build({
      errors: ok(errorsDashboard({ issues: section({ ...base.sections.issues.data!, issues }) })),
    });
    const glitch = report.findings.filter((f) => f.source === "glitchtip");
    expect(glitch).toHaveLength(ERROR_ISSUE_CAP + 1); // + the "N more" line
    expect(glitch.find((f) => f.title === "6 more active GlitchTip issues not listed")!.severity).toBe("minor");
    expect(report.findings[0]).toMatchObject({ severity: "major", title: "api: Fatal" });
    expect(report.sections.errors!.active).toHaveLength(21);
    expect(report.sections.errors!.active[0]!.id).toBe("f");
    expect(glitch.every((f) => f.title !== "web: Quiet")).toBe(true);
  });

  it("PostHog site errors and low uptime are minor findings", () => {
    const sites = [
      { host: "a.dev", errors: 3, requests: 50, failures: 2, p95Ms: 800 },
      { host: "b.dev", errors: 0, requests: 9, failures: 0, p95Ms: null },
      // One aborted request in 100,000 is under the 5% line: not a finding.
      { host: "c.dev", errors: 0, requests: 100_000, failures: 1, p95Ms: null },
      // Errors with no requests to weigh them against still are.
      { host: "d.dev", errors: 2, requests: 0, failures: 0, p95Ms: null },
    ];
    const uptime: UptimeResponse = {
      days: 7, overallUptimePercent: null, overallUptimeTone: "unknown",
      services: [{ slug: "s", name: "Shop", uptimePercent: 97.5, totalChecks: 10 } as UptimeResponse["services"][number]],
    };
    const report = build({ errors: ok(errorsDashboard({ sites: section(sites) })), uptime: ok(uptime) });
    const titles = report.findings.map((f) => f.title);
    expect(titles).toContain("a.dev: 3 client errors, 2 failed of 50 requests");
    expect(titles).toContain("Shop: 97.50% up over 7d");
    expect(titles.some((t) => t.startsWith("b.dev"))).toBe(false);
    expect(titles.some((t) => t.startsWith("c.dev"))).toBe(false);
    expect(titles).toContain("d.dev: 2 client errors, 0 failed of 0 requests");
    expect(report.verdict).toBe("attention");
  });

  it("a dashboard still refreshing at the deadline is incomplete", () => {
    const report = build({ analytics: ok({ ...analyticsDashboard(), refreshing: true }) });
    expect(report.complete).toBe(false);
    expect(report.coverage.analytics.notes).toContain("analytics dashboard still refreshing at the deadline");
    expect(report.verdict).toBe("unknown");
  });
});

describe("buildReport — rules the server adds", () => {
  it("counts a GlitchTip error once: the board's error problem yields to the issue list", () => {
    const err = problem({ target: "errors|web", source: "glitchtip", name: "web", environment: null, severity: "minor", state: "erroring" });
    const base = errorsDashboard();
    const listed = build({
      monitor: ok({ ...MONITOR, problems: [err] }),
      errors: ok(errorsDashboard({ issues: section({ ...base.sections.issues.data!, issues: [issue({})] }) })),
    });
    expect(listed.findings.map((f) => f.source)).toEqual(["glitchtip"]);

    // With the issue list unreadable, the board's summary is the only word on it.
    const unlisted = build({ monitor: ok({ ...MONITOR, problems: [err] }), errors: { ok: false, error: "down" } });
    expect(unlisted.findings.map((f) => f.source)).toContain("monitor:glitchtip");
    expect(unlisted.findings.find((f) => f.source === "monitor:glitchtip")!.issueKey).toBeUndefined();
  });

  it("a GlitchTip list that is not current does not stand in for the board's error problem", () => {
    // The cached list predates a new crash: a failed refresh, one still running at the deadline
    // (every due read with wait=0), or a list not read to the end. The board's problem stays.
    const err = problem({ target: "errors|web", source: "glitchtip", name: "web", environment: null, severity: "major", state: "erroring" });
    const base = errorsDashboard();
    const cached = base.sections.issues.data!;
    const cases: Record<string, ErrorsDashboardResponse> = {
      "failed refresh": errorsDashboard({ issues: { data: cached, error: "GlitchTip 500", updatedAt: "2026-11-06T09:00:00Z" } }),
      "still refreshing": { ...base, refreshing: true, refreshingSources: { glitchtip: true, posthog: false } },
      "read partway": errorsDashboard({ issues: section({ ...cached, summary: { ...cached.summary, complete: false } }) }),
    };
    for (const [why, data] of Object.entries(cases)) {
      expect(glitchtipListCurrent(data), why).toBe(false);
      const report = build({ monitor: ok({ ...MONITOR, problems: [err] }), errors: ok(data) });
      expect(report.findings.map((f) => f.source), why).toContain("monitor:glitchtip");
      expect(report.verdict, why).toBe("degraded");
    }
    expect(glitchtipListCurrent(base)).toBe(true);
  });

  it("a PostHog refresh leaves the GlitchTip list current, so a crash is counted once", () => {
    const err = problem({ target: "errors|web", source: "glitchtip", name: "web", environment: null, severity: "major", state: "erroring" });
    const data = { ...errorsDashboard(), refreshing: true, refreshingSources: { glitchtip: false, posthog: true } };
    expect(glitchtipListCurrent(data)).toBe(true);
    const report = build({ monitor: ok({ ...MONITOR, problems: [err] }), errors: ok(data) });
    expect(report.findings.map((f) => f.source)).not.toContain("monitor:glitchtip");
  });

  it("an unreachable provider is one finding at the board's severity, not also its board problem", () => {
    const platform = problem({ target: "platform-health|vercel", source: "vercel", name: "Vercel", environment: null, severity: "minor", state: "unreachable" });
    const live = { ...LIVE, providers: { ...LIVE.providers, vercel: { configured: true, ok: false } } };
    const report = build({ monitor: ok({ ...MONITOR, problems: [platform] }), deploys: ok({ live }) });
    expect(report.findings).toEqual([{ severity: "minor", source: "provider:vercel", title: "vercel API unreachable from the monitor" }]);
    expect(report.verdict).toBe("attention");

    // With no board problem to follow (the board unread, or not yet graded) it is minor too.
    expect(build({ deploys: ok({ live }) }).findings).toEqual([
      { severity: "minor", source: "provider:vercel", title: "vercel API unreachable from the monitor" },
    ]);
  });

  it("a stale deploy keeps the board's severity: major in production, minor in testing", () => {
    // The board grades staleness by tier (staleProdProblems); the report must not re-grade it.
    const prod = problem({ state: "stale", severity: "major", target: "vercel|prj_2|" });
    const testing = problem({ state: "stale", severity: "minor", target: "vercel|prj_3|testing", name: "hub-help", environment: "testing" });
    const report = build({ monitor: ok({ ...MONITOR, problems: [prod, testing] }) });
    expect(report.findings.map((f) => [f.severity, f.title])).toEqual([
      ["major", "zork production: vercel stale"],
      ["minor", "hub-help testing: vercel stale"],
    ]);
    expect(report.verdict).toBe("degraded");
  });

  it("a testing-tier stale deploy alone is attention, not degraded", () => {
    const testing = problem({ state: "stale", severity: "minor", target: "vercel|prj_3|testing", name: "hub-help", environment: "testing" });
    const report = build({ monitor: ok({ ...MONITOR, problems: [testing] }) });
    expect(report.findings).toHaveLength(1);
    expect(report.findings[0]!.severity).toBe("minor");
    expect(report.verdict).toBe("attention");
  });

  it("an issue key is the target when two open issues share a name", () => {
    const a = problem({ target: "vercel|p1|", source: "vercel" });
    const b = problem({ target: "railway|p2|production", source: "railway" });
    const keys = issueKeys([openIssue(a), openIssue(b)]);
    expect(keys.get(a.target)).toBe(a.target);
    expect(keys.get(b.target)).toBe(b.target);
    expect(issueKeys([openIssue(a)]).get(a.target)).toBe("zork");
  });

  it("integration error is major, warn is minor, unconfigured is disclosed with its unset env", () => {
    const integrations: IntegrationsResponse = {
      generatedAt: "x",
      overall: "error",
      selfCheck: null,
      checks: [
        { id: "cron", label: "Cron", configured: true, ok: false, state: "error", detail: "missed\nmore" },
        { id: "posthog", label: "PostHog", configured: true, ok: true, state: "warn", detail: "slow" },
        { id: "railway", label: "Railway", configured: false, ok: false, state: "warn", detail: "", missingEnv: ["RAILWAY_TOKEN"] },
      ],
    };
    const report = build({ integrations: ok(integrations) });
    expect(report.findings).toEqual([
      { severity: "major", source: "integration:cron", title: "Cron integration error", detail: "missed" },
      { severity: "minor", source: "integration:posthog", title: "PostHog integration warn", detail: "slow" },
    ]);
    expect(report.coverage.integrations.unconfigured).toEqual(["Railway (unset: RAILWAY_TOKEN)"]);
    expect(report.sections.integrations!.checks[0]!.detail).toBe("missed");
  });

  it("an integration in error is a finding even when it reports itself unconfigured", () => {
    // checkCloudflare with a token but no discoverable account, and the fallback for a check
    // that threw, both say configured:false with state 'error'; the board shows them red.
    const integrations: IntegrationsResponse = {
      generatedAt: "x",
      overall: "error",
      selfCheck: null,
      checks: [
        {
          id: "cloudflare", label: "Cloudflare", configured: false, ok: false, state: "error",
          detail: "CLOUDFLARE_ACCOUNT_ID not set and could not auto-discover", missingEnv: ["CLOUDFLARE_ACCOUNT_ID"],
        },
        { id: "stats-store", label: "Stats store", configured: false, ok: false, state: "error", detail: "boom" },
      ],
    };
    const report = build({ integrations: ok(integrations) });
    expect(report.findings).toEqual([
      { severity: "major", source: "integration:cloudflare", title: "Cloudflare integration error", detail: "CLOUDFLARE_ACCOUNT_ID not set and could not auto-discover" },
      { severity: "major", source: "integration:stats-store", title: "Stats store integration error", detail: "boom" },
    ]);
    expect(report.coverage.integrations.unconfigured).toBeUndefined();
    expect(report.verdict).toBe("degraded");
  });

  it("runtime errors: fatal or a frequent 5xx is major, majors are listed first, and the rest is counted", () => {
    const groups = [
      ...Array.from({ length: 20 }, (_, i) => group({ key: `m${i}`, status: 404, level: "error", count: 50 })),
      group({ key: "fatal", level: "fatal", status: null, path: null, method: null, source: "edge" }),
      group({ key: "5xx", status: 503, count: 5 }),
      group({ key: "rare5xx", status: 500, count: 4 }),
    ];
    const report = build({ runtimeErrors: ok({ ...RUNTIME, report: { ...RUNTIME.report, total: 30, groups } }) });
    const runtime = report.findings.filter((f) => f.source === "vercel-runtime");
    expect(runtime).toHaveLength(RUNTIME_GROUP_CAP + 1);
    expect(runtime.filter((f) => f.severity === "major").map((f) => f.title)).toEqual([
      "shop: GET /api/cart → 503",
      "shop: edge",
    ]);
    expect(runtime.find((f) => f.title.includes("more Vercel runtime"))!.title).toBe(
      `${30 - RUNTIME_GROUP_CAP} more Vercel runtime error groups not listed`,
    );
    expect(report.sections.runtimeErrors!.groups).toHaveLength(23);
    expect(report.verdict).toBe("degraded");
  });

  it("a cap that hides a fatal GlitchTip issue is itself major", () => {
    const fatal = Array.from({ length: ERROR_ISSUE_CAP + 2 }, (_, n) =>
      issue({ id: String(n), title: `Fatal ${n}`, level: "fatal", count: 100 - n }),
    );
    const base = errorsDashboard();
    const report = build({
      errors: ok(errorsDashboard({ issues: section({ ...base.sections.issues.data!, issues: fatal }) })),
    });
    const more = report.findings.find((f) => f.title === "2 more active GlitchTip issues not listed")!;
    expect(more.severity).toBe("major");
  });

  it("a cap that hides a major runtime group is itself major", () => {
    const groups = Array.from({ length: RUNTIME_GROUP_CAP + 3 }, (_, i) =>
      group({ key: `f${i}`, level: "fatal", status: null }),
    );
    const report = build({ runtimeErrors: ok({ ...RUNTIME, report: { ...RUNTIME.report, total: groups.length, groups } }) });
    const more = report.findings.find((f) => f.title === "3 more Vercel runtime error groups not listed")!;
    expect(more.severity).toBe("major");
  });

  it("runtime errors are dated by the read, not by the report", () => {
    const report = build();
    expect(report.coverage.runtimeErrors.updatedAt).toBe("2026-11-06T11:50:00Z");
    expect(report.coverage.runtimeErrors.notes).toBeUndefined();
    expect(report.sections.runtimeErrors).toMatchObject({ readAt: "2026-11-06T11:50:00Z", complete: true });
  });

  it("a cut-short, failing or missing runtime read is a note", () => {
    const cut = build({ runtimeErrors: ok({ ...RUNTIME, report: { ...RUNTIME.report, complete: false } }) });
    expect(cut.coverage.runtimeErrors.notes).toEqual([
      "vercel runtime read was cut short; there may be more groups than listed",
    ]);
    const failing = build({
      runtimeErrors: ok({ ...RUNTIME, failing: { streak: 2, atMs: Date.parse("2026-11-06T11:55:00Z") } }),
    });
    expect(failing.coverage.runtimeErrors.notes).toEqual([
      "last 2 vercel runtime reads failed (latest 2026-11-06T11:55:00.000Z); these groups are from the read at 2026-11-06T11:50:00Z",
    ]);
    const never = build({ runtimeErrors: ok({ ...RUNTIME, report: { ...RUNTIME.report, readAt: null } }) });
    expect(never.coverage.runtimeErrors.notes).toEqual(["vercel runtime errors not read yet"]);
    expect(never.coverage.runtimeErrors.updatedAt).toBeNull();
  });

  it("runtime errors with no Vercel token are unconfigured, not a gap", () => {
    const report = build({ runtimeErrors: ok({ ...RUNTIME, configured: false }) });
    expect(report.coverage.runtimeErrors.unconfigured).toEqual(["vercel"]);
    expect(report.complete).toBe(true);
  });

  it("the monitor having never cycled is a note, not a finding", () => {
    const report = build({ monitor: ok({ ...MONITOR, lastCycleAt: null }) });
    expect(report.findings).toEqual([]);
    expect(report.coverage.monitor.notes).toEqual(["monitor has not completed a probe cycle"]);
    expect(report.verdict).toBe("unknown");
  });

  it("vercel analytics projects that could not be read are a note", () => {
    const analytics = analyticsDashboard();
    analytics.sections.vercel = section({ ...analytics.sections.vercel.data!, failed: 2 });
    const report = build({ analytics: ok(analytics) });
    expect(report.coverage.analytics.notes).toEqual(["vercel web analytics: 2 projects could not be read"]);
  });

  it("failing deploys carry their log tail or why there is none", () => {
    const problems = [
      problem({ target: "a", name: "a", deployment: { id: "a", createdAt: "2026-11-06T10:00:00Z" } }),
      problem({ target: "b", name: "b", deployment: { id: "b", createdAt: "2026-11-06T09:00:00Z" } }),
    ];
    const report = build({
      monitor: ok({ ...MONITOR, problems }),
      deploys: ok({ live: LIVE, logs: { a: { tail: ["x", "y"], lines: 9 }, b: { error: "no build log" } } }),
    });
    const byId = Object.fromEntries(report.sections.deploys!.failing.map((d) => [d.id, d]));
    expect(byId.a).toMatchObject({ logTail: ["x", "y"], logLines: 9 });
    expect(byId.a!.logError).toBeUndefined();
    expect(byId.b).toMatchObject({ logError: "no build log" });
  });

  it("findings sort by severity, then source, then title, and counts add up", () => {
    const report = build({
      uptime: ok({ days: 7, overallUptimePercent: null, overallUptimeTone: "unknown", services: [{ slug: "s", name: "Shop", uptimePercent: 90, totalChecks: 1 } as UptimeResponse["services"][number]] }),
      integrations: { ok: false, error: "x" },
      monitor: ok({ ...MONITOR, problems: [problem({ target: "s", source: "http", severity: "critical", state: "down" })] }),
    });
    expect(report.findings.map((f) => [f.severity, f.source])).toEqual([
      ["critical", "monitor:http"],
      ["major", "report"],
      ["minor", "uptime"],
    ]);
    expect(report.counts).toEqual({ critical: 1, major: 1, minor: 1 });
  });

  it("every source is covered, and a section is null exactly when its source failed", () => {
    const report = build({ uptime: { ok: false, error: "db" } });
    expect(Object.keys(report.coverage)).toEqual(["monitor", "deploys", "integrations", "errors", "runtimeErrors", "analytics", "uptime"]);
    for (const [name, cov] of Object.entries(report.coverage)) {
      expect(report.sections[name as keyof typeof report.sections] === null).toBe(!cov.ok);
    }
  });
});
