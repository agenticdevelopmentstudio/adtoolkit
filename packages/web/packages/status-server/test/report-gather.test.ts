import { HTTPException } from "hono/http-exception";
import { describe, expect, it, vi } from "vitest";
import type { Problem } from "../src/board";
import type { LiveDeploymentDTO, LiveSnapshot } from "../src/monitor/live-types";
import {
  gatherReport,
  LOG_DEPLOY_CAP,
  LOG_TAIL_LINES,
  logTail,
  parseReportParams,
  REPORT_DEFAULTS,
  type ReportSources,
} from "../src/report/report-gather";
import type { DashboardSet } from "../src/telemetry/dashboard/dashboard-set";
import type { AnalyticsDashboardResponse, ErrorsDashboardResponse } from "../src/telemetry/dashboard/types";
import { analyticsViews, errorsViews } from "../src/telemetry/dashboard/views";

// The reading half: every source fail-soft, the dashboards given `wait` to settle, and a
// dashboard still refreshing at the deadline disclosed rather than read as healthy.

const NOW = () => new Date("2026-11-06T12:00:00Z");

function errorsDash(refreshing: boolean): ErrorsDashboardResponse {
  const sections = {
    issues: { data: null, error: null, updatedAt: null },
    sites: { data: null, error: null, updatedAt: null },
    detail: { data: null, error: null, updatedAt: null },
    runtime: { data: null, error: null, updatedAt: null },
  };
  return {
    generatedAt: "x",
    refreshing,
    refreshingSources: { glitchtip: refreshing, posthog: false },
    configured: { glitchtip: false, posthog: false, vercel: false },
    sections,
    views: errorsViews(sections, { posthog: false }),
  };
}

function analyticsDash(refreshing: boolean): AnalyticsDashboardResponse {
  const empty = { data: null, error: null, updatedAt: null };
  return {
    generatedAt: "x",
    refreshing,
    range: "24h",
    configured: { posthog: false, vercel: false },
    sections: { traffic: empty, dimensions: empty, paths: empty, vitals: empty, health: empty, vercel: empty },
    views: analyticsViews(
      { traffic: empty, dimensions: empty, paths: empty, vitals: empty, health: empty, vercel: empty },
      { posthog: false, vercel: false },
    ),
  };
}

function failed(id: string, createdAt: string): LiveDeploymentDTO {
  return {
    id,
    platform: "vercel",
    projectName: id,
    providerProjectId: `p-${id}`,
    status: "failed",
    buildPhase: null,
    deployPhase: "failed",
    environment: "production",
    tier: "production",
    commitHash: null,
    commitMessage: null,
    branch: "main",
    commitRepo: null,
    url: null,
    errorText: "boom",
    liveHost: null,
    createdAt,
    phaseConfirmedAt: createdAt,
    effectiveStatus: "failed",
  } as LiveDeploymentDTO;
}

/** The board's failed deploy problem for `failed(id, createdAt)`'s row. */
function failedProblem(id: string, createdAt: string): Problem {
  return {
    target: `vercel|p-${id}|`,
    source: "vercel",
    name: id,
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
    branch: "main",
    errorText: "boom",
    since: createdAt,
    deployment: { id, createdAt },
  };
}

/** A monitor read whose board holds these problems. */
function monitorWith(problems: Problem[]): ReportSources["monitor"] {
  return async () => ({
    snapshot: { generatedAt: "x", overall: "healthy", services: [], openIssues: [] },
    problems,
    lastCycleAt: "2026-11-06T11:59:00Z",
    stale: false,
  });
}

