// A HAND MIRROR of status-server's telemetry/dashboard/types.ts: the wire shapes of
// GET /analytics/dashboard and GET /errors/dashboard. This package only has status-server as a
// devDependency, so it cannot import them at runtime; dashboard-types-parity.test.ts stops the
// two copies drifting.

export const ANALYTICS_RANGES = ["24h", "7d", "30d"] as const;
export type AnalyticsRange = (typeof ANALYTICS_RANGES)[number];

export interface DashboardSection<T> {
  /** The last good answer. Survives a later failure, so stale data stays on screen. */
  data: T | null;
  /** Why the latest attempt failed; null if it succeeded or none has finished. */
  error: string | null;
  /** When `data` was fetched. */
  updatedAt: string | null;
}

export type DashboardSections<S> = { [N in keyof S]: DashboardSection<S[N]> };


// ── PostHog ────────────────────────────────────────────────────────────────

export interface TrafficSection {
  buckets: string[];
  /** `sessions` sums per-bucket uniques, so a session spanning two buckets counts twice. */
  totals: { pageviews: number; sessions: number };
  /** One value per bucket. */
  pageviews: number[];
  sessions: number[];
  sites: { host: string; pageviews: number; sessions: number; series: number[] }[];
}

export interface DimensionRow {
  host: string;
  device: string;
  browser: string;
  country: string;
  referrer: string;
  pageviews: number;
}

export interface DimensionsSection {
  rows: DimensionRow[];
  /** The row cap was hit, so the tail is missing from every breakdown. */
  truncated: boolean;
}

export interface PathRow {
  host: string;
  path: string;
  pageviews: number;
}

export interface VitalsRow {
  host: string;
  samples: number;
  lcp: number | null;
  inp: number | null;
  cls: number | null;
  fcp: number | null;
}

export interface SiteHealthRow {
  host: string;
  errors: number;
  requests: number;
  failures: number;
  p95Ms: number | null;
}

// ── Vercel Web Analytics ───────────────────────────────────────────────────

export interface Marginal {
  name: string;
  pageviews: number;
}

export interface VercelProjectTraffic {
  project: string;
  domain: string | null;
  pageviews: number;
  visitors: number;
  series: number[];
  countries: Marginal[];
  referrers: Marginal[];
  paths: Marginal[];
  devices: Marginal[];
  /** A breakdown call failed, so `series` and the lists are short; `pageviews` is still whole. */
  incomplete: boolean;
}

/** One production project, whether or not it has analytics on or had any traffic. */
export interface VercelRosterEntry {
  project: string;
  domain: string | null;
  analyticsOn: boolean;
  /** Null when analytics is off or the count could not be read, which is not a zero. */
  pageviews: number | null;
  visitors: number | null;
}

export interface VercelTrafficSection {
  buckets: string[];
  /** Production projects only: staging and testing are never counted. */
  projectsTotal: number;
  projectsEnabled: number;
  /** Projects whose count could not be read, so `totals` and the roster are short. */
  failed: number;
  /** Projects counted in `totals` whose breakdowns could not all be read, so the series and lists are short. */
  incomplete: number;
  roster: VercelRosterEntry[];
  totals: { pageviews: number; visitors: number };
  pageviews: number[];
  visitors: number[];
  projects: VercelProjectTraffic[];
}

// ── The two responses ──────────────────────────────────────────────────────

export interface AnalyticsSectionData {
  traffic: TrafficSection;
  dimensions: DimensionsSection;
  paths: PathRow[];
  vitals: VitalsRow[];
  health: SiteHealthRow[];
  vercel: VercelTrafficSection;
}

export interface AnalyticsDashboardResponse {
  generatedAt: string;
  refreshing: boolean;
  range: AnalyticsRange;
  configured: { posthog: boolean; vercel: boolean };
  sections: DashboardSections<AnalyticsSectionData>;
  views: AnalyticsViews;
}

export interface ErrorIssue {
  id: string;
  shortId: string | null;
  title: string;
  /** The exception class, e.g. "SyntaxError". */
  type: string | null;
  /** The file it was raised from, when GlitchTip knows. */
  source: string | null;
  level: string | null;
  count: number;
  userCount: number;
  firstSeen: string | null;
  lastSeen: string | null;
  release: string | null;
  project: string;
  permalink: string | null;
  /** Same test that puts an error on the board: error/fatal, seen in the last 24h. */
  active: boolean;
}

export interface ErrorsIssuesSection {
  buckets: string[];
  issues: ErrorIssue[];
  summary: {
    active: number;
    backlog: number;
    events: number;
    /** Null when the resolved count could not be read. */
    resolved: number | null;
    /** False when GlitchTip's list could not be walked to its end. */
    complete: boolean;
    byType: { name: string; issues: number; events: number }[];
    /** Currently unresolved issues by the day they first fired. */
    newPerDay: number[];
  };
}

/** One kind of error a site reported. PostHog holds no message text, only these names. */
export interface SiteErrorRow {
  host: string;
  name: string;
  feature: string | null;
  step: string | null;
  boundary: string | null;
  page: string | null;
  count: number;
  lastSeen: string | null;
}

export interface SiteFailedRequestRow {
  host: string;
  /** 0 means the request never got a response. */
  status: number;
  method: string | null;
  path: string;
  count: number;
  lastSeen: string | null;
}

export interface SiteErrorDays {
  host: string;
  /** One value per bucket. */
  errors: number[];
  failures: number[];
}

/** What sits behind each site's row in `sites`, for that site's own page. */
export interface SiteErrorDetailSection {
  buckets: string[];
  days: SiteErrorDays[];
  errors: SiteErrorRow[];
  requests: SiteFailedRequestRow[];
  /** A row cap was hit, so the rarest errors or failed requests are missing. */
  truncated: boolean;
}

