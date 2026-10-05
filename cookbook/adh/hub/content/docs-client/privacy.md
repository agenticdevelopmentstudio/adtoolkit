
- **Data collected**: None beyond what the caller explicitly supplies —
  `content`, `category`, `tags`, and (per `create-may-double-file`)
  `note` — plus the fixed `doc: true` marker this client always adds on
  create. No field is appended that the caller did not provide or that this
  recipe's other requirements do not already name.
- **Storage**: None client-side. `docsApi` holds no cache and no local
  copy of any document, category, or tag (`stateless-client`); all
  persistence is the backend's.
- **Transmission**: Every request travels through `authedJson`/
  `authedRequest` (`packages/web/packages/data/src/http.ts`, itself
  re-exporting `@agentic-toolkit/auth/client`), the same bearer-token
  authenticated channel every other data client in this package uses;
  `docs.ts` adds no transmission of its own and performs no additional
  encryption, redaction, or inspection of the document content it sends.
- **Retention**: Not controlled at this layer. `docsApi.remove` performs a
  soft delete on the backend (per the module comment: "the backend
  tombstones the doc marker with the document"); how long a tombstoned row
  is retained is a backend policy this client has no visibility into.

