
- **React/Web** (source platform): `packages/web/packages/messaging/src/hooks/use-dms.ts` and
  `use-notifications.ts` hold the hooks; both build on `authedJson`/`authedRequest`/`AuthHttpError`
  from `@agentic-toolkit/auth/client`, `useAuth` from `@agentic-toolkit/auth`, and the shared
  `connectSse`/`SseHandle` from `@agentic-toolkit/data/stream` — the one live-connection transport
  every real-time consumer in the web app now shares, per that package's own top-of-file comment.
  The live connection is a browser `EventSource`, which cannot set a request header — the reason
  its access token rides the URL query string instead; the client-generated message id uses
  `crypto.randomUUID()` when available, falling back to a `Date.now()`-based string.
- **SwiftUI**: model `DmMessage`, `DmChatSummary`, `PresenceView`, `DmConversation`, and
  `Notification` as `Codable, Hashable, Sendable` structs; port each hook to an `@Observable` (or
  `ObservableObject`) type whose `async` methods mirror `send`/`markRead`/`loadMore`/mutation calls,
  backed by `URLSession` for plain requests and `URLSession.bytes(for:)` (or a small SSE-framing
  helper over it) for the two live streams, since Foundation has no built-in `EventSource`
  equivalent; the token-in-query quirk MUST be preserved deliberately if parity with the web client
  is the goal, or flagged as a divergence if the port instead sends it as a header-equivalent the
  platform's stream transport supports.
- **AppKit / UIKit**: no direct UI dependency exists in either source file; a macOS/iOS messaging
  surface would consume the ported hooks through an injected data-source/view-model object exposing
  the same fields (`chats`, `messages`, `loading`, `error`, `hasMore`, …) rather than calling
  `URLSession` from a view controller directly.
- **Compose**: model the wire rows as `@Serializable` Kotlin `data class`es and each hook as a
  `ViewModel` exposing `StateFlow`s, backed by Ktor's or OkHttp's SSE support for the two live
  streams and coroutine `suspend fun`s for the plain calls; Ktor's client-side SSE plugin removes
  the need to hand-roll a poll fallback, though preserving this recipe's self-healing behavior
  exactly would still require one.
- **WinUI 3**: a .NET port would model the wire rows as `record`s attributed for
  `System.Text.Json`, and each hook as a class exposing `Task`-returning methods built on
  `HttpClient`, attaching `Authorization: Bearer <token>` the way `authedFetch` does and refreshing
  on a `401` the same one-retry way; `HttpClient` has no native SSE client, so the two live streams
  would need a package such as `LaunchDarkly.EventSource` or a hand-rolled reader over a streamed
  `HttpResponseMessage`, with an `ObservableCollection`/`INotifyPropertyChanged`-based
  view-model layer standing in for the `useState` calls this recipe's hooks use to hold `messages`
  and `chats` — this is the platform with the least existing prior art in this repo for both the
  refresh-and-retry contract and the token-in-query stream pattern, so a WinUI 3 port needs to
  build the equivalent of both `authedFetch` and `connectSse`, not just these two hooks.

