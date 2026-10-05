
- **SwiftUI**: The source file imports `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a `String` extension that copies the string so `withUTF8` can make it contiguous and calls `memmem` on the buffer.
- **Compose**: On the JVM use `String.contains` on a `ByteArray` search via `ByteBuffer`; for hot paths over large files, search raw `ByteArray` lines with a Boyer-Moore-style search and skip decoding.
- **React/Web**: Search `Uint8Array` buffers with `Buffer.indexOf` in Node, which is byte-exact and fast, and skip decoding to a string for lines that do not match.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Search `ReadOnlySpan<byte>` with `MemoryExtensions.IndexOf(span, needleSpan)`, which is vectorized, after encoding the text once with `Encoding.UTF8.GetBytes`; avoid `string.Contains`, which is culture-sensitive unless `StringComparison.Ordinal` is passed.

