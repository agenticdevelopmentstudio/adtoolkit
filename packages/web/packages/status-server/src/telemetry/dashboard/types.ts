import type { AnalyticsRange } from "./ranges";
import type { DashboardSections } from "./sectioned-dashboard";
import type { RuntimeErrorsReport } from "../types";
import type { AnalyticsViews, ErrorsViews } from "./views";

export type { RuntimeErrorGroup, RuntimeErrorsReport } from "../types";

export { ANALYTICS_RANGES } from "./ranges";
export { DIMENSIONS, VERCEL_BREAKDOWNS, VITALS } from "./views";
export type {
  AnalyticsViews,
  BreakdownTopic,
  ChartSeries,
  Dimension,
  ErrorsSiteChart,
  ErrorsSiteReport,
  ErrorsViews,
  JoinedSite,
  RatedHealth,
  RatedVitalsRow,
  SectionFailure,
  SiteBreakdown,
  SiteErrorView,
  SiteFailedRequestView,
  SiteReport,
  VercelBreakdown,
  VercelProjectBar,
  Vital,
  VitalRating,
} from "./views";

// The wire shapes of GET /analytics/dashboard and GET /errors/dashboard. status-web keeps a hand
// mirror in telemetry/dashboard-types.ts, held to this file by dashboard-types-parity.test.ts.


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
  /** What the pages draw, derived from `sections` on the server (src/telemetry/dashboard/views.ts). */
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

export interface ErrorsSectionData {
  issues: ErrorsIssuesSection;
  sites: SiteHealthRow[];
  detail: SiteErrorDetailSection;
  /** Vercel runtime errors of the last 24h, read from the store (same body as `GET /errors/runtime`). */
  runtime: RuntimeErrorsReport;
}

export interface ErrorsDashboardResponse {
  generatedAt: string;
  refreshing: boolean;
  /** Which source is still refreshing; `refreshing` is either of them. */
  refreshingSources: { glitchtip: boolean; posthog: boolean };
  configured: { glitchtip: boolean; posthog: boolean; vercel: boolean };
  sections: DashboardSections<ErrorsSectionData>;
  /** What the per-site pages draw, derived from `sections` on the server (views.ts). */
  views: ErrorsViews;
}
