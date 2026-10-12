import Foundation

/// The JSON spelling a request body or reply takes between `steno`, the daemon
/// and the app: snake_case keys, ISO-8601 dates. One definition, so the three
/// ends of a relayed request cannot drift into three dialects — a `Date` added
/// to a DTO decodes the same everywhere it travels.
public enum StenographerWire {
    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
