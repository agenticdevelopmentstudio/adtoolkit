import Foundation

/// A ``TextSubstitutionFilter`` applied to a byte stream that arrives in
/// pieces — keystrokes on their way to a shell, output on its way to the
/// screen — where a word can be split across two reads.
///
/// Bytes, not text, because a terminal stream is not guaranteed to be valid
/// UTF-8 at any boundary, and decoding it to match would corrupt whatever
/// binary or half-character sits at the end of a read. Patterns are matched as
/// their UTF-8 bytes: ASCII letters case-insensitively, everything else
/// exactly. That is narrower than the filter's own `String` matching, which
/// folds case for every script — a stream cannot afford Unicode case folding
/// across a read boundary, and names typed at a shell are overwhelmingly ASCII.
///
/// A run of bytes that could still become a match is **held** rather than
/// emitted, because emitting half a name and matching the other half later is
/// exactly the leak this exists to stop. What is held comes out when the
/// stream diverges from every pattern, when a pattern completes, or when the
/// owner calls ``flush()`` — the output side does, after a moment of quiet, so
/// a prompt ending in "mike" is not kept off the screen forever.
public struct StreamingTextSubstitution: Sendable {

    public enum Direction: Sendable {
        /// Aliases replaced by the real text — what goes *to* the program.
        case revealing
        /// Real text replaced by aliases — what comes *back* to the user.
        case concealing
    }

    private struct Pattern: Sendable {
        /// Lowercased ASCII, so a byte compares after one lowercase of its own.
        let bytes: [UInt8]
        let replacement: [UInt8]
    }

    /// Longest first, so "mike fullerton" is taken whole before "mike".
    private let patterns: [Pattern]
    /// The first byte of every pattern, lowercased: any other byte can be
    /// emitted without looking further, which is nearly every byte of output.
    private let firstBytes: Set<UInt8>
    private var held: [UInt8] = []

    public init(filter: TextSubstitutionFilter, direction: Direction) {
        let mapping = filter.pairs.map { pair in
            direction == .revealing ? (pair.alias, pair.real) : (pair.real, pair.alias)
        }
        patterns = mapping
            .map { Pattern(bytes: Array($0.0.utf8).map(Self.lowercased), replacement: Array($0.1.utf8)) }
            .sorted { $0.bytes.count > $1.bytes.count }
        firstBytes = Set(patterns.compactMap(\.bytes.first))
    }

    /// Whether bytes are being held back for want of more input.
    public var isHolding: Bool { !held.isEmpty }

    /// Takes the next read and returns what can be passed on now; anything
    /// that could still turn out to be a match is kept for the next call.
    public mutating func feed<Bytes: Sequence>(_ bytes: Bytes) -> [UInt8] where Bytes.Element == UInt8 {
        guard !patterns.isEmpty else {
            let passed = held + Array(bytes)
            held.removeAll()
            return passed
        }
        held.append(contentsOf: bytes)
        return drain(final: false)
    }

    /// Passes on everything held, substituting whatever already matches.
    public mutating func flush() -> [UInt8] {
        drain(final: true)
    }

    private mutating func drain(final: Bool) -> [UInt8] {
        let input = held
        var output: [UInt8] = []
        output.reserveCapacity(input.count)
        var index = 0
        scanning: while index < input.count {
            let byte = input[index]
            guard firstBytes.contains(Self.lowercased(byte)) else {
                output.append(byte)
                index += 1
                continue
            }
            let remaining = input.count - index
            let couldStillMatch = patterns.contains {
                $0.bytes.count > remaining && matches(input, at: index, $0.bytes, length: remaining)
            }
            if !final, couldStillMatch {
                held = Array(input[index...])
                return output
            }
            for pattern in patterns where pattern.bytes.count <= remaining
                && matches(input, at: index, pattern.bytes, length: pattern.bytes.count) {
                output.append(contentsOf: pattern.replacement)
                index += pattern.bytes.count
                continue scanning
            }
            output.append(byte)
            index += 1
        }
        held.removeAll()
        return output
    }

    /// Whether the first `length` bytes of `pattern` match `input` from `start`.
    private func matches(_ input: [UInt8], at start: Int, _ pattern: [UInt8], length: Int) -> Bool {
        for offset in 0..<length where Self.lowercased(input[start + offset]) != pattern[offset] {
            return false
        }
        return true
    }

    private static func lowercased(_ byte: UInt8) -> UInt8 {
        (0x41...0x5A).contains(byte) ? byte | 0x20 : byte
    }
}
