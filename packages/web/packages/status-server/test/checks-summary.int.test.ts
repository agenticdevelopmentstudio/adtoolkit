import { describe, it, expect } from 'vitest';
import { sql } from 'drizzle-orm';
import * as schema from '../src/libsql/schema';
import { checksSummarySql, createHealthStore } from '../src/libsql/stores/health-store';
import { freshDb } from './helpers/db';

// `checksSummary` backs one label on the integrations self-check, and it used to count the
// whole health_checks table: 30-38s per call in prod, with every Storage call queued behind
// it on the one database thread. These pin its numbers AND that neither of its queries
// scans the table — a plan that says `SCAN health_checks` is the outage coming back.

const nowSec = () => Math.floor(Date.now() / 1000);

describe('health.checksSummary', () => {
  it('counts the last 24h of checks and every service that has any', async () => {
    const db = await freshDb();
    const old = nowSec() - 3 * 86_400;
    const recent = nowSec() - 60;
    await db.insert(schema.healthChecks).values([
      { serviceSlug: 'a', status: 'healthy', checkedAt: new Date(old * 1000) },
      { serviceSlug: 'a', status: 'healthy', checkedAt: new Date(recent * 1000) },
      { serviceSlug: 'b', status: 'down', checkedAt: new Date(recent * 1000) },
      { serviceSlug: 'c', status: 'healthy', checkedAt: new Date(old * 1000) },
    ]);
    expect(await createHealthStore(db).checksSummary()).toEqual({ samplesLast24h: 2, services: 3 });
  });

  it('is zero on an empty table', async () => {
    expect(await createHealthStore(await freshDb()).checksSummary()).toEqual({ samplesLast24h: 0, services: 0 });
  });

  it('reads health_checks only through its indexes', async () => {
    const db = await freshDb();
    const q = checksSummarySql(nowSec() - 86_400);
    const plans = await Promise.all([q.samples, q.services].map((stmt) => db.all<{ detail: string }>(sql`explain query plan ${stmt}`)));
    const details = plans.flat().map((r) => r.detail);
    expect(details.filter((d) => /health_checks/.test(d)).length).toBeGreaterThan(0);
    for (const d of details.filter((d) => /health_checks/.test(d))) {
      // SEARCH, not SCAN: `SCAN health_checks USING COVERING INDEX …` still reads every row.
      expect(d, d).toMatch(/^SEARCH health_checks USING (COVERING )?INDEX/);
    }
  });
});
