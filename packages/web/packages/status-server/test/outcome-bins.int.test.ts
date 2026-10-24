import { describe, it, expect } from 'vitest';
import { sql } from 'drizzle-orm';
import * as schema from '../src/libsql/schema';
import { createLibsqlStorage } from '../src/libsql';
import { outcomeBinSql } from '../src/monitor/deploy-status';
import { binByOutcome } from '../src/board/facts';
import type { DeployFact } from '../src/board/types';
import { freshDb } from './helpers/db';

// The SQL bins decide what the board READS; `binByOutcome` decides what a row MEANS. A
// row the authoritative split puts in a bin but the SQL leaves out is a verdict the board
// can never see — which is exactly what `NOT (build_phase IN …)` did to every row with a
// NULL build (every Crunchy cluster, every Cloudflare Worker deploy) until migration 0017.
// So: every phase pair, NULL build included, read through the real partial indexes.

const BUILD = [null, 'queued', 'building', 'built', 'failed', 'canceled', 'unknown'] as const;
const DEPLOY = ['none', 'deploying', 'deployed', 'failed', 'unknown'] as const;
const PAIRS = BUILD.flatMap((b) => DEPLOY.map((d) => ({ buildPhase: b, deployPhase: d })));
const idOf = (b: string | null, d: string) => `${b ?? 'null'}:${d}`;

async function seeded() {
  const db = await freshDb();
  let t = 1_700_000_000;
  // One target per pair, so latest-per-target returns every row the bin admits.
  await db.insert(schema.deployments).values(
    PAIRS.map(({ buildPhase, deployPhase }) => ({
      id: idOf(buildPhase, deployPhase),
      platform: 'crunchy',
      projectName: idOf(buildPhase, deployPhase),
      environment: 'production',
      buildPhase,
      deployPhase,
      createdAt: new Date((t += 1) * 1000),
    })),
  );
  return db;
}

async function sqlBin(db: Awaited<ReturnType<typeof freshDb>>, bin: 'concluded' | 'in-flight'): Promise<Set<string>> {
  const rows = await db.all<{ id: string }>(sql.raw(`select id from deployments where ${outcomeBinSql(bin)}`));
  return new Set(rows.map((r) => r.id));
}

// The bins are READ together (`readDeployOutcomeCandidates` concatenates them) and
// `binByOutcome` re-splits the result, so the invariant is membership in their UNION, not
// bin-for-bin agreement. They do disagree on purpose for a few pairs — `queued:deployed`,
// `building:deployed`, `failed:deploying` have a verdict in `combinedStatus` but a phase
// still in flight, so the SQL files them in-flight — and that costs nothing: either bin
// hands the newest row of its target to `collapseByTarget`.
describe('the SQL outcome bins read a superset of binByOutcome', () => {
  const facts = PAIRS.map((p) => ({ deploymentId: idOf(p.buildPhase, p.deployPhase), ...p }) as unknown as DeployFact);
  const authoritative = binByOutcome(facts);

  it('every row the split bins is in one of the SQL bins', async () => {
    const db = await seeded();
    const read = new Set([...(await sqlBin(db, 'concluded')), ...(await sqlBin(db, 'in-flight'))]);
    for (const f of [...authoritative.concluded, ...authoritative.inFlight]) {
      expect(read.has(f.deploymentId), f.deploymentId).toBe(true);
    }
  });

  it('the two bins never overlap, so a row is read once', async () => {
    const db = await seeded();
    const concluded = await sqlBin(db, 'concluded');
    for (const id of await sqlBin(db, 'in-flight')) expect(concluded.has(id), id).toBe(false);
  });

  it('a NULL-build verdict reaches the board read (Crunchy, Cloudflare Workers)', async () => {
    const db = await seeded();
    const read = (await createLibsqlStorage(db).board.readDeployOutcomeCandidates()).map((f) => f.deploymentId);
    expect(read).toContain('null:failed');
    expect(read).toContain('null:deployed');
    // A failure outranks an expired or canceled other half, as it does in `combinedStatus`.
    expect(read).toEqual(expect.arrayContaining(['failed:unknown', 'unknown:failed', 'canceled:failed']));
    const { concluded } = binByOutcome(await createLibsqlStorage(db).board.readDeployOutcomeCandidates());
    expect(concluded.map((f) => f.deploymentId)).toEqual(expect.arrayContaining(['null:failed', 'null:deployed']));
  });
});
