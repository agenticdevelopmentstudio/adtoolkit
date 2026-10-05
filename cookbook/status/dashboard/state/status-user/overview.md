
The status user state is a thin shape adapter over the shared session state. It returns the current authenticated user object, or `null` when the user is "unauthenticated / unknown". It calls the underlying shared session state and returns only that state's `user` field, dropping its loading flag.

The adapter exists so that one request function owns the `/auth/me` semantics, so consumers can't drift. All fetch, caching and retry behavior therefore comes from the session state and its request function. This recipe specifies that inherited contract as seen through the adapter, because a port has to reproduce it for the adapter to behave the same.

Callers that need only the user object use this state — for example, views that read the result for role gating by checking `user?.role`, or a banner that derives an `isAdmin` flag from `role === "admin"`. Callers that also need the loading flag use the shared session state directly instead.

