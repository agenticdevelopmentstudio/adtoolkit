// @vitest-environment jsdom
// The insight API layer at the `authedJson` boundary: every report builds the
// documented URL and query string, every price-table write sends the documented
// method and body, and a write invalidates every insight read (a rate change
// re-prices all of them).
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { ReactNode } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { renderHook, waitFor } from "@testing-library/react";

const { authedJson } = vi.hoisted(() => ({ authedJson: vi.fn() }));
vi.mock("../http", () => ({ authedJson }));

import {
  INSIGHT_QUERY_KEY,
  insightApi,
  useBreakdown,
  useBreakdownDetail,
  useCreateFixedCost,
  useCreateRate,
  useDeleteFixedCost,
  useDeleteRate,
  useFixedCosts,
  useInsightItems,
  useInsightOverview,
  useRates,
  useRunRate,
  useUpdateFixedCost,
  useUpdateRate,
} from "../insight";

const range = { from: "2026-09-01", to: "2026-09-30" };
const KEY = "0b7c1b1e-7a3f-4c1e-9a55-2f1d2c3b4a59";

beforeEach(() => authedJson.mockReset());

function harness() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={client}>{children}</QueryClientProvider>
  );
  return { client, wrapper };
}

describe("insightApi reports", () => {
  beforeEach(() => authedJson.mockResolvedValue({}));

  it("run rate: the month as a query param", async () => {
    await insightApi.runRate("2026-09");
    expect(authedJson).toHaveBeenCalledWith("/api/usage/insight/run-rate?month=2026-09");
  });

  it("items: the range", async () => {
    await insightApi.items(range);
    expect(authedJson).toHaveBeenCalledWith(
      "/api/usage/insight/items?from=2026-09-01&to=2026-09-30",
    );
  });

  it("overview: the range, with the interval only when given", async () => {
    await insightApi.overview(range, "week");
    expect(authedJson).toHaveBeenLastCalledWith(
      "/api/usage/insight/overview?from=2026-09-01&to=2026-09-30&interval=week",
    );
    await insightApi.overview(range);
    expect(authedJson).toHaveBeenLastCalledWith(
      "/api/usage/insight/overview?from=2026-09-01&to=2026-09-30",
    );
  });

  it("breakdown: range, dimension, and only the paging/sort params that are set", async () => {
    await insightApi.breakdown({ ...range, by: "organization" });
    expect(authedJson).toHaveBeenLastCalledWith(
      "/api/usage/insight/breakdown?from=2026-09-01&to=2026-09-30&by=organization",
    );
    await insightApi.breakdown({ ...range, by: "persona", sort: "estimated", limit: 25, offset: 50 });
    expect(authedJson).toHaveBeenLastCalledWith(
      "/api/usage/insight/breakdown?from=2026-09-01&to=2026-09-30&by=persona&sort=estimated&limit=25&offset=50",
    );
  });

  it("breakdown detail: dimension and key in the path, range in the query", async () => {
    await insightApi.breakdownDetail("user", KEY, range);
    expect(authedJson).toHaveBeenCalledWith(
      `/api/usage/insight/breakdown/user/${KEY}?from=2026-09-01&to=2026-09-30`,
    );
  });
});

describe("insightApi price tables", () => {
  it("lists unwrap the { rows } envelope", async () => {
    const rate = { id: "r1" };
    authedJson.mockResolvedValueOnce({ rows: [rate] });
    await expect(insightApi.rates()).resolves.toEqual([rate]);
    expect(authedJson).toHaveBeenLastCalledWith("/api/usage/rates");

    const cost = { id: "f1" };
    authedJson.mockResolvedValueOnce({ rows: [cost] });
    await expect(insightApi.fixedCosts()).resolves.toEqual([cost]);
    expect(authedJson).toHaveBeenLastCalledWith("/api/usage/fixed-costs");
  });

  it("rates: POST, PATCH by id, DELETE by id", async () => {
    authedJson.mockResolvedValue({});
    const body = {
      category: "llm" as const,
      provider: "anthropic",
      sku: "claude-x",
      quantityKey: "input_tokens",
      microsPerUnit: "3",
    };
    await insightApi.createRate(body);
    expect(authedJson).toHaveBeenLastCalledWith("/api/usage/rates", {
      method: "POST",
      body: JSON.stringify(body),
    });
    await insightApi.updateRate("r1", { microsPerUnit: "2.5" });
    expect(authedJson).toHaveBeenLastCalledWith("/api/usage/rates/r1", {
      method: "PATCH",
      body: JSON.stringify({ microsPerUnit: "2.5" }),
    });
    await insightApi.deleteRate("r1");
    expect(authedJson).toHaveBeenLastCalledWith("/api/usage/rates/r1", { method: "DELETE" });
  });

  it("fixed costs: POST, PATCH by id, DELETE by id", async () => {
    authedJson.mockResolvedValue({});
    const body = {
      provider: "railway",
      label: "Hosting",
      monthlyMicros: 20_000_000,
      effectiveFrom: "2026-09-01",
    };
    await insightApi.createFixedCost(body);
    expect(authedJson).toHaveBeenLastCalledWith("/api/usage/fixed-costs", {
      method: "POST",
      body: JSON.stringify(body),
    });
    await insightApi.updateFixedCost("f1", { effectiveTo: null });
    expect(authedJson).toHaveBeenLastCalledWith("/api/usage/fixed-costs/f1", {
      method: "PATCH",
      body: JSON.stringify({ effectiveTo: null }),
    });
    await insightApi.deleteFixedCost("f1");
    expect(authedJson).toHaveBeenLastCalledWith("/api/usage/fixed-costs/f1", {
      method: "DELETE",
    });
  });
});