/**
 * One group of Vercel runtime errors: same project, source, method, normalized path, status and
 * first message line.
 */
export interface RuntimeErrorGroup {
  /** Stable hash of the grouping fields. */
  key: string;
  project: string;
  /** The deployment the group was LAST seen on. */
  deploymentId: string;
  domain: string | null;
  source: string;
  method: string | null;
  /** Numeric, uuid and hash segments read `:id`. */
  path: string | null;
  status: number | null;
  /** The worst level any of its lines carried. */
  level: string;
  /** First line of the message, at most 200 characters. */
  message: string;
  /** Events in the 24 hours before the read. */
  count: number;
  firstSeen: string;
  lastSeen: string;
  /** The request id of the most recent event, to look it up in Vercel. */
  sampleRequestId: string | null;
}

/** `GET /errors/runtime`, and the errors dashboard's `runtime` section. */
export interface RuntimeErrorsReport {
  generatedAt: string;
  window: "24h";
  /** When the groups were read from Vercel; null before the first read. */
  readAt: string | null;
  /** False when that read was cut short, so there may be more groups. */
  complete: boolean;
  /** Groups seen in the window; `groups` may be capped below it. */
  total: number;
  /** Seen in the window, worst level first, then most frequent. */
  groups: RuntimeErrorGroup[];
}

export interface ErrorsSectionData {
  issues: ErrorsIssuesSection;
  sites: SiteHealthRow[];
  detail: SiteErrorDetailSection;
  /** Vercel runtime errors of the last 24h (same body as `GET /errors/runtime`). */
  runtime: RuntimeErrorsReport;
}

export interface ErrorsDashboardResponse {
  generatedAt: string;
  refreshing: boolean;
  /** Which source is still refreshing; `refreshing` is either of them. */
  refreshingSources: { glitchtip: boolean; posthog: boolean };
  configured: { glitchtip: boolean; posthog: boolean; vercel: boolean };
  sections: DashboardSections<ErrorsSectionData>;
  views: ErrorsViews;
}

// ── Views: what the Analytics and Errors pages draw, derived by the server ──────────────────────
// Every join, sort, threshold and rating behind these lives in status-server's
// telemetry/dashboard/views.ts; the pages only lay them out.

export const DIMENSIONS = ["country", "device", "browser", "referrer"] as const;
export type Dimension = (typeof DIMENSIONS)[number];
export const VERCEL_BREAKDOWNS = ["countries", "referrers", "paths", "devices"] as const;
export type VercelBreakdown = (typeof VERCEL_BREAKDOWNS)[number];
export type BreakdownTopic = "pages" | "countries" | "referrers" | "devices" | "browsers";
export const VITALS = ["lcp", "inp", "cls", "fcp"] as const;
export type Vital = (typeof VITALS)[number];
export type VitalRating = "good" | "fair" | "poor";

export interface RatedHealth extends SiteHealthRow {
  /** The server's verdict that `failures / requests` is high. */
  failureRateHigh: boolean;
}

export interface JoinedSite {
  key: string;
  posthog: { pageviews: number; sessions: number; series: number[] } | null;
  vercel: { project: string; pageviews: number; visitors: number; series: number[] } | null;
  health: RatedHealth | null;
}

export interface ChartSeries {
  labels: string[];
  posthog: (number | null)[] | null;
  vercel: (number | null)[] | null;
}

export interface RatedVitalsRow extends VitalsRow {
  site: string;
  ratings: Record<Vital, VitalRating | null>;
}

export interface SiteBreakdown {
  topic: BreakdownTopic;
  posthog: Marginal[] | null;
  vercel: Marginal[] | null;
}

export interface SiteReport {
  posthog: { pageviews: number; sessions: number } | null;
  vercel: { pageviews: number; visitors: number } | null;
  health: RatedHealth | null;
  pageviews: ChartSeries | null;
  breakdowns: SiteBreakdown[];
  projects: VercelRosterEntry[];
  vercelIncomplete: boolean;
  vitals: RatedVitalsRow[];
  empty: boolean;
}

export interface SectionFailure {
  source: "PostHog" | "Vercel";
  what: string[];
  error: string;
}

export interface VercelProjectBar {
  site: string;
  project: string;
  pageviews: number;
  visitors: number;
}

export interface AnalyticsViews {
  sites: string[];
  joined: JoinedSite[];
  pageviews: ChartSeries;
  pages: Marginal[] | null;
  dimensions: Record<Dimension, Marginal[]> | null;
  vercelProjects: VercelProjectBar[] | null;
  vercelBreakdowns: Record<VercelBreakdown, Marginal[]> | null;
  vitals: RatedVitalsRow[] | null;
  siteReports: Record<string, SiteReport>;
  failures: SectionFailure[];
}

export interface ErrorsSiteChart {
  buckets: string[];
  errors: number[];
  failures: number[];
}

export interface SiteErrorView extends SiteErrorRow {
  id: string;
}

export interface SiteFailedRequestView extends SiteFailedRequestRow {
  id: string;
}

export interface ErrorsSiteReport {
  health: RatedHealth | null;
  chart: ErrorsSiteChart | null;
  errors: SiteErrorView[];
  requests: SiteFailedRequestView[];
  empty: boolean;
}

export interface ErrorsViews {
  sites: string[];
  mostErrors: RatedHealth[];
  mostErrorsLimit: number;
  siteReports: Record<string, ErrorsSiteReport>;
  siteFailures: SectionFailure[];
}

