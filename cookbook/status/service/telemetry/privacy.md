
`buildErrorsFetcher` and `buildAnalyticsFetcher` read the `GLITCHTIP_API_TOKEN` and `POSTHOG_API_KEY` secrets from `StatusConfig.credentials` and pass them only to the provider fetchers; this module never logs or persists them, though its `console.error` calls log caught error objects as-is. Analytics metrics are anonymous aggregates, and ErrorDTO carries only a `userCount`, not user identities. Credential storage belongs to `StatusConfig` and the environment.

