import { latestAsset, loadReleases } from "./releases.ts";

/**
 * A route handler for a stable link to the newest installer — the URL a README badge or a
 * support reply hands out once, because the redirect target moves instead of the link.
 * Usage: `export const GET = latestHandler(RAW_BASE)`. Before the first release publishes
 * there is nothing to point at, and it is a 404.
 */
export function latestHandler(
  rawBase: string,
  kind: "pkg" | "zip" = "pkg",
): () => Promise<Response> {
  return async () => {
    const asset = latestAsset(await loadReleases(rawBase), kind);
    if (asset === null) {
      return new Response("No releases published yet", { status: 404 });
    }
    return Response.redirect(asset.url, 302);
  };
}
