
This logic provides one pure function that turns text into a slug. Its doc comment describes it as "Lowercase, hyphenate
runs of non-alphanumerics, trim leading/trailing hyphens" and calls it "The one
shared slug form for groups and sites."

The board uses it in two places:

- the config panel view shows the slug function's result for the draft name as the placeholder of the
  group slug field. When the typed slug is blank after trimming, it sends
  the slug function's result for the draft name as the group's `slug` on save.
- the endpoints configuration view derives a site's `slug` from the
  endpoint URL's host, via the slug function. It does this when it creates the backing
  site row, and again when it renames a site that only this endpoint owns.

The function does no I/O and does not check whether a slug is unique. The backend
(the status server) enforces uniqueness through the `uniq_site_group_slug` and
`uniq_site_group_site_slug` indexes.

