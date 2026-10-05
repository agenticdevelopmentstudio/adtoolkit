
- **Data collected**: The free-text `query` a caller passes to `search`, and
  the `namespace`/`name`/`version` identifiers a caller passes to `detail`,
  are sent to the configured registry as URL query items or path
  components; `OpenVSXClient` itself collects and attaches nothing beyond
  what the caller supplies as arguments.
- **Storage**: None. `OpenVSXClient` holds no cache and persists nothing
  between calls — whichever caller receives the decoded `OpenVSXSearchPage`,
  `OpenVSXExtensionDetail`, `Data`, or `String` decides whether to store it
  (doc comment).
- **Transmission**: Every `search`/`detail` request, and every artifact
  fetch that passes `requireFetchable`, leaves the device for `registryBase`
  (`https://open-vsx.org/api` by default, or a caller-configured self-hosted
  host) over `https`; the doc comment states that nothing beyond the request
  itself is sent that the registry could attribute to a user.
- **Retention**: Not applicable — no value returned by this type is retained
  past the call that produced it; the type stores nothing between calls
  (doc comment).

