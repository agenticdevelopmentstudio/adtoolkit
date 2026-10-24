import { crunchyPhases } from "./deploy-status";
import { toValidDate, type ProviderDeploy } from "./provider-deploy";
import { listCrunchyClusters } from "@agentic-toolkit/deploy-platform/providers";

/**
 * List every cluster in the team and map each to a deploy row whose phase IS its health
 * (see crunchyPhases). Poll-only, mirroring fetch-cloudflare: missing token → dormant; any
 * failure → ok:false so the platform-health path opens a "can't reach Crunchy" blind-spot
 * issue. The listing itself is `listCrunchyClusters`, the same call the project
 * enumeration makes, so every cluster with rows here is one Auto Configure can wire.
 *
 * `providerProjectId` is the cluster id, as Railway's is its project id: a cluster renamed
 * at Crunchy keeps its identity, and `learnProjectIds` adopts the id onto the endpoint
 * that monitors it.
 */
export async function fetchCrunchyClusters(env: {
  CRUNCHY_API_TOKEN?: string;
}): Promise<{ ok: boolean; deploys: ProviderDeploy[] }> {
  if (!env.CRUNCHY_API_TOKEN) return { ok: true, deploys: [] };
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 6_000);
  try {
    const clusters = await listCrunchyClusters(env.CRUNCHY_API_TOKEN, controller.signal);
    if (!clusters) return { ok: false, deploys: [] };
    const deploys: ProviderDeploy[] = clusters.map((c) => ({
      id: `cr_${c.id}`,
      platform: "crunchy",
      projectName: c.name,
      providerProjectId: c.id,
      ...crunchyPhases(c.state, Boolean(c.is_suspended)),
      environment: c.environment ?? "production",
      commitHash: null,
      commitMessage: null,
      branch: null,
      commitRepo: null,
      url: null,
      createdAt: toValidDate(c.created_at) ?? new Date(), // fall back to poll time, never Invalid Date
    }));
    return { ok: true, deploys };
  } finally {
    clearTimeout(timer);
  }
}
