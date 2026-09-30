// @vitest-environment jsdom
import { describe, it, expect, afterEach, vi } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { BreakdownDetail } from "./BreakdownDetail";
import type { BreakdownDetail as Detail, InsightItem } from "../api/insight";

const useBreakdownDetail = vi.fn();

vi.mock("../api/insight", () => ({
  useBreakdownDetail: (...args: unknown[]) => useBreakdownDetail(...args),
}));

vi.mock("@agentic-toolkit/adh-ui/components/time-series-chart", () => ({
  TimeSeriesChart: ({ series }: { series: { label: string }[] }) => (
    <div data-testid="chart">{series.map((s) => s.label).join(",")}</div>
  ),
}));

afterEach(cleanup);

const item = (over: Partial<InsightItem> = {}): InsightItem => ({
  category: "llm",
  provider: "anthropic",
  sku: "claude-sonnet",
  quantities: { requests: 3 },
  capturedMicros: 0,
  costMicros: null,
  source: "unpriced",
  unpricedLines: 1,
  lines: 1,
  rates: [],
  ...over,
});

const detail: Detail = {
  by: "ecosystem",
  key: "k1",
  label: "Main ecosystem",
  items: [item(), item({ sku: "priced", source: "rate", costMicros: 1_500_000, unpricedLines: 0 })],
  daily: [
    { day: "2026-09-01", directMicros: null, requests: 2 },
    { day: "2026-09-02", directMicros: 1_500_000, requests: 1 },
  ],
};

describe("BreakdownDetail", () => {
  it("reads the detail for its key and shows the items and daily trend", () => {
    useBreakdownDetail.mockReturnValue({ data: detail, isLoading: false, error: null });
    const range = { from: "2026-09-01", to: "2026-09-02" };
    render(<BreakdownDetail by="ecosystem" itemKey="k1" range={range} onClose={vi.fn()} />);
    expect(useBreakdownDetail).toHaveBeenCalledWith("ecosystem", "k1", range);
    expect(screen.getByRole("heading", { name: "Main ecosystem" })).toBeTruthy();
    expect(screen.getByText("Unpriced")).toBeTruthy();
    expect(screen.getByText("$1.50")).toBeTruthy();
    expect(screen.getAllByTestId("chart").map((c) => c.textContent)).toEqual([
      "Direct cost",
      "Requests",
    ]);
  });

  it("closes", () => {
    useBreakdownDetail.mockReturnValue({ data: detail, isLoading: false, error: null });
    const onClose = vi.fn();
    render(
      <BreakdownDetail by="ecosystem" itemKey="k1" range={{ from: "a", to: "b" }} onClose={onClose} />,
    );
    fireEvent.click(screen.getByRole("button", { name: "Close" }));
    expect(onClose).toHaveBeenCalledTimes(1);
  });
});
