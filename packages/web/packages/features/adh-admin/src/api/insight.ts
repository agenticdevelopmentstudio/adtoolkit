"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import type { RequestBody, SuccessBody, paths } from "@agentic-toolkit/adh-api-types";
import { authedJson } from "./http";

// ── Usage cost insight: what the platform costs, and who drives it ─────────
//
// The admin-gated `/usage/insight/*` reports read the metered usage and price it:
// a month's run rate, the priced items over a range, a time series, and a
// per-organization/ecosystem/user/persona breakdown with its drill-down. The prices
// themselves are two admin-edited tables — per-unit rates (`/usage/rates`) and fixed
// monthly costs (`/usage/fixed-costs`) — so a write to either re-prices every report,
// and each mutation below invalidates the whole insight key rather than guessing which
// reports it touched.
//
// Every money field is an integer µUSD count, or `null` when unpriced; format it with
// `formatMicros` from `@agenticdevelopertoolkit/ui/lib/money`.

/** An inclusive calendar-day range, both ends `YYYY-MM-DD` (UTC days). */
export interface InsightRange {
  from: string;
  to: string;
}

export type RunRate = SuccessBody<"/usage/insight/run-rate", "get">;
export type InsightItems = SuccessBody<"/usage/insight/items", "get">;
export type InsightItem = InsightItems["items"][number];
export type InsightOverview = SuccessBody<"/usage/insight/overview", "get">;
export type InsightInterval = InsightOverview["interval"];
export type Breakdown = SuccessBody<"/usage/insight/breakdown", "get">;
export type BreakdownBy = Breakdown["by"];
export type BreakdownDetail = SuccessBody<"/usage/insight/breakdown/{by}/{key}", "get">;

/** What the breakdown ranks by: direct cost, estimated (direct + hosting share), or requests. */
export type BreakdownSort = NonNullable<
  paths["/usage/insight/breakdown"]["get"]["parameters"]["query"]["sort"]
>;

export interface BreakdownParams extends InsightRange {
  by: BreakdownBy;
  sort?: BreakdownSort;
  /** Page size, 1–200 (the server defaults to 50). */
  limit?: number;
  offset?: number;
}

export type UsageRate = SuccessBody<"/usage/rates", "get">["rows"][number];
export type CreateRateBody = RequestBody<"/usage/rates", "post">;
export type UpdateRateBody = RequestBody<"/usage/rates/{id}", "patch">;
export type FixedCost = SuccessBody<"/usage/fixed-costs", "get">["rows"][number];
export type CreateFixedCostBody = RequestBody<"/usage/fixed-costs", "post">;
export type UpdateFixedCostBody = RequestBody<"/usage/fixed-costs/{id}", "patch">;

/** A query string from the params that are set; `undefined` ones are left off. */
function query(params: Record<string, string | number | undefined>): string {
  const qs = new URLSearchParams();
  for (const [name, value] of Object.entries(params)) {
    if (value !== undefined) qs.set(name, String(value));
  }
  return qs.toString();
}

const rangeQuery = ({ from, to }: InsightRange) => ({ from, to });

// ── Network shaping (mirrors syncTablesApi) ─────────────────────────────────
//
// A plain object so the URL and body shaping is unit-testable at the fetch boundary
// (mock `./http`); the hooks below are thin react-query wrappers over it.
export const insightApi = {
  runRate(month: string): Promise<RunRate> {
    return authedJson<RunRate>(`/api/usage/insight/run-rate?${query({ month })}`);
  },

  items(range: InsightRange): Promise<InsightItems> {
    return authedJson<InsightItems>(`/api/usage/insight/items?${query(rangeQuery(range))}`);
  },

  overview(range: InsightRange, interval?: InsightInterval): Promise<InsightOverview> {
    return authedJson<InsightOverview>(
      `/api/usage/insight/overview?${query({ ...rangeQuery(range), interval })}`,
    );
  },

  breakdown({ by, sort, limit, offset, ...range }: BreakdownParams): Promise<Breakdown> {
    return authedJson<Breakdown>(
      `/api/usage/insight/breakdown?${query({ ...rangeQuery(range), by, sort, limit, offset })}`,
    );
  },

  breakdownDetail(by: BreakdownBy, key: string, range: InsightRange): Promise<BreakdownDetail> {
    return authedJson<BreakdownDetail>(
      `/api/usage/insight/breakdown/${encodeURIComponent(by)}/${encodeURIComponent(key)}?${query(rangeQuery(range))}`,
    );
  },

  async rates(): Promise<UsageRate[]> {
    const { rows } = await authedJson<{ rows: UsageRate[] }>("/api/usage/rates");
    return rows;
  },

  createRate(body: CreateRateBody): Promise<UsageRate> {
    return authedJson<UsageRate>("/api/usage/rates", { method: "POST", body: JSON.stringify(body) });
  },

  updateRate(id: string, changes: UpdateRateBody): Promise<UsageRate> {
    return authedJson<UsageRate>(`/api/usage/rates/${encodeURIComponent(id)}`, {
      method: "PATCH",
      body: JSON.stringify(changes),
    });
  },

  deleteRate(id: string): Promise<{ ok: boolean }> {
    return authedJson<{ ok: boolean }>(`/api/usage/rates/${encodeURIComponent(id)}`, {
      method: "DELETE",
    });
  },

  async fixedCosts(): Promise<FixedCost[]> {
    const { rows } = await authedJson<{ rows: FixedCost[] }>("/api/usage/fixed-costs");
    return rows;
  },

  createFixedCost(body: CreateFixedCostBody): Promise<FixedCost> {
    return authedJson<FixedCost>("/api/usage/fixed-costs", {
      method: "POST",
      body: JSON.stringify(body),
    });
  },

  updateFixedCost(id: string, changes: UpdateFixedCostBody): Promise<FixedCost> {
    return authedJson<FixedCost>(`/api/usage/fixed-costs/${encodeURIComponent(id)}`, {
      method: "PATCH",
      body: JSON.stringify(changes),
    });
  },

  deleteFixedCost(id: string): Promise<{ ok: boolean }> {
    return authedJson<{ ok: boolean }>(`/api/usage/fixed-costs/${encodeURIComponent(id)}`, {
      method: "DELETE",
    });
  },
};

