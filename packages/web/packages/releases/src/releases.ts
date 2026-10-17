/**
 * Release metadata read at request time from an app's public releases repo, so
 * shipping a release never needs a site deploy: `releases.json` is the single
 * source of truth and this module is the only place that trusts its shape.
 * Nothing here names a product — every call takes the repo's raw base URL
 * (e.g. `https://raw.githubusercontent.com/<org>/<app>-releases/main`).
 *
 * Schema 1, written by `tools/apple/macos_release.py`'s `merge_release`:
 *
 * ```json
 * { "schema": 1, "latest": "2.155.0" | null, "releases": [{
 *   "version": "2.155.0", "build": 412, "date": "2026-09-28T00:00:00Z",
 *   "minimumSystemVersion": "14.0", "notes": "notes/2.155.0.md",
 *   "pkg": { "url": "https://…", "size": 12345, "sha256": "…" },
 *   "zip": { "url": "https://…", "size": 12345, "sha256": "…" } }] }
 * ```
 *
 * Plain TypeScript with no Next.js imports, so `releases.test.ts` runs under
 * Node's own test runner with no build step. The `next: { revalidate }` fetch
 * option is Next's data-cache hint and is ignored anywhere else.
 */

export interface ReleaseAsset {
  url: string;
  size: number;
  sha256: string;
}

export interface ReleaseEntry {
  version: string;
  build: number;
  date: string;
  minimumSystemVersion: string;
  notes: string;
  pkg: ReleaseAsset;
  zip: ReleaseAsset;
}

export interface ReleasesJson {
  schema: 1;
  latest: string | null;
  /** Newest build first. */
  releases: ReleaseEntry[];
}

const EMPTY: ReleasesJson = { schema: 1, latest: null, releases: [] };

// Next's data cache: a release lands on the site within this window, no deploy.
const REVALIDATE_SECONDS = 300;

const trimBase = (rawBase: string): string => rawBase.replace(/\/+$/, "");

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.length > 0;
}

// Asset URLs are embedded as direct download links and updater targets; neither
// place should ever be handed plain http.
function isHttpsUrl(value: unknown): value is string {
  return typeof value === "string" && value.startsWith("https://");
}

// `notes` is appended to the raw base verbatim, so this is the only gate between
// a crafted feed and a link pointed anywhere else on the host. A flat
// `notes/<safe-name>.md` shape closes that off rather than blocklisting `..`.
const NOTES_PATH_RE = /^notes\/[0-9A-Za-z._-]+\.md$/;

function isValidNotesPath(value: unknown): value is string {
  return typeof value === "string" && NOTES_PATH_RE.test(value) && !value.includes("..");
}

function parseAsset(value: unknown): ReleaseAsset | null {
  if (typeof value !== "object" || value === null) return null;
  const asset = value as Record<string, unknown>;
  if (!isHttpsUrl(asset.url)) return null;
  if (typeof asset.size !== "number" || !Number.isFinite(asset.size)) return null;
  if (!isNonEmptyString(asset.sha256)) return null;
  return { url: asset.url, size: asset.size, sha256: asset.sha256 };
}

function parseEntry(value: unknown): ReleaseEntry | null {
  if (typeof value !== "object" || value === null) return null;
  const entry = value as Record<string, unknown>;
  if (!isNonEmptyString(entry.version)) return null;
  if (typeof entry.build !== "number" || !Number.isFinite(entry.build)) return null;
  if (!isNonEmptyString(entry.date)) return null;
  if (!isNonEmptyString(entry.minimumSystemVersion)) return null;
  if (!isValidNotesPath(entry.notes)) return null;
  const pkg = parseAsset(entry.pkg);
  const zip = parseAsset(entry.zip);
  if (pkg === null || zip === null) return null;
  return {
    version: entry.version,
    build: entry.build,
    date: entry.date,
    minimumSystemVersion: entry.minimumSystemVersion,
    notes: entry.notes,
    pkg,
    zip,
  };
}

function rawVersion(value: unknown): string | null {
  if (typeof value !== "object" || value === null) return null;
  const version = (value as Record<string, unknown>).version;
  return isNonEmptyString(version) ? version : null;
}

/**
 * Strict schema-1 validation, scoped so one bad release never blanks the page.
 * A malformed top level (not an object, wrong `schema`, `releases` not an array,
 * `latest` neither null nor a string, or `latest` naming no entry at all)
 * returns `null`. A malformed ENTRY is dropped on its own with a `console.warn`
 * and the rest are kept, sorted newest build first; if the dropped entry is the
 * one `latest` names, `latest` becomes `null`.
 */
export function parseReleases(json: unknown): ReleasesJson | null {
  if (typeof json !== "object" || json === null) return null;
  const doc = json as Record<string, unknown>;
  if (doc.schema !== 1) return null;
  if (!Array.isArray(doc.releases)) return null;
  if (doc.latest !== null && !isNonEmptyString(doc.latest)) return null;
  const rawLatest = doc.latest as string | null;
  if (rawLatest !== null && !doc.releases.some((raw) => rawVersion(raw) === rawLatest)) {
    return null;
  }

  const releases: ReleaseEntry[] = [];
  doc.releases.forEach((raw, index) => {
    const entry = parseEntry(raw);
    if (entry === null) {
      console.warn(`releases.json: skipping malformed release #${index} ${rawVersion(raw) ?? "(no version)"}`);
      return;
    }
    releases.push(entry);
  });
  releases.sort((a, b) => b.build - a.build);

  let latest = rawLatest;
  if (latest !== null && !releases.some((r) => r.version === latest)) {
    console.warn(`releases.json: latest ${latest} was malformed and skipped; no latest release`);
    latest = null;
  }
  return { schema: 1, latest, releases };
}

/**
 * Fetches and validates `${rawBase}/releases.json`. Any failure (network error,
 * non-OK response, invalid JSON, a doc that fails `parseReleases`) collapses to
 * the empty doc, so callers have exactly one "nothing to show" branch.
 */
export async function loadReleases(rawBase: string): Promise<ReleasesJson> {
  try {
    const res = await fetch(`${trimBase(rawBase)}/releases.json`, {
      next: { revalidate: REVALIDATE_SECONDS },
    } as RequestInit);
    if (!res.ok) return EMPTY;
    return parseReleases(await res.json()) ?? EMPTY;
  } catch {
    return EMPTY;
  }
}

/** The pkg or zip of the release `latest` names, or `null` when there is none. */
export function latestAsset(r: ReleasesJson, kind: "pkg" | "zip"): ReleaseAsset | null {
  if (r.latest === null) return null;
  return r.releases.find((release) => release.version === r.latest)?.[kind] ?? null;
}

const SAFE_VERSION_RE = /^[0-9A-Za-z._-]+$/;

/** The markdown release notes for `version`, or `null` if absent or unreachable. */
export async function releaseNotes(rawBase: string, version: string): Promise<string | null> {
  if (!SAFE_VERSION_RE.test(version) || version.includes("..")) return null;
  try {
    const res = await fetch(`${trimBase(rawBase)}/notes/${version}.md`, {
      next: { revalidate: REVALIDATE_SECONDS },
    } as RequestInit);
    return res.ok ? await res.text() : null;
  } catch {
    return null;
  }
}
