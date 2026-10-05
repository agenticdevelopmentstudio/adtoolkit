
This recipe is the shared query-cache runtime that every toolkit
data-fetching hook reads through, rather than any cache client a host
application mounts for its own code. It owns exactly one client-side cache
instance per tab, held at module scope specifically so it survives a
same-segment route remount that would otherwise reset a component-state
cache to empty on every navigation; a provider component for mounting that
cache declaratively, where nesting it inside another instance of itself, or
mounting it more than once, is a no-op rather than a second cache; a
consumer accessor that resolves to the same cache whether or not a provider
is mounted above the caller, and even when a host's own, differently
configured cache-provider component (built on the same underlying cache
library) is mounted above it instead; and a session-watch guard that empties
the whole cache the instant the signed-in principal changes, so a second
user on a shared machine is never served the first user's cached rows. It
has no visual surface of its own.

