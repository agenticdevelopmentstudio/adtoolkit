import { BEARER, okJson, ref, errors, type Paths, type Schemas } from '../shared';

// ---------------------------------------------------------------------------
// The Analytics and Errors topics (src/routes/telemetry-dashboards.ts). Shapes are defined in
// src/telemetry/dashboard/types.ts. Each answers immediately with what is known: `refreshing`
// says more is coming, and every section is { data, error, updatedAt } on its own, because the
// providers behind them succeed and fail independently.
// ---------------------------------------------------------------------------

const tag = 'dashboards';
const num = { type: 'number' };
const str = { type: 'string' };
const bool = { type: 'boolean' };
const nullableNum = { type: ['number', 'null'] };
const nullableStr = { type: ['string', 'null'] };
const strs = { type: 'array', items: str };
const nums = { type: 'array', items: num };

function object(properties: Record<string, unknown>): Record<string, unknown> {
  return { type: 'object', required: Object.keys(properties), properties };
}

function list(schema: unknown): Record<string, unknown> {
  return { type: 'array', items: schema };
}

/** One section: its last good answer, why the latest attempt failed, and when it was fetched. */
function section(data: Record<string, unknown>): Record<string, unknown> {
  return object({ data: { anyOf: [data, { type: 'null' }] }, error: nullableStr, updatedAt: nullableStr });
}

function nullable(schema: Record<string, unknown>): Record<string, unknown> {
  return { anyOf: [schema, { type: 'null' }] };
}

function described(schema: Record<string, unknown>, description: string): Record<string, unknown> {
  return { ...schema, description };
}

/** A map from site name to `schema`. */
function bySite(schema: unknown): Record<string, unknown> {
  return { type: 'object', additionalProperties: schema };
}

const nullableNums = { type: 'array', items: nullableNum };
const vitalRating = { type: ['string', 'null'], enum: ['good', 'fair', 'poor', null] };

