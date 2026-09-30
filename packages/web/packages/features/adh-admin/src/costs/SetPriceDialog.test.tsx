// @vitest-environment jsdom
import { describe, it, expect, afterEach, vi } from "vitest";
import { render, screen, fireEvent, cleanup, waitFor } from "@testing-library/react";
import { SetPriceDialog } from "./SetPriceDialog";
import type { InsightItem } from "../api/insight";

const createAsync = vi.fn();
vi.mock("../api/insight", () => ({
  useCreateRate: () => ({ mutateAsync: createAsync }),
}));

afterEach(() => {
  cleanup();
  createAsync.mockReset();
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

  it("prefills the rate already in effect and does not re-send it unchanged", () => {
    open(
      item({
        source: "rate",
        rates: [
          {
            category: "llm",
            provider: "anthropic",
            sku: "claude-sonnet",
            quantityKey: "input_tokens",
            microsPerUnit: "3",
            effectiveFrom: "2026-01-01",
          },
        ],
      }),
    );
    expect((screen.getByLabelText("input_tokens price") as HTMLInputElement).value).toBe("3");
    expect(save().disabled).toBe(true);
    fireEvent.change(screen.getByLabelText("input_tokens price"), { target: { value: "4" } });
    expect(save().disabled).toBe(false);
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
