// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import type { ConfigSet } from "../api/processing";

const { authedJson, authedRequest } = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));
vi.mock("../api/http", () => ({ authedJson, authedRequest }));
vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));
vi.mock("../processing/useConfigSetServices", () => ({
  useConfigSetServices: () => ({ items: [], isFetching: false, error: null }),
}));

import { ProcessingConfigsPane } from "./ProcessingConfigsPane";

const set = (over: Partial<ConfigSet>): ConfigSet => ({
  id: "cs-1",
  name: "Local llama",
  description: null,
  service: null,
  provider: "local",
  model: "llama3.2",
  params: {},
  isDefault: false,
  createdAt: "2026-10-01T00:00:00Z",
  updatedAt: "2026-10-01T00:00:00Z",
  ...over,
});

let sets: ConfigSet[];

beforeEach(() => {
  sets = [
    set({}),
    set({
      id: "cs-2",
      name: "Claude fast",
      provider: "anthropic",
      model: "claude-x",
      service: { id: "svc", name: "My Claude", providerKind: "anthropic" },
      isDefault: true,
    }),
  ];
  authedJson.mockReset();
  authedRequest.mockReset();
  authedJson.mockImplementation(async (url: string) =>
    url === "/api/processing/admin/config-sets" ? { configSets: sets } : {},
  );
  authedRequest.mockResolvedValue(undefined);
});
afterEach(cleanup);

function mount() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={client}>
      <ProcessingConfigsPane />
    </QueryClientProvider>,
  );
}

const select = async (name: string) =>
  fireEvent.click(await screen.findByRole("checkbox", { name: `Select ${name}` }));

describe("ProcessingConfigsPane", () => {
  it("lists name, provider, model and a Default badge", async () => {
    mount();
    expect(await screen.findByText("Local llama")).toBeTruthy();
    expect(screen.getByText("Claude fast")).toBeTruthy();
    expect(screen.getByText("claude-x")).toBeTruthy();
    expect(screen.getAllByText("anthropic").length).toBeGreaterThan(0);
    expect(screen.getAllByText("Default")).toHaveLength(1);
  });

  it("says where paid-provider keys live, and offers no key field", async () => {
    mount();
    await screen.findByText("Local llama");
    expect(
      screen.getByText(
        "A paid config set runs only on nodes that hold that provider's key (AI_NODE_<PROVIDER>_API_KEY).",
      ),
    ).toBeTruthy();
    expect(screen.queryByLabelText(/api key/i)).toBeNull();
  });

  it("Make default calls the API for the selected set", async () => {
    mount();
    await select("Local llama");
    fireEvent.click(screen.getByRole("button", { name: /make default/i }));
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith("/api/processing/admin/config-sets/cs-1/default", {
        method: "POST",
      }),
    );
  });

  it("shows the server's message when Make default is refused", async () => {
    authedJson.mockImplementation(async (url: string) => {
      if (url.endsWith("/default")) throw new Error("Config set is not usable as default");
      return { configSets: sets };
    });
    mount();
    await select("Local llama");
    fireEvent.click(screen.getByRole("button", { name: /make default/i }));
    expect(await screen.findByText("Config set is not usable as default")).toBeTruthy();
  });

  it("moves the Default badge after Make default (the list refetches)", async () => {
    authedJson.mockImplementation(async (url: string, init?: { method?: string }) => {
      if (url.endsWith("/default") && init?.method === "POST") {
        sets = sets.map((x) => ({ ...x, isDefault: x.id === "cs-1" }));
        return {};
      }
      return { configSets: sets };
    });
    mount();
    await select("Local llama");
    fireEvent.click(screen.getByRole("button", { name: /make default/i }));
    await waitFor(() => {
      const badge = screen.getByText("Default");
      expect(badge.closest("[role=row]")?.textContent).toContain("Local llama");
    });
  });

  it("says that jobs pinned to a deleted set fall back to the default", async () => {
    mount();
    await select("Local llama");
    fireEvent.click(screen.getByRole("button", { name: "Delete" }));
    expect(await screen.findByText(/fall back to the default set/)).toBeTruthy();
  });

  it("Clear default calls DELETE on the default", async () => {
    mount();
    await screen.findByText("Local llama");
    fireEvent.click(screen.getByRole("button", { name: /clear default/i }));
    await waitFor(() =>
      expect(authedRequest).toHaveBeenCalledWith("/api/processing/admin/config-sets/default", {
        method: "DELETE",
      }),
    );
  });

  it("deletes the selected set after confirmation, surfacing a refusal", async () => {
    authedRequest.mockRejectedValue(new Error("config set not found"));
    mount();
    await select("Local llama");
    fireEvent.click(screen.getByRole("button", { name: "Delete" }));
    fireEvent.change(await screen.findByLabelText(/Type the word/), {
      target: { value: "delete" },
    });
    fireEvent.click(screen.getAllByRole("button", { name: "Delete" }).at(-1)!);
    await waitFor(() =>
      expect(authedRequest).toHaveBeenCalledWith("/api/processing/admin/config-sets/cs-1", {
        method: "DELETE",
      }),
    );
    expect(await screen.findByText(/config set not found/)).toBeTruthy();
  });
});
