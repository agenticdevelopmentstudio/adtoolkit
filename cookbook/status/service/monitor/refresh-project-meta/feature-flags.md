
Not applicable: none of the three exported functions consults a feature-flag system; every branch in the source is driven by `snapshot.ok`, `snapshot.configured`, `meta.length`, or `env.VERCEL_API_TOKEN`, never a flag lookup.

