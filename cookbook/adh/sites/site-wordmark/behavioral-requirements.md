
- **render-registry-brand**: The wordmark MUST render the site's full
  brand name for the given site identifier, resolved from the shared site
  registry.
- **accent-trailing-word**: The wordmark MUST split the brand via the
  shared title-split logic and render the trailing accent segment in the gold
  accent color role and italic, with the lead segment in the primary text
  color role.
- **default-identity-to-description**: The wordmark MUST render the site's
  registry description as the identity line when no tagline is provided.
- **honor-explicit-tagline**: The wordmark MUST render a provided
  tagline as the identity line in place of the description.
- **omit-identity-when-null**: The wordmark MUST render no identity line
  when the tagline is null or an empty string, or when neither a tagline nor a
  description exists — the identity line is omitted whenever its resolved
  value is falsy, so null, absent, and empty string are all treated as "omit".
- **fall-back-on-unknown-site**: The wordmark MUST still render — accenting
  the site identifier value itself, since there is no registry entry to derive
  a label from — when the site identifier resolves to no registry entry, never
  throwing.

