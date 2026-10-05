
Not applicable: `live-events.ts` handles no credentials, tokens, or personal data. It broadcasts already-built `LiveSnapshot` DTOs (service/deployment status) between server-side subscribers, treating the snapshot as an opaque value it never inspects; any personal-data handling happens in `Storage`/`buildLiveSnapshot`, external to this file.

