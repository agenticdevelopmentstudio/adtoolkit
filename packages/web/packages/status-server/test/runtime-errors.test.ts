import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { _resetProviderCooldowns, rateLimitedUntil } from "@adh-sdk/deploy-platform/cooldown";
import {
  groupIdentity,
  messageShape,
  groupRuntimeEntries,
  loadRuntimeErrorsReport,
  logEventToEntry,
  normalizePath,
  responseEventToEntry,
  runtimeErrorsReport,
  RUNTIME_ERROR_REPORT_CAP,
  RUNTIME_ERROR_WINDOW_MS,
  worseLevel,
  type RuntimeProject,
} from "../src/telemetry/runtime-errors";
import { vercelRuntimeFetcher } from "../src/telemetry/fetchers/vercel-runtime";
import { collectTelemetry } from "../src/telemetry/server";
import type { Fetcher } from "../src/telemetry/ports";
import type { RuntimeErrorGroup, RuntimeLogEntry } from "../src/telemetry/types";
import { createLibsqlStorage } from "../src/libsql";
import { runIntegrationsCheck, _resetSelfCheckStability } from "../src/monitor/integrations";
import { freshDb } from "./helpers/db";
import { testConfig } from "./helpers/config";

const NOW = Date.parse("2026-11-06T12:00:00.000Z");
const PROJECTS: ReadonlyMap<string, RuntimeProject> = new Map([
  ["prj_site", { name: "site-production", domain: "site.example.com" }],
]);

function entry(over: Partial<RuntimeLogEntry> = {}): RuntimeLogEntry {
  return {
    project: "site-production",
    deploymentId: "dpl_1",
    domain: "site.example.com",
    requestId: "req_1",
    timestampMs: NOW - 60_000,
    level: "error",
    source: "function",
    method: "GET",
    path: "/api/posts/123",
    status: null,
    message: "boom\nat handler (index.js:1)",
    ...over,
  };
}

function group(over: Partial<RuntimeErrorGroup> = {}): RuntimeErrorGroup {
  return {
    key: "k",
    project: "p",
    deploymentId: "d",
    domain: null,
    source: "function",
    method: "GET",
    path: "/",
    status: null,
    level: "error",
    message: "m",
    count: 1,
    firstSeen: new Date(NOW - 60_000).toISOString(),
    lastSeen: new Date(NOW - 60_000).toISOString(),
    sampleRequestId: null,
    ...over,
  };
}

const iso = (ms: number) => new Date(ms).toISOString();

describe("logEventToEntry", () => {
  const raw = {
    timestamp: iso(NOW),
    projectId: "prj_site",
    deploymentId: "dpl_1",
    requestId: "req_1",
    source: "function",
    message: "m",
  };

  it("keeps error and fatal lines, dated and placed by the event", () => {
    expect(logEventToEntry({ ...raw, level: "error" }, PROJECTS)).toMatchObject({
      level: "error",
      project: "site-production",
      domain: "site.example.com",
      requestId: "req_1",
      timestampMs: NOW,
      status: null,
    });
    expect(logEventToEntry({ ...raw, level: "fatal" }, PROJECTS)?.level).toBe("fatal");
  });

  it("drops lower levels, undated events, and projects that are not production", () => {
    expect(logEventToEntry({ ...raw, level: "warning" }, PROJECTS)).toBeNull();
    expect(logEventToEntry({ ...raw, level: undefined }, PROJECTS)).toBeNull();
    expect(logEventToEntry({ ...raw, level: "error", timestamp: "x" }, PROJECTS)).toBeNull();
    expect(logEventToEntry({ ...raw, level: "error", projectId: "prj_staging" }, PROJECTS)).toBeNull();
  });

  it("strips the query and fragment, and prefers the event's own domain", () => {
    const e = logEventToEntry(
      { ...raw, level: "error", requestPath: "/a/b?token=x#frag", requestMethod: "POST", domain: "other.example.com" },
      PROJECTS,
    )!;
    expect(e).toMatchObject({ path: "/a/b", method: "POST", domain: "other.example.com" });
    expect(logEventToEntry({ ...raw, level: "error", requestPath: "?q=1" }, PROJECTS)?.path).toBe("/");
  });
});

