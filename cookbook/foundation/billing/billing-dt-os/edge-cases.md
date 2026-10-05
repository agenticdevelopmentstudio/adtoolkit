
- A running segment has an empty end and zero seconds.
- Amounts in different currencies are never combined.
- A reader that knows one currency reads the top-level buckets and still gets a true figure.
- A daemon that predates per-currency rows still decodes.
- A typo in a copied origin string would silently never match, hence the shared constants.

