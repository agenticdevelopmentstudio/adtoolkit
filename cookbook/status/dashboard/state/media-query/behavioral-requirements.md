
- **signature**: Media Query MUST accept one input, a CSS media query string, and MUST return a single boolean value.
- **initial-value**: Media Query MUST return `false` on the first evaluation, before any subscription is established, regardless of whether the query would match.
- **ssr-value**: Media Query MUST return `false` during a server-rendering pass, where no viewport exists to measure.
- **client-only**: Media Query MUST run only in a live client execution context; it has no server-only or universal-rendering variant.
- **mount-sync**: Once its subscription is established, Media Query MUST evaluate the query against the current viewport and MUST update its returned value to that match result.
- **change-subscription**: Once subscribed, Media Query MUST listen for change notifications for the query and MUST update its returned value to the match value carried by each notification.
- **unsubscribe-on-unmount**: When the caller stops using it, Media Query MUST remove the change listener it registered.
- **query-change-resubscribe**: When the query input changes, Media Query MUST remove the listener for the previous query, MUST evaluate the new query immediately, and MUST subscribe to change notifications for the new query.
- **stable-query-no-resubscribe**: While the query input is unchanged, Media Query MUST NOT re-evaluate or re-subscribe.
- **stale-value-on-query-change**: At the moment the query input changes, Media Query MUST still report the previous query's match result; the new query's result appears only once its subscription updates.
- **no-input-validation**: Media Query MUST pass the query to the environment's media-query facility unchanged; it performs no parsing or validation of its own.
- **no-environment-guard**: Media Query MUST call the environment's media-query facility directly with no check that it exists; in an environment without that facility, evaluation fails with an error.
- **modern-listener-api-only**: Media Query MUST register for change notifications using the environment's standard subscribe/unsubscribe pair; it has no fallback to a deprecated listener-registration mechanism.
- **no-side-effects**: Media Query MUST NOT perform network, file, storage, or logging side effects; its only side effect is the change-listener registration.
- **single-threaded-ordering**: All evaluation and listener callbacks MUST run on a single execution thread; updates are applied in the order the environment delivers change notifications.

