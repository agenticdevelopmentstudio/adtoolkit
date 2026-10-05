
- **Data collected**: none originated by this module. It transits whatever
  the browser and backend already exchange through it — session cookies,
  `Authorization` headers, OAuth codes in request bodies, and `Set-Cookie`
  tokens in 3xx responses — per credentials-forwarded-opaquely, without
  inspecting, parsing, or logging any of it.
- **Storage**: none. The backend forwarder is a stateless per-request
  forward; it holds nothing in memory or on disk beyond the lifetime of a
  single call.
- **Transmission**: yes. Credentials leave the browser and pass through
  this server compute to the backend at the resolved backend URL
  (`localhost` in development, an environment-configured or default
  production URL). TLS, if any, is provided by the deployment platform;
  this module does not configure it.
- **Retention**: none. Nothing this module handles is retained after the
  response it produced is returned to the caller.

