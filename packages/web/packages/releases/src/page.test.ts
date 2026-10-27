// node --experimental-strip-types --test src/*.test.ts (also `pnpm test`).
// What a downloads page and its `/downloads/latest` route share: the words' holes,
// the three ways a release's facts are shown, the notes link and the redirect.
import { test, type TestContext } from "node:test";
import assert from "node:assert/strict";
import { fill } from "./fill.ts";
import { releaseDate, releaseSize, releaseSystem } from "./display.ts";
import { latestHandler } from "./latest.ts";
import { latestRelease, releaseNotesUrl } from "./releases.ts";

const BASE = "https://example.com/releases/main";

test("fill puts a value in each named hole and leaves an unknown hole as written", () => {
  assert.equal(
    fill("Version {version}, {size}. {missing}", { version: "1.2.0", size: 3 }),
    "Version 1.2.0, 3. {missing}",
  );
});

test("releaseSize is megabytes to one decimal", () => {
  assert.equal(releaseSize(12_845_056), "12.3 MB");
});

test("releaseDate reads a date-only value in UTC, not the host's zone", () => {
  // A Pacific-time host would print September 27 for a UTC-midnight date.
  assert.equal(releaseDate("2026-09-28"), "September 28, 2026");
  assert.equal(releaseDate("2026-09-28T00:00:00Z"), "September 28, 2026");
});

test("releaseDate hands back a value it cannot read", () => {
  assert.equal(releaseDate("soon"), "soon");
});

test("releaseSystem drops only a trailing .0", () => {
  assert.equal(releaseSystem("26.0"), "26");
  assert.equal(releaseSystem("14.2"), "14.2");
  assert.equal(releaseSystem("10.0.1"), "10.0.1");
});

test("releaseNotesUrl joins the raw base and the entry's notes path once", () => {
  assert.equal(releaseNotesUrl(`${BASE}/`, "notes/1.0.0.md"), `${BASE}/notes/1.0.0.md`);
  assert.equal(releaseNotesUrl(BASE, "notes/1.0.0.md"), `${BASE}/notes/1.0.0.md`);
});

const ASSET = { url: "https://example.com/v1/App-1.pkg", size: 1, sha256: "a" };
const ONE = {
  schema: 1,
  latest: "1.0.0",
  releases: [
    {
      version: "1.0.0",
      build: 1,
      date: "2026-09-26",
      minimumSystemVersion: "14.0",
      notes: "notes/1.0.0.md",
      pkg: ASSET,
      zip: { ...ASSET, url: "https://example.com/v1/App-1.zip" },
    },
  ],
};

test("latestRelease is the entry latest names, or null with no latest", () => {
  const doc = { ...ONE, schema: 1 as const };
  assert.equal(latestRelease(doc)?.version, "1.0.0");
  assert.equal(latestRelease({ ...doc, latest: null }), null);
});

function serve(t: TestContext, body: unknown): void {
  t.mock.method(globalThis, "fetch", () => Promise.resolve(Response.json(body)));
}

test("latestHandler redirects to the newest installer", async (t) => {
  serve(t, ONE);
  const res = await latestHandler(BASE)();
  assert.equal(res.status, 302);
  assert.equal(res.headers.get("location"), ASSET.url);
});

test("latestHandler can point at another asset kind", async (t) => {
  serve(t, ONE);
  const res = await latestHandler(BASE, "zip")();
  assert.equal(res.headers.get("location"), "https://example.com/v1/App-1.zip");
});

test("latestHandler is a 404 before the first release", async (t) => {
  serve(t, { schema: 1, latest: null, releases: [] });
  const res = await latestHandler(BASE)();
  assert.equal(res.status, 404);
  assert.equal(await res.text(), "No releases published yet");
});
