
Endpoint slugging exists specifically to make each API endpoint reachable by
a crawlable, collision-checked URL slug: slug projection projects an endpoint
to a slug (path segments with `{param}` braces stripped, plus the lower-cased
method appended), and slug lookup reverses that projection for routing,
returning nothing on a miss rather than throwing. This is the deep-linking
contract for the whole recipe; no other given source participates in deep
linking.

