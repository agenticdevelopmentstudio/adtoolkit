
This is the shared SEO layer for every site in a multi-site family. It
exposes four pure operations — building a full metadata object, building a
canonical-only metadata object, building a robots policy, and building a
sitemap — plus a fixed image-size constant, all derived from a site
identifier (resolved via the site registry) and a small amount of
caller-supplied copy. It exists because, per the source's own
documentation, 46 of 47 sites had no canonical URL and most had no Open
Graph/Twitter block at all, which matters specifically because the family
runs three public tiers of byte-identical HTML (a production host, a
staging host, and a testing host) that a search engine would otherwise
index as competing duplicates. This recipe is the contract for a port of
that layer to another runtime.

