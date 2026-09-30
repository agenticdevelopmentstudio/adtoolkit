// @vitest-environment jsdom
import { describe, it, expect, afterEach, vi } from "vitest";
import { render, screen, fireEvent, cleanup, waitFor } from "@testing-library/react";
import { FixedCostsList } from "./FixedCostsList";
import { todayUtc } from "./days";
import type { FixedCost } from "../api/insight";

const updateAsync = vi.fn();
const deleteAsync = vi.fn();
let rows: FixedCost[] = [];
vi.mock("../api/insight", () => ({
  useFixedCosts: () => ({ data: rows, isLoading: false, error: null }),
  useCreateFixedCost: () => ({ mutateAsync: vi.fn() }),
  useUpdateFixedCost: () => ({ mutateAsync: updateAsync }),
  useDeleteFixedCost: () => ({ mutateAsync: deleteAsync }),
}));

afterEach(() => {
  cleanup();
  updateAsync.mockReset();
  deleteAsync.mockReset();
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

/** Render the list over `costs` and select the row labelled `label`. */
function selectRow(costs: FixedCost[], label: string) {
  rows = costs;
  render(<FixedCostsList />);
  fireEvent.click(screen.getByText(label).closest("[role='row']")!);
}

const button = (name: string) => screen.getByRole("button", { name }) as HTMLButtonElement;

describe("FixedCostsList", () => {
  it("deletes a cost that starts in the future", async () => {
    deleteAsync.mockResolvedValue({ ok: true });
    selectRow([cost({ effectiveFrom: "2999-01-01" })], "Backend service");
    expect(screen.queryByRole("button", { name: "End cost" })).toBeNull();
    fireEvent.click(button("Delete"));
    await waitFor(() => expect(deleteAsync).toHaveBeenCalledWith("c1"));
    expect(updateAsync).not.toHaveBeenCalled();
  });

  // The backend lets a cost be deleted while `effectiveFrom >= today`, so today counts as not begun.
  it("deletes a cost that starts today", async () => {
    deleteAsync.mockResolvedValue({ ok: true });
    selectRow([cost({ effectiveFrom: todayUtc() })], "Backend service");
    fireEvent.click(button("Delete"));
    await waitFor(() => expect(deleteAsync).toHaveBeenCalledWith("c1"));
  });

  it("ends a running open-ended cost today", async () => {
    updateAsync.mockResolvedValue({});
    selectRow([cost()], "Backend service");
    expect(screen.queryByRole("button", { name: "Delete" })).toBeNull();
    fireEvent.click(button("End cost"));
    await waitFor(() =>
      expect(updateAsync).toHaveBeenCalledWith({ id: "c1", changes: { effectiveTo: todayUtc() } }),
    );
    expect(deleteAsync).not.toHaveBeenCalled();
  });

  it("shows a rejected action beside it, and clears it when another row is chosen", async () => {
    updateAsync.mockRejectedValue(new Error("the cost has already ended"));
    selectRow([cost(), cost({ id: "c2", label: "Database" })], "Backend service");
    fireEvent.click(button("End cost"));
    expect((await screen.findByRole("alert")).textContent).toBe("the cost has already ended");
    fireEvent.click(screen.getByText("Database").closest("[role='row']")!);
    await waitFor(() => expect(screen.queryByRole("alert")).toBeNull());
  });
});