describe("responseEventToEntry", () => {
  const raw = { timestamp: iso(NOW), projectId: "prj_site", requestId: "req_9", requestPath: "/api/x" };

  it("keeps 5xx responses as error entries", () => {
    expect(responseEventToEntry({ ...raw, httpStatus: 503 }, PROJECTS)).toMatchObject({
      level: "error",
      source: "response",
      status: 503,
      message: "HTTP 503",
      requestId: "req_9",
    });
  });

  it("drops anything below 500 and anything without a status", () => {
    expect(responseEventToEntry({ ...raw, httpStatus: 404 }, PROJECTS)).toBeNull();
    expect(responseEventToEntry(raw, PROJECTS)).toBeNull();
  });
});

describe("grouping", () => {
  it("reads id-like segments as :id and leaves words alone", () => {
    expect(normalizePath("/posts/123/edit")).toBe("/posts/:id/edit");
    expect(normalizePath("/u/3f2504e0-4f89-11d3-9a0c-0305e82c3301")).toBe("/u/:id");
    expect(normalizePath("/blob/deadbeef1234abcd")).toBe("/blob/:id");
    expect(normalizePath("/s/V1StGXR8Z5jdHi6BmyT2x")).toBe("/s/:id");
    expect(normalizePath("/about/facebook-account")).toBe("/about/facebook-account");
    expect(normalizePath("/")).toBe("/");
    expect(normalizePath(null)).toBeNull();
  });

  it("keys on the normalized path and the first message line, stably", () => {
    const a = groupIdentity(entry({ path: "/api/posts/1", message: "boom\nstack a" }));
    const b = groupIdentity(entry({ path: "/api/posts/2", message: "boom\nstack b", requestId: "req_2" }));
    expect(a.key).toBe(b.key);
    expect(a.key).toMatch(/^[0-9a-f]{32}$/);
    expect(a).toMatchObject({ path: "/api/posts/:id", message: "boom" });
    expect(groupIdentity(entry({ status: 502 })).key).not.toBe(a.key);
    expect(groupIdentity(entry({ message: "x".repeat(300) })).message).toHaveLength(200);
  });

  it("a message that embeds an id, number or timestamp is one error, not one per value", () => {
    expect(messageShape("Order 8231 not found")).toBe("Order # not found");
    expect(messageShape("user 3f2504e0-4f89-11d3-9a0c-0305e82c3301 has no plan")).toBe("user :id has no plan");
    expect(messageShape("timeout after 3000ms at 2026-11-06T10:00:00Z")).toBe("timeout after #ms at #-#-#T#:#:#Z");
    expect(messageShape("Cannot read properties of undefined (reading 'id')")).toBe("Cannot read properties of undefined (reading 'id')");

    // 40 requests to /api/orders/<n>, each logging its own order number, are one group of 40.
    const entries = Array.from({ length: 40 }, (_, i) =>
      entry({ path: `/api/orders/${8231 + i}`, message: `Order ${8231 + i} not found`, requestId: `r${i}`, timestampMs: 1_000 + i }),
    );
    const groups = groupRuntimeEntries(entries);
    expect(groups).toHaveLength(1);
    expect(groups[0]).toMatchObject({ count: 40, path: "/api/orders/:id", message: "Order 8231 not found" });
    // Different words stay different errors.
    expect(groupIdentity(entry({ message: "Order 1 not found" })).key).not.toBe(groupIdentity(entry({ message: "Order 1 shipped" })).key);
  });

  it("folds a read: counts, worst level, and the newest event's deployment and sample", () => {
    const [g, ...rest] = groupRuntimeEntries([
      entry({ requestId: "r1", timestampMs: 1_000, level: "error", deploymentId: "dpl_old" }),
      entry({ requestId: "r2", timestampMs: 3_000, level: "error", deploymentId: "dpl_new" }),
      entry({ requestId: "r3", timestampMs: 2_000, level: "fatal", deploymentId: "dpl_old" }),
    ]);
    expect(rest).toEqual([]);
    expect(g).toMatchObject({
      count: 3,
      level: "fatal",
      firstSeen: iso(1_000),
      lastSeen: iso(3_000),
      deploymentId: "dpl_new",
      sampleRequestId: "r2",
    });
    expect(worseLevel("error", "mystery")).toBe("error");
  });
});