export const dashboardSchemas: Schemas = {
  SiteHealthRow: object({ host: str, errors: num, requests: num, failures: num, p95Ms: nullableNum }),
  DashboardMarginal: object({ name: str, pageviews: num }),
  RuntimeErrorGroup: object({
    key: str,
    project: str,
    deploymentId: str,
    domain: nullableStr,
    source: str,
    method: nullableStr,
    path: nullableStr,
    status: nullableNum,
    level: str,
    message: str,
    count: num,
    firstSeen: str,
    lastSeen: str,
    sampleRequestId: nullableStr,
  }),
  VitalsRow: object({ host: str, samples: num, lcp: nullableNum, inp: nullableNum, cls: nullableNum, fcp: nullableNum }),
  ErrorIssue: object({
    id: str,
    shortId: nullableStr,
    title: str,
    type: nullableStr,
    source: nullableStr,
    level: nullableStr,
    count: num,
    userCount: num,
    firstSeen: nullableStr,
    lastSeen: nullableStr,
    release: nullableStr,
    project: str,
    permalink: nullableStr,
    active: bool,
  }),
  SiteErrorRow: object({
    host: str,
    name: str,
    feature: nullableStr,
    step: nullableStr,
    boundary: nullableStr,
    page: nullableStr,
    count: num,
    lastSeen: nullableStr,
  }),
  SiteFailedRequestRow: object({ host: str, status: num, method: nullableStr, path: str, count: num, lastSeen: nullableStr }),
  RuntimeErrorsReport: object({
    generatedAt: str,
    window: { type: 'string', enum: ['24h'] },
    readAt: nullableStr,
    complete: bool,
    total: num,
    groups: list(ref('RuntimeErrorGroup')),
  }),

  // ── views: what the pages draw, derived on the server (src/telemetry/dashboard/views.ts) ──
  RatedHealth: described(
    object({ host: str, errors: num, requests: num, failures: num, p95Ms: nullableNum, failureRateHigh: bool }),
    'A site\'s health, its hosts joined (counts add, p95 is the worse). `failureRateHigh`: failures/requests is at or above 5%.',
  ),
  ChartSeries: described(
    object({ labels: strs, posthog: nullable(nullableNums), vercel: nullable(nullableNums) }),
    'Pageviews per bucket from each provider on the union of their axes. A null provider has not seen it; a null value is a bucket it has not reached.',
  ),
  JoinedSite: described(
    object({
      key: str,
      posthog: nullable(object({ pageviews: num, sessions: num, series: nums })),
      vercel: nullable(object({ project: str, pageviews: num, visitors: num, series: nums })),
      health: nullable(ref('RatedHealth')),
    }),
    'One site across both providers, never summed. Null means that provider has not seen the site.',
  ),
  RatedVitalsRow: described(
    object({
      host: str,
      samples: num,
      lcp: nullableNum,
      inp: nullableNum,
      cls: nullableNum,
      fcp: nullableNum,
      site: str,
      ratings: object({ lcp: vitalRating, inp: vitalRating, cls: vitalRating, fcp: vitalRating }),
    }),
    'One host\'s web vitals, rated against Google\'s Core Web Vitals boundaries (null: not measured).',
  ),
  SectionFailure: described(
    object({ source: { type: 'string', enum: ['PostHog', 'Vercel'] }, what: strs, error: str }),
    'Sections of one source that could not be read at all, failing with the same error.',
  ),
  SiteReport: described(
    object({
      posthog: nullable(object({ pageviews: num, sessions: num })),
      vercel: nullable(object({ pageviews: num, visitors: num })),
      health: nullable(ref('RatedHealth')),
      pageviews: nullable(ref('ChartSeries')),
      breakdowns: list(
        object({
          topic: { type: 'string', enum: ['pages', 'countries', 'referrers', 'devices', 'browsers'] },
          posthog: nullable(marginalList()),
          vercel: nullable(marginalList()),
        }),
      ),
      projects: list(
        object({ project: str, domain: nullableStr, analyticsOn: bool, pageviews: nullableNum, visitors: nullableNum }),
      ),
      vercelIncomplete: bool,
      vitals: list(ref('RatedVitalsRow')),
      empty: bool,
    }),
    'What one site has, and only that: an absent figure is null or empty. `empty` says nothing has anything to draw.',
  ),
  AnalyticsViews: described(
    object({
      sites: strs,
      joined: list(ref('JoinedSite')),
      pageviews: ref('ChartSeries'),
      pages: nullable(marginalList()),
      dimensions: nullable(
        object({ country: marginalList(), device: marginalList(), browser: marginalList(), referrer: marginalList() }),
      ),
      vercelProjects: nullable(list(object({ site: str, project: str, pageviews: num, visitors: num }))),
      vercelBreakdowns: nullable(
        object({ countries: marginalList(), referrers: marginalList(), paths: marginalList(), devices: marginalList() }),
      ),
      vitals: nullable(list(ref('RatedVitalsRow'))),
      siteReports: bySite(ref('SiteReport')),
      failures: list(ref('SectionFailure')),
    }),
    'Everything the Analytics pages draw, derived from `sections`: the joined site list and table, the all-sites ' +
      'chart and breakdowns, rated vitals, each site\'s report, and which configured sections could not be read.',
  ),
  ErrorsSiteReport: described(
    object({
      health: nullable(ref('RatedHealth')),
      chart: nullable(object({ buckets: strs, errors: nums, failures: nums })),
      errors: list(
        object({
          host: str,
          name: str,
          feature: nullableStr,
          step: nullableStr,
          boundary: nullableStr,
          page: nullableStr,
          count: num,
          lastSeen: nullableStr,
          id: str,
        }),
      ),
      requests: list(
        object({ host: str, status: num, method: nullableStr, path: str, count: num, lastSeen: nullableStr, id: str }),
      ),
      empty: bool,
    }),
    'One site\'s errors page, its hosts joined; rows commonest first, each with the identity it was merged on.',
  ),
  ErrorsViews: described(
    object({
      sites: strs,
      mostErrors: list(ref('RatedHealth')),
      mostErrorsLimit: num,
      siteReports: bySite(ref('ErrorsSiteReport')),
      siteFailures: list(ref('SectionFailure')),
    }),
    'What the Errors pages draw from PostHog\'s per-site sections: the site list, the sites with the most errors, ' +
      'each site\'s report, and which sections could not be read.',
  ),
};

function marginalList(): Record<string, unknown> {
  return list(ref('DashboardMarginal'));
}

