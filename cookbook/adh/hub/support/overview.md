
The Support group is seven small, independent pieces of non-UI logic that every
feature module in this domain builds on:

- a **form/notice detail-pane factory** — builds the two detail panes every
  feature uses: an editable form and a read-only notice.
- **date parsing and formatting** — ISO-8601 string ↔ date conversion at the
  three edges a feature touches dates: forms, labels, and request bodies.
- an **error normalizer** — the universal error boundary: a feature's rail
  only ever shows the shared named error type, which normalizes whatever a
  data source throws.
- a **blank-string helper** — one operation that turns a form's `""` into an
  absent value, so optional fields encode as absent, not empty.
- a **JSON document value type** — for backend fields typed as free-form JSON
  (bag values, metadata, template vars).
- **rail-path position lookups** — two helpers for the path array a module
  receives when resolving a child.
- **slug rules** — the identifier rules shared by every feature that lets a
  user pick a slug (personas, products, buckets, users).

None of the seven pieces depends on any of the others. A detail-pane
descriptor, a path item, a form specification, a form section, a read-only
field descriptor, a form value wrapper, a form's mutable state object, and a
form-hosting view are types these pieces build on or return but are not among
this recipe's seven given pieces — see the related HTDV Engine recipe. A
shared injection point for the markdown-editing module, and the domain's own
shared error type (whose categories include validation, not-found, and
conflict) are likewise domain-wide concepts referenced here, but not
redescribed beyond what the form/notice factory and the error
normalizer/JSON parser do with them.

