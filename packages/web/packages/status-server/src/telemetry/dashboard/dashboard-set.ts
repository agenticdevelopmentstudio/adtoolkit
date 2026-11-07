import { glitchtipConfigured, posthogConfigured, vercelConfigured, type StatusConfig } from '../../config/port';
import type { Storage } from '../../storage/ports';
import { loadRuntimeErrorsReport } from '../runtime-errors';
import { loadErrorIssues, resolvedCounter } from './errors-sections';
import {
  loadDimensions,
  loadPaths,
  loadSiteErrorDetail,
  loadSiteHealth,
  loadTraffic,
  loadVitals,
} from './posthog-sections';
import { ANALYTICS_RANGES as ANALYTICS_RANGE_KEYS, rangeWindow, type AnalyticsRange } from './ranges';
import { emptySections, sectionedDashboard, type DashboardSection } from './sectioned-dashboard';
import type {
  AnalyticsDashboardResponse,
  AnalyticsSectionData,
  ErrorsDashboardResponse,
  ErrorsSectionData,
  RuntimeErrorsReport,
} from './types';
import { loadVercelTraffic } from './vercel-section';
import { analyticsViews, errorsViews, type AnalyticsViews, type ErrorsViews } from './views';

// ---------------------------------------------------------------------------
// The Analytics and Errors dashboards: ONE set of stale-while-revalidate caches per app.
//
// Built once in `createApp` and handed to every reader — the dashboard routes, `GET /report`
// and the MCP tools — so a report and an open dashboard tab share one refresh instead of each
// paying a minute of provider time for the same answer. `analytics`/`errors` never wait (see
// sectioned-dashboard.ts); `settle*` is the wait, for a server-side reader that must hand its
// own client a finished answer rather than a "poll me" flag.
// ---------------------------------------------------------------------------

/** These describe days of traffic, and a refresh costs a minute of provider time. */
const ANALYTICS_TTL_MS = 10 * 60_000;
const ERRORS_TTL_MS = 60_000;

type PosthogSections = Omit<AnalyticsSectionData, 'vercel'>;
type VercelSections = Pick<AnalyticsSectionData, 'vercel'>;
type SitesSections = Pick<ErrorsSectionData, 'sites' | 'detail'>;
type GlitchtipSections = Omit<ErrorsSectionData, keyof SitesSections | 'runtime'>;

const POSTHOG_SECTIONS = ['traffic', 'dimensions', 'paths', 'vitals', 'health'] as const;
const VERCEL_SECTIONS = ['vercel'] as const;
const GLITCHTIP_SECTIONS = ['issues'] as const;
const SITES_SECTIONS = ['sites', 'detail'] as const;

export interface DashboardSet {
  /** `GET /analytics/dashboard`: what is known now, refreshing behind the answer. */
  analytics(range: AnalyticsRange): AnalyticsDashboardResponse;
  /** `GET /errors/dashboard`: same, plus the runtime-errors read of our own store. */
  errors(nowMs?: number): Promise<ErrorsDashboardResponse>;
  /** Wait up to `timeoutMs` for the analytics refresh of `range` to finish. True when settled. */
  settleAnalytics(range: AnalyticsRange, timeoutMs: number): Promise<boolean>;
  /** Wait up to `timeoutMs` for the errors refresh to finish. True when settled. */
  settleErrors(timeoutMs: number): Promise<boolean>;
}

/**
 * The runtime section is a read of OUR store (the monitor cycle polls Vercel), so unlike the
 * provider sections it is answered in this request, never left for a later poll.
 */
async function runtimeSection(storage: Storage, nowMs: number): Promise<DashboardSection<RuntimeErrorsReport>> {
  try {
    const data = await loadRuntimeErrorsReport(storage.telemetry.runtimeErrors, nowMs);
    // When the groups were read from Vercel, not when this request asked the store.
    return { data, error: null, updatedAt: data.readAt };
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : String(err), updatedAt: null };
  }
}

/**
 * Remembers the last value computed from these inputs. A section object is replaced only when a
 * refresh publishes it, so the clients polling a refresh reuse one derivation of the views until
 * something they depend on actually changes.
 */
function lastValue<V>(): (inputs: readonly unknown[], compute: () => V) => V {
  let last: { inputs: readonly unknown[]; value: V } | null = null;
  return (inputs, compute) => {
    if (last && last.inputs.length === inputs.length && last.inputs.every((input, i) => input === inputs[i])) {
      return last.value;
    }
    const value = compute();
    last = { inputs, value };
    return value;
  };
}

const allSettled = async (waits: Promise<boolean>[]): Promise<boolean> => (await Promise.all(waits)).every(Boolean);

