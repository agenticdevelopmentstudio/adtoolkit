import { describe, it, expect } from 'vitest';
import { sql } from 'drizzle-orm';
import type { InStatement } from '@libsql/client';
import * as schema from '../src/libsql/schema';
import { createLibsqlStorage } from '../src/libsql';
import { outcomeBinSql } from '../src/monitor/deploy-status';
import type { OwnedProjects } from '../src/storage/ports';
import { freshDb, type Db } from './helpers/db';

// Every read here runs on the ONE database thread, so a statement that scans a table that
// grows with history (deployments, errors, issues, the reapers' tables) stalls every
// Storage call queued behind it — `checksSummary` doing exactly that took 30-38s a call in
// prod. These pin each formerly-scanning read to its index: a `SCAN <table>` creeping back
// into one of these plans fails here, on libSQL's own planner, before it ships.
// `tools/audit_query_plans.py` runs the same check over every statement the suites send.

/** Every statement `run` sends, with libSQL's plan for it. */
async function plansOf(db: Db, run: () => Promise<unknown>): Promise<{ sql: string; plan: string[] }[]> {
  const client = db.$client;
  const real = client.execute.bind(client);
  const sent: { sql: string; args: unknown }[] = [];
  client.execute = ((stmt: InStatement | string, args?: unknown) => {
    sent.push(typeof stmt === 'string' ? { sql: stmt, args: args ?? [] } : { sql: stmt.sql, args: stmt.args ?? [] });
    return (real as (s: unknown, a?: unknown) => ReturnType<typeof real>)(stmt, args);
  }) as typeof client.execute;
  try {
    await run();
  } finally {
    client.execute = real;
  }
  return Promise.all(
    sent.map(async (s) => {
      const r = await real({ sql: `explain query plan ${s.sql}`, args: s.args as never });
      return { sql: s.sql, plan: r.rows.map((row) => String(row.detail)) };
    }),
  );
}

/** The one whole-index walk allowed below: the skip scan's opening `limit 1` probe of a
 *  bin's PARTIAL index, which reads one entry in index order (no sort step). */
const OPENING_PROBE = /^SCAN deployments USING (COVERING )?INDEX idx_deploy_(concluded|inflight)_latest$/;

function expectIndexed(statements: { sql: string; plan: string[] }[]): void {
  expect(statements.length).toBeGreaterThan(0);
  for (const { sql: text, plan } of statements) {
    // A `json_each` over bound args is a VIRTUAL TABLE: it walks the caller's list, not a table.
    for (const line of plan.filter((l) => /^SCAN /.test(l) && !/VIRTUAL TABLE/.test(l))) {
      const probe = OPENING_PROBE.test(line) && /limit \?$/i.test(text) && !plan.some((l) => /TEMP B-TREE/.test(l));
      expect(probe, `${line}\n  in: ${text}`).toBe(true);
    }
  }
}

const OWNED: OwnedProjects = new Map([
  ['vercel', { ids: new Set(['prj_web']), names: new Set(['web', 'docs']) }],
  ['railway', { ids: new Set(['rw_api']), names: new Set(['api']) }],
  ['cloudflare', { ids: new Set<string>(), names: new Set(['edge']) }],
  ['crunchy', { ids: new Set(['cl_db']), names: new Set<string>() }],
]);

async function seedDeploys(db: Db): Promise<void> {
  let t = 1_700_000_000_000;
  const row = (id: string, platform: string, projectName: string, environment: string | null, extra = {}) => ({
    id, platform, projectName, environment, buildPhase: 'built', deployPhase: 'deployed', createdAt: new Date((t += 1000)),
    ...extra,
  });
  await db.insert(schema.deployments).values([
    row('a1', 'vercel', 'web', 'production', { providerProjectId: 'prj_web', liveHost: 'web.example.com' }),
    row('a2', 'vercel', 'web', 'production', { buildPhase: 'building', deployPhase: 'none' }),
    row('a3', 'railway', 'api', 'staging', { providerProjectId: 'rw_api' }),
    row('a4', 'railway', 'api', null),
    row('a5', 'cloudflare-pages', 'edge', 'production'),
    row('a6', 'crunchy', 'db', null, { providerProjectId: 'cl_db', buildPhase: null, deployPhase: 'failed' }),
    row('a7', 'vercel', 'unowned', 'production'),
  ]);
}

