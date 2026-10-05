
This is the client-side contract for the Hub's "Applications" product topic: an
applications data source is the interface every network call is delegated to; the
applications data model holds the wire types (application, application-create,
application-update, consumer kind, application token, application-token-created) plus
the domain-only, deliberately non-wire-serializable grant types (CRUD permissions,
table grant, schema grant); and the applications topic is the navigation controller
that resolves the rail path into list/detail panes for an application's Settings,
Bucket permissions, and Access tokens sections, using an injected buckets data source
to label and enumerate the buckets/tables a grant can target. Every thrown error is
normalized to the shared error type before it reaches a caller, and every token
secret this component ever holds is a transient, reveal-once-then-drop entry in an
in-memory dictionary — the same pattern the sibling Authentication feature
(`adtoolkit://cookbook/adh/hub/security/authentication-client`) uses for its own
API and storage tokens.

