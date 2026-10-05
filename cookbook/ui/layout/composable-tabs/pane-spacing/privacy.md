
- **Data collected**: The six `pane_spacing_*` integers only — window-chrome layout preferences, not personal or sensitive data.
- **Storage**: Local only, via the app's settings store. None of the six settings is marked secure, so each routes to the non-secure settings path, which defaults to the platform's standard local-preferences storage unless the host app configures a different provider — a choice made outside this component.
- **Transmission**: None. No network call appears anywhere in this component.
- **Retention**: Persists until explicitly changed or removed; this component defines no expiration or automatic cleanup.