describe('formerly-scanning reads now go through an index', () => {
  it('board.readDeployOutcomeCandidates seeks one row per target', async () => {
    const db = await freshDb();
    await seedDeploys(db);
    const storage = createLibsqlStorage(db);
    expectIndexed(await plansOf(db, () => storage.board.readDeployOutcomeCandidates()));
  });

  it('the owned-deploy feeds seek each owned project instead of walking created_at', async () => {
    const db = await freshDb();
    await seedDeploys(db);
    const storage = createLibsqlStorage(db);
    expectIndexed(await plansOf(db, () => storage.deploy.listRecentOwned(OWNED, 50)));
    expectIndexed(await plansOf(db, () => storage.board.readDeployEvents(0, OWNED)));
    expectIndexed(
      await plansOf(db, () => storage.board.readDeployActivityPage({ beforeMs: null, strict: false, limit: 2 }, OWNED)),
    );
    expectIndexed(
      await plansOf(db, () =>
        storage.board.readDeployActivityPage({ beforeMs: Date.now(), strict: true, limit: 2 }, OWNED),
      ),
    );
  });

  it('an EMPTY owned set reads no deploy rows — never the whole table', async () => {
    // `ownedDeploysWhere` returns FALSE for it; an undefined WHERE would hand back every row.
    const db = await freshDb();
    await seedDeploys(db);
    const storage = createLibsqlStorage(db);
    const none: OwnedProjects = new Map();
    expect(await storage.deploy.listRecentOwned(none, 50)).toEqual([]);
    expect(await storage.board.readDeployEvents(0, none)).toEqual([]);
  });

  it('deploy.listForLiveHostStamp reads owned rows and hosted rows, not the table', async () => {
    const db = await freshDb();
    await seedDeploys(db);
    const storage = createLibsqlStorage(db);
    const plans = await plansOf(db, () => storage.deploy.listForLiveHostStamp(OWNED));
    expectIndexed(plans);
    const rows = await storage.deploy.listForLiveHostStamp(OWNED);
    // Every owned row (the crunchy cluster by its id) and nothing unowned without a host.
    expect(rows.map((r) => r.id).sort()).toEqual(['a1', 'a2', 'a3', 'a4', 'a5', 'a6']);
    await storage.deploy.setLiveHost('a7', 'stale.example.com');
    expect((await storage.deploy.listForLiveHostStamp(OWNED)).map((r) => r.id)).toContain('a7');
  });

  it('the open-errors reads and the resolve sweep seek resolved = false', async () => {
    const db = await freshDb();
    const storage = createLibsqlStorage(db);
    const err = (issueKey: string) => ({
      id: issueKey, issueKey, project: 'p', title: 't', culprit: null, level: 'error', count: 1, userCount: 1,
      firstSeen: new Date().toISOString(), lastSeen: new Date().toISOString(), permalink: null,
    });
    await storage.telemetry.errors.save([err('1'), err('2')]);
    expectIndexed(await plansOf(db, () => storage.board.readErrorFacts()));
    expectIndexed(await plansOf(db, () => storage.telemetry.errors.load()));
    const sweep = await plansOf(db, () => storage.telemetry.errors.save([err('1')]));
    expectIndexed(sweep.filter((s) => /^update/i.test(s.sql)));
    expectIndexed(await plansOf(db, () => storage.telemetry.errors.save([])));
  });

  it('the issue activity pages seek each monitored target', async () => {
    const db = await freshDb();
    const storage = createLibsqlStorage(db);
    const targets = ['vercel|web|', 'railway|api|staging'];
    for (const cursor of [
      { beforeMs: null, strict: false, limit: 5 },
      { beforeMs: Date.now(), strict: true, limit: 5 },
    ]) {
      expectIndexed(await plansOf(db, () => storage.board.readIssueOpenedPage(cursor, targets)));
      expectIndexed(await plansOf(db, () => storage.board.readIssueResolvedPage(cursor, targets)));
    }
  });

  it('the expiry reapers seek expires_at', async () => {
    const db = await freshDb();
    const storage = createLibsqlStorage(db);
    expectIndexed(await plansOf(db, () => storage.device.purgeExpired()));
    const maintenance = await plansOf(db, () => storage.maintenance.runMaintenance());
    expectIndexed(maintenance.filter((s) => /from sessions/i.test(s.sql)));
  });

  it('the remaining history-table reads seek their indexes', async () => {
    const db = await freshDb();
    await seedDeploys(db);
    const storage = createLibsqlStorage(db);
    const window = { platforms: ['vercel', 'railway'], createdAfterMs: 0, limit: 10 };
    expectIndexed(
      await plansOf(db, () =>
        storage.deploy.listInFlightCandidates({ ...window, excludeIds: ['a1'], fetchedBeforeMs: Date.now() }),
      ),
    );
    expectIndexed(await plansOf(db, () => storage.deploy.listFailedWithoutError(window)));
    expectIndexed(await plansOf(db, () => storage.deploy.setErrorText('a1', 'boom')));
    expectIndexed(await plansOf(db, () => storage.health.latestChecks(['a', 'b'])));
    expectIndexed(await plansOf(db, () => storage.health.badRunOnsets(['a', 'b'])));
    expectIndexed(await plansOf(db, () => storage.history.checksFor('a', 24)));
    expectIndexed(await plansOf(db, () => storage.issues.listOpen()));
  });
});

