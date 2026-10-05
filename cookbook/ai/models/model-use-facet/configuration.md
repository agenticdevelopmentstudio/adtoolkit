
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | string | required | Evidence text passed to the core facet derivation — normally a model's description and/or `goodFor` blurb, already joined by the caller. |
| `capabilities` | list of strings | `[]` | Reported capability strings passed alongside `text`; matched via the capability-matching check for the three capability-implied facets. |
| `model` | a resolved model | required | Input to facet derivation for a resolved model; its `description`, `goodFor`, and `capabilities` fields are read, its `id` is deliberately not. |
| `extraText` | string, optional | absent | Additional description text not carried by the catalog (e.g. a local server's live-fetched blurb for a model the catalog has never seen), appended to the model's `description`/`goodFor` before derivation. |
| `selected` | set of facets | caller-supplied | The set of uses a filter control has checked, passed to the match check; an empty set is the default, unfiltered state of a "Good for" filter menu. |

