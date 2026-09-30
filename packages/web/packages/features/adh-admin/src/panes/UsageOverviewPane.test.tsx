// @vitest-environment jsdom
import { describe, it, expect, afterEach, beforeEach, vi } from "vitest";
import { render, screen, fireEvent, cleanup, within } from "@testing-library/react";
import { UsageOverviewPane, overviewTotals } from "./UsageOverviewPane";
import type { InsightOverview } from "../api/insight";

const useInsightOverview = vi.fn();

vi.mock("../api/insight", () => ({
  useInsightOverview: (...args: unknown[]) => useInsightOverview(...args),
}));

vi.mock("@agentic-toolkit/adh-ui/components/time-series-chart", () => ({
  TimeSeriesChart: ({ series }: { series: { label: string }[] }) => (
    <div data-testid="chart">{series.map((s) => s.label).join(",")}</div>
  ),
}));

type Point = InsightOverview["points"][number];

const point = (over: Partial<Point> = {}): Point => ({
  start: "2026-09-01",
  requests: 100,
  bytesIn: 1024,
  bytesOut: 2048,
  serverMs: 1_000,
  dbMs: 500,
  llmTokens: { input: 10, output: 20, cacheRead: 5, cacheWrite: 1, reasoning: 4 },
  embeddings: 0,
  emails: 2,
  smsSegments: 1,
  storageOps: 0,
  directMicros: 1_000_000,
  ...over,
});

beforeEach(() => {
  useInsightOverview.mockReset();
  useInsightOverview.mockReturnValue({
    data: { interval: "day", points: [point(), point({ start: "2026-09-02" })] },
    isLoading: false,
    error: null,
  });
});

afterEach(cleanup);

describe("overviewTotals", () => {
  it("sums every series; tokens exclude reasoning, which output already holds", () => {
    const t = overviewTotals([point(), point()]);
    expect(t).toMatchObject({ requests: 200, bytesIn: 2048, llmTokens: 72, emails: 4 });
    expect(t).toMatchObject({ directMicros: 2_000_000, directIsFloor: false });
  });

  it("is Unpriced when every bucket is, and a floor when only some are", () => {
    expect(overviewTotals([point({ directMicros: null })]).directMicros).toBeNull();
    expect(overviewTotals([point(), point({ directMicros: null })])).toMatchObject({
      directMicros: 1_000_000,
      directIsFloor: true,
    });
  });
});

describe("UsageOverviewPane", () => {
  it("draws a chart per series group and a totals row", () => {
    render(<UsageOverviewPane />);
    expect(screen.getAllByTestId("chart").map((c) => c.textContent)).toEqual([
      "Requests",
      "In,Out",
      "Server,Database",
      "Input,Output,Cache read,Cache write",
      "Emails,SMS",
      "Direct cost",
    ]);
    const totals = within(screen.getByRole("region", { name: "Totals" }));
    expect(totals.getByText("200")).toBeTruthy();
    expect(totals.getByText("$2.00")).toBeTruthy();
  });

  it("reads Unpriced, never $0.00, when every bucket is unpriced", () => {
    useInsightOverview.mockReturnValue({
      data: { interval: "day", points: [point({ directMicros: null })] },
      isLoading: false,
      error: null,
    });
    render(<UsageOverviewPane />);
    const totals = within(screen.getByRole("region", { name: "Totals" }));
    expect(totals.getByText("Unpriced")).toBeTruthy();
    expect(totals.queryByText("$0.00")).toBeNull();
  });

  it("refetches with the chosen interval", () => {
    render(<UsageOverviewPane />);
    expect(useInsightOverview.mock.calls.at(-1)![1]).toBe("day");
    fireEvent.change(screen.getByLabelText("Interval"), { target: { value: "week" } });
    expect(useInsightOverview.mock.calls.at(-1)![1]).toBe("week");
  });
});
