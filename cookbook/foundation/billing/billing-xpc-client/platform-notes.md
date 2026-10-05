
- **SwiftUI**: Not used; the client has no view layer.
- **Compose**: A repository over Retrofit or a bound service, returning a sealed result.
- **React/Web**: A client over `fetch` with a typed `Result`; JSON snake_case in and out.
- **AppKit / UIKit**: Generic `final class BillingXPCClient<Transport: BillingXPCTransport>: BillingService`; the leaf adds the retroactive transport conformance to its XPC client.
- **WinUI 3**: A client over `HttpClient` or a named-pipe/RPC transport with `System.Text.Json` (`JsonNamingPolicy.SnakeCaseLower`), returning a `Result<T, BillingRefusal>`; the daemon connection is not XPC on Windows.

