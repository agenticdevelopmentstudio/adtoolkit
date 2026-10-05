
This service owns everything screen-related for the toolkit's window
management:

- the identity of the set of displays attached right now;
- a persisted list of every screen set the machine has been attached to,
  each with first-seen and last-seen timestamps, aged out after a
  configurable maximum age (default 180 days);
- classification of live screen-parameter changes into one of three change
  kinds — a resolution change, an arrangement change, or a screen-set
  change — that it delivers to registered observers.

A "screen set" is the group of displays connected at one location: a laptop
that travels between home and office produces one set per desk. The window
frame manager keys window placements by the current set's identity, so each
window remembers one position per location. Use the shared instance in
production; inject an isolated instance (a mock screen provider, in-memory
set storage, a fixed clock) in tests.

