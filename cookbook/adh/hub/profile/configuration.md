
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| The workspace option (every list/create/update/delete/usage operation) | optional string | omitted → the caller's own principal | Workspace slug scoping the call to an organization's profile instead of the caller's own; percent-encoded when present. |
| The create/update input (social links) | an object | none — required | `{ platform, url, handle, sortOrder? }`, sent verbatim as the request body. |
| The create/update input (addresses) | an object | none — required | `{ label, line1, line2, city, region, postalCode, country }`, sent verbatim as the request body. |
| Target table / target id / level (privacy-grant set) | string, string, a privacy-level value | none — required | The level is mapped through the fixed audience-mask map to an integer bitmask before sending. |
| Grants (privacy-level resolution) | a list of privacy-grant records | none — required, caller supplies the already-loaded list | Pure lookup; issues no network call of its own. |
| The fixed audience-mask map | a module constant | fixed `{"only-me": 0, public: 1, hub: 2}` | Not injectable or configurable. |
| The four cache-key roots | module constants | fixed | Not injectable; the privacy cache key alone is exported directly, per `privacy-key-not-namespaced`. |

