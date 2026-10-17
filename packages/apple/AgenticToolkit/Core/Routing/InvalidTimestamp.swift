import Foundation

/// Why a rejected `?since=` needs a type of its own: `Result`'s failure must be
/// an `Error`, and a retroactive `extension String: Error` would make every
/// string in the process a throwable — a cure worse than the bare `String` it
/// replaces.
public struct InvalidTimestamp: Error, Equatable, CustomStringConvertible {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var description: String { message }
}
