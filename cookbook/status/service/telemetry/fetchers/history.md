
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-10-04 | Mike Fullerton | Resolved posthog-malformed-result-shape marker as current behavior plus pending decision |
| 1.0.2 | 2026-09-27 | Mike Fullerton | Moved into the concept grouping. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation, documenting the GlitchTip issues fetcher and PostHog HogQL analytics fetcher: their env-gated no-op, single bounded fetch attempt, DTO mapping, the `complete`-flag contract with the reconciling errors store, and the PostHog batch's sequential, partial-success semantics. Records the open questions over both providers' unverified response schemas and PostHog's unsignaled malformed-shape case.