const siteHealth = ref('SiteHealthRow');
const marginals = list(ref('DashboardMarginal'));

const analyticsSections = object({
  traffic: section(
    object({
      buckets: strs,
      totals: object({ pageviews: num, sessions: num }),
      pageviews: nums,
      sessions: nums,
      sites: list(object({ host: str, pageviews: num, sessions: num, series: nums })),
    }),
  ),
  dimensions: section(
    object({
      rows: list(object({ host: str, device: str, browser: str, country: str, referrer: str, pageviews: num })),
      truncated: bool,
    }),
  ),
  paths: section(list(object({ host: str, path: str, pageviews: num }))),
  vitals: section(
    list(ref('VitalsRow')),
  ),
  health: section(list(siteHealth)),
  vercel: section(
    object({
      buckets: strs,
      projectsTotal: num,
      projectsEnabled: num,
      failed: num,
      incomplete: num,
      roster: list(
        object({ project: str, domain: nullableStr, analyticsOn: bool, pageviews: nullableNum, visitors: nullableNum }),
      ),
      totals: object({ pageviews: num, visitors: num }),
      pageviews: nums,
      visitors: nums,
      projects: list(
        object({
          project: str,
          domain: nullableStr,
          pageviews: num,
          visitors: num,
          series: nums,
          countries: marginals,
          referrers: marginals,
          paths: marginals,
          devices: marginals,
          incomplete: bool,
        }),
      ),
    }),
  ),
});

const errorsSections = object({
  issues: section(
    object({
      buckets: strs,
      issues: list(ref('ErrorIssue')),
      summary: object({
        active: num,
        backlog: num,
        events: num,
        resolved: nullableNum,
        complete: bool,
        byType: list(object({ name: str, issues: num, events: num })),
        newPerDay: nums,
      }),
    }),
  ),
  sites: section(list(siteHealth)),
  detail: section(
    object({
      buckets: strs,
      days: list(object({ host: str, errors: nums, failures: nums })),
      errors: list(ref('SiteErrorRow')),
      requests: list(ref('SiteFailedRequestRow')),
      truncated: bool,
    }),
  ),
  runtime: section(ref('RuntimeErrorsReport')),
});

export const dashboardPaths: Paths = {
  '/analytics/dashboard': {
    get: {
      tags: [tag],
      summary: 'Per-site and aggregate traffic from PostHog and Vercel Web Analytics',
      security: BEARER,
      parameters: [
        { name: 'range', in: 'query', schema: { type: 'string', enum: ['24h', '7d', '30d'], default: '7d' } },
      ],
      responses: {
        200: okJson(
          'What is known now; poll while `refreshing`',
          object({
            generatedAt: str,
            refreshing: bool,
            range: str,
            configured: object({ posthog: bool, vercel: bool }),
            sections: analyticsSections,
            views: ref('AnalyticsViews'),
          }),
        ),
        ...errors(400, 401),
      },
    },
  },
  '/errors/dashboard': {
    get: {
      tags: [tag],
      summary:
        'Every unresolved GlitchTip issue, 30-day event history, each site’s errors and failed requests, and the last 24h of Vercel runtime errors',
      security: BEARER,
      responses: {
        200: okJson(
          'What is known now; poll while `refreshing`',
          object({
            generatedAt: str,
            refreshing: bool,
            refreshingSources: object({ glitchtip: bool, posthog: bool }),
            configured: object({ glitchtip: bool, posthog: bool, vercel: bool }),
            sections: errorsSections,
            views: ref('ErrorsViews'),
          }),
        ),
        ...errors(401),
      },
    },
  },
  '/errors/runtime': {
    get: {
      tags: [tag],
      summary: 'Vercel runtime errors of the last 24h, grouped',
      description:
        'Error/fatal log lines and 5xx responses of each production project’s current production deployment, ' +
        'as the monitor cycle last read them. Grouped by project, source, method, normalized path, status and ' +
        'first message line; `count` is lines since `firstSeen` (7-day retention). Worst level first, then most ' +
        'frequent. `total` counts every group in the window; `groups` is capped at 200.',
      security: BEARER,
      responses: {
        200: okJson('The groups of the latest whole read of the 24 hours before it', ref('RuntimeErrorsReport')),
        ...errors(401),
      },
    },
  },
};
