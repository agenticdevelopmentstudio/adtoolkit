
The catalog is the decoded model of what the Open VSX registry's HTTP API
returns: one summary row from `GET /api/-/search` (a search entry), one page
of that search (a search page), and the full record for one version of one
extension from `GET /api/<namespace>/<name>` or `.../<version>` (an
extension detail). It has no visual surface, performs no network request
itself, and is not the code that fetches these responses — that is the
registry client, out of this recipe's scope. Its defining discipline is that
every URL-shaped registry field decodes as a plain string, never as a parsed
URL, so that one entry with a malformed icon link never sinks the decode of
the page it appeared on; computed accessors parse each URL lazily, where it
is used, so a bad string costs exactly the accessor that reads it. The
catalog's second job is the installability verdict: a pure function from
already-decoded metadata to a named verdict — whether a given registry
version could be installed into this host at all, decided before any bytes
are downloaded.