describe("runtimeErrorsReport", () => {
  it("orders worst level first, then most frequent, caps the list, and dates it by the read", () => {
    const fatal = group({ key: "fatal", level: "fatal", count: 1 });
    const many = group({ key: "many", count: 9 });
    const few = group({ key: "few", count: 2 });
    const r = runtimeErrorsReport([few, many, fatal], { readAtMs: NOW - 5 * 60_000, complete: false }, NOW);
    expect(r).toMatchObject({
      generatedAt: iso(NOW),
      window: "24h",
      readAt: iso(NOW - 5 * 60_000),
      complete: false,
      total: 3,
    });
    expect(r.groups.map((g) => g.key)).toEqual(["fatal", "many", "few"]);

    const lots = Array.from({ length: RUNTIME_ERROR_REPORT_CAP + 5 }, (_, i) => group({ key: `g${i}` }));
    const capped = runtimeErrorsReport(lots, null, NOW);
    expect(capped).toMatchObject({ total: RUNTIME_ERROR_REPORT_CAP + 5, readAt: null, complete: true });
    expect(capped.groups).toHaveLength(RUNTIME_ERROR_REPORT_CAP);
  });

  it("does not age groups out against the clock: an old read stays, dated as old", () => {
    const old = group({ lastSeen: iso(NOW - 3 * RUNTIME_ERROR_WINDOW_MS) });
    const r = runtimeErrorsReport([old], { readAtMs: NOW - 2 * RUNTIME_ERROR_WINDOW_MS, complete: true }, NOW);
    expect(r.total).toBe(1);
    expect(r.readAt).toBe(iso(NOW - 2 * RUNTIME_ERROR_WINDOW_MS));
  });
});

describe("the runtime-errors store", () => {
  // Whole seconds: the timestamp columns store seconds.
  const t = (minutesAgo: number) => NOW - minutesAgo * 60_000;

  it("has no read before the first save", async () => {
    const store = createLibsqlStorage(await freshDb()).telemetry.runtimeErrors;
    expect(await store.lastRead()).toBeNull();
    expect(await store.load()).toEqual([]);
  });

  it("each save replaces the snapshot and records the read", async () => {
    const store = createLibsqlStorage(await freshDb()).telemetry.runtimeErrors;
    const read = [
      entry({ requestId: "a", timestampMs: t(30), path: "/api/posts/1" }),
      entry({ requestId: "b", timestampMs: t(20), path: "/api/posts/2" }),
    ];
    await store.save(read, { nowMs: NOW });
    // The same window read again is the same answer, not twice the count.
    await store.save(read, { nowMs: NOW });
    const [g, ...rest] = await store.load();
    expect(rest).toEqual([]);
    expect(g).toMatchObject({
      project: "site-production",
      path: "/api/posts/:id",
      message: "boom",
      count: 2,
      firstSeen: iso(t(30)),
      lastSeen: iso(t(20)),
      sampleRequestId: "b",
    });
    expect(await store.lastRead()).toEqual({ readAtMs: NOW, complete: true });

    // A later read without that error leaves nothing of it behind.
    await store.save([entry({ message: "other", timestampMs: t(1) })], { nowMs: NOW + 60_000, complete: false });
    expect((await store.load()).map((x) => x.message)).toEqual(["other"]);
    expect(await store.lastRead()).toEqual({ readAtMs: NOW + 60_000, complete: false });

    // An empty read is an answer too: no errors in the window.
    await store.save([], { nowMs: NOW + 120_000 });
    expect(await store.load()).toEqual([]);
    expect(await store.lastRead()).toEqual({ readAtMs: NOW + 120_000, complete: true });
  });

  it("stores more groups than one insert holds", async () => {
    const store = createLibsqlStorage(await freshDb()).telemetry.runtimeErrors;
    // Distinct groups need distinct identities; a number in the message no longer makes one.
    const many = Array.from({ length: 450 }, (_, i) => entry({ project: `p${i}`, message: "err", timestampMs: t(5) }));
    await store.save(many, { nowMs: NOW });
    expect(await store.load()).toHaveLength(450);
    const report = await loadRuntimeErrorsReport(store, NOW);
    expect(report).toMatchObject({ total: 450, readAt: iso(NOW), complete: true });
    expect(report.groups).toHaveLength(RUNTIME_ERROR_REPORT_CAP);
  });
});