// Explicit row types: each hook returns its own result type, which a bare tuple array would
// unify into one (and then reject the other rows).
type QueryRow = [name: string, hook: () => { isSuccess: boolean }, url: string];
type MutationRow = [
  name: string,
  hook: () => { mutateAsync: (vars: never) => Promise<unknown> },
  vars: unknown,
];

describe("query hooks", () => {
  beforeEach(() => authedJson.mockResolvedValue({ rows: [] }));

  it.each<QueryRow>([
    ["useRunRate", () => useRunRate("2026-09"), "/api/usage/insight/run-rate?month=2026-09"],
    [
      "useInsightItems",
      () => useInsightItems(range),
      "/api/usage/insight/items?from=2026-09-01&to=2026-09-30",
    ],
    [
      "useInsightOverview",
      () => useInsightOverview(range, "month"),
      "/api/usage/insight/overview?from=2026-09-01&to=2026-09-30&interval=month",
    ],
    [
      "useBreakdown",
      () => useBreakdown({ ...range, by: "ecosystem", sort: "requests" }),
      "/api/usage/insight/breakdown?from=2026-09-01&to=2026-09-30&by=ecosystem&sort=requests",
    ],
    [
      "useBreakdownDetail",
      () => useBreakdownDetail("organization", KEY, range),
      `/api/usage/insight/breakdown/organization/${KEY}?from=2026-09-01&to=2026-09-30`,
    ],
    ["useRates", () => useRates(), "/api/usage/rates"],
    ["useFixedCosts", () => useFixedCosts(), "/api/usage/fixed-costs"],
  ])("%s fetches its URL under the insight key", async (_name, hook, url) => {
    const { client, wrapper } = harness();
    const { result } = renderHook(hook, { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(authedJson).toHaveBeenCalledWith(url);
    const keys = client.getQueryCache().getAll().map((q) => q.queryKey);
    expect(keys).toHaveLength(1);
    expect(keys[0]!.slice(0, INSIGHT_QUERY_KEY.length)).toEqual([...INSIGHT_QUERY_KEY]);
  });

  it("useBreakdownDetail stays idle until a key is chosen", () => {
    const { wrapper } = harness();
    const { result } = renderHook(() => useBreakdownDetail("user", undefined, range), { wrapper });
    expect(result.current.fetchStatus).toBe("idle");
    expect(authedJson).not.toHaveBeenCalled();
  });
});

describe("mutation hooks invalidate every insight read", () => {
  beforeEach(() => authedJson.mockResolvedValue({}));

  it.each<MutationRow>([
    ["useCreateRate", () => useCreateRate(), { category: "llm", provider: "p", sku: "s", quantityKey: "k", microsPerUnit: "1" }],
    ["useUpdateRate", () => useUpdateRate(), { id: "r1", changes: { note: "n" } }],
    ["useDeleteRate", () => useDeleteRate(), "r1"],
    ["useCreateFixedCost", () => useCreateFixedCost(), { provider: "p", label: "l", monthlyMicros: 1, effectiveFrom: "2026-09-01" }],
    ["useUpdateFixedCost", () => useUpdateFixedCost(), { id: "f1", changes: { label: "l" } }],
    ["useDeleteFixedCost", () => useDeleteFixedCost(), "f1"],
  ])("%s", async (_name, hook, vars) => {
    const { client, wrapper } = harness();
    const spy = vi.spyOn(client, "invalidateQueries");
    const { result } = renderHook(hook, { wrapper });
    // Each hook takes its own variables; the table pairs them by row.
    await result.current.mutateAsync(vars as never);
    expect(spy).toHaveBeenCalledWith({ queryKey: INSIGHT_QUERY_KEY });
  });
});