// The skip scan replaced a `GROUP BY platform, project_name, environment` with
// `max(created_at)`. Same rows, same order, over random histories that exercise every
// phase pair, NULL and empty environments, and every platform the fetchers write.
describe('readDeployOutcomeCandidates matches the GROUP BY it replaced', () => {
  const BUILD = [null, 'queued', 'building', 'built', 'failed', 'canceled', 'unknown'];
  const DEPLOY = ['none', 'deploying', 'deployed', 'failed', 'unknown'];
  const PLATFORMS = ['vercel', 'railway', 'cloudflare-pages', 'crunchy'];
  const NAMES = ['a', 'b', 'c'];
  const ENVS = [null, '', 'production', 'staging'];

  /** A small deterministic PRNG so a failure reproduces from its seed. */
  function rng(seed: number): () => number {
    let s = seed >>> 0;
    return () => ((s = (s * 1_664_525 + 1_013_904_223) >>> 0) / 2 ** 32);
  }
  const pick = <T,>(r: () => number, xs: T[]): T => xs[Math.floor(r() * xs.length)]!;

  async function groupByIds(db: Db, bin: 'concluded' | 'in-flight'): Promise<string[]> {
    const rows = await db.all<{ id: string }>(
      sql.raw(
        `select id, max(created_at) from deployments where ${outcomeBinSql(bin)} group by platform, project_name, environment`,
      ),
    );
    return rows.map((r) => r.id);
  }

  for (const seed of [1, 2, 3, 4, 5, 6, 7, 8]) {
    it(`seed ${seed}`, async () => {
      const db = await freshDb();
      const r = rng(seed);
      const n = 20 + Math.floor(r() * 180);
      // Distinct created_at per row: the GROUP BY's pick among rows TIED on max(created_at)
      // is unspecified, so ties would test SQLite rather than the rewrite.
      // created_at is stored in whole SECONDS, so distinctness has to be in seconds: a
      // shuffled 0..n-1 keeps the time order independent of the id order.
      const secs = Array.from({ length: n }, (_, i) => i);
      for (let i = n - 1; i > 0; i--) {
        const j = Math.floor(r() * (i + 1));
        [secs[i], secs[j]] = [secs[j]!, secs[i]!];
      }
      const rows = Array.from({ length: n }, (_, i) => ({
        id: `d${seed}_${i}`,
        platform: pick(r, PLATFORMS),
        projectName: pick(r, NAMES),
        environment: pick(r, ENVS),
        buildPhase: pick(r, BUILD),
        deployPhase: pick(r, DEPLOY),
        createdAt: new Date((1_700_000_000 + secs[i]!) * 1000),
      }));
      for (let i = 0; i < rows.length; i += 50) await db.insert(schema.deployments).values(rows.slice(i, i + 50));
      const want = [...(await groupByIds(db, 'concluded')), ...(await groupByIds(db, 'in-flight'))];
      const got = (await createLibsqlStorage(db).board.readDeployOutcomeCandidates()).map((f) => f.deploymentId);
      expect(got).toEqual(want);
      expect(want.length).toBeGreaterThan(0);
    });
  }
});
