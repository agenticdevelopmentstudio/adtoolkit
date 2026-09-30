// @vitest-environment jsdom
import { describe, it, expect, afterEach, vi } from "vitest";
import { render, screen, cleanup } from "@testing-library/react";
import { CostItemsTable, CostCell, quantitiesText } from "./CostItemsTable";
import type { InsightItem } from "../api/insight";

vi.mock("../api/insight", () => ({
  useCreateRate: () => ({ mutateAsync: vi.fn() }),
}));

afterEach(cleanup);

const item = (over: Partial<InsightItem> = {}): InsightItem => ({
  category: "llm",
  provider: "anthropic",
  sku: "claude-sonnet",
  quantities: { requests: 340, input_tokens: 1_200_000 },
  capturedMicros: 0,
  costMicros: null,
  source: "unpriced",
  unpricedLines: 3,
  lines: 3,
  rates: [],
  ...over,
});

describe("CostCell", () => {
  it("reads an unpriced item as Unpriced, never $0.00", () => {
    const { container } = render(<CostCell item={item()} />);
    expect(container.textContent).toBe("Unpriced");
    expect(container.textContent).not.toContain("$0.00");
  });

  it("formats a priced item, and marks one with unpriced lines as a floor", () => {
    const { container } = render(
      <CostCell item={item({ source: "rate", costMicros: 1_500_000, unpricedLines: 0 })} />,
    );
    expect(container.textContent).toBe("$1.50");
    cleanup();
    const floor = render(
      <CostCell item={item({ source: "mixed", costMicros: 1_500_000, unpricedLines: 2 })} />,
    );
    expect(floor.container.textContent).toBe("≥ $1.50");
  });

  it("shows a customer-key item as a dash: quantity only, never our cost", () => {
    const { container } = render(
      <CostCell item={item({ source: "customer_key", costMicros: 0, unpricedLines: 0 })} />,
    );
    expect(container.textContent).toBe("—");
  });

  it("keeps a real zero as $0.00 (a priced free item is not unpriced)", () => {
    const { container } = render(
      <CostCell item={item({ source: "rate", costMicros: 0, unpricedLines: 0 })} />,
    );
    expect(container.textContent).toBe("$0.00");
  });
});

describe("quantitiesText", () => {
  it("compacts and sorts the quantities", () => {
    expect(quantitiesText({ requests: 340, input_tokens: 1_200_000 })).toBe(
      "input_tokens 1.2M · requests 340",
    );
  });
});

describe("CostItemsTable", () => {
  it("renders an unpriced row as Unpriced with its source badge, and Customer key by label", () => {
    render(
      <CostItemsTable
        loading={false}
        error={undefined}
        items={[
          item(),
          item({ sku: "byok", source: "customer_key", costMicros: 0, unpricedLines: 0 }),
          item({ sku: "priced", source: "rate", costMicros: 2_500_000, unpricedLines: 0 }),
        ]}
      />,
    );
    expect(screen.getAllByText("Unpriced").length).toBeGreaterThanOrEqual(2); // badge + cell
    expect(screen.getByText("Customer key")).toBeTruthy();
    expect(screen.getByText("$2.50")).toBeTruthy();
    expect(screen.queryByText("$0.00")).toBeNull();
  });
});
