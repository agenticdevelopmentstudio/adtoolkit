
None of the four files persist anything client-side (there is no local
cache, no storage write, no cookie access); every request body sent is
exactly the caller-supplied input, or its `compact()`-filtered subset for a
`schemasApi.update` PUT, transmitted over whatever transport `authedJson`/
`authedRequest` use (bearer-token HTTP, defined outside these four files).
The data these operations carry — document content and titles, category and
tag names, bucket/table names and descriptions — is user-authored content,
not a credential or token; none of it is retained, transformed, or
forwarded to any destination other than the single backend route each call
targets.

