
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses the type unchanged from any view model or store. The type is a `String`-backed enumeration conforming to `Codable`, `Sendable` and `CaseIterable`.
- **Compose**: Model it as an enum class with a `value` string (`oauth`, `long-lived`), a `title`, and companion `key(account, kindValue)` and `parse(itemKey)` functions; serialize by `value`.
- **React/Web**: A string-literal union `'oauth' | 'long-lived'` with a title map and pure `credentialKey` / `parseCredentialKey` functions; split the key at the first colon only.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: An `enum ClaudeCredentialKind` with a `[JsonConverter(typeof(StringEnumConverter))]`-style mapping to `oauth` and `long-lived`, a `Title` extension method, and static `Key` and `Parse` helpers; use `IndexOf(':')` for the first colon so account names keep later colons. Store keys in Windows Credential Manager target names built through that one helper.

