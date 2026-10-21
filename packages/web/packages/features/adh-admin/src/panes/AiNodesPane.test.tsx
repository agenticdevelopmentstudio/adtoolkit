// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import type { NodeLog, ProcessingNode } from "../api/processing";

const { authedJson, authedRequest } = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));
vi.mock("../api/http", () => ({ authedJson, authedRequest }));
vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));

import { AiNodesPane } from "./AiNodesPane";

const node = (over: Partial<ProcessingNode>): ProcessingNode => ({
  id: "node-a",
  kind: "typescript",
  version: "1.2.3",
  host: "box-a",
  providers: ["local", "openai"],
  config: { pollIntervalMs: 2000, model: "llama3.2" },
  online: true,
  firstSeenAt: "2026-10-01T00:00:00Z",
  lastSeenAt: new Date().toISOString(),
  jobsCompleted: 12,
  jobsFailed: 3,
  ...over,
});

const log = (id: number, over: Partial<NodeLog> = {}): NodeLog => ({
  id,
  nodeId: "node-a",
  occurredAt: "2026-10-21T10:00:00Z",
  receivedAt: "2026-10-21T10:00:01Z",
  level: "info",
  event: "job.claimed",
  message: `message ${id}`,
  jobId: null,
  data: null,
  ...over,
});

let logPages: Record<string, { entries: NodeLog[]; nextBefore: number | null }>;

beforeEach(() => {
  authedJson.mockReset();
  authedRequest.mockReset();
  authedRequest.mockResolvedValue(undefined);
  logPages = {};
  authedJson.mockImplementation(async (url: string) => {
    if (url === "/api/processing/admin/nodes") {
      return {
        nodes: [
          node({}),
          node({ id: "node-b", kind: "swift", online: false, providers: ["local"], jobsFailed: 0 }),
        ],
      };
    }
    if (url === "/api/processing/admin/settings") return { logRetentionDays: 14 };
    if (url.includes("/logs")) return logPages[url] ?? { entries: [], nextBefore: null };
    return {};
  });
});
afterEach(cleanup);

function mount() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={client}>
      <AiNodesPane />
    </QueryClientProvider>,
  );
  return client;
}

const openNode = async (id: string) =>
  fireEvent.click(await screen.findByRole("checkbox", { name: `Select ${id}` }));

describe("AiNodesPane list", () => {
  it("shows an Online / Offline badge, kind, version, providers and job counts", async () => {
    mount();
    await screen.findByText("node-a");
    expect(screen.getByText("Online")).toBeTruthy();
    expect(screen.getByText("Offline")).toBeTruthy();
    expect(screen.getByText("swift")).toBeTruthy();
    expect(screen.getAllByText("1.2.3")).toHaveLength(2);
    expect(screen.getByText("local, openai")).toBeTruthy();
    expect(screen.getByText("12 / 3")).toBeTruthy();
  });

  it("deletes the selected node after confirmation", async () => {
    mount();
    await openNode("node-b");
    fireEvent.click(screen.getByRole("button", { name: "Delete" }));
    fireEvent.change(await screen.findByLabelText(/Type the word/), { target: { value: "delete" } });
    fireEvent.click(screen.getAllByRole("button", { name: "Delete" }).at(-1)!);
    await waitFor(() =>
      expect(authedRequest).toHaveBeenCalledWith("/api/processing/admin/nodes/node-b", {
        method: "DELETE",
      }),
    );
  });
});

