
The telemetry state is the status dashboard's single read of production telemetry: grouped error issues (GlitchTip) and headline analytics KPIs (PostHog), delivered as one snapshot object (`{ generatedAt, errors, analytics }`). The dashboard's error and traffic cards both read it.

The state knows only two ports, both composed in one composition root:

- the source — where a fresh snapshot comes from. Today it is the live source, which does `GET /telemetry` through the caller's injected API client. An alternative source backed by Turso is wired as the alternative and is selected by changing one line in the composition root.
- the cache — where the browser keeps the last snapshot. Today it is the local cache, a persistent-storage adapter under the key `adh-telemetry-v1`.

The contract: poll the source, persist each snapshot to the cache, hydrate from the cache after mount rather than during render (so server render and first client paint match), and let live data win over the cached snapshot, which wins over an empty snapshot. The state never names GlitchTip, PostHog or Turso in its own logic, so swapping the backend leaves it untouched.

