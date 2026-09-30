// @vitest-environment jsdom
import { describe, it, expect, afterEach, vi } from "vitest";
import { render, screen, fireEvent, cleanup, waitFor } from "@testing-library/react";
import { FixedCostDialog, hasStarted } from "./FixedCostsList";
import type { FixedCost } from "../api/insight";

const createAsync = vi.fn();
const updateAsync = vi.fn();
vi.mock("../api/insight", () => ({
  useCreateFixedCost: () => ({ mutateAsync: createAsync }),
  useUpdateFixedCost: () => ({ mutateAsync: updateAsync }),
  useFixedCosts: () => ({ data: [], isLoading: false, error: null }),
}));

afterEach(() => {
  cleanup();
  createAsync.mockReset();
  updateAsync.mockReset();
});

const cost = (over: Partial<FixedCost> = {}): FixedCost => ({
  id: "c1",
  provider: "railway",
  label: "Backend service",
  monthlyMicros: 20_000_000,
  effectiveFrom: "2020-01-01",
  effectiveTo: null,
  note: "",
  createdAt: "2020-01-01T00:00:00Z",
  updatedAt: "2020-01-01T00:00:00Z",
  ...over,
});

const save = () => screen.getByRole("button", { name: "Save" }) as HTMLButtonElement;

describe("FixedCostDialog", () => {
  it("creates with the dollars converted to exact integer µUSD", async () => {
    createAsync.mockResolvedValue({});
    const onClose = vi.fn();
    render(<FixedCostDialog cost={null} open onClose={onClose} />);
    fireEvent.change(screen.getByLabelText("Provider"), { target: { value: "railway" } });
    fireEvent.change(screen.getByLabelText("Label"), { target: { value: "DB" } });
    fireEvent.change(screen.getByLabelText("Monthly amount (dollars)"), { target: { value: "20.1" } });
    fireEvent.change(screen.getByLabelText("From"), { target: { value: "2026-10-01" } });
    fireEvent.click(save());
    await waitFor(() => expect(onClose).toHaveBeenCalled());
    expect(createAsync).toHaveBeenCalledWith({
      provider: "railway",
      label: "DB",
      monthlyMicros: 20_100_000,
      effectiveFrom: "2026-10-01",
    });
  });

  it("offers only label, end date and note on a cost that has started", () => {
    expect(hasStarted(cost())).toBe(true);
    render(<FixedCostDialog cost={cost()} open onClose={vi.fn()} />);
    expect(screen.getByLabelText("Label")).toBeTruthy();
    expect(screen.getByLabelText("To")).toBeTruthy();
    expect(screen.getByLabelText("Note")).toBeTruthy();
    expect(screen.queryByLabelText("Monthly amount (dollars)")).toBeNull();
    expect(screen.queryByLabelText("From")).toBeNull();
    expect(screen.queryByLabelText("Provider")).toBeNull();
  });

  it("PATCHes only the end date when that is all that changed", async () => {
    updateAsync.mockResolvedValue({});
    render(<FixedCostDialog cost={cost()} open onClose={vi.fn()} />);
    expect(save().disabled).toBe(true);
    fireEvent.change(screen.getByLabelText("To"), { target: { value: "2026-09-30" } });
    fireEvent.click(save());
    await waitFor(() => expect(updateAsync).toHaveBeenCalled());
    expect(updateAsync).toHaveBeenCalledWith({ id: "c1", changes: { effectiveTo: "2026-09-30" } });
  });

  it("offers the amount on a cost that starts in the future", () => {
    expect(hasStarted(cost({ effectiveFrom: "2999-01-01" }))).toBe(false);
    render(<FixedCostDialog cost={cost({ effectiveFrom: "2999-01-01" })} open onClose={vi.fn()} />);
    expect((screen.getByLabelText("Monthly amount (dollars)") as HTMLInputElement).value).toBe("20");
  });

  it("shows the backend's 409 message inline", async () => {
    updateAsync.mockRejectedValue(new Error("a started fixed cost keeps its amount"));
    render(<FixedCostDialog cost={cost()} open onClose={vi.fn()} />);
    fireEvent.change(screen.getByLabelText("Note"), { target: { value: "x" } });
    fireEvent.click(save());
    await screen.findByText("a started fixed cost keeps its amount");
  });
});