// --- the fetcher, against a fake Vercel -----------------------------------------------------

const ENV = { VERCEL_API_TOKEN: "tok", VERCEL_TEAM_ID: "team_1" };

type EventAnswer =
  | { pages: unknown[][]; excluded?: boolean; noCursor?: boolean }
  | { status: number; body?: string };

interface FakeVercel {
  projects: unknown[];
  user?: string;
  events: Record<string, EventAnswer>;
  /** Answer 413 result_too_large to any page asked for with a limit above this. */
  maxLimit?: number;
}

interface EventsCall {
  teamId: string | null;
  reason: string | null;
  body: {
    event: string;
    scope: { ownerId: string; projectIds: string[] };
    timeRange: { start: string; end: string };
    filter: string;
    limit: number;
    cursor?: string;
  };
}

function fakeVercel(v: FakeVercel) {
  const paths: string[] = [];
  const events: EventsCall[] = [];
  const fetch = vi.fn(async (input: URL | string, init?: RequestInit) => {
    const url = new URL(String(input));
    paths.push(url.pathname);
    if (url.pathname === "/v9/projects") return Response.json({ projects: v.projects, pagination: { next: null } });
    if (url.pathname === "/v2/user") return Response.json({ user: { id: v.user } });
    if (url.pathname === "/v1/observability/events" && init?.method === "POST") {
      const body = JSON.parse(String(init.body)) as EventsCall["body"];
      const headers = new Headers(init.headers);
      events.push({
        teamId: url.searchParams.get("teamId"),
        reason: headers.get("x-vercel-observability-query-reason"),
        body,
      });
      if (v.maxLimit !== undefined && body.limit > v.maxLimit) {
        return Response.json({ error: { code: "result_too_large" } }, { status: 413 });
      }
      const answer = v.events[body.event];
      if (!answer) return Response.json({ events: [], pagination: { hasMore: false, nextCursor: null } });
      if ("status" in answer) {
        return new Response(answer.body ?? "", { status: answer.status, headers: { "retry-after": "60" } });
      }
      const page = body.cursor ? Number(body.cursor) : 0;
      const more = page + 1 < answer.pages.length;
      return Response.json({
        events: answer.pages[page] ?? [],
        pagination: { hasMore: more, nextCursor: more && !answer.noCursor ? String(page + 1) : null },
        meta: answer.excluded ? { excludedIntervals: [{ start: iso(NOW - 3_600_000), end: iso(NOW) }] } : {},
      });
    }
    return new Response("unexpected", { status: 500 });
  });
  vi.stubGlobal("fetch", fetch);
  return { fetch, paths, events };
}

const project = (id: string, name: string) => ({
  id,
  name,
  targets: { production: { id: null, alias: [`${name}.example.com`] } },
});
const logEvent = (requestId: string, over: Record<string, unknown> = {}) => ({
  timestamp: iso(NOW - 1_000),
  projectId: "p1",
  deploymentId: "dpl_a",
  requestId,
  requestMethod: "GET",
  requestPath: "/api/x",
  source: "function",
  level: "error",
  message: "boom",
  ...over,
});
const responseEvent = (requestId: string, httpStatus: number, over: Record<string, unknown> = {}) => ({
  timestamp: iso(NOW - 2_000),
  projectId: "p1",
  deploymentId: "dpl_a",
  requestId,
  requestMethod: "GET",
  requestPath: "/api/y",
  httpStatus,
  requestHostname: "a-production.example.com",
  ...over,
});
const fetcher = (opts: Parameters<typeof vercelRuntimeFetcher>[1] = {}, env: typeof ENV | { VERCEL_API_TOKEN: string } = ENV) =>
  vercelRuntimeFetcher(env, { now: () => NOW, ...opts });

