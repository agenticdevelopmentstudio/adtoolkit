
Not applicable: the catalog carries no user data, credential, or token. It
transmits only a `GET` request (no request body) to a base URL the caller
supplies, and stores only model names and integer byte sizes in memory;
nothing it holds is written to disk or leaves the process except that
outbound request.

