// @vitest-environment jsdom
import { describe, it, expect, afterEach, beforeEach, vi } from "vitest";
import { render, screen, fireEvent, cleanup, within } from "@testing-library/react";
import { BreakdownPane } from "./BreakdownPane";
import { ESTIMATE_HINT, UNATTRIBUTED_KEY, type BreakdownRow } from "../breakdown/BreakdownTable";
import type { Breakdown } from "../api/insight";

const useBreakdown = vi.fn();
const useBreakdownDetail = vi.fn();

vi.mock("../api/insight", () => ({
  useBreakdown: (...args: unknown[]) => useBreakdown(...args),
  useBreakdownDetail: (...args: unknown[]) => useBreakdownDetail(...args),
}));

// jsdom lays nothing out; the chart's own rendering is adh-ui's to test.
vi.mock("@agentic-toolkit/adh-ui/components/time-series-chart", () => ({
  TimeSeriesChart: ({ series }: { series: { label: string }[] }) => (
    <div data-testid="chart">{series.map((s) => s.label).join(",")}</div>
  ),
}));

const TOKENS = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, reasoning: 0 };

const row = (over: Partial<BreakdownRow>): BreakdownRow => ({
  key: "11111111-1111-1111-1111-111111111111",
  label: "Acme",
  requests: 10,
  serverMs: 100,
  dbMs: 50,
  llmTokens: TOKENS,
  directMicros: 2_000_000,
  hostingShareMicros: 500_000,
  estimatedMicros: 2_500_000,
  unpricedLines: 0,
  ...over,
});

const page = (rows: BreakdownRow[], total = rows.length): Breakdown => ({
  by: "organization",
  total,
  fixedMicros: 30_000_000,
  rows,
});

const lastCall = () => useBreakdown.mock.calls.at(-1)![0];

beforeEach(() => {
  useBreakdown.mockReset();
  useBreakdownDetail.mockReset();
  useBreakdown.mockReturnValue({
    data: page([
      row({ key: UNATTRIBUTED_KEY, label: "Unattributed", directMicros: null, estimatedMicros: 900_000 }),
      row({}),
      row({ key: "22222222-2222-2222-2222-222222222222", label: "Globex" }),
    ]),
    isLoading: false,
    error: null,
  });
  useBreakdownDetail.mockReturnValue({ data: undefined, isLoading: true, error: null });
});

afterEach(cleanup);

describe("BreakdownPane", () => {
  it("starts grouped by organization, sorted by direct cost, on the first page", () => {
    render(<BreakdownPane />);
    expect(lastCall()).toMatchObject({ by: "organization", sort: "direct", limit: 50, offset: 0 });
  });

  it("refetches with `by` when the group-by changes", () => {
    render(<BreakdownPane />);
    fireEvent.change(screen.getByLabelText("Group by"), { target: { value: "persona" } });
    expect(lastCall()).toMatchObject({ by: "persona", offset: 0 });
  });

  it("passes the sort param when a sortable header is clicked", () => {
    render(<BreakdownPane />);
    fireEvent.click(screen.getByRole("button", { name: /Estimated total/ }));
    expect(lastCall()).toMatchObject({ sort: "estimated" });
    fireEvent.click(screen.getByRole("button", { name: "Requests" }));
    expect(lastCall()).toMatchObject({ sort: "requests" });
  });

  it("labels the estimated column as an estimate, with the hosting-share hint", () => {
    render(<BreakdownPane />);
    expect(screen.getByTitle(ESTIMATE_HINT)).toBeTruthy();
    expect(screen.getByText(/an estimate/)).toBeTruthy();
    expect(screen.getByText(/\$30\.00/)).toBeTruthy(); // the fixed pool
  });

  it("renders the unattributed row last, and its unpriced direct cost as Unpriced", () => {
    render(<BreakdownPane />);
    const rows = within(screen.getByRole("grid", { name: "Breakdown" })).getAllByRole("row");
    expect(rows.at(-1)!.textContent).toContain("Unattributed");
    expect(rows.at(-1)!.textContent).toContain("Unpriced");
    expect(rows.at(-1)!.textContent).not.toContain("$0.00");
  });

  it("opens the detail for a clicked row, with its key", () => {
    render(<BreakdownPane />);
    fireEvent.click(screen.getByText("Globex"));
    expect(useBreakdownDetail).toHaveBeenLastCalledWith(
      "organization",
      "22222222-2222-2222-2222-222222222222",
      expect.objectContaining({ from: expect.any(String), to: expect.any(String) }),
    );
    expect(screen.getByRole("region", { name: "Breakdown detail" })).toBeTruthy();
  });

  it("closes the detail when the group-by changes", () => {
    render(<BreakdownPane />);
    fireEvent.click(screen.getByText("Globex"));
    fireEvent.change(screen.getByLabelText("Group by"), { target: { value: "user" } });
    expect(screen.queryByRole("region", { name: "Breakdown detail" })).toBeNull();
  });

  it("pages with offset from the total", () => {
    useBreakdown.mockReturnValue({ data: page([row({})], 120), isLoading: false, error: null });
    render(<BreakdownPane />);
    expect(screen.getByText("Page 1 of 3")).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: "Next" }));
    expect(lastCall()).toMatchObject({ limit: 50, offset: 50 });
  });
});