describe("vercelRuntimeFetcher", () => {
  let errors: ReturnType<typeof vi.spyOn>;
  beforeEach(() => {
    _resetProviderCooldowns();
    errors = vi.spyOn(console, "error").mockImplementation(() => {});
  });
  afterEach(() => {
    vi.unstubAllGlobals();
    _resetProviderCooldowns();
    errors.mockRestore();
  });

  it("asks nothing without a token", async () => {
    const { fetch } = fakeVercel({ projects: [], events: {} });
    expect(await vercelRuntimeFetcher({}).fetch()).toEqual({ ok: true, items: [] });
    expect(fetch).not.toHaveBeenCalled();
  });

  it("asks for the last 24h of production errors and 5xx, and keeps production projects only", async () => {
    const { events } = fakeVercel({
      projects: [project("p1", "a-production"), project("p3", "a-staging")],
      events: {
        "vercel.log": { pages: [[logEvent("1"), logEvent("2", { projectId: "p3" })]] },
        "vercel.proxy_response": { pages: [[responseEvent("3", 503)]] },
      },
    });
    const res = await fetcher().fetch();
    expect(res).toMatchObject({ ok: true, complete: true });
    expect(res.items.map((e) => [e.project, e.requestId, e.source, e.status])).toEqual([
      ["a-production", "1", "function", null],
      ["a-production", "3", "response", 503],
    ]);
    expect(res.items[1]?.domain).toBe("a-production.example.com");

    expect(events.map((c) => c.body.event)).toEqual(["vercel.log", "vercel.proxy_response"]);
    for (const call of events) {
      expect(call.teamId).toBe("team_1");
      expect(call.reason).toBeTruthy();
      expect(call.body.scope).toEqual({ ownerId: "team_1", projectIds: ["p1"] });
      expect(call.body.timeRange).toEqual({ start: iso(NOW - RUNTIME_ERROR_WINDOW_MS), end: iso(NOW) });
      expect(call.body.filter).toContain('environment:"production"');
    }
  });

  it("uses the token's own account when no team is configured", async () => {
    const { events } = fakeVercel({ projects: [project("p1", "a-production")], user: "user_9", events: {} });
    expect(await fetcher({}, { VERCEL_API_TOKEN: "tok" }).fetch()).toMatchObject({ ok: true, complete: true });
    expect(events[0]).toMatchObject({ teamId: "user_9", body: { scope: { ownerId: "user_9" } } });
  });

  it("asks nothing more when there is no production project", async () => {
    const { events } = fakeVercel({ projects: [project("p3", "a-staging")], events: {} });
    expect(await fetcher().fetch()).toEqual({ ok: true, items: [], complete: true });
    expect(events).toEqual([]);
  });

  it("follows the cursor to the end of the window", async () => {
    const { events } = fakeVercel({
      projects: [project("p1", "a-production")],
      events: { "vercel.log": { pages: [[logEvent("1")], [logEvent("2")], [logEvent("3")]] } },
    });
    const res = await fetcher().fetch();
    expect(res).toMatchObject({ ok: true, complete: true });
    expect(res.items.map((e) => e.requestId)).toEqual(["1", "2", "3"]);
    expect(events.filter((c) => c.body.event === "vercel.log").map((c) => c.body.cursor)).toEqual([
      undefined,
      "1",
      "2",
    ]);
  });

  it("is not complete at the page cap, with excluded intervals, or with no cursor to follow", async () => {
    const pages = [[logEvent("1")], [logEvent("2")], [logEvent("3")]];
    fakeVercel({ projects: [project("p1", "a-production")], events: { "vercel.log": { pages } } });
    const capped = await fetcher({ maxPages: 2 }).fetch();
    expect(capped).toMatchObject({ ok: true, complete: false });
    expect(capped.items).toHaveLength(2);

    fakeVercel({ projects: [project("p1", "a-production")], events: { "vercel.log": { pages: [[logEvent("1")]], excluded: true } } });
    expect(await fetcher().fetch()).toMatchObject({ ok: true, complete: false });

    fakeVercel({ projects: [project("p1", "a-production")], events: { "vercel.log": { pages, noCursor: true } } });
    const stuck = await fetcher().fetch();
    expect(stuck).toMatchObject({ ok: true, complete: false });
    expect(stuck.items).toHaveLength(1);
  });

  it("halves the page size when a page is too large, and keeps it", async () => {
    const { events } = fakeVercel({
      projects: [project("p1", "a-production")],
      maxLimit: 300,
      events: { "vercel.log": { pages: [[logEvent("1")], [logEvent("2")]] } },
    });
    const res = await fetcher().fetch();
    expect(res).toMatchObject({ ok: true, complete: true });
    expect(events.filter((c) => c.body.event === "vercel.log").map((c) => c.body.limit)).toEqual([
      1000, 500, 250, 250,
    ]);
  });

  it("fails on any other error, so the store keeps what it had", async () => {
    fakeVercel({
      projects: [project("p1", "a-production")],
      events: { "vercel.log": { status: 500 } },
    });
    expect(await fetcher().fetch()).toEqual({ ok: false, items: [] });
  });

  it("keeps the runtime logs when only the 5xx responses query fails, and is not complete", async () => {
    for (const status of [402, 429, 500]) {
      _resetProviderCooldowns();
      fakeVercel({
        projects: [project("p1", "a-production")],
        events: {
          "vercel.log": { pages: [[logEvent("1")]] },
          "vercel.proxy_response": { status },
        },
      });
      const res = await fetcher().fetch();
      expect(res).toMatchObject({ ok: true, complete: false });
      expect(res.items.map((e) => e.requestId)).toEqual(["1"]);
    }
  });

  it("fails on a 429, records the shared cooldown, and then asks nothing while it lasts", async () => {
    const { fetch } = fakeVercel({ projects: [project("p1", "a-production")], events: { "vercel.log": { status: 429 } } });
    expect(await fetcher().fetch()).toEqual({ ok: false, items: [] });
    expect(rateLimitedUntil("vercel")).not.toBeNull();

    fetch.mockClear();
    expect(await fetcher().fetch()).toEqual({ ok: false, items: [] });
    expect(fetch).not.toHaveBeenCalled();
  });

  it("fails at the overall deadline, the project list included", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(
        (_input: unknown, init?: RequestInit) =>
          new Promise<Response>((_, reject) => {
            init?.signal?.addEventListener("abort", () => reject(init.signal!.reason));
          }),
      ),
    );
    const started = Date.now();
    expect(await fetcher({ overallBudgetMs: 50 }).fetch()).toEqual({ ok: false, items: [] });
    expect(Date.now() - started).toBeLessThan(5_000);
  });
});

