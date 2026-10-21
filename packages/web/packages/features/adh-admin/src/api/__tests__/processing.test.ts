// The processing-admin API layer at the `authedJson` boundary: every call builds the documented
// URL, method and body, and the query keys all sit under the `processing-admin` prefix.
import { beforeEach, describe, expect, it, vi } from "vitest";

const { authedJson, authedRequest } = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));
vi.mock("../http", () => ({ authedJson, authedRequest }));

import {
  PROCESSING_ADMIN_KEY,
  clearDefaultConfigSet,
  createConfigSet,
  deleteConfigSet,
  deleteNode,
  getNode,
  getProcessingSettings,
  listConfigSets,
  listNodeLogs,
  listNodes,
  processingKeys,
  putProcessingSettings,
  setDefaultConfigSet,
  updateConfigSet,
} from "../processing";

const BASE = "/api/processing/admin";

beforeEach(() => {
  authedJson.mockReset();
  authedRequest.mockReset();
  authedJson.mockResolvedValue({});
});

describe("config sets", () => {
  it("lists", async () => {
    await listConfigSets();
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/config-sets`);
  });

  it("creates with a POST body", async () => {
    await createConfigSet({ name: "n", model: "m", serviceId: null });
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/config-sets`, {
      method: "POST",
      body: JSON.stringify({ name: "n", model: "m", serviceId: null }),
    });
  });

  it("updates with a PUT body", async () => {
    await updateConfigSet("abc", { name: "n", model: "m" });
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/config-sets/abc`, {
      method: "PUT",
      body: JSON.stringify({ name: "n", model: "m" }),
    });
  });

  it("deletes", async () => {
    // 204 No Content: authedJson would throw on the empty body, so deletes go through authedRequest.
    await deleteConfigSet("abc");
    expect(authedRequest).toHaveBeenCalledWith(`${BASE}/config-sets/abc`, { method: "DELETE" });
  });

  it("makes a set the default, and clears the default", async () => {
    await setDefaultConfigSet("abc");
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/config-sets/abc/default`, { method: "POST" });
    await clearDefaultConfigSet();
    expect(authedRequest).toHaveBeenCalledWith(`${BASE}/config-sets/default`, { method: "DELETE" });
  });
});

describe("nodes", () => {
  it("lists, gets and deletes", async () => {
    await listNodes();
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/nodes`);
    await getNode("n 1");
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/nodes/n%201`);
    await deleteNode("n 1");
    expect(authedRequest).toHaveBeenCalledWith(`${BASE}/nodes/n%201`, { method: "DELETE" });
  });

  it("pages logs with only the filters given", async () => {
    await listNodeLogs("n1");
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/nodes/n1/logs`);
    await listNodeLogs("n1", { level: "error", before: 40, limit: 50 });
    expect(authedJson).toHaveBeenLastCalledWith(
      `${BASE}/nodes/n1/logs?level=error&before=40&limit=50`,
    );
  });
});

describe("settings", () => {
  it("reads and writes the retention", async () => {
    await getProcessingSettings();
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/settings`);
    await putProcessingSettings({ logRetentionDays: 30 });
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/settings`, {
      method: "PUT",
      body: JSON.stringify({ logRetentionDays: 30 }),
    });
  });
});

describe("query keys", () => {
  it("all sit under the processing-admin prefix", () => {
    const keys = [
      processingKeys.configSets(),
      processingKeys.nodes(),
      processingKeys.node("n1"),
      processingKeys.logs("n1", { level: "warn" }),
      processingKeys.settings(),
    ];
    for (const k of keys) expect(k[0]).toBe(PROCESSING_ADMIN_KEY[0]);
  });
});
