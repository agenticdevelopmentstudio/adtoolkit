
The platform filter options logic holds the option taxonomy for the Platform filter in the Sites config list. It provides three things: a no-platform sentinel value, a function that returns the full set of known platform keys, and a pure function that computes the filter's option rows from a list of endpoints.

The logic exists to fix a specific bug: a purely data-driven list only showed platforms present among the endpoints, so an entry such as "railway" vanished from the filter whenever no site was wired to it. The fix is that every known platform is always offered, regardless of which endpoints exist.

The known platforms are a canonical, ordered list, currently `vercel`, `railway`, `cloudflare`, and `crunchy`. Each option row carries a key and a label.

The one caller is the endpoints configuration view. It seeds its selection state with the full set of known keys (including the no-platform sentinel), resets it to that full set or to an empty set from its "all" toggle, recomputes its option rows whenever the endpoint list changes, and keeps an endpoint visible when its selection contains that endpoint's platform (with an absent platform mapped to the no-platform sentinel). The logic itself holds no state and performs no I/O.

