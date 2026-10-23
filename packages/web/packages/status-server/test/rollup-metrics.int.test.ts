import { describe, it, expect, beforeEach } from 'vitest';
import { sql } from 'drizzle-orm';
import { healthChecks, metricsHourly } from '../src/libsql/schema';
import { rollupMetricsSql } from '../src/libsql/stores/maintenance-store';
import { freshDb, type Db } from './helpers/db';

describe('rollupMetrics', () => {
  let db: Db;
  beforeEach(async () => {
    db = await freshDb();
  });

  it('aggregates the current and previous hour, ignoring older history', async () => {
    const now = new Date();
    const hourStartSec = Math.floor(Date.now() / 3_600_000) * 3600;
    // One second before this hour began: the tail a cycle straddling the hour leaves
    // behind, which this rollup must still fold into the previous hour's bucket.
    const lastHourTail = new Date((hourStartSec - 1) * 1000);
    const threeHoursAgo = new Date(Date.now() - 3 * 3_600_000);
    await db.insert(healthChecks).values([
      { serviceSlug: 'svc-a', status: 'healthy', responseTimeMs: 100, statusCode: 200, checkedAt: now },
      { serviceSlug: 'svc-a', status: 'healthy', responseTimeMs: 300, statusCode: 200, checkedAt: now },
      { serviceSlug: 'svc-a', status: 'down', responseTimeMs: 500, statusCode: 500, checkedAt: now },
      { serviceSlug: 'svc-a', status: 'down', responseTimeMs: 700, statusCode: 500, checkedAt: lastHourTail },
      // Older history must NOT be folded into either bucket.
      { serviceSlug: 'svc-a', status: 'down', responseTimeMs: 900, statusCode: 500, checkedAt: threeHoursAgo },
      { serviceSlug: 'svc-a', status: 'down', responseTimeMs: 900, statusCode: 500, checkedAt: threeHoursAgo },
    ]);

    await db.run(rollupMetricsSql(['svc-a']));

    const rows = await db.select().from(metricsHourly).orderBy(metricsHourly.hour);
    expect(rows).toHaveLength(2);
    expect(rows[0]).toMatchObject({ serviceSlug: 'svc-a', totalChecks: 1, downChecks: 1, minResponseTimeMs: 700 });
    expect(rows[1]).toMatchObject({
      serviceSlug: 'svc-a',
      totalChecks: 3,
      healthyChecks: 2,
      downChecks: 1,
      minResponseTimeMs: 100,
      maxResponseTimeMs: 500,
    });
  });

  it('is idempotent — re-running recomputes the bucket rather than doubling it', async () => {
    await db.insert(healthChecks).values([
      { serviceSlug: 'svc-a', status: 'healthy', responseTimeMs: 100, statusCode: 200, checkedAt: new Date() },
    ]);
    await db.run(rollupMetricsSql(['svc-a']));
    await db.run(rollupMetricsSql(['svc-a']));

    const rows = await db.select().from(metricsHourly);
    expect(rows).toHaveLength(1);
    expect(rows[0]?.totalChecks).toBe(1);
  });

  it('SEEKS the hour via the index instead of scanning every historical row', async () => {
    // The regression guard for the outage. Wrapping `checked_at` in arithmetic
    // (`(checked_at / 3600) * 3600 = ...`) is not sargable: SQLite then walks EVERY row of
    // every probed slug on EVERY tick, so the cost grows with total history and eventually
    // exceeds the container's CPU quota — the event-loop starvation that had the supervisor
    // restarting the container. The plan must show a RANGE on the bare column.
    const plan = await db.run(sql`explain query plan ${rollupMetricsSql(['svc-a'])}`);
    const detail = (plan.rows as unknown as Array<{ detail: string }>).map((r) => r.detail).join(' | ');

    expect(detail).toMatch(/idx_health_service_checked/);
    expect(detail).toMatch(/checked_at>/); // an indexed range seek, not a full per-slug walk
  });
});
