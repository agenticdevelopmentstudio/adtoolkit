import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { enumerateDeployProjectsVerified } from "./index.js";
import { deployIntegrations } from "../schema/index.js";
import type { DeployDb } from "../conn/index.js";

// Crunchy Bridge as a first-class platform: each cluster is enumerated as a domainless
// project (so Auto Configure can wire a deploy-only monitor to it), and a LIVE cluster
// listing counts as both a verified project list and a verified (empty) domain list.

/** Crunchy configured, nothing else — so no other provider is called. */
function crunchyOnly(): DeployDb {
  const result = (data: unknown[]) => {
    const p = Promise.resolve(data) as Promise<unknown[]> & { where: () => Promise<unknown[]> };
    p.where = () => Promise.resolve(data);
    return p;
  };
  const integrations = [{ platform: "crunchy", config: {}, tokenEnvVar: "TEST_CRUNCHY_TOKEN", isActive: true }];
  return {
    select: () => ({ from: (table: unknown) => result(table === deployIntegrations ? integrations : []) }),
  } as unknown as DeployDb;
}

beforeEach(() => {
  vi.stubEnv("TEST_CRUNCHY_TOKEN", "cbkey_x");
});

afterEach(() => {
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("enumerateDeployProjectsVerified — crunchy", () => {
  it("enumerates each cluster as a domainless project and verifies the platform", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        new Response(JSON.stringify({ clusters: [
          { id: "qki2", name: "adh-staging", state: "ready" },
          { id: "fq2z", name: "adh-production", state: "ready" },
        ] }), { status: 200, headers: { "content-type": "application/json" } }),
      ),
    );

    const r = await enumerateDeployProjectsVerified(crunchyOnly());

    expect(r.projects.map((p) => [p.platform, p.projectName, p.domain, p.domains])).toEqual([
      ["crunchy", "adh-production", null, []],
      ["crunchy", "adh-staging", null, []],
    ]);
    expect(r.verifiedPlatforms).toContain("crunchy");
    expect(r.verifiedDomains).toContain("crunchy");
  });

  it("verifies nothing when the listing fails — no cluster can be read as deleted", async () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    vi.stubGlobal("fetch", vi.fn(async () => new Response("nope", { status: 503 })));

    const r = await enumerateDeployProjectsVerified(crunchyOnly());

    expect(r.projects).toEqual([]);
    expect(r.verifiedPlatforms).not.toContain("crunchy");
    expect(r.verifiedDomains).not.toContain("crunchy");
  });
});