// --- collectTelemetry + the integrations check ----------------------------------------------

describe("Vercel runtime errors in the cycle and the self-check", () => {
  const saved: Record<string, string | undefined> = {};
  const KEYS = [
    "VERCEL_API_TOKEN",
    "VERCEL_TEAM_ID",
    "GLITCHTIP_URL",
    "GLITCHTIP_API_TOKEN",
    "GLITCHTIP_ORG",
    "POSTHOG_HOST",
    "POSTHOG_API_KEY",
    "POSTHOG_PROJECT_ID",
    "CLOUDFLARE_API_TOKEN",
    "CLOUDFLARE_ACCOUNT_ID",
    "RAILWAY_API_TOKEN",
  ];
  beforeEach(() => {
    for (const k of KEYS) {
      saved[k] = process.env[k];
      delete process.env[k];
    }
    _resetSelfCheckStability();
    _resetProviderCooldowns();
    // The Vercel deploy probe in the self-check: answer it, never the network.
    vi.stubGlobal("fetch", vi.fn(async () => Response.json({ projects: [] })));
  });
  afterEach(() => {
    vi.unstubAllGlobals();
    for (const k of KEYS) {
      if (saved[k] === undefined) delete process.env[k];
      else process.env[k] = saved[k];
    }
  });

  const fixed = (result: Awaited<ReturnType<Fetcher<RuntimeLogEntry>["fetch"]>>): Fetcher<RuntimeLogEntry> => ({
    fetch: async () => result,
  });
  const runtimeCheck = async (storage: ReturnType<typeof createLibsqlStorage>) =>
    (await runIntegrationsCheck(storage, testConfig())).checks.find((c) => c.id === "vercel-runtime");

  it("is a missing-env warning without a token, and records the feature as off", async () => {
    const storage = createLibsqlStorage(await freshDb());
    const fetch = vi.fn(async () => ({ ok: true as const, items: [] }));
    await collectTelemetry(storage, testConfig(), { runtimeErrors: { fetch } });
    expect(fetch).not.toHaveBeenCalled();
    const fact = (await storage.board.readPlatformFacts()).find((p) => p.source === "vercel-runtime");
    expect(fact).toMatchObject({ configured: false });
    expect(await runtimeCheck(storage)).toMatchObject({ configured: false, state: "warn" });
  });

  it("is pending before the first read, ok after one, still ok after one failure, and red after two", async () => {
    process.env.VERCEL_API_TOKEN = "tok";
    const storage = createLibsqlStorage(await freshDb());
    expect(await runtimeCheck(storage)).toMatchObject({ state: "warn", detail: "first runtime-log read pending" });

    const now = Date.now();
    await collectTelemetry(storage, testConfig(), {
      runtimeErrors: fixed({ ok: true, items: [entry({ timestampMs: now - 60_000 })], complete: true }),
    });
    const ok = await runtimeCheck(storage);
    expect(ok).toMatchObject({ configured: true, ok: true, state: "ok" });
    expect(ok?.detail).toMatch(/^1 runtime error group in the 24h before the read/);

    const failing = fixed({ ok: false, items: [] });
    await collectTelemetry(storage, testConfig(), { runtimeErrors: failing });
    // One failure is a blip: the snapshot still stands.
    const blip = await runtimeCheck(storage);
    expect(blip).toMatchObject({ state: "ok", ok: true });
    expect(blip?.detail).toMatch(/\(1 in a row\) · 1 runtime error group/);
    await collectTelemetry(storage, testConfig(), { runtimeErrors: failing });
    const red = await runtimeCheck(storage);
    expect(red).toMatchObject({ state: "error", ok: false });
    expect(red?.detail).toMatch(/\(2 in a row\)/);
    // The groups read before the outage are kept.
    expect(await storage.telemetry.runtimeErrors.load()).toHaveLength(1);
  });

  it("warns when the read was cut short", async () => {
    process.env.VERCEL_API_TOKEN = "tok";
    const storage = createLibsqlStorage(await freshDb());
    await collectTelemetry(storage, testConfig(), { runtimeErrors: fixed({ ok: true, items: [], complete: false }) });
    const check = await runtimeCheck(storage);
    expect(check).toMatchObject({ state: "warn", ok: true });
    expect(check?.detail).toMatch(/cut short/);
  });

  it("survives a fetcher that throws", async () => {
    process.env.VERCEL_API_TOKEN = "tok";
    const errors = vi.spyOn(console, "error").mockImplementation(() => {});
    const storage = createLibsqlStorage(await freshDb());
    await collectTelemetry(storage, testConfig(), {
      runtimeErrors: {
        fetch: async () => {
          throw new Error("kaboom");
        },
      },
    });
    const fact = (await storage.board.readPlatformFacts()).find((p) => p.source === "vercel-runtime");
    expect(fact).toMatchObject({ configured: true, ok: false });
    errors.mockRestore();
  });
});