const LIVE: LiveSnapshot = {
  generatedAt: "x",
  lastCycleAt: "x",
  probeIntervalMs: 60_000,
  monitorVersion: "v",
  services: [],
  deployments: [],
  staleProd: [],
  providers: {
    vercel: { configured: true, ok: true },
    "cloudflare-pages": { configured: true, ok: true },
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

function dashboards(over: Partial<DashboardSet> = {}): DashboardSet {
  return {
    analytics: () => analyticsDash(false),
    errors: async () => errorsDash(false),
    settleAnalytics: async () => true,
    settleErrors: async () => true,
    ...over,
  };
}

function sources(over: Partial<ReportSources> = {}): ReportSources {
  return {
    monitorVersion: "v1",
    dashboards: dashboards(),
    monitor: async () => ({
      snapshot: { generatedAt: "x", overall: "healthy", services: [], openIssues: [] },
      problems: [],
      lastCycleAt: "2026-11-06T11:59:00Z",
      stale: false,
    }),
    live: async () => LIVE,
    deployLog: async () => ({ error: "unused" }),
    integrations: async () => ({ generatedAt: "x", overall: "ok", checks: [], selfCheck: null }),
    runtimeErrors: async () => ({
      configured: false,
      report: { generatedAt: "x", window: "24h", readAt: null, complete: true, total: 0, groups: [] },
      failing: null,
    }),
    uptime: async (days) => ({ days, services: [], overallUptimePercent: null, overallUptimeTone: "unknown" }),
    ...over,
  };
}

const params = (over: Partial<typeof REPORT_DEFAULTS> = {}) => ({ ...REPORT_DEFAULTS, wait: 0, ...over });

describe("gatherReport", () => {
  it("reads every source into a healthy, complete report", async () => {
    const report = await gatherReport(sources(), params(), NOW);
    expect(report.verdict).toBe("healthy");
    expect(report.complete).toBe(true);
    expect(report.monitorVersion).toBe("v1");
    expect(report.generatedAt).toBe("2026-11-06T12:00:00.000Z");
  });

  it("a source that throws is uncovered, a major finding, and clears complete — the rest still read", async () => {
    const report = await gatherReport(
      sources({
        integrations: async () => {
          throw new Error("integrations exploded");
        },
      }),
      params(),
      NOW,
    );
    expect(report.coverage.integrations).toEqual({ ok: false, error: "integrations exploded" });
    expect(report.sections.integrations).toBeNull();
    expect(report.findings).toContainEqual({
      severity: "major",
      source: "report",
      title: "could not read integrations",
      detail: "integrations exploded",
    });
    expect(report.complete).toBe(false);
    expect(report.verdict).toBe("degraded");
    expect(report.coverage.uptime.ok).toBe(true);
    expect(report.sections.uptime).not.toBeNull();
  });

  it("a dashboard refreshing on first read is given `wait` to settle, then read again", async () => {
    let settled = false;
    const settleErrors = vi.fn(async (ms: number) => {
      settled = true;
      return ms > 0;
    });
    const settleAnalytics = vi.fn(async () => {
      settled = true;
      return true;
    });
    const report = await gatherReport(
      sources({
        dashboards: dashboards({
          errors: async () => errorsDash(!settled),
          analytics: () => analyticsDash(!settled),
          settleErrors,
          settleAnalytics,
        }),
      }),
      params({ wait: 5, range: "7d" }),
      NOW,
    );
    expect(settleErrors).toHaveBeenCalledWith(5000);
    expect(settleAnalytics).toHaveBeenCalledWith("7d", 5000);
    expect(report.complete).toBe(true);
    expect(report.coverage.errors.notes).toBeUndefined();
  });

  it("a dashboard still refreshing at the deadline is a coverage note, never silence", async () => {
    const report = await gatherReport(
      sources({
        dashboards: dashboards({ errors: async () => errorsDash(true), settleErrors: async () => false }),
      }),
      params({ wait: 1 }),
      NOW,
    );
    expect(report.coverage.errors.notes).toContain("errors dashboard still refreshing at the deadline");
    expect(report.complete).toBe(false);
    expect(report.verdict).toBe("unknown");
  });

  it("wait=0 never waits on a refreshing dashboard", async () => {
    const settleAnalytics = vi.fn(async () => true);
    const report = await gatherReport(
      sources({ dashboards: dashboards({ analytics: () => analyticsDash(true), settleAnalytics }) }),
      params({ wait: 0 }),
      NOW,
    );
    expect(settleAnalytics).not.toHaveBeenCalled();
    expect(report.coverage.analytics.notes).toContain("analytics dashboard still refreshing at the deadline");
  });

  it("passes `days` to the uptime read", async () => {
    const report = await gatherReport(sources(), params({ days: 30 }), NOW);
    expect(report.sections.uptime!.days).toBe(30);
  });

  it("logs=1 attaches the log tail of at most five failing deploys, newest first", async () => {
    const problems = Array.from({ length: 7 }, (_, i) => failedProblem(`d${i}`, `2026-11-06T0${i}:00:00.000Z`));
    const deployLog = vi.fn(async (id: string) =>
      id === "d6" ? { error: "no build log for vercel (or no token)" } : logTail(Array.from({ length: 60 }, (_, n) => `${id} ${n}`).join("\n")),
    );
    // The feed holds none of them: the logs follow the board, not the feed.
    const report = await gatherReport(sources({ monitor: monitorWith(problems), deployLog }), params({ logs: true }), NOW);
    expect(deployLog).toHaveBeenCalledTimes(LOG_DEPLOY_CAP);
    expect(deployLog.mock.calls.map(([id]) => id)).toEqual(["d6", "d5", "d4", "d3", "d2"]);
    const failing = report.sections.deploys!.failing;
    expect(failing.map((d) => d.id)).toEqual(["d6", "d5", "d4", "d3", "d2", "d1", "d0"]);
    expect(failing[0]).toMatchObject({ logError: "no build log for vercel (or no token)" });
    expect(failing[1]!.logTail).toHaveLength(LOG_TAIL_LINES);
    expect(failing[1]!.logTail!.at(-1)).toBe("d5 59");
    expect(failing[1]!.logLines).toBe(60);
    expect(failing[6]!.logTail).toBeUndefined();
    expect(failing[6]!.logError).toBeUndefined();
  });

  it("without logs no build log is read", async () => {
    const deployLog = vi.fn(async () => ({ error: "x" }));
    await gatherReport(
      sources({
        monitor: monitorWith([failedProblem("a", "2026-11-06T01:00:00Z")]),
        live: async () => ({ ...LIVE, deployments: [failed("a", "2026-11-06T01:00:00Z")] }),
        deployLog,
      }),
      params(),
      NOW,
    );
    expect(deployLog).not.toHaveBeenCalled();
  });

  it("a log read that throws becomes that deploy's logError", async () => {
    const report = await gatherReport(
      sources({
        monitor: monitorWith([failedProblem("a", "2026-11-06T01:00:00Z")]),
        deployLog: async () => {
          throw new Error("socket hang up");
        },
      }),
      params({ logs: true }),
      NOW,
    );
    expect(report.sections.deploys!.failing[0]).toMatchObject({ logError: "socket hang up" });
  });
});

describe("logTail", () => {
  it("keeps the last lines and counts them all, ignoring trailing blank lines", () => {
    expect(logTail("a\nb\r\nc\n\n")).toEqual({ tail: ["a", "b", "c"], lines: 3 });
    expect(logTail("")).toEqual({ tail: [], lines: 0 });
  });
});

describe("parseReportParams", () => {
  it("defaults", () => {
    expect(parseReportParams({})).toEqual({ range: "24h", days: 7, wait: 20, logs: false });
    expect(parseReportParams({ range: "", days: "", wait: "", logs: "" } as never)).toMatchObject({ days: 7, wait: 20 });
  });

  it("accepts the CLI's query and the MCP tool's typed values", () => {
    expect(parseReportParams({ range: "30d", days: "365", wait: "0", logs: "1" })).toEqual({
      range: "30d",
      days: 365,
      wait: 0,
      logs: true,
    });
    expect(parseReportParams({ range: "7d", days: 1, wait: 60, logs: true })).toEqual({ range: "7d", days: 1, wait: 60, logs: true });
    expect(parseReportParams({ logs: "0" }).logs).toBe(false);
  });

  const bad: [Parameters<typeof parseReportParams>[0], string][] = [
    [{ range: "1y" }, "range must be one of 24h, 7d, 30d"],
    [{ days: "0" }, "days must be an integer 1-365"],
    [{ days: "366" }, "days must be an integer 1-365"],
    [{ days: "1.5" }, "days must be an integer 1-365"],
    [{ days: "seven" }, "days must be an integer 1-365"],
    [{ wait: "-1" }, "wait must be an integer 0-60"],
    [{ wait: 61 }, "wait must be an integer 0-60"],
    [{ logs: "yes" }, "logs must be 0 or 1"],
    [{ logs: 2 }, "logs must be 0 or 1"],
  ];
  it.each(bad)("rejects %j with a 400", (raw, message) => {
    try {
      parseReportParams(raw);
      expect.unreachable();
    } catch (err) {
      expect(err).toBeInstanceOf(HTTPException);
      expect((err as HTTPException).status).toBe(400);
      expect((err as HTTPException).message).toBe(message);
    }
  });
});
