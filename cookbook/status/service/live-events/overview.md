
`live-events.ts` is the status backend's in-process pub/sub hub for `/live`
push updates. It is one module, six exported functions, no HTTP route of its
own: `subscribeLive`/`publishSnapshot` are the fan-out (one `LiveSnapshot`
object handed to every open SSE stream), `recentSnapshot` is a short-lived
cache of the last published snapshot, `liveSubscriberCount` reports the
current subscriber count for the health/observability surface,
`emitLiveUpdate` is the debounced trigger a producer (a webhook handler in
`routes/hooks.ts`, or, per the module's own doc comment, a finished poll
cycle) calls to schedule a fresh build-and-publish, and `resetLiveEvents` is a
test-only reset of all module state. The actual SSE transport
(`routes/stream.ts`, subscribing on connect and writing `event: snapshot`
frames) and the actual snapshot construction (`buildLiveSnapshot` in
`routes/reads.ts`, which reads `Storage`) are both external to this file;
this recipe specifies only what `live-events.ts` itself does with the
snapshot once one exists.

