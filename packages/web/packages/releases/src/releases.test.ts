// node --experimental-strip-types --test src/*.test.ts (also `pnpm test`).
// No Next.js imports and no build step: fetch is replaced per test.
import { test, type TestContext } from "node:test";
import assert from "node:assert/strict";
import { loadReleases, latestAsset, releaseNotes } from "./releases.ts";
import { appcastHandler } from "./appcast.ts";

const BASE = "https://example.com/releases/main";
const EMPTY = { schema: 1, latest: null, releases: [] };
const asset = (v: string, ext: string) => ({
  url: `https://example.com/v${v}/App-${v}.${ext}`,
  size: 100,
  sha256: "abc123",
});
function entry(version: string, build: number) {
  return {
    version,
    build,
    date: "2026-09-26T00:00:00Z",
    minimumSystemVersion: "14.0",
    notes: `notes/${version}.md`,
    pkg: asset(version, "pkg"),
    zip: asset(version, "zip"),
  };
}

function stubFetch(t: TestContext, impl: (url: string) => Promise<Response>): string[] {
  const calls: string[] = [];
  t.mock.method(globalThis, "fetch", (url: string) => {
    calls.push(url);
    return impl(url);
  });
  return calls;
}

const json = (body: unknown) => Promise.resolve(Response.json(body));

test("loadReleases sorts newest build first", async (t) => {
  const calls = stubFetch(t, () =>
    json({
      schema: 1,
      latest: "1.0.172.0",
      releases: [entry("2.160.0", 160), entry("1.0.172.0", 172), entry("2.161.0", 161)],
    }),
  );
  const r = await loadReleases(BASE);
  assert.deepEqual(r.releases.map((e) => e.build), [172, 161, 160]);
  assert.deepEqual(calls, [`${BASE}/releases.json`]);
});

test("latestAsset is null for an empty releases.json", async (t) => {
  stubFetch(t, () => json(EMPTY));
  const r = await loadReleases(BASE);
  assert.equal(latestAsset(r, "pkg"), null);
  assert.equal(latestAsset(r, "zip"), null);
});

test("latestAsset returns the asset of the release latest names", async (t) => {
  stubFetch(t, () =>
    json({ schema: 1, latest: "1.0.0", releases: [entry("1.0.0", 1), entry("0.9.0", 0)] }),
  );
  const r = await loadReleases(BASE);
  assert.equal(latestAsset(r, "pkg")?.url, "https://example.com/v1.0.0/App-1.0.0.pkg");
  assert.equal(latestAsset(r, "zip")?.url, "https://example.com/v1.0.0/App-1.0.0.zip");
});

test("loadReleases degrades to an empty doc on a failed fetch, a 404 or a bad schema", async (t) => {
  stubFetch(t, () => Promise.reject(new Error("offline")));
  assert.deepEqual(await loadReleases(BASE), EMPTY);
  t.mock.restoreAll();
  stubFetch(t, () => json({ schema: 2, latest: null, releases: [] }));
  assert.deepEqual(await loadReleases(BASE), EMPTY);
  t.mock.restoreAll();
  stubFetch(t, () => Promise.resolve(new Response("nope", { status: 404 })));
  assert.deepEqual(await loadReleases(BASE), EMPTY);
});

test("a malformed entry is skipped on its own and warned about", async (t) => {
  const warn = t.mock.method(console, "warn", () => {});
  stubFetch(t, () =>
    json({
      schema: 1,
      latest: "1.0.0",
      releases: [
        { ...entry("1.1.0", 2), pkg: { ...asset("1.1.0", "pkg"), url: "http://example.com/a.pkg" } },
        { ...entry("1.0.1", 3), notes: "notes/../../x.md" },
        entry("1.0.0", 1),
      ],
    }),
  );
  const r = await loadReleases(BASE);
  assert.deepEqual(r.releases.map((e) => e.version), ["1.0.0"]);
  assert.equal(warn.mock.callCount(), 2);
});

test("a latest naming a malformed entry becomes null", async (t) => {
  t.mock.method(console, "warn", () => {});
  stubFetch(t, () =>
    json({
      schema: 1,
      latest: "1.1.0",
      releases: [{ ...entry("1.1.0", 2), notes: "../x.md" }, entry("1.0.0", 1)],
    }),
  );
  const r = await loadReleases(BASE);
  assert.equal(r.latest, null);
  assert.equal(latestAsset(r, "pkg"), null);
  assert.equal(r.releases.length, 1);
});

test("releaseNotes fetches the notes file for a version, or null", async (t) => {
  const calls = stubFetch(t, (url) =>
    Promise.resolve(
      url.endsWith("notes/1.0.0.md") ? new Response("# 1.0.0\n") : new Response("", { status: 404 }),
    ),
  );
  assert.equal(await releaseNotes(BASE, "1.0.0"), "# 1.0.0\n");
  assert.equal(await releaseNotes(BASE, "2.0.0"), null);
  assert.equal(await releaseNotes(BASE, "../evil"), null);
  assert.deepEqual(calls, [`${BASE}/notes/1.0.0.md`, `${BASE}/notes/2.0.0.md`]);
});

test("appcastHandler returns 502 when the upstream fetch fails", async (t) => {
  stubFetch(t, () => Promise.reject(new Error("offline")));
  assert.equal((await appcastHandler(BASE)()).status, 502);
  t.mock.restoreAll();
  stubFetch(t, () => Promise.resolve(new Response("missing", { status: 404 })));
  assert.equal((await appcastHandler(BASE)()).status, 502);
});

test("appcastHandler passes the feed through byte-for-byte", async (t) => {
  // CRLF, multibyte text, a NUL and 0xff all survive: the feed is EdDSA-signed,
  // so one altered byte fails verification.
  const bytes = new Uint8Array([
    ...new TextEncoder().encode("<rss>\r\n  <t>é</t>\n</rss>\n"),
    0x00,
    0xff,
  ]);
  const calls = stubFetch(t, () => Promise.resolve(new Response(bytes)));
  const res = await appcastHandler(BASE)();
  assert.equal(res.status, 200);
  assert.match(res.headers.get("content-type") ?? "", /^application\/xml/);
  assert.deepEqual(new Uint8Array(await res.arrayBuffer()), bytes);
  assert.deepEqual(calls, [`${BASE}/appcast.xml`]);
});
