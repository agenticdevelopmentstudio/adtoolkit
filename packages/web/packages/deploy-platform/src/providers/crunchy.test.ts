import { afterEach, describe, expect, it, vi } from "vitest";
import { listCrunchyClusters } from "./crunchy.js";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("listCrunchyClusters", () => {
  it("lists every cluster, sending the raw key as a Bearer token", async () => {
    const fetchMock = vi.fn(async () => json({ clusters: [{ id: "fq2z", name: "adh-production", state: "ready" }] }));
    vi.stubGlobal("fetch", fetchMock);

    const out = await listCrunchyClusters("cbkey_x", new AbortController().signal);

    expect(out).toEqual([{ id: "fq2z", name: "adh-production", state: "ready" }]);
    const [url, init] = fetchMock.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe("https://api.crunchybridge.com/clusters");
    expect(init.headers).toMatchObject({ Authorization: "Bearer cbkey_x" });
  });

  it("drops a cluster with no id or name — neither can key a row or a monitor", async () => {
    vi.stubGlobal("fetch", vi.fn(async () => json({ clusters: [{ id: "", name: "x", state: "ready" }, { id: "a", name: "", state: "ready" }] })));
    expect(await listCrunchyClusters("cbkey_x", new AbortController().signal)).toEqual([]);
  });

  it("is null, never empty, when the read fails — a failed listing is not 'no clusters'", async () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    vi.stubGlobal("fetch", vi.fn(async () => new Response("nope", { status: 500 })));
    expect(await listCrunchyClusters("cbkey_x", new AbortController().signal)).toBeNull();

    vi.stubGlobal("fetch", vi.fn(async () => { throw new Error("ECONNRESET"); }));
    expect(await listCrunchyClusters("cbkey_x", new AbortController().signal)).toBeNull();
  });
});