describe("AiNodesPane detail", () => {
  it("shows the reported config as key/value", async () => {
    mount();
    await openNode("node-a");
    const config = await screen.findByRole("region", { name: "Reported config" });
    expect(within(config).getByText("pollIntervalMs")).toBeTruthy();
    expect(within(config).getByText("2000")).toBeTruthy();
    expect(within(config).getByText("llama3.2")).toBeTruthy();
  });

  it("refetches the logs when the level filter changes", async () => {
    mount();
    await openNode("node-a");
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith("/api/processing/admin/nodes/node-a/logs?limit=50"),
    );
    fireEvent.change(await screen.findByLabelText("Level"), { target: { value: "error" } });
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith(
        "/api/processing/admin/nodes/node-a/logs?level=error&limit=50",
      ),
    );
  });

  it("Load more pages with nextBefore, appending older entries", async () => {
    logPages["/api/processing/admin/nodes/node-a/logs?limit=50"] = {
      entries: [log(100), log(99)],
      nextBefore: 99,
    };
    logPages["/api/processing/admin/nodes/node-a/logs?before=99&limit=50"] = {
      entries: [log(98)],
      nextBefore: null,
    };
    mount();
    await openNode("node-a");
    await screen.findByText("message 100");
    fireEvent.click(screen.getByRole("button", { name: "Load more" }));
    await screen.findByText("message 98");
    expect(screen.getByText("message 100")).toBeTruthy();
    expect(screen.queryByRole("button", { name: "Load more" })).toBeNull();
  });
});

describe("AiNodesPane node delete copy", () => {
  it("says the registry row goes and the logs stay until retention", async () => {
    mount();
    await openNode("node-b");
    fireEvent.click(screen.getByRole("button", { name: "Delete" }));
    expect(await screen.findByText(/removed from the registry/)).toBeTruthy();
    expect(screen.getByText(/logs are kept until the retention window/)).toBeTruthy();
  });
});

describe("AiNodesPane logs level label", () => {
  it("labels the filter as a minimum level", async () => {
    mount();
    await openNode("node-a");
    const level = await screen.findByLabelText("Level");
    expect(within(level).getByRole("option", { name: "warn and above" })).toBeTruthy();
  });
});

describe("AiNodesPane retention", () => {
  it("shows a failed settings read", async () => {
    const base = authedJson.getMockImplementation()!;
    authedJson.mockImplementation(async (url: string, init?: unknown) => {
      if (url === "/api/processing/admin/settings") throw new Error("settings unavailable");
      return base(url, init);
    });
    mount();
    expect(await screen.findByText("settings unavailable")).toBeTruthy();
  });

  it("does not overwrite what the admin is typing when the stored value changes", async () => {
    const client = mount();
    const input = (await screen.findByLabelText("Log retention (days)")) as HTMLInputElement;
    await waitFor(() => expect(input.value).toBe("14"));
    fireEvent.change(input, { target: { value: "99" } });
    expect(input.value).toBe("99");
    // a refetch returning a different stored value must leave the typed text alone
    authedJson.mockImplementation(async (url: string) =>
      url === "/api/processing/admin/settings" ? { logRetentionDays: 20 } : { nodes: [] },
    );
    const calls = authedJson.mock.calls.length;
    await client.invalidateQueries({ queryKey: ["processing-admin", "settings"] });
    await waitFor(() => expect(authedJson.mock.calls.length).toBeGreaterThan(calls));
    expect(input.value).toBe("99");
  });

  it("rejects a value outside 1..365 and saves a valid one", async () => {
    mount();
    const input = (await screen.findByLabelText("Log retention (days)")) as HTMLInputElement;
    await waitFor(() => expect(input.value).toBe("14"));
    const saveBtn = screen.getByRole("button", { name: "Save retention" }) as HTMLButtonElement;

    for (const bad of ["0", "366", "1.5", ""]) {
      fireEvent.change(input, { target: { value: bad } });
      expect(saveBtn.disabled).toBe(true);
    }
    fireEvent.change(input, { target: { value: "0" } });
    expect(screen.getByText("Retention must be a whole number of days from 1 to 365.")).toBeTruthy();

    fireEvent.change(input, { target: { value: "30" } });
    expect(saveBtn.disabled).toBe(false);
    fireEvent.click(saveBtn);
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith("/api/processing/admin/settings", {
        method: "PUT",
        body: JSON.stringify({ logRetentionDays: 30 }),
      }),
    );
  });
});
