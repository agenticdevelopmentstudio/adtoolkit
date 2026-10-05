
Not applicable: `live-types.ts` declares data shapes only — it collects, stores, and transmits nothing itself. None of its fields is a token or credential; the URLs, project names, commit-adjacent identifiers and error strings the bundled DTOs carry are operational monitoring data already produced elsewhere, and this file neither reads nor writes them.