// ── Hooks ───────────────────────────────────────────────────────────────────

/** Every insight read keys under this, so one invalidation re-prices them all. */
export const INSIGHT_QUERY_KEY = ["admin", "usage", "insight"] as const;

const insightKey = (...parts: readonly unknown[]) => [...INSIGHT_QUERY_KEY, ...parts] as const;

/** The run rate for a `YYYY-MM` month. */
export function useRunRate(month: string) {
  return useQuery({
    queryKey: insightKey("run-rate", month),
    queryFn: () => insightApi.runRate(month),
  });
}

export function useInsightItems(range: InsightRange) {
  return useQuery({
    queryKey: insightKey("items", range.from, range.to),
    queryFn: () => insightApi.items(range),
  });
}

/** The time series; `interval` omitted lets the server pick its default (day). */
export function useInsightOverview(range: InsightRange, interval?: InsightInterval) {
  return useQuery({
    queryKey: insightKey("overview", range.from, range.to, interval ?? null),
    queryFn: () => insightApi.overview(range, interval),
  });
}

export function useBreakdown(params: BreakdownParams) {
  const { from, to, by, sort, limit, offset } = params;
  return useQuery({
    queryKey: insightKey("breakdown", by, from, to, sort ?? null, limit ?? null, offset ?? null),
    queryFn: () => insightApi.breakdown(params),
  });
}

/** One breakdown row's items and daily series (idle until a key is chosen). */
export function useBreakdownDetail(by: BreakdownBy, key: string | undefined, range: InsightRange) {
  return useQuery({
    queryKey: insightKey("breakdown-detail", by, key ?? "", range.from, range.to),
    enabled: !!key,
    queryFn: () => insightApi.breakdownDetail(by, key!, range),
  });
}

export function useRates() {
  return useQuery({ queryKey: insightKey("rates"), queryFn: () => insightApi.rates() });
}

export function useFixedCosts() {
  return useQuery({ queryKey: insightKey("fixed-costs"), queryFn: () => insightApi.fixedCosts() });
}

/** A write to the price tables: on success, every insight read is stale. */
function useInsightMutation<TVars, TResult>(mutationFn: (vars: TVars) => Promise<TResult>) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn,
    onSuccess: () => qc.invalidateQueries({ queryKey: INSIGHT_QUERY_KEY }),
  });
}

export function useCreateRate() {
  return useInsightMutation((body: CreateRateBody) => insightApi.createRate(body));
}

export function useUpdateRate() {
  return useInsightMutation(({ id, changes }: { id: string; changes: UpdateRateBody }) =>
    insightApi.updateRate(id, changes),
  );
}

export function useDeleteRate() {
  return useInsightMutation((id: string) => insightApi.deleteRate(id));
}

export function useCreateFixedCost() {
  return useInsightMutation((body: CreateFixedCostBody) => insightApi.createFixedCost(body));
}

export function useUpdateFixedCost() {
  return useInsightMutation(({ id, changes }: { id: string; changes: UpdateFixedCostBody }) =>
    insightApi.updateFixedCost(id, changes),
  );
}

export function useDeleteFixedCost() {
  return useInsightMutation((id: string) => insightApi.deleteFixedCost(id));
}
