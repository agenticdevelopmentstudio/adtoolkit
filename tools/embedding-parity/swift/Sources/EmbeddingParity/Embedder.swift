// Turns text into a semantic search vector from a model bundle built by
// symanticsearchmodel. Everything model-specific comes from the bundle's
// manifest, so swapping the model means swapping the bundle, not this file.

import CryptoKit
import Foundation
import OnnxRuntimeBindings
import Tokenizers

public struct Manifest: Decodable, Sendable {
    public struct Prefixes: Decodable, Sendable {
        public let query: String
        public let document: String
        public let documentUntitled: String

        enum CodingKeys: String, CodingKey {
            case query, document
            case documentUntitled = "document_untitled"
        }
    }

    public struct File: Decodable, Sendable {
        public let sha256: String
        public let bytes: Int
    }

    public let name: String
    public let prefixes: Prefixes
    public let maxTokens: Int?
    public let output: String
    public let truncateDims: Int
    public let files: [String: File]

    enum CodingKeys: String, CodingKey {
        case name, prefixes, output, files
        case maxTokens = "max_tokens"
        case truncateDims = "truncate_dims"
    }
}

public enum EmbedderError: Error, CustomStringConvertible {
    case hashMismatch(file: String, actual: String, expected: String)
    case truncationRequested(Int)
    case missingOutput(String)

    public var description: String {
        switch self {
        case let .hashMismatch(file, actual, expected):
            "\(file) has sha256 \(actual), the manifest says \(expected)"
        case let .truncationRequested(n):
            "this embedder cuts nothing, and the manifest asks for max_tokens \(n)"
        case let .missingOutput(name):
            "the model gave no \(name) output"
        }
    }
}

func sha256(of url: URL) throws -> String {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    var hasher = SHA256()
    while let chunk = try handle.read(upToCount: 1 << 20), !chunk.isEmpty {
        hasher.update(data: chunk)
    }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
}

public final class Embedder: @unchecked Sendable {
    public let manifest: Manifest
    private let tokenizer: Tokenizer
    private let env: ORTEnv
    private let session: ORTSession

    /// Fails unless every file the manifest lists has its recorded hash. A
    /// bundle checked out without git LFS holds pointer files instead, and
    /// this is where that shows up.
    public static func verify(bundle: URL, manifest: Manifest) throws {
        for (name, file) in manifest.files {
            let actual = try sha256(of: bundle.appendingPathComponent(name))
            guard actual == file.sha256 else {
                throw EmbedderError.hashMismatch(file: name, actual: actual, expected: file.sha256)
            }
        }
    }

    public init(bundle: URL, verify: Bool = true) async throws {
        manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: bundle.appendingPathComponent("manifest.json")))
        if let limit = manifest.maxTokens { throw EmbedderError.truncationRequested(limit) }
        if verify { try Self.verify(bundle: bundle, manifest: manifest) }

        tokenizer = try await AutoTokenizer.from(modelFolder: bundle)
        env = try ORTEnv(loggingLevel: .warning)
        let options = try ORTSessionOptions()
        try options.setGraphOptimizationLevel(.all)
        session = try ORTSession(env: env, modelPath: bundle.appendingPathComponent("model.onnx").path, sessionOptions: options)
    }

    public func queryText(_ text: String) -> String {
        manifest.prefixes.query + text
    }

    public func documentText(_ text: String, title: String? = nil) -> String {
        guard let title else { return manifest.prefixes.documentUntitled + text }
        return manifest.prefixes.document.replacingOccurrences(of: "{title}", with: title) + text
    }

    public func tokenize(_ prefixed: String) -> [Int] {
        tokenizer.encode(text: prefixed)
    }

    public func embed(prefixed: String) throws -> [Float] {
        var ids = tokenize(prefixed).map(Int64.init)
        var mask = [Int64](repeating: 1, count: ids.count)
        let shape: [NSNumber] = [1, NSNumber(value: ids.count)]
        let inputIds = try ORTValue(tensorData: NSMutableData(bytes: &ids, length: ids.count * 8), elementType: .int64, shape: shape)
        let attention = try ORTValue(tensorData: NSMutableData(bytes: &mask, length: mask.count * 8), elementType: .int64, shape: shape)
        let outputs = try session.run(
            withInputs: ["input_ids": inputIds, "attention_mask": attention],
            outputNames: [manifest.output],
            runOptions: nil
        )
        guard let value = outputs[manifest.output] else { throw EmbedderError.missingOutput(manifest.output) }
        let data = try value.tensorData() as Data
        let full = data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
        return Self.truncate(full, to: manifest.truncateDims)
    }

    public func embedQuery(_ text: String) throws -> [Float] {
        try embed(prefixed: queryText(text))
    }

    public func embedDocument(_ text: String, title: String? = nil) throws -> [Float] {
        try embed(prefixed: documentText(text, title: title))
    }

    static func truncate(_ vector: [Float], to dims: Int) -> [Float] {
        let cut = Array(vector.prefix(dims))
        let norm = cut.reduce(0) { $0 + $1 * $1 }.squareRoot()
        return cut.map { $0 / norm }
    }
}
