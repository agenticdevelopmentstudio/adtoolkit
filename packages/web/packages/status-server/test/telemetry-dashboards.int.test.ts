import { beforeEach, describe, expect, it } from 'vitest';
import { createApp } from '../src/app';
import { sessionHeaders } from './helpers/auth';
import { freshDb as bootDb } from './helpers/db';
import { testDeps } from './helpers/storage';

const PROVIDER_ENV = [
  'GLITCHTIP_URL',
  'GLITCHTIP_API_TOKEN',
  'GLITCHTIP_ORG',
  'POSTHOG_HOST',
  'POSTHOG_API_KEY',
  'POSTHOG_PROJECT_ID',
  'VERCEL_API_TOKEN',
  'VERCEL_TEAM_ID',
];

async function parse(res: Response): Promise<Record<string, any>> {
  return (await res.json()) as Record<string, any>;
}

describe('dashboard routes, with no provider configured', () => {
  let app: ReturnType<typeof createApp>;
  let viewAuth: { Cookie: string };

  beforeEach(async () => {
    // No provider env may leak in: these must answer without touching the network.
    for (const name of PROVIDER_ENV) delete process.env[name];
    const db = await bootDb();
    viewAuth = await sessionHeaders(db, 'viewer');
    app = createApp(testDeps(db));
  });

  it('gates both: GlitchTip titles and per-site traffic are operator-only', async () => {
    expect((await app.request('/analytics/dashboard')).status).toBe(401);
    expect((await app.request('/errors/dashboard')).status).toBe(401);
  });

  it('refuses a range outside the closed list', async () => {
    const range = await app.request('/analytics/dashboard?range=forever', { headers: viewAuth });
    expect(range.status).toBe(400);
    expect(await parse(range)).toEqual({ error: 'invalid range' });

  });

  it('defaults to seven days, and says nothing is configured', async () => {
    const res = await app.request('/analytics/dashboard', { headers: viewAuth });
    expect(res.status).toBe(200);
    expect(res.headers.get('cache-control')).toBe('no-store');
    const body = await parse(res);
    expect(body.range).toBe('7d');
    expect(body.refreshing).toBe(false);
    expect(body.configured).toEqual({ posthog: false, vercel: false });
    expect(Object.keys(body.sections).sort()).toEqual(['dimensions', 'health', 'paths', 'traffic', 'vercel', 'vitals']);
    for (const section of Object.values<Record<string, unknown>>(body.sections)) {
      expect(section).toEqual({ data: null, error: null, updatedAt: null });
    }
  });

  it('answers the errors topic with empty sections rather than a failure', async () => {
    const res = await app.request('/errors/dashboard', { headers: viewAuth });
    expect(res.status).toBe(200);
    expect(res.headers.get('cache-control')).toBe('no-store');
    const body = await parse(res);
    expect(body.refreshing).toBe(false);
    expect(body.refreshingSources).toEqual({ glitchtip: false, posthog: false });
    expect(body.configured).toEqual({ glitchtip: false, posthog: false, vercel: false });
    expect(Object.keys(body.sections).sort()).toEqual(['detail', 'issues', 'runtime', 'sites']);
    for (const section of Object.values<Record<string, unknown>>(body.sections)) {
      expect(section).toEqual({ data: null, error: null, updatedAt: null });
    }
  });

  it('answers the runtime errors with an empty 24h report, behind the view gate', async () => {
    expect((await app.request('/errors/runtime')).status).toBe(401);
    const res = await app.request('/errors/runtime', { headers: viewAuth });
    expect(res.status).toBe(200);
    expect(res.headers.get('cache-control')).toBe('no-store');
    const body = await parse(res);
    expect(Object.keys(body).sort()).toEqual(['generatedAt', 'groups', 'total', 'window']);
    expect(body.window).toBe('24h');
    expect(body.total).toBe(0);
    expect(body.groups).toEqual([]);
    expect(Number.isNaN(Date.parse(body.generatedAt))).toBe(false);
  });
});
