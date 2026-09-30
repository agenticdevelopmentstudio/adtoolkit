// @vitest-environment jsdom
import { describe, it, expect, afterEach, vi } from "vitest";
import { render, screen, fireEvent, cleanup, waitFor } from "@testing-library/react";
import { SetPriceDialog } from "./SetPriceDialog";
import type { InsightItem } from "../api/insight";

const createAsync = vi.fn();
let ratesData: unknown[] = [];
vi.mock("../api/insight", () => ({
  useCreateRate: () => ({ mutateAsync: createAsync }),
  useRates: () => ({ data: ratesData }),
}));

afterEach(() => {
  cleanup();
  createAsync.mockReset();
  ratesData = [];
});

const item = (over: Partial<InsightItem> = {}): InsightItem => ({
  category: "llm",
  provider: "anthropic",
  sku: "claude-sonnet",
  quantities: { input_tokens: 2_000_000, output_tokens: 500_000 },
  capturedMicros: 0,
  costMicros: null,
  source: "unpriced",
  unpricedLines: 4,
  lines: 4,
  rates: [],
  ...over,
});

const save = () => screen.getByRole("button", { name: "Save" }) as HTMLButtonElement;

function open(it: InsightItem, onClose = vi.fn()) {
  render(<SetPriceDialog item={it} open onClose={onClose} />);
  return onClose;
}

describe("SetPriceDialog", () => {
  it("lists the item's quantity keys, sorted, with Save disabled until a price is typed", () => {
    open(item());
    expect(screen.getByLabelText("input_tokens price")).toBeTruthy();
    expect(screen.getByLabelText("output_tokens price")).toBeTruthy();
    expect(save().disabled).toBe(true);
  });

  it("converts a $ per 1M price to the exact per-unit decimal and creates the rate", async () => {
    createAsync.mockResolvedValue({});
    const onClose = open(item());
    fireEvent.change(screen.getByLabelText("input_tokens price"), { target: { value: "0.15" } });
    fireEvent.change(screen.getByLabelText("input_tokens price unit"), {
      target: { value: "dollars-per-1m" },
    });
    fireEvent.change(screen.getByLabelText("Effective from"), { target: { value: "2026-09-30" } });
    fireEvent.click(save());
    await waitFor(() => expect(onClose).toHaveBeenCalled());
    expect(createAsync).toHaveBeenCalledTimes(1);
    expect(createAsync).toHaveBeenCalledWith({
      category: "llm",
      provider: "anthropic",
      sku: "claude-sonnet",
      quantityKey: "input_tokens",
      microsPerUnit: "0.15",
      effectiveFrom: "2026-09-30",
    });
  });

  it("converts $ per 1K by shifting three places", async () => {
    createAsync.mockResolvedValue({});
    open(item());
    fireEvent.change(screen.getByLabelText("output_tokens price"), { target: { value: "0.015" } });
    fireEvent.change(screen.getByLabelText("output_tokens price unit"), {
      target: { value: "dollars-per-1k" },
    });
    fireEvent.click(save());
    await waitFor(() => expect(createAsync).toHaveBeenCalled());
    expect(createAsync.mock.calls[0]![0].microsPerUnit).toBe("15");
  });

  it("refuses a conversion past 12 fractional digits with a field error and sends nothing", () => {
    open(item());
    fireEvent.change(screen.getByLabelText("input_tokens price"), {
      target: { value: "0.0000000000000000001" },
    });
    fireEvent.change(screen.getByLabelText("input_tokens price unit"), {
      target: { value: "dollars-per-unit" },
    });
    expect(screen.getByText(/finer than 12 decimal places/)).toBeTruthy();
    expect(save().disabled).toBe(true);
  });

  describe("baseline from the rate table", () => {
    const priced = (effectiveFrom: string, microsPerUnit: string, sku = "claude-sonnet") => ({
      id: `${sku}-${effectiveFrom}`,
      category: "llm" as const,
      provider: "anthropic",
      sku,
      quantityKey: "input_tokens",
      microsPerUnit,
      effectiveFrom,
      note: "",
      createdAt: "2026-01-01T00:00:00Z",
      createdByUserId: null,
    });
    const price = () => screen.getByLabelText("input_tokens price") as HTMLInputElement;

    it("prefills the rate in effect today and does not re-send it unchanged", () => {
      ratesData = [priced("2026-01-01", "3")];
      open(item());
      expect(price().value).toBe("3");
      expect(save().disabled).toBe(true);
      fireEvent.change(price(), { target: { value: "4" } });
      expect(save().disabled).toBe(false);
    });

    it("does not prefill a future-dated rate", () => {
      ratesData = [priced("2999-01-01", "9")];
      open(item());
      expect(price().value).toBe("");
    });

    it("takes a newer rate even when it is not in the item's viewed-month rates", () => {
      // item.rates (the viewed month) holds only the old rate; the table has a newer one.
      ratesData = [priced("2026-01-01", "3"), priced("2026-06-01", "5")];
      open(item({ rates: [{ ...priced("2026-01-01", "3") }] }));
      expect(price().value).toBe("5");
    });

    it("ignores another item's rate and recomputes when the effective date moves", () => {
      ratesData = [priced("2026-01-01", "3"), priced("2026-06-01", "5"), priced("2026-01-01", "7", "other")];
      open(item());
      expect(price().value).toBe("5");
      fireEvent.change(screen.getByLabelText("Effective from"), { target: { value: "2026-03-01" } });
      expect(price().value).toBe("3");
    });

    it("says it keeps the current rate when blank, and disables the date after a partial save", async () => {
      ratesData = [priced("2026-01-01", "3")];
      createAsync.mockResolvedValueOnce({}).mockRejectedValueOnce(new Error("boom"));
      open(item());
      expect(price().placeholder).toBe("blank to keep the current rate");
      expect(screen.getByLabelText("output_tokens price")).toHaveProperty(
        "placeholder",
        "blank to leave unpriced",
      );
      fireEvent.change(price(), { target: { value: "4" } });
      fireEvent.change(screen.getByLabelText("output_tokens price"), { target: { value: "15" } });
      fireEvent.click(save());
      await screen.findByText("boom");
      expect((screen.getByLabelText("Effective from") as HTMLInputElement).disabled).toBe(true);
    });
  });

  it("shows the backend's 409 message inline under the key and stays open", async () => {
    createAsync.mockRejectedValue(new Error("a rate for that item and start day exists"));
    const onClose = open(item());
    fireEvent.change(screen.getByLabelText("input_tokens price"), { target: { value: "3" } });
    fireEvent.click(save());
    await screen.findByText("a rate for that item and start day exists");
    expect(onClose).not.toHaveBeenCalled();
  });

  it("does not re-send a key that already landed when a later key failed", async () => {
    createAsync.mockResolvedValueOnce({}).mockRejectedValueOnce(new Error("boom"));
    open(item());
    fireEvent.change(screen.getByLabelText("input_tokens price"), { target: { value: "3" } });
    fireEvent.change(screen.getByLabelText("output_tokens price"), { target: { value: "15" } });
    fireEvent.click(save());
    await screen.findByText("boom");
    createAsync.mockResolvedValue({});
    fireEvent.click(save());
    await waitFor(() => expect(createAsync).toHaveBeenCalledTimes(3));
    expect(createAsync.mock.calls[2]![0].quantityKey).toBe("output_tokens");
  });
});
