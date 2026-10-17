/**
 * A route handler that proxies the Sparkle appcast from the public releases
 * repo, so the feed URL an app is built with is the site's own and storage can
 * move without stranding installed copies — and the content still needs no
 * site deploy to change. Usage: `export const GET = appcastHandler(RAW_BASE)`.
 *
 * The body is passed through as bytes, never decoded: the feed is EdDSA-signed
 * and one altered byte fails verification. A missing or unreachable upstream
 * file is a 502 (before the first release publishes, there is no appcast).
 */
export function appcastHandler(rawBase: string): () => Promise<Response> {
  const url = `${rawBase.replace(/\/+$/, "")}/appcast.xml`;
  const fail = (): Response =>
    new Response("Failed to fetch appcast.xml from the releases repo", { status: 502 });

  return async () => {
    try {
      const res = await fetch(url, { next: { revalidate: 300 } } as RequestInit);
      if (!res.ok) return fail();
      return new Response(await res.arrayBuffer(), {
        status: 200,
        headers: { "Content-Type": "application/xml; charset=utf-8" },
      });
    } catch {
      return fail();
    }
  };
}
