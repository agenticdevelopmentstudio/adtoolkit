import { describe, it, expect } from "vitest";
import type { DeploymentDTO } from "../types";
import type { ActivityRow, Problem } from "./board-types";
import { isRealEnvDeploy, isRealEnvDeployRow, activityWindowLabel, isUnresolvedActivity } from "./overview";

function deploy(overrides: Partial<DeploymentDTO>): DeploymentDTO {
  return {
    id: "vc_1",
    platform: "vercel",
    projectName: "adh",
    status: "success",
    buildPhase: "built",
    deployPhase: "none",
    environment: "production",
    tier: "production",
    commitHash: "abc1234def",
    commitMessage: "test commit\nsecond line",
    branch: "main",
    commitRepo: null,
    url: "https://x.vercel.app",
    errorText: null,
    liveHost: null,
    createdAt: "2026-06-04T18:00:00.000Z",
    ...overrides,
  };
}

// `envFromProject` moved to @agentic-toolkit/deploy-platform/canon and is tested there
// (src/canon/canon.test.ts) — both name shapes and the production default.

describe("isRealEnvDeploy", () => {
  it("drops Vercel preview builds (environment=null) but keeps real env deploys", () => {
    const preview = deploy({ id: "p", platform: "vercel", environment: null, status: "failed" });
    const prod = deploy({ id: "r", platform: "vercel", environment: "production", status: "failed" });
    expect(isRealEnvDeploy(preview)).toBe(false);
    expect(isRealEnvDeploy(prod)).toBe(true);
  });

  it("keeps non-Vercel deploys even with a null environment", () => {
    const cf = deploy({ id: "cf", platform: "cloudflare-pages", environment: null, status: "success" });
    expect(isRealEnvDeploy(cf)).toBe(true);
  });

  it("isRealEnvDeployRow (raw form) drops Vercel preview rows incl. empty-string env", () => {
    expect(isRealEnvDeployRow("vercel", null)).toBe(false);
    expect(isRealEnvDeployRow("vercel", "")).toBe(false);
    expect(isRealEnvDeployRow("vercel", "production")).toBe(true);
    expect(isRealEnvDeployRow("railway", null)).toBe(true);
    expect(isRealEnvDeployRow("cloudflare-pages", null)).toBe(true);
  });
});

describe("activityWindowLabel — the caption for the window the SERVER chose", () => {
  const HOUR = 3_600_000;

  it("names the default 24h window", () => {
    expect(activityWindowLabel(0, 24 * HOUR)).toBe("24h");
  });

  it("switches to days once the window is at least two of them", () => {
    expect(activityWindowLabel(0, 7 * 24 * HOUR)).toBe("7d");
    // 47h is not a whole number of days, so it stays in hours rather than rounding to "2d"
    // and captioning the counts with a window nobody configured.
    expect(activityWindowLabel(0, 47 * HOUR)).toBe("47h");
  });

  it("never captions a sub-hour window as 0h", () => {
    expect(activityWindowLabel(0, 60_000)).toBe("1h");
  });
});

describe("isUnresolvedActivity — the 'in progress or failed only' rule", () => {
  const T = "vercel:site";
  function row(o: Partial<ActivityRow>): ActivityRow {
    return {
      id: "r", kind: "deploy", step: "build", source: "vercel", tone: "bad", verb: "build failed",
      target: T, name: "site", environment: "production", detail: null, sourceUrl: null,
      liveUrl: null, commitHash: null, commitMessage: null, commitRepo: null, branch: null,
      errorText: null, at: "2026-10-30T12:00:00.000Z", ...o,
    };
  }
  function problem(o: Partial<Problem>): Problem {
    return {
      target: T, source: "vercel", name: "site", environment: "production", severity: "major",
      state: "failed", statusCode: null, detail: null, sourceUrl: null, liveUrl: null,
      commitHash: null, commitMessage: null, commitRepo: null, branch: null, errorText: null,
      since: "2026-10-30T12:00:00.000Z", ...o,
    };
  }

  it("keeps an in-flight build or deploy row with no problem at all", () => {
    expect(isUnresolvedActivity(row({ tone: "progress", verb: "building" }), [])).toBe(true);
    expect(isUnresolvedActivity(row({ step: "deploy", tone: "progress", verb: "deploying" }), [])).toBe(true);
  });

  it("drops finished, canceled and unknown rows", () => {
    for (const tone of ["good", "neutral", "stale"] as const) {
      expect(isUnresolvedActivity(row({ tone }), [problem({})])).toBe(false);
    }
  });

  it("keeps a failure only while its target is still a problem", () => {
    expect(isUnresolvedActivity(row({}), [problem({})])).toBe(true);
    expect(isUnresolvedActivity(row({}), [])).toBe(false);
    expect(isUnresolvedActivity(row({}), [problem({ target: "vercel:other" })])).toBe(false);
  });

  it("drops a failure older than the open problem's onset — an earlier, recovered run", () => {
    const p = problem({ since: "2026-10-30T13:00:00.000Z" });
    expect(isUnresolvedActivity(row({ at: "2026-10-30T12:00:00.000Z" }), [p])).toBe(false);
    expect(isUnresolvedActivity(row({ at: "2026-10-30T13:05:00.000Z" }), [p])).toBe(true);
  });

  it("treats an incident opening (minor ones included) like a failure, never as in flight", () => {
    const opened = row({ kind: "probe", step: null, source: "http", target: "ep-1", verb: "down" });
    const minor = { ...opened, tone: "progress" as const, verb: "degraded" };
    expect(isUnresolvedActivity(opened, [])).toBe(false);
    expect(isUnresolvedActivity(minor, [])).toBe(false);
    expect(isUnresolvedActivity(opened, [problem({ target: "ep-1", source: "http" })])).toBe(true);
    expect(isUnresolvedActivity(minor, [problem({ target: "ep-1", source: "http" })])).toBe(true);
  });
});
