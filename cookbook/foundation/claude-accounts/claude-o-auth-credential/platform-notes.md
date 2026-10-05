
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses the type unchanged from any view model or store. The type is a `struct` conforming to `Codable`, `Sendable` and `Equatable`.
- **Compose**: A Kotlin `data class` with `@Serializable`, `Long?`/`Double?` expiry fields and computed `expirySeconds` properties; data-class equality gives the equality requirement for free.
- **React/Web**: An interface with the seven fields plus pure helper functions `expirySeconds(c)` and `refreshExpirySeconds(c)`; keep expiries as numbers in milliseconds and never store them as `Date`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A `record ClaudeOAuthCredential` in C# with `double?` expiry properties and `ExpirySeconds` computed properties; serialize with System.Text.Json using the same camel-case names. Persist it through `PasswordVault` or Windows Credential Manager under a key from the credential-kind key helper.

