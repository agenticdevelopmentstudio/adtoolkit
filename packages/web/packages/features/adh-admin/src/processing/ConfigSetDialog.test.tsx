// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import type { ConfigSet } from "../api/processing";

const { authedJson, authedRequest } = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));
vi.mock("../api/http", () => ({ authedJson, authedRequest }));

const services = [
  {
    id: "svc-openai",
    name: "My OpenAI",
    providerKind: "openai",
    models: [{ id: "gpt-a", displayName: "GPT A" }, { id: "gpt-b" }],
  },
  { id: "svc-claude", name: "My Claude", providerKind: "anthropic", models: [{ id: "claude-x" }] },
  { id: "svc-empty", name: "Bare", providerKind: "gemini", models: [] },
  { id: "svc-ext", name: "Custom endpoint", providerKind: "external", models: [{ id: "x" }] },
];
vi.mock("./useConfigSetServices", () => ({
  useConfigSetServices: () => ({ items: services, isFetching: false, error: null }),
}));

import { ConfigSetDialog } from "./ConfigSetDialog";

afterEach(cleanup);
beforeEach(() => {
  authedJson.mockReset();
  authedJson.mockResolvedValue({});
});

function mount(configSet: ConfigSet | null = null, onClose = vi.fn()) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={client}>
      <ConfigSetDialog open configSet={configSet} onClose={onClose} onDirtyChange={vi.fn()} />
    </QueryClientProvider>,
  );
  return { onClose };
}

const type = (label: string, value: string) =>
  fireEvent.change(screen.getByLabelText(label), { target: { value } });
const save = () => fireEvent.click(screen.getByRole("button", { name: "Save" }));

describe("ConfigSetDialog", () => {
  it("explains that paid services must use the provider's own API host", () => {
    mount();
    expect(
      screen.getByText(/Paid services must use the provider's own API host\./),
    ).toBeTruthy();
  });

  it("saves a local set: free-text model, no service, timeout in seconds sent as ms", async () => {
    const { onClose } = mount();
    type("Name", "Local llama");
    type("Model", "llama3.2");
    type("Temperature", "0.5");
    type("Max output tokens", "800");
    type("Timeout (seconds)", "30");
    save();
    await waitFor(() => expect(onClose).toHaveBeenCalled());
    expect(authedJson).toHaveBeenCalledWith("/api/processing/admin/config-sets", {
      method: "POST",
      body: JSON.stringify({
        name: "Local llama",
        description: null,
        serviceId: null,
        model: "llama3.2",
        params: { temperature: 0.5, maxOutputTokens: 800, timeoutMs: 30000 },
      }),
    });
  });

  it("offers the node's local LLM first, then the services", () => {
    mount();
    const options = within(screen.getByLabelText("Service")).getAllByRole("option");
    expect(options.map((o) => o.textContent)).toEqual([
      "Node's local LLM",
      "My OpenAI",
      "My Claude",
      "Bare",
    ]);
  });

  it("does not offer services of a kind no node can run", () => {
    mount();
    const names = within(screen.getByLabelText("Service")).getAllByRole("option").map((o) => o.textContent);
    expect(names).not.toContain("Custom endpoint");
  });

  it("keeps showing the service of a set that is not among the admin's own", () => {
    const set: ConfigSet = {
      id: "cs-9",
      name: "Shared",
      description: null,
      service: { id: "svc-other", name: "Team Claude", providerKind: "anthropic" },
      provider: "anthropic",
      model: "claude-z",
      params: {},
      isDefault: false,
      createdAt: "2026-10-01T00:00:00Z",
      updatedAt: "2026-10-01T00:00:00Z",
    };
    mount(set);
    const service = screen.getByLabelText("Service") as HTMLSelectElement;
    expect(service.value).toBe("svc-other");
    expect(within(service).getByRole("option", { name: /Team Claude/ })).toBeTruthy();
    // Its models are unknown here, so the model is free text.
    expect((screen.getByLabelText("Model") as HTMLInputElement).value).toBe("claude-z");
    expect(screen.getByLabelText("Model").tagName).toBe("INPUT");
  });

  it("limits the model options to the chosen service's models", () => {
    mount();
    type("Service", "svc-openai");
    const models = within(screen.getByLabelText("Model")).getAllByRole("option");
    expect(models.map((o) => (o as HTMLOptionElement).value)).toEqual(["", "gpt-a", "gpt-b"]);
    type("Service", "svc-claude");
    const next = within(screen.getByLabelText("Model")).getAllByRole("option");
    expect(next.map((o) => (o as HTMLOptionElement).value)).toEqual(["", "claude-x"]);
  });

  it("falls back to free text for a service that lists no models", () => {
    mount();
    type("Service", "svc-empty");
    expect(screen.getByLabelText("Model").tagName).toBe("INPUT");
  });

  it("sends the chosen service and model", async () => {
    mount();
    type("Name", "Paid");
    type("Service", "svc-openai");
    type("Model", "gpt-b");
    save();
    await waitFor(() => expect(authedJson).toHaveBeenCalled());
    expect(JSON.parse(authedJson.mock.calls[0]![1].body)).toMatchObject({
      serviceId: "svc-openai",
      model: "gpt-b",
    });
  });

  it("shows the server's message when the save is refused", async () => {
    authedJson.mockRejectedValue(new Error("A config set named 'x' already exists"));
    mount();
    type("Name", "x");
    type("Model", "m");
    save();
    expect(await screen.findByText("A config set named 'x' already exists")).toBeTruthy();
  });

  it("edits with PUT, showing the timeout in seconds", async () => {
    const set: ConfigSet = {
      id: "cs-1",
      name: "Existing",
      description: "d",
      service: null,
      provider: "local",
      model: "llama3.2",
      params: { timeoutMs: 45000 },
      isDefault: false,
      createdAt: "2026-10-01T00:00:00Z",
      updatedAt: "2026-10-01T00:00:00Z",
    };
    const { onClose } = mount(set);
    expect((screen.getByLabelText("Timeout (seconds)") as HTMLInputElement).value).toBe("45");
    type("Model", "llama3.3");
    save();
    await waitFor(() => expect(onClose).toHaveBeenCalled());
    expect(authedJson.mock.calls[0]![0]).toBe("/api/processing/admin/config-sets/cs-1");
    expect(authedJson.mock.calls[0]![1].method).toBe("PUT");
  });
});
