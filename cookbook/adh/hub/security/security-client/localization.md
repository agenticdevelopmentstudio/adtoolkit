
The bucket access lists client is the one place in this domain that authors its own English strings,
rather than relaying one from the backend:

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| — | `An access list named "<name>" already exists.` | Thrown when creating a group hits a name conflict, via the shared conflict-translation helper |
| — | `An access list named "<name>" already exists.` | Thrown when updating a group hits a name conflict, via the shared conflict-translation helper |
| — | `That member is already in this access list.` | Thrown when adding a member hits a uniqueness conflict, via the shared conflict-translation helper |

There is no localization mechanism in this domain (no catalog, no key, no localization-lookup call) —
the three strings above are hardcoded literals, stated as fact per the non-UI component guidance rather
than as a gap. Every other error message a caller can observe from either client originates in the
backend's response body and is extracted by a shared error-message helper, not authored in this
component.

