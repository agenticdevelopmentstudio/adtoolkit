
This logic turns the status server's `/integrations` report into the self-check view that the self-check banner view renders. It exports:

- **the self-check view** — the view shape: `missingEnv`, `missingEnvError`, `issues`, `hasError`.
- **the derivation function** — the pure derivation, returning null when there is nothing to show, so the bar can render exactly when the derivation's result is non-null.

The doc comment says the function is "kept separate from the component so the (slightly fiddly) filtering rules are unit-tested without a DOM". Two consumers call it: the self-check banner view, which renders the bar, and the dashboard view, which counts issues the same way the banner does, so the pill and the bar never disagree.

The report carries `generatedAt` (string), `overall` (a check state) and `checks` (a list of checks); each check carries `id`, `label`, `configured`, `ok`, `state` (one of `"ok"`, `"warn"`, `"error"`), `detail`, and the optional `missingEnv` (a list of strings), `unreachable` (boolean) and `correlated` (boolean). The report itself is produced by the status server (see [Status Server Monitor Integrations](adtoolkit://cookbook/status/service/monitor/integrations)) and fetched by [the integrations state](adtoolkit://cookbook/status/dashboard/state/integrations).