export function createDashboardSet(config: StatusConfig, storage: Storage): DashboardSet {
  const creds = config.credentials;

  // Providers refresh independently: a slow PostHog must not hold back GlitchTip or Vercel.
  const posthog = sectionedDashboard<AnalyticsRange, PosthogSections>({
    ttlMs: ANALYTICS_TTL_MS,
    sections: POSTHOG_SECTIONS,
    loaders: (range) => {
      const w = rangeWindow(range, Date.now());
      return {
        traffic: () => loadTraffic(creds, w),
        dimensions: () => loadDimensions(creds, w),
        paths: () => loadPaths(creds, w),
        vitals: () => loadVitals(creds, w),
        health: () => loadSiteHealth(creds, w),
      };
    },
  });
  const vercel = sectionedDashboard<AnalyticsRange, VercelSections>({
    ttlMs: ANALYTICS_TTL_MS,
    sections: VERCEL_SECTIONS,
    // One project's timeout shouldn't leave its chart flat for the whole TTL.
    incomplete: (_name, data) => data.failed > 0 || data.incomplete > 0,
    loaders: (range) => ({ vercel: () => loadVercelTraffic(creds, rangeWindow(range, Date.now())) }),
  });
  const analyticsViewsOf = new Map(ANALYTICS_RANGE_KEYS.map((range) => [range, lastValue<AnalyticsViews>()]));
  const errorsViewsOf = lastValue<ErrorsViews>();
  const resolvedCount = resolvedCounter(creds);
  const glitchtip = sectionedDashboard<'all', GlitchtipSections>({
    ttlMs: ERRORS_TTL_MS,
    sections: GLITCHTIP_SECTIONS,
    loaders: () => ({
      issues: () => loadErrorIssues(creds, config.glitchtipProjects, resolvedCount),
    }),
  });
  const errorSites = sectionedDashboard<'all', SitesSections>({
    ttlMs: ANALYTICS_TTL_MS,
    sections: SITES_SECTIONS,
    loaders: () => {
      const w = rangeWindow('30d', Date.now());
      return {
        sites: () => loadSiteHealth(creds, w),
        detail: () => loadSiteErrorDetail(creds, w),
      };
    },
  });

  return {
    analytics(range) {
      const posthogOn = posthogConfigured(config);
      const vercelOn = vercelConfigured(config);
      const ph = posthogOn ? posthog.read(range) : null;
      const vc = vercelOn ? vercel.read(range) : null;
      const configured = { posthog: posthogOn, vercel: vercelOn };
      const sections = {
        ...(ph?.sections ?? emptySections<PosthogSections>(POSTHOG_SECTIONS)),
        ...(vc?.sections ?? emptySections<VercelSections>(VERCEL_SECTIONS)),
      };
      return {
        generatedAt: new Date().toISOString(),
        refreshing: Boolean(ph?.refreshing || vc?.refreshing),
        range,
        configured,
        sections,
        views: analyticsViewsOf.get(range)!(
          [...Object.values(sections), posthogOn, vercelOn],
          () => analyticsViews(sections, configured),
        ),
      };
    },

    async errors(nowMs = Date.now()) {
      const glitchtipOn = glitchtipConfigured(config);
      const posthogOn = posthogConfigured(config);
      const vercelOn = vercelConfigured(config);
      const gt = glitchtipOn ? glitchtip.read('all') : null;
      const sites = posthogOn ? errorSites.read('all') : null;
      const runtime: DashboardSection<RuntimeErrorsReport> = vercelOn
        ? await runtimeSection(storage, nowMs)
        : { data: null, error: null, updatedAt: null };
      const sections = {
        ...(gt?.sections ?? emptySections<GlitchtipSections>(GLITCHTIP_SECTIONS)),
        ...(sites?.sections ?? emptySections<SitesSections>(SITES_SECTIONS)),
        runtime,
      };
      return {
        generatedAt: new Date(nowMs).toISOString(),
        refreshing: Boolean(gt?.refreshing || sites?.refreshing),
        refreshingSources: { glitchtip: Boolean(gt?.refreshing), posthog: Boolean(sites?.refreshing) },
        configured: { glitchtip: glitchtipOn, posthog: posthogOn, vercel: vercelOn },
        sections,
        // Runtime is read fresh every request and no view uses it, so it is not an input.
        views: errorsViewsOf([sections.sites, sections.detail, posthogOn], () =>
          errorsViews(sections, { posthog: posthogOn }),
        ),
      };
    },

    settleAnalytics: (range, timeoutMs) => allSettled([posthog.settle(range, timeoutMs), vercel.settle(range, timeoutMs)]),
    settleErrors: (timeoutMs) => allSettled([glitchtip.settle('all', timeoutMs), errorSites.settle('all', timeoutMs)]),
  };
}
