
**The engine's configuration** — the one config surface:

| Field | Type | Default | Description |
|---|---|---|---|
| `deviceId` | string | — | Device identifier sent in every push request. |
| `pullLimit` | integer | `500` | Max changes requested per pull page. |
| `pushBatchSize` | integer | `100` | Max outbox ops per push round-trip. |
| `baseBackoff` | duration (seconds) | `2` | Base retry delay for the exponential backoff. |
| `maxBackoff` | duration (seconds) | `3600` | Cap on the retry delay. |
| `hostResources` | optional list of resources | none | Resources this host mirrors. Absent accepts the server's whole manifest (pre-enrollment behavior); when set, the effective set is `manifest ∩ hostResources` and out-of-set changes are skipped. |

Pull-only (route-mode) refusal is **not** an engine-config concern: it is
enforced solely at the store's write path, so the set is passed only to the
store's construction (below), never to the engine's configuration.

**Store construction parameters:**

- The on-disk store's constructor takes the bounded database plus a set of
  pull-only resource identifiers (default empty).
- The in-memory reference store's constructor takes a set of pull-only
  resource identifiers (default empty).

The store's pull-only-resource set is what actually enforces
`pull-only-refused-at-stage`: staging a mutation raises a pull-only-resource
refusal error before any storage work.

**The client-side sync catalog** — the adh values hosts wire in, generated
from the backend's sync resource registry:

- The full catalog — every catalog resource (**97**, all schema version 1),
  passed as the host-registered resources for the engine's registration step.
- The pull-only subset of the catalog — the **44** route-mode resources,
  passed as the pull-only set to the store's construction (the only place
  that enforces it).

Both counts are read off the checked-in generated catalog source, not pinned
to a backend revision. They were 79 and 27 when this was first written
against adh main `64825b107`; the generated file is the live number, so
count there rather than trusting this paragraph.

