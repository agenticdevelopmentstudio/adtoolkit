
- **SwiftUI**: Not used; these are plain values a view binds to.
- **Compose**: Kotlin data classes with `kotlinx.serialization` and `@SerialName` snake_case.
- **React/Web**: TypeScript interfaces or zod schemas with snake_case wire keys.
- **AppKit / UIKit**: Swift `Codable`, `Sendable`, `Equatable` structs; keys convert through `.convertToSnakeCase`; the overview has a custom decoder using `decodeIfPresent`.
- **WinUI 3**: C# records with `System.Text.Json` and `JsonNamingPolicy.SnakeCaseLower`; `required` members for non-optional fields.

