
- **Data collected**: Board/work-item/plan administrative metadata — names,
  descriptions, statuses, dates, labels, health reports, comment bodies, and
  the `(kind, id)` participant/assignee/author references this domain
  carries but does not itself resolve to a person's profile. `authorLabel`
  on a comment ("how the author was named at the time of writing") and
  `createdBy` on a status update are the closest this domain comes to
  personal data, and both are opaque display strings the backend supplies,
  never computed or enriched here.
- **Storage**: This component holds no cache of its own — every call is a
  live round trip through an authenticated request helper. Whatever caching
  a consumer layers on top (a query-caching layer, as the sibling
  `hub-domain-ecosystems` recipe documents for its reference implementation)
  is outside this domain's files.
- **Transmission**: Every call travels through an authenticated,
  Bearer-token request helper; this domain itself attaches no credentials
  and reads no cookies.
- **Retention**: This domain retains nothing between calls; it is a
  stateless set of functions over the network. The live-wake subscription
  helper is the one exception — a connection/listener-set entry per
  actively-watched board id, which is discarded the moment the last
  subscriber unsubscribes, holding no data, only a handle and callbacks.

