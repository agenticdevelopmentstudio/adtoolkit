
- The request builder's token parameter is forwarded as an `Authorization`
  header and is never persisted, cached, or logged by any given source; the
  caller owns the token's lifecycle.
- Snippet generation deliberately substitutes the fixed token placeholder for
  any real token so that copying a generated snippet to the clipboard can
  never leak a live credential — a privacy-motivated design decision (see
  Design Decisions).
- The table visibility gate's tier check (read-allowlist/write-allowlist) is
  presentation data-minimization only: it narrows which tables the UI
  *offers* to a non-admin viewer, but it is explicitly documented as not a
  security or privacy boundary — the server independently decides what data
  is actually returned.
- None of the given sources persist personally identifiable information to
  local storage, a database, or any other durable store.

